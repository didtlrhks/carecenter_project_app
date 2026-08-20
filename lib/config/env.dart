import 'dev_settings.dart';

/// Base URL: `{API}/api/v1`
///
/// 우선순위:
/// 1. `--dart-define=API_BASE_URL=...`
/// 2. [kApiBaseUrl] (운영 기본값)
class Env {
  Env._();

  static const dartDefine = String.fromEnvironment('API_BASE_URL');

  static String defaultBaseUrl() {
    if (dartDefine.isNotEmpty) return _normalize(dartDefine);
    return _normalize(kApiBaseUrl);
  }

  static String _normalize(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) return trimmed.substring(0, trimmed.length - 1);
    return trimmed;
  }

  /// 예전에 저장된 로컬/에뮬레이터 주소면 true. 운영 URL로 교체한다.
  static bool looksLikeStaleLocalHost(String url) {
    final u = url.toLowerCase();
    return u.contains('10.0.2.2') ||
        u.contains('localhost') ||
        u.contains('127.0.0.1') ||
        u.contains('10.31.120.') ||
        u.startsWith('http://192.168.') ||
        (u.contains('yoyangcall.xyz') && u.startsWith('http://'));
  }
}
