import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import '../models/me.dart';
import '../services/api_client.dart';
import '../services/biometric_service.dart';
import '../services/token_store.dart';
import '../utils/phone.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.api, this.store, {BiometricService? biometric})
      : biometric = biometric ?? BiometricService();

  final ApiClient api;
  final TokenStore store;
  final BiometricService biometric;

  bool ready = false;
  /// 토큰은 있지만 생체 인증 전.
  bool locked = false;
  Me? user;
  String? lastError;
  bool justLoggedInWithPassword = false;

  /// 로그인/복원 직후 FCM 토큰 등록 등.
  Future<void> Function()? onSessionReady;

  bool get isLoggedIn => user != null && !locked;

  Future<void> bootstrap() async {
    api.applyBaseUrl(store.apiBaseUrl);
    api.onUnauthorized = () {
      user = null;
      locked = false;
      notifyListeners();
    };

    final access = await store.accessToken;
    final hasSession = access != null && access.isNotEmpty;

    if (!hasSession) {
      // 세션 없는데 생체만 켜져 있으면 불일치 → 로그인 화면으로
      if (store.biometricEnabled) {
        await store.setBiometricEnabled(false);
      }
      locked = false;
      user = null;
      ready = true;
      notifyListeners();
      return;
    }

    if (store.biometricEnabled) {
      locked = true;
      user = await store.readUser();
      ready = true;
      notifyListeners();
      return;
    }

    await _restoreSession();
    ready = true;
    notifyListeners();
  }

  Future<void> unlockWithBiometrics() async {
    lastError = null;
    final ok = await biometric.authenticate(reason: '요양보호사 앱을 열려면 인증해 주세요');
    if (!ok) {
      lastError = '인증에 실패했습니다. 다시 시도하거나 비밀번호로 로그인하세요.';
      notifyListeners();
      return;
    }
    await _restoreSession();
    if (user == null) {
      locked = false;
      lastError = '세션이 만료되었습니다. 비밀번호로 다시 로그인해 주세요.';
      notifyListeners();
      return;
    }
    locked = false;
    notifyListeners();
  }

  Future<void> unlockWithPasswordFallback() async {
    // 비밀번호 로그인 화면으로 보낼 때 세션만 지움. 생체 설정은 유지(다시 켤 필요 없음).
    await logout(keepBiometricPreference: true);
  }

  Future<void> _restoreSession() async {
    final cached = await store.readUser();
    try {
      final me = await api.me();
      if (!me.isCaregiver) {
        await _clearRemoteSession(clearBiometric: true);
        user = null;
        locked = false;
        return;
      }
      user = me;
      locked = false;
      await store.persistUser(me);
      await _registerStoredDeviceToken();
      await onSessionReady?.call();
    } catch (_) {
      if (cached != null && cached.isCaregiver) {
        user = cached;
        locked = false;
      } else {
        await store.clearSession();
        user = null;
        locked = false;
      }
    }
  }

  Future<void> login(String loginId, String password) async {
    lastError = null;
    justLoggedInWithPassword = false;
    final phone = digitsOnly(loginId);
    final payload = await api.login(phone, password);
    if (!payload.user.isCaregiver) {
      try {
        await api.logout(payload.refreshToken);
      } catch (_) {}
      throw ApiException(403, 'FORBIDDEN_ROLE', '센터 관리자는 웹을 사용하세요');
    }
    await store.persist(payload);
    await store.setLastPhone(phone);
    user = payload.user;
    locked = false;
    justLoggedInWithPassword = true;
    notifyListeners();
    try {
      await _registerStoredDeviceToken();
      await onSessionReady?.call();
    } catch (e) {
      // 푸시 등록 실패해도 로그인은 유지
      debugPrint('onSessionReady failed: $e');
    }
  }

  void clearJustLoggedInFlag() {
    if (!justLoggedInWithPassword) return;
    justLoggedInWithPassword = false;
  }

  Future<bool> offerBiometricIfAvailable() async {
    if (store.biometricEnabled) return false;
    return biometric.isAvailable;
  }

  Future<void> enableBiometric() async {
    final ok = await biometric.authenticate(reason: '다음부터 지문·얼굴로 앱을 열려면 인증해 주세요');
    if (!ok) {
      throw ApiException(400, 'BIOMETRIC_FAILED', '생체 인증에 실패했습니다.');
    }
    await store.setBiometricEnabled(true);
    notifyListeners();
  }

  Future<void> logout({bool keepBiometricPreference = false}) async {
    try {
      await _unregisterDeviceToken();
    } catch (_) {}
    try {
      await _clearRemoteSession(clearBiometric: !keepBiometricPreference);
    } catch (_) {
      await store.clearSession();
      if (!keepBiometricPreference) {
        await store.setBiometricEnabled(false);
      }
    }
    user = null;
    locked = false;
    justLoggedInWithPassword = false;
    notifyListeners();
  }

  Future<void> _clearRemoteSession({bool clearBiometric = false}) async {
    final refresh = await store.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      await api.logout(refresh);
    }
    await store.clearSession();
    if (clearBiometric) {
      await store.setBiometricEnabled(false);
    }
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
