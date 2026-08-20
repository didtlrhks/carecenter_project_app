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

## 로그인 vs Firebase

**로그인은 Firebase Auth가 아닙니다.** 전화번호 + 비밀번호로 우리 서버 `POST /auth/login` 을 칩니다. SNS(구글/애플/카카오) 없음.

Firebase는 **푸시(FCM)** 용입니다. 로그인 성공 후 FCM 토큰을 `POST /me/device-tokens` 로 올립니다.

### 스토어 배포 없이 확인할 수 있나?

| 무엇을 | 스토어 배포 | 필요한 것 |
|--------|-------------|-----------|
| 전화번호 로그인 | **필요 없음** | `flutter run` + 백엔드. 이미 동작 |
| Firebase 이메일/비번 로그인 (쓰지 않음) | 필요 없음 | `google-services.json` 만 있으면 debug로 확인 가능 |
| FCM 푸시 (Android) | **필요 없음** | 실기기 + Firebase 앱 등록 + `flutterfire configure` |
| FCM 푸시 (iOS) | 스토어는 필요 없음 | **유료 Apple Developer** + APNs 키 + **실기기** (시뮬레이터 불가) |

Play Store / App Store 올리기 전에 debug 빌드로 로그인·푸시 모두 확인 가능합니다.

## Firebase 프로젝트 연결 (푸시)

콘솔에서 Android 앱 ID `kr.centerservice.center_service_app`, iOS `kr.centerserviceapp.centerServiceApp` 로 앱을 만든 뒤:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

이 명령이 `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` 를 채웁니다.

설정 전에는 앱이 그대로 로그인/인박스 폴링으로 동작합니다. Firebase 초기화만 건너뜁니다.

푸시 페이로드의 `jobRequestId` 로 공고 상세를 엽니다.

서버 FCM 발송은 아직 인박스 저장이 기본입니다. 앱 수신·토큰 등록은 준비됐고, 콘솔에서 테스트 메시지를 보내 수신을 확인할 수 있습니다.

## API

- Base: `{API}/api/v1`
- `Authorization: Bearer {accessToken}`
- 응답: `{ data, error }`
- access 만료 → `POST /auth/refresh` → 실패 시 로그인
- 시각은 UTC로 받고 **KST**로 표시
- 토큰은 Secure Storage에 저장

## 구현 범위

- [x] 로그인 / 토큰 저장 / `GET /me` + CAREGIVER 검사
- [x] 콜 목록 + 상세 (확정 전 주소 비공개)
- [x] 가능 / 거절 / 철회
- [x] 알림함 폴링
- [x] 내 일정 (SELECTED 이후만)
- [x] 프로필 · 가능시간 · 활동지역
- [x] FCM 토큰 등록 / 알림 탭 딥링크 (Firebase 프로젝트 연결 후 실동작)
- [ ] 서버 FCM 발송 (center-service)
