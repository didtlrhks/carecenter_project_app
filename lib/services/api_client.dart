import 'dart:async';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../models/api_error.dart';
import '../models/caregiver_profile.dart';
import '../models/job_request.dart';
import '../models/me.dart';
import '../models/notification_item.dart';
import '../models/page_result.dart';
import '../models/schedule.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient(this._store) {
    dio = Dio(
      BaseOptions(
        baseUrl: _store.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Content-Type': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] != true) {
            final token = await _store.accessToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  final TokenStore _store;
  late final Dio dio;

  void Function()? onUnauthorized;

  Future<_RefreshOutcome>? _refreshInFlight;

  void applyBaseUrl(String url) {
    dio.options.baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<T> _request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? query,
    bool skipAuth = false,
    bool retried = false,
    required T Function(dynamic json) parse,
  }) async {
    try {
      final res = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          extra: {'skipAuth': skipAuth, '_retried': retried},
        ),
      );

      final status = res.statusCode ?? 0;
      final body = res.data;

      if (status == 401 && !skipAuth && !retried) {
        final outcome = await _refresh();
        if (outcome == _RefreshOutcome.success) {
          return _request(
            path,
            method: method,
            data: data,
            query: query,
            skipAuth: skipAuth,
            retried: true,
            parse: parse,
          );
        }
        if (outcome == _RefreshOutcome.invalidSession) {
          onUnauthorized?.call();
        }
        throw _errorFrom(status, body, fallback: '로그인이 필요합니다.');
      }

      if (body is! Map) {
        throw ApiException(status, 'UNKNOWN', '서버 응답을 읽을 수 없습니다.');
      }
      final map = Map<String, dynamic>.from(body);
      final error = map['error'];
      if (status >= 400 || error != null || !map.containsKey('data')) {
        throw _errorFrom(status, map, fallback: '요청에 실패했습니다.');
      }
      return parse(map['data']);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      final status = e.response?.statusCode ?? 0;
      if (status == 401 && !skipAuth && !retried) {
        final outcome = await _refresh();
        if (outcome == _RefreshOutcome.success) {
          return _request(
            path,
            method: method,
            data: data,
            query: query,
            skipAuth: skipAuth,
            retried: true,
            parse: parse,
          );
        }
        if (outcome == _RefreshOutcome.invalidSession) {
          onUnauthorized?.call();
        }
      }
      throw ApiException(status, 'NETWORK', _networkMessage(e));
    }
  }

  String _networkMessage(DioException e) {
    final base = dio.options.baseUrl;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '서버 응답이 없습니다.\n$base';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (Env.looksLikeStaleLocalHost(base)) {
          return '서버에 연결할 수 없습니다.\n로컬 주소가 남아 있습니다. 앱을 재시작하면 운영 API로 바뀝니다.\n현재: $base';
        }
        return '서버에 연결할 수 없습니다.\n$base\n백엔드가 켜져 있고 같은 Wi‑Fi인지 확인해 주세요.';
      default:
        return '네트워크 오류가 발생했습니다.\n$base';
    }
  }

  ApiException _errorFrom(int status, dynamic body, {required String fallback}) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        return ApiException(
          status,
          error['code'] as String? ?? 'UNKNOWN',
          error['message'] as String? ?? fallback,
        );
      }
    }
    return ApiException(status, status == 0 ? 'NETWORK' : 'UNKNOWN', fallback);
  }

  Future<_RefreshOutcome> _refresh() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }
    final completer = Completer<_RefreshOutcome>();
    _refreshInFlight = completer.future;
    try {
      final outcome = await _doRefresh();
      completer.complete(outcome);
      return outcome;
    } catch (e) {
      completer.complete(_RefreshOutcome.transientFailure);
      return _RefreshOutcome.transientFailure;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<_RefreshOutcome> _doRefresh() async {
    final refreshToken = await _store.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _store.clearSession();
      return _RefreshOutcome.invalidSession;
    }

    try {
      final res = await dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final body = res.data;
      final status = res.statusCode ?? 0;

      // 서버가 리프레시를 거부한 경우만 로그아웃
      if (status == 401 || status == 403) {
        await _store.clearSession();
        return _RefreshOutcome.invalidSession;
      }

      if (status != 200 || body is! Map) {
        return _RefreshOutcome.transientFailure;
      }

      final map = Map<String, dynamic>.from(body);
      final error = map['error'];
      if (error != null || map['data'] == null) {
        final code = error is Map ? error['code'] as String? : null;
        if (code == 'UNAUTHENTICATED' || status == 401) {
          await _store.clearSession();
          return _RefreshOutcome.invalidSession;
        }
        return _RefreshOutcome.transientFailure;
      }

      final data = Map<String, dynamic>.from(map['data'] as Map);
      final tokens = RefreshTokens.fromJson(data);
      await _store.persistTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      if (data['user'] is Map) {
        await _store.persistUser(Me.fromJson(Map<String, dynamic>.from(data['user'] as Map)));
      }
      return _RefreshOutcome.success;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 401 || status == 403) {
        await _store.clearSession();
        return _RefreshOutcome.invalidSession;
      }
      // 타임아웃·연결 실패 시 세션 유지 (폴링이 로그인으로 보내지 않도록)
      return _RefreshOutcome.transientFailure;
    } catch (_) {
      return _RefreshOutcome.transientFailure;
    }
  }

  Future<AuthPayload> login(String loginId, String password) {
    return _request(
      '/auth/login',
      method: 'POST',
      skipAuth: true,
      data: {'loginId': loginId, 'password': password},
      parse: (json) => AuthPayload.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _request(
        '/auth/logout',
        method: 'POST',
        skipAuth: true,
        data: {'refreshToken': refreshToken},
        parse: (_) => true,
      );
    } catch (_) {
      /* 폐기 실패해도 로컬 세션은 지운다 */
    }
  }

  Future<Me> me() {
    return _request('/me', parse: (json) => Me.fromJson(Map<String, dynamic>.from(json as Map)));
  }

  Future<PageResult<JobRequest>> myJobRequests({int page = 1, int pageSize = 50}) {
    return _request(
      '/me/job-requests',
      query: {'page': page, 'pageSize': pageSize},
      parse: (json) => PageResult.fromJson(Map<String, dynamic>.from(json as Map), JobRequest.fromJson),
    );
  }

  Future<JobRequest> myJobRequest(String id) {
    return _request(
      '/me/job-requests/$id',
      parse: (json) => JobRequest.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<JobRequest> apply(String id) {
    return _request(
      '/me/job-requests/$id/apply',
      method: 'POST',
      parse: (json) => JobRequest.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<JobRequest> reject(String id) {
    return _request(
      '/me/job-requests/$id/reject',
      method: 'POST',
      parse: (json) => JobRequest.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<JobRequest> withdraw(String id) {
    return _request(
      '/me/job-requests/$id/withdraw',
      method: 'POST',
      parse: (json) => JobRequest.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<PageResult<ScheduleItem>> mySchedules({int page = 1, int pageSize = 50}) {
    return _request(
      '/me/schedules',
      query: {'page': page, 'pageSize': pageSize},
      parse: (json) => PageResult.fromJson(Map<String, dynamic>.from(json as Map), ScheduleItem.fromJson),
    );
  }

  Future<PageResult<NotificationItem>> notifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 50,
  }) {
    return _request(
      '/me/notifications',
      query: {
        if (unreadOnly) 'unreadOnly': 'true',
        'page': page,
        'pageSize': pageSize,
      },
      parse: (json) =>
          PageResult.fromJson(Map<String, dynamic>.from(json as Map), NotificationItem.fromJson),
    );
  }

  Future<NotificationItem> markNotificationRead(String id) {
    return _request(
      '/me/notifications/$id/read',
      method: 'POST',
      parse: (json) => NotificationItem.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<CaregiverProfile> myCaregiver() {
    return _request(
      '/me/caregiver',
      parse: (json) => CaregiverProfile.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<CaregiverProfile> patchCaregiver({
    bool? acceptsBackup,
    bool? acceptsNew,
    bool? hasVehicle,
    String? gender,
  }) {
    return _request(
      '/me/caregiver',
      method: 'PATCH',
      data: {
        'acceptsBackup': ?acceptsBackup,
        'acceptsNew': ?acceptsNew,
        'hasVehicle': ?hasVehicle,
        'gender': ?gender,
      },
      parse: (json) => CaregiverProfile.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<List<Availability>> replaceAvailabilities(List<Availability> items) {
    return _request(
      '/me/caregiver/availabilities',
      method: 'PUT',
      data: {'items': items.map((e) => e.toItemJson()).toList()},
      parse: (json) {
        if (json is! List) return <Availability>[];
        return [
          for (final item in json)
            if (item is Map) Availability.fromJson(Map<String, dynamic>.from(item)),
        ];
      },
    );
  }

  Future<List<ServiceArea>> replaceServiceAreas(List<String> regionCodes) {
    return _request(
      '/me/caregiver/service-areas',
      method: 'PUT',
      data: {'regionCodes': regionCodes},
      parse: (json) {
        if (json is! List) return <ServiceArea>[];
        return [
          for (final item in json)
            if (item is Map) ServiceArea.fromJson(Map<String, dynamic>.from(item)),
        ];
      },
    );
  }

  Future<void> registerDeviceToken(String token, String platform) {
    return _request(
      '/me/device-tokens',
      method: 'POST',
      data: {'token': token, 'platform': platform},
      parse: (_) {},
    );
  }

  Future<void> unregisterDeviceToken(String token) {
    return _request(
      '/me/device-tokens/unregister',
      method: 'POST',
      data: {'token': token},
      parse: (_) {},
    );
  }
}

enum _RefreshOutcome {
  success,
  /// 리프레시 토큰 만료/폐기 → 로그인 필요
  invalidSession,
  /// 일시적 네트워크/서버 오류 → 세션 유지
  transientFailure,
}
