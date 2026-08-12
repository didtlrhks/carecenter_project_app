import 'dart:io';

import 'package:flutter/foundation.dart';

import 'dev_settings.dart';

/// Base URL: `{API}/api/v1`
///
/// 우선순위:
/// 1. `--dart-define=API_BASE_URL=...`
/// 2. `--dart-define=DEV_HOST=...`
/// 3. [kDevHost] (실기기/개발 기본값 — 한 번만 맞추면 됨)
/// 4. iOS 시뮬레이터: localhost
class Env {
  Env._();

  static const dartDefine = String.fromEnvironment('API_BASE_URL');
  static const devHostDefine = String.fromEnvironment('DEV_HOST');

  static String get _devHost {
    if (devHostDefine.isNotEmpty) return devHostDefine;
    return kDevHost;
  }

  static String defaultBaseUrl() {
    if (dartDefine.isNotEmpty) return _normalize(dartDefine);
    // 개발 기본: Mac LAN IP. 실기기·에뮬레이터 모두 동일 Wi‑Fi면 이 주소로 접속.
    if (kDebugMode || (!kIsWeb && Platform.isAndroid)) {
      return _normalize('http://$_devHost:$kDevPort/api/v1');
    }
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      return 'http://localhost:$kDevPort/api/v1';
    }
    return _normalize('http://$_devHost:$kDevPort/api/v1');
  }

  static String _normalize(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) return trimmed.substring(0, trimmed.length - 1);
    return trimmed;
  }

  /// 예전에 저장된 에뮬레이터/루프백 주소면 true.
  static bool looksLikeEmulatorOnlyHost(String url) {
    final u = url.toLowerCase();
    return u.contains('10.0.2.2') || u.contains('localhost') || u.contains('127.0.0.1');
  }
}
