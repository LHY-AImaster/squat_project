# ☁️ Cloud Deployment

본 문서는 Supabase PostgreSQL과 Render를 활용한 SquatMate의 백엔드 배포 및 Android 앱 빌드 절차를 설명합니다.

## 1. Create PostgreSQL Database

[Supabase](https://supabase.com/)에서 PostgreSQL 프로젝트를 생성합니다.

- 데이터베이스 접속 정보를 확인합니다.
- 서버에서 사용할 접속 정보를 준비합니다.
- 연결 방식과 네트워크 설정은 Supabase가 제공하는 연결 정보를 따릅니다.

## 2. Deploy Backend

[Render](https://render.com/)에서 GitHub 저장소를 연결하고 Web Service를 생성합니다.

- 저장소와 배포 브랜치를 선택합니다.
- Runtime을 Docker로 설정하고 저장소에 포함된 Dockerfile을 사용합니다.
- 환경 변수에 PostgreSQL 접속 정보, JWT 설정, Gemini API Key 등을 등록합니다.
- 배포 완료 후 서버 로그를 확인하고 정상적으로 시작되는지 확인합니다.

## 3. Configure Mobile App

Flutter 앱에서 사용하는 백엔드 API 주소를 배포한 서버 주소로 설정합니다. Release 빌드에 로컬 개발 서버 주소가 남아 있지 않은지 확인합니다.

## 4. Build Android APK

`app` 디렉터리에서 실행합니다.

```bash
flutter build apk --release
```

빌드된 APK는 일반적으로 다음 경로에 생성됩니다.

```text
app/build/app/outputs/flutter-apk/app-release.apk
```

APK를 Android 기기에 설치하고 회원가입, 로그인, 기록 저장 및 조회, AI 코칭 기능을 확인합니다. Android 앱에서 인터넷 통신에 필요한 권한이 포함되어 있는지도 확인해야 합니다.

## Deployment Notes

- 환경 변수는 `env.example`과 최종 설정 코드를 기준으로 구성합니다.
- 비밀 정보는 GitHub에 올리지 말고 호스팅 서비스의 환경 변수 설정을 사용합니다.
- 무료 호스팅 환경에서는 유휴 시간 이후 서버 재가동으로 요청이 지연될 수 있습니다.
- 데이터베이스의 백업 및 보존 정책은 사용 중인 PostgreSQL 서비스의 설정을 확인합니다.