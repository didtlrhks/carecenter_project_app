#!/usr/bin/env bash
# Firebase / FlutterFire 연결 (인터랙티브 로그인 필요)
set -euo pipefail
cd "$(dirname "$0")/.."

export PATH="$PATH:$HOME/.pub-cache/bin"

if ! command -v flutterfire >/dev/null 2>&1; then
  dart pub global activate flutterfire_cli
fi

echo "Firebase 로그인 상태를 확인합니다…"
if ! firebase projects:list >/dev/null 2>&1; then
  echo "토큰이 만료됐거나 로그인이 필요합니다. 브라우저에서 로그인하세요."
  firebase login --reauth
fi

echo "프로젝트를 선택한 뒤 Android/iOS 앱을 연결합니다."
flutterfire configure \
  --platforms=android,ios \
  --android-package-name=kr.centerservice.center_service_app \
  --ios-bundle-id=kr.centerserviceapp.centerServiceApp

echo "완료: lib/firebase_options.dart, google-services.json, GoogleService-Info.plist"
echo "다음: 앱 로그인 후 로그에서 [Push] device token registered 확인,"
echo "      Firebase 콘솔 Messaging → 테스트 메시지로 수신 확인."
