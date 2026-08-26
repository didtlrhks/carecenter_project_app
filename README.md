# 요양보호사 앱

재가센터에서 온 **근무 콜**에 응답하는 Flutter 앱입니다.  
앱 사용자는 **CAREGIVER** 만입니다. 센터 관리/최종 수락은 웹을 사용합니다.

## 제품 규칙

1. 콜이 오면 **[가능] / [거절]** 을 고른다.
2. **[가능] = 지원이지 확정이 아니다.**  
   카피: “지원이 전달되었습니다. 센터가 최종 수락하면 확정됩니다.”
3. 확정은 센터가 최종 수락한 뒤에만 일어난다. 그때 `ASSIGNED` 알림 + 내 일정에 표시.
4. 다른 사람이 선정되면 “마감되었습니다” 알림. 일정은 생기지 않는다.
5. 초대받지 않은 공고는 서버가 404를 준다.

## 화면

하단 탭: **콜 / 일정 / 알림 / 내정보**

- 콜: 진행중(`INVITED`, `APPLIED`) / 지난 건(`SELECTED`, `NOT_SELECTED`, `REJECTED`)
- 일정: `GET /me/schedules` — **확정된 근무만**. 지원 중인 건은 그리지 않음
- 알림: 인박스 + 포그라운드 25초 폴링 + pull-to-refresh
- 내정보: 대타/신규 수락, 가능 시간, 활동 지역

## 실행

운영 API: `https://api.yoyangcall.xyz/api/v1`  
Swagger: `https://api.yoyangcall.xyz/api/docs`

```bash
cd center-service-app
flutter pub get
flutter run
```

로컬 서버를 쓰려면:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

시드 계정: `01012345678` / `Caregiver123!`

## 로그인

**로그인은 Firebase Auth가 아닙니다.** 센터에 등록된 전화번호 + 비밀번호로 서버 `POST /auth/login` 만 호출합니다.  
가입·비밀번호 찾기 UI는 없습니다. 모를 때는 센터에 문의합니다.

### UX

- 전화번호는 `010-1234-5678` 형식으로 보이고, 서버에는 숫자만 보냅니다.
- 마지막 로그인 번호는 기기에 기억됩니다.
- 첫 로그인 성공 후 **지문/얼굴로 열기**를 켤 수 있습니다.
- 켠 뒤에는 앱 재실행 시 생체 인증으로 세션을 엽니다. 세션이 만료되면 비밀번호를 다시 입력합니다.

### 확인

| 경우 | 기대 |
|------|------|
| 미등록 번호 | 로그인 실패 |
| 시드 `01012345678` / `Caregiver123!` | 성공 → (선택) 생체 설정 → 재실행 시 지문/얼굴 |
| CAREGIVER가 아닌 계정 | “센터 관리자는 웹을 사용하세요” |

## Firebase 푸시 (FCM)

Firebase는 **푸시만** 담당합니다. 로그인 성공 후 FCM 토큰을 `POST /me/device-tokens` 로 올립니다.  
설정 전에는 인박스 API 폴링만으로 알림 탭이 동작합니다.

### 1회 연결

콘솔에서 앱을 등록합니다.

- Android: `kr.centerservice.center_service_app`
- iOS: `kr.centerserviceapp.centerServiceApp`

로컬 터미널에서 (브라우저 로그인 필요):

```bash
./tool/configure_firebase.sh
```

또는 수동으로:

```bash
firebase login --reauth
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"
cd center-service-app
flutterfire configure \
  --platforms=android,ios \
  --android-package-name=kr.centerservice.center_service_app \
  --ios-bundle-id=kr.centerserviceapp.centerServiceApp
```

생성·갱신되는 파일:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Android Google Services 플러그인은 `android/settings.gradle.kts`에 등록되어 있고,  
`google-services.json`이 있을 때만 `android/app/build.gradle.kts`에서 적용됩니다.

### 푸시 확인

1. 앱 로그인 후 로그에 FCM 토큰 / 서버 `device-tokens` 등록 확인
2. Firebase 콘솔 → Messaging → **테스트 메시지** → 앱 토큰 붙여넣기
3. 포그라운드: 로컬 알림 / 백그라운드·종료: 시스템 알림
4. 알림 탭 또는 `jobRequestId` 딥링크로 공고 상세

서버가 FCM Admin으로 자동 발송하기 전이어도, 콘솔 테스트 메시지로 수신은 확인할 수 있습니다.

### 스토어 없이 확인

| 무엇을 | 스토어 배포 | 필요한 것 |
|--------|-------------|-----------|
| 전화번호 로그인 | **필요 없음** | `flutter run` + 백엔드 |
| FCM 푸시 (Android) | **필요 없음** | 실기기 + Firebase 앱 등록 + `flutterfire configure` |
| FCM 푸시 (iOS) | 스토어는 필요 없음 | **유료 Apple Developer** + APNs 키 + **실기기** |

## API

- Base: `{API}/api/v1`
- `Authorization: Bearer {accessToken}`
- 응답: `{ data, error }`
- access 만료 → `POST /auth/refresh` → 실패 시 로그인
- 시각은 UTC로 받고 **KST**로 표시
- 토큰은 Secure Storage에 저장

## 구현 범위

- [x] 로그인 / 토큰 저장 / `GET /me` + CAREGIVER 검사
- [x] 큰 UI · 전화 하이픈 · 번호 기억 · 생체 잠금해제
- [x] 콜 목록 + 상세 (확정 전 주소 비공개)
- [x] 가능 / 거절 / 철회
- [x] 알림함 폴링
- [x] 내 일정 (SELECTED 이후만)
- [x] 프로필 · 가능시간 · 활동지역
- [x] FCM 토큰 등록 / 알림 탭 딥링크 (Firebase 프로젝트 연결 후 실동작)
- [ ] 서버 FCM 발송 (center-service)
