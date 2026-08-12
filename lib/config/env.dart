import 'dart:io';

import 'package:flutter/foundation.dart';

/// Base URL: `{API}/api/v1`
///
/// 우선순위:
/// 1. `--dart-define=API_BASE_URL=...`
/// 2. 로그인 화면에서 저장한 개발용 주소
/// 3. 플랫폼 기본값 (Android 에뮬레이터는 10.0.2.2)
class Env {
  Env._();

  static const dartDefine = String.fromEnvironment('API_BASE_URL');

  static String defaultBaseUrl() {
    if (dartDefine.isNotEmpty) return dartDefine;
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }
}
