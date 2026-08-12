import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/me.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.api, this.store);

  final ApiClient api;
  final TokenStore store;

  bool ready = false;
  Me? user;
  String? lastError;

  /// 로그인/복원 직후 FCM 토큰 등록 등.
  Future<void> Function()? onSessionReady;

  bool get isLoggedIn => user != null;

  Future<void> bootstrap() async {
    api.applyBaseUrl(store.apiBaseUrl);
    api.onUnauthorized = () {
      user = null;
      notifyListeners();
    };
    final cached = await store.readUser();
    final access = await store.accessToken;
    if (access != null && access.isNotEmpty) {
      try {
        final me = await api.me();
        if (!me.isCaregiver) {
          await _clearRemoteSession();
          user = null;
        } else {
          user = me;
          await store.persistUser(me);
          await _registerStoredDeviceToken();
          await onSessionReady?.call();
        }
      } catch (_) {
        if (cached != null && cached.isCaregiver) {
          user = cached;
        } else {
          await store.clearSession();
          user = null;
        }
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String loginId, String password) async {
    lastError = null;
    final payload = await api.login(loginId.trim(), password);
    if (!payload.user.isCaregiver) {
      try {
        await api.logout(payload.refreshToken);
      } catch (_) {}
      throw ApiException(403, 'FORBIDDEN_ROLE', '센터 관리자는 웹을 사용하세요');
    }
    await store.persist(payload);
    user = payload.user;
    notifyListeners();
    await _registerStoredDeviceToken();
    await onSessionReady?.call();
  }

  Future<void> logout() async {
    await _unregisterDeviceToken();
    await _clearRemoteSession();
    user = null;
    notifyListeners();
  }

  Future<void> _clearRemoteSession() async {
    final refresh = await store.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      await api.logout(refresh);
    }
    await store.clearSession();
  }

  Future<void> _registerStoredDeviceToken() async {
    final token = await store.fcmToken;
    if (token == null || token.isEmpty) return;
    try {
      await api.registerDeviceToken(token, _platform);
    } catch (_) {}
  }

  Future<void> _unregisterDeviceToken() async {
    final token = await store.fcmToken;
    if (token == null || token.isEmpty) return;
    try {
      await api.unregisterDeviceToken(token);
    } catch (_) {}
  }

  /// FCM 연동 후 호출. 로그인 상태면 즉시 서버에 등록한다.
  Future<void> setDeviceToken(String token) async {
    await store.setFcmToken(token);
    if (!isLoggedIn) return;
    await api.registerDeviceToken(token, _platform);
  }

  String get _platform {
    if (kIsWeb) return 'ANDROID';
    return Platform.isIOS ? 'IOS' : 'ANDROID';
  }
}
