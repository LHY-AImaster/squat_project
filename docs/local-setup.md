## 🧑‍💻 Run Locally

아래는 PostgreSQL 통합 완료를 가정한 로컬 실행 안내입니다. 실제 공개 전에는 환경 변수명, 파일 위치, 데이터베이스 초기화 방식 및 실행 명령을 최종 코드와 대조해야 합니다.

### Prerequisites

- Git
- Flutter SDK
- JDK 21
- PostgreSQL
- Gemini API Key (AI 코칭 기능 사용 시)

### 1. Clone Repository

```bash
git clone https://github.com/dlgurfuf-AImaster/squat_project.git
cd squat_project
```

### 2. Configure Environment Variables

`env.example`을 참고하여 프로젝트에서 요구하는 환경 변수 파일을 구성합니다.

필요한 설정은 실제 코드에 따라 달라질 수 있지만, 일반적으로 다음 항목을 확인해야 합니다.

- PostgreSQL 접속 정보
- JWT 관련 설정
- Gemini API Key
- Flutter 앱에서 사용할 백엔드 API 주소

실제 변수명과 파일 위치는 각 디렉터리의 `env.example` 및 설정 파일을 기준으로 확인합니다.

> `.env` 파일, API Key, JWT 비밀키, 데이터베이스 비밀번호 등 민감한 정보는 공개 저장소에 커밋하지 마세요.

### 3. Configure PostgreSQL

PostgreSQL을 실행하고 프로젝트에 사용할 데이터베이스와 계정을 준비합니다. 환경 변수에 데이터베이스 접속 정보를 설정한 뒤 서버를 실행하여 연결을 확인합니다.

데이터베이스 테이블 생성 방식은 프로젝트의 최종 JPA 및 SQL 설정을 따릅니다.

### 4. Run Backend

`server` 디렉터리로 이동한 뒤 Spring Boot 서버를 실행합니다.

Windows:

```powershell
.\gradlew.bat bootRun
```

서버가 정상적으로 시작되고 PostgreSQL에 연결되는지 확인합니다.

### 5. Run Flutter App

`app` 디렉터리에서 Flutter 의존성을 설치합니다.

```bash
flutter pub get
flutter run
```

앱의 API 주소를 실행 중인 서버 주소로 설정해야 합니다. Android 실기기에서 앱을 실행하는 경우 `localhost`는 PC가 아니라 휴대폰 자체를 가리키므로, 휴대폰에서 접근 가능한 PC의 IP 주소나 적절한 서버 주소를 사용해야 합니다.
