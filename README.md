# ziplog-BE

서울 아파트 실거래가 분석 서비스 백엔드.
국토교통부 실거래가 Open API(매매·전월세)를 수집해 **원천(raw) → 정제(core) → 집계(mart)** 3계층으로 적재한다.

> 현재 단계: **DB 모델링 완료** (Flyway V1~V13). 수집 배치·API 는 아직 구현 전이라, 앱을 실행하면 스키마와 기준정보(법정동·수집 대상 구)만 생성된다.

## 기술 스택

- Java 21, Spring Boot 4.2 (Web MVC, Data JPA, Batch, Validation)
- PostgreSQL 17 (Docker), Flyway

## 사전 준비

| 항목 | 확인 |
|---|---|
| JDK 21 | `java -version` |
| Docker Desktop | `docker info` (실행 중이어야 함) |
| 공공데이터포털 인증키 | 아래 [환경 변수](#1-환경-변수-env) 참고 (수집 배치 구현 후 필요) |

## 실행 방법

### 1. 환경 변수 (`.env`)

`.env.sample` 을 복사해 `.env` 를 만들고 값을 채운다. **`.env` 는 `.gitignore` 에 포함되어 커밋되지 않는다.**

```bash
# macOS / Linux / Git Bash
cp .env.sample .env

# Windows PowerShell
Copy-Item .env.sample .env
```

`.env` 에서 채울 값

| 키 | 필수 | 값 |
|---|---|---|
| `DATA_GO_KR_APT_BRG_SERVICE_KEY` | 수집 시 | 아파트 매매 API 인증키 |
| `DATA_GO_KR_APT_RENT_SERVICE_KEY` | 수집 시 | 아파트 전월세 API 인증키 |
| `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` | 선택 | 비워두면 compose 기본값 (`localhost:5434`, `ziplog`/`ziplog`) |

인증키 주의사항
- 공공데이터포털 마이페이지의 **"일반 인증키(Encoding)"** 값을 그대로 붙여넣는다.
- Encoding 키(`%` 포함)는 **추가 URL 인코딩 없이** 쿼리스트링에 붙인다. 다시 인코딩하면 `SERVICE_KEY_IS_NOT_REGISTERED_ERROR` 가 난다.
- 활용신청 필요 API: [아파트 매매 실거래가](https://www.data.go.kr/data/15126469/openapi.do), [아파트 전월세 실거래가](https://www.data.go.kr/data/15126474/openapi.do) (각 일일 10,000건)

### 2. DB 실행

```bash
docker compose up -d
```

- PostgreSQL 17 컨테이너 `ziplog-db` 가 **`localhost:5434`** 로 뜬다 (5432 는 다른 프로젝트와 충돌을 피하려고 사용 안 함)
- DB / 계정 / 비밀번호: `ziplog` / `ziplog` / `ziplog`

### 3. 애플리케이션 실행 (Flyway 마이그레이션 자동 적용)

```bash
# macOS / Linux / Git Bash
./gradlew bootRun

# Windows PowerShell / CMD
.\gradlew.bat bootRun
```

기동 로그에 아래가 보이면 성공:

```
Successfully applied 13 migrations to schema "public", now at version v13
```

웹 서버 없이 **마이그레이션만 적용하고 종료**하려면:

```bash
./gradlew bootRun --args='--spring.main.web-application-type=none'
```

### 4. 확인

```bash
docker exec -it ziplog-db psql -U ziplog -d ziplog
```

```sql
-- 마이그레이션 이력 (V1~V13)
SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank;

-- 기준정보: 법정동 20,561행, 수집 대상 서울 25개 구
SELECT level, count(*) FROM core.legal_dong GROUP BY level;
SELECT r.sgg_cd, l.sgg_nm FROM core.region r JOIN core.legal_dong l USING (bjd_cd);

-- 테이블/컬럼 설명 (psql)
\dt+ raw.*
\d+ core.apt_trade
```

IntelliJ Database 탭에서 `localhost:5434 / ziplog` 로 연결하면 컬럼 한글 설명이 함께 보인다.

### DB 초기화 (데이터까지 모두 삭제)

```bash
docker compose down -v   # 볼륨까지 삭제
docker compose up -d
./gradlew bootRun        # V1~V13 다시 적용
```

## 데이터 구조

| 계층 | 스키마 | 테이블 | 역할 |
|---|---|---|---|
| 원천 | `raw` | `collect_job` | 수집 단위(API, 구, 계약년월) 로그. 1 job = 1 스냅샷 |
| | | `molit_apt_trade_raw`, `molit_apt_rent_raw` | 국토교통부 API 응답을 필드 1:1, 문자열 그대로 보관 |
| 정제 | `core` | `legal_dong`, `region` | 전국 법정동 마스터 / 수집 대상 시군구 |
| | | `apt_complex` | 단지 마스터 (매매·전월세 공유) |
| | | `apt_trade`, `apt_rent` | 타입 변환·법정동코드 매칭된 거래 |
| 집계 | `mart` | `trade_monthly_*`, `rent_monthly_*` | 월별 시군구 / 법정동 / 단지×면적대 통계 |

- 설계 문서: [docs/sdd/001-db-modeling.md](docs/sdd/001-db-modeling.md)
- ERD: [docs/erd/README.md](docs/erd/README.md)

## 프로젝트 구조

```
ziplog-BE
├── compose.yaml                         # 로컬 PostgreSQL
├── .env.sample                          # 환경 변수 템플릿 (복사해서 .env 생성)
├── .env                                 # 인증키 (직접 생성, 커밋 제외)
├── docs
│   ├── sdd/001-db-modeling.md           # DB 설계 문서
│   └── erd/                             # Mermaid ERD
└── src/main/resources
    ├── application.yaml
    └── db/migration/V1__ ~ V13__*.sql   # Flyway 마이그레이션
```

## 마이그레이션 규칙

- 적용된 마이그레이션 파일은 **수정하지 않는다.** 변경은 새 버전(`V14__...`)으로 추가
- JPA `ddl-auto: validate` — 엔티티와 스키마가 다르면 기동 실패
- 모든 테이블·컬럼에 한글 `COMMENT` 를 단다
- 법정동 연간 갱신: 새 CSV 수령 시 새 버전 마이그레이션으로 upsert, 사라진 코드는 `is_active=false` (삭제 금지)

## 문제 해결

| 증상 | 원인 / 해결 |
|---|---|
| `Connection refused ... 5434` | Docker Desktop 또는 `ziplog-db` 컨테이너가 꺼져 있음 → `docker compose up -d` |
| `Port 5434 is already allocated` | 다른 컨테이너가 사용 중 → `compose.yaml` 포트와 `DB_URL` 을 함께 변경 |
| `Validate failed: Migration checksum mismatch` | 이미 적용된 마이그레이션 파일이 수정됨 → 로컬이면 [DB 초기화](#db-초기화-데이터까지-모두-삭제), 아니면 수정 되돌리고 새 버전으로 추가 |
| `Port 8080 was already in use` | 다른 앱이 8080 사용 중 → `--args='--server.port=8081'` |
