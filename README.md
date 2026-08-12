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

백엔드가 `http://localhost:3000` 에서 켜져 있어야 합니다.

```bash
cd center-service-app
flutter pub get
flutter run
```

| 환경 | 기본 API |
|------|----------|
| iOS 시뮬레이터 / macOS | `http://localhost:3000/api/v1` |
| Android 에뮬레이터 | `http://10.0.2.2:3000/api/v1` |
| 실제 기기 | 로그인 화면 **서버 설정**에 Mac IP 입력. 예: `http://192.168.0.10:3000/api/v1` |

강제 지정:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000/api/v1
```

## 시드 계정

| loginId | password |
|---------|----------|
| `01012345678` | `Caregiver123!` |

센터 관리자 계정으로 로그인하면 “센터 관리자는 웹을 사용하세요” 후 로그아웃됩니다.

## API

- Base: `{API}/api/v1`
- `Authorization: Bearer {accessToken}`
- 응답: `{ data, error }`
- access 만료 → `POST /auth/refresh` → 실패 시 로그인
- 시각은 UTC로 받고 **KST**로 표시
- 토큰은 Secure Storage에 저장

FCM 디바이스 토큰 API(`POST /me/device-tokens`)는 클라이언트에 준비되어 있습니다.  
서버 Push 연동 전이므로 MVP는 인박스 폴링을 사용합니다.

## 구현 범위 (MVP 1–6)

- [x] 로그인 / 토큰 저장 / `GET /me` + CAREGIVER 검사
- [x] 콜 목록 + 상세 (확정 전 주소 비공개)
- [x] 가능 / 거절 / 철회
- [x] 알림함 폴링
- [x] 내 일정 (SELECTED 이후만)
- [x] 프로필 · 가능시간 · 활동지역
- [ ] FCM 토큰 실연동 (다음 단계)
- [ ] 백그라운드 푸시 딥링크 (다음 단계)
