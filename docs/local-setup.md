# 🧑‍💻 Run Locally

본 문서는 SquatMate의 개발 환경을 구성하고 로컬 PostgreSQL 데이터베이스, Spring Boot 서버 및 Flutter 앱을 실행하는 절차를 설명합니다.

## Prerequisites

- Git
- Flutter SDK
- JDK 21
- Android Studio 및 Android SDK
- PostgreSQL
- Gemini API Key (AI 코칭 기능 사용 시)

## 1. Clone Repository

```bash
git clone https://github.com/LHY-AImaster/squat_project.git
cd squat_project
```

## 2. Configure Environment Variables

`server/.env.example`을 참고하여 `server/.env` 파일을 생성하고 필요한 환경 변수를 설정합니다.

- `POSTGRES_PASSWORD`: PostgreSQL 계정 비밀번호
- `JWT_SECRET`: JWT 서명에 사용할 비밀키
- `GEMINI_API_KEY`: Gemini API 인증 키

IntelliJ에서 EnvFile 플러그인을 사용하여 `.env` 파일을 Spring Boot 실행 환경에 등록합니다.

> `.env` 파일과 API Key, JWT 비밀키 등 민감한 정보는 공개 저장소에 커밋하지 마세요.

## 3. Configure PostgreSQL

로컬 PostgreSQL 서버를 실행하고 다음 설정에 맞춰 데이터베이스와 사용자 계정을 생성합니다.

| 항목 | 설정값 |
|---|---|
| 데이터베이스 | `squatmate` |
| 사용자 계정 | `squatmate_app` |
| 호스트 | `localhost` |
| 포트 | `5432` |

사용자 계정의 비밀번호는 `.env` 파일의 `POSTGRES_PASSWORD` 값과 일치시킵니다.

서버 실행 시 JPA의 `ddl-auto=update` 설정에 따라 필요한 테이블이 생성되거나 갱신됩니다.

## 4. Run Backend

`server` 디렉터리로 이동한 뒤 Spring Boot 서버를 실행합니다.

Windows:

```powershell
.\gradlew.bat bootRun
```

서버의 기본 실행 포트는 `9000`입니다. 서버가 정상적으로 시작되고 PostgreSQL에 연결되는지 확인합니다.

## 5. Run Flutter App

`app` 디렉터리에서 Flutter 의존성을 설치하고 앱을 실행합니다.

```bash
flutter pub get
flutter run
```

앱의 API 주소를 실행 중인 백엔드 서버 주소로 설정해야 합니다.

- Android 에뮬레이터: PC의 로컬 서버에 접근할 때 일반적으로 `10.0.2.2:9000`을 사용합니다.
- Android 실기기: PC와 동일한 네트워크에 연결한 뒤 PC의 로컬 IP 주소와 서버 포트 `9000`을 사용합니다.

실기기에서 `localhost`를 사용하면 PC가 아닌 휴대폰 자체를 가리키므로 주의해야 합니다.