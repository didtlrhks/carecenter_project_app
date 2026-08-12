import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../models/me.dart';

class TokenStore {
  static const _accessKey = 'cs.accessToken';
  static const _refreshKey = 'cs.refreshToken';
  static const _userKey = 'cs.user';
  static const _apiKey = 'cs.apiBaseUrl';
  static const _fcmKey = 'cs.fcmToken';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get apiBaseUrl => _prefs?.getString(_apiKey) ?? Env.defaultBaseUrl();

  Future<void> setApiBaseUrl(String url) async {
    await _prefs?.setString(_apiKey, url.trim());
  }

  Future<String?> get accessToken => _secure.read(key: _accessKey);
  Future<String?> get refreshToken => _secure.read(key: _refreshKey);
  Future<String?> get fcmToken => _secure.read(key: _fcmKey);

  Future<void> setFcmToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _secure.delete(key: _fcmKey);
    } else {
      await _secure.write(key: _fcmKey, value: token);
    }
  }

  Future<Me?> readUser() async {
    final raw = await _secure.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Me.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> persist(AuthPayload payload) async {
    await _secure.write(key: _accessKey, value: payload.accessToken);
    await _secure.write(key: _refreshKey, value: payload.refreshToken);
    await _secure.write(key: _userKey, value: jsonEncode(payload.user.toJson()));
  }

  Future<void> persistTokens({required String accessToken, required String refreshToken}) async {
    await _secure.write(key: _accessKey, value: accessToken);
    await _secure.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> persistUser(Me user) async {
    await _secure.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
    await _secure.delete(key: _userKey);
  }
}
