# SDD-001. 서울 아파트 실거래가 DB 모델링 (Flyway)

| 항목 | 내용 |
|---|---|
| 상태 | Draft (리뷰 대기) |
| 작성일 | 2026-11-22 |
| 범위 | DB 스키마 설계 및 Flyway 마이그레이션 계획. 배치/API 구현은 범위 밖 |
| 스택 | PostgreSQL, Flyway, Spring Boot 4.2, Spring Batch, JPA |

---

## 1. 목표 / 비목표

### 목표
- 국토교통부 실거래가 Open API 2종의 원본을 **유실 없이** 적재한다.
- 원천(raw) → 정제(core) → 집계(mart) 3계층 ELT 구조로, 정제·집계 로직이 바뀌어도 API 재호출 없이 재계산 가능하게 한다.
- 모든 스키마 변경은 Flyway 마이그레이션으로만 관리한다.

### 비목표 (이번 SDD 범위 밖)
- 수집 배치(Job/Step) 구현, API 서버, 화면
- 전세가율·월세 전환율 등 매매×전월세 교차 지표 (§9 O6)
- 단지 좌표/세대수 등 외부 단지 정보

---

## 2. 데이터 소스

| 구분 | 매매 | 전월세 |
|---|---|---|
| 데이터셋 | data.go.kr 15126469 | data.go.kr 15126474 |
| Endpoint | `https://apis.data.go.kr/1613000/RTMSDataSvcAptTrade/getRTMSDataSvcAptTrade` | `https://apis.data.go.kr/1613000/RTMSDataSvcAptRent/getRTMSDataSvcAptRent` |
| 요청 파라미터 | `serviceKey`, `LAWD_CD`(시군구 5자리), `DEAL_YMD`(YYYYMM), `pageNo`, `numOfRows` | 동일 |
| 응답 | XML | XML |
| 일일 트래픽 | 10,000 | 10,000 |
| 제공 시작월 (실측) | **2006-01** (2005-12 = 0건) | **2011-01** (2010-12 = 0건) |
| `.env` 키 | `DATA_GO_KR_APT_BRG_SERVICE_KEY` | `DATA_GO_KR_APT_RENT_SERVICE_KEY` |

> 실측 메모 (2026-11-22, 강남구 11680 / 2024-10 호출)
> - `.env` 키는 **Encoding 키**(`%` 포함). 쿼리스트링에 **추가 인코딩 없이** 붙여야 정상 응답(`resultCode=000`). 재인코딩 시 `SERVICE_KEY_IS_NOT_REGISTERED_ERROR`.
> - `numOfRows=1000` 동작 확인. 강남구 2024-10 매매 305건, 전월세 1,728건(2페이지).
> - 값이 없는 필드는 태그가 빠지지 않고 **공백 한 칸(`" "`)** 으로 내려온다.
> - 금액은 `"1,024,000"` 처럼 **천 단위 콤마 포함 문자열, 단위 만원**.

### 2.1 매매 응답 필드 (실측 20개)

| API 필드 | 의미 | 샘플 | 비고 |
|---|---|---|---|
| sggCd | 시군구코드 | 11680 | |
| umdNm | 법정동명 | 역삼동 | 법정동 **코드는 없음** |
| aptNm | 단지명 | 한화진넥스빌 | |
| jibun | 지번 | 706-20 | |
| aptDong | 동 | 101 | 등기 완료 건만, 미공개 시 공백 |
| buildYear | 건축년도 | 2001 | |
| dealYear / dealMonth / dealDay | 계약일 | 2024 / 10 / 1 | |
| dealAmount | 거래금액(만원) | 51,000 | 콤마 포함 |
| excluUseAr | 전용면적(㎡) | 51.08 | |
| floor | 층 | 9 | 음수(지하) 가능성 고려 |
| dealingGbn | 거래유형 | 중개거래 / 직거래 | |
| estateAgentSggNm | 중개사 소재지 | 서울 강남구 | 복수 시 콤마 구분 |
| rgstDate | 등기일자 | 25.02.28 | `yy.MM.dd` |
| cdealType | 해제여부 | O | 해제 시 `O`, 아니면 공백 |
| cdealDay | 해제사유발생일 | 24.11.06 | `yy.MM.dd` |
| slerGbn / buyerGbn | 매도자/매수자 구분 | 개인 / 법인 / 기타 | |
| landLeaseholdGbn | 토지임대부 여부 | N | |

⚠️ **매매 API에는 `aptSeq`(단지 일련번호), 법정동코드, 도로명주소가 없다.** (상세 API `RTMSDataSvcAptTradeDev` 에는 있으나 현재 키로는 미등록 → §9 열린 이슈)

### 2.2 전월세 응답 필드 (실측 25개)

| API 필드 | 의미 | 샘플 | 비고 |
|---|---|---|---|
| sggCd, umdNm, aptNm, jibun, buildYear | 매매와 동일 | | |
| aptSeq | 단지 일련번호 | 11680-211 | **전월세에만 존재** |
| dealYear / dealMonth / dealDay | 계약일 | | |
| deposit | 보증금(만원) | 90,000 | 콤마 포함 |
| monthlyRent | 월세(만원) | 160 | 0 이면 전세 |
| excluUseAr, floor | 전용면적, 층 | | |
| contractTerm | 계약기간 | 24.02~26.02 | `yy.MM~yy.MM` |
| contractType | 계약구분 | 신규 / 갱신 | |
| useRRRight | 갱신요구권 사용 | 사용 | |
| preDeposit / preMonthlyRent | 종전 보증금/월세 | 10,000 / 100 | |
| roadnm | 도로명주소 | 삼성로 151 | |
| roadnmsggcd, roadnmcd, roadnmseq, roadnmbcd, roadnmbonbun, roadnmbubun | 도로명 코드 구성요소 | 11680 / 3122005 / 4 / 0 / 00151 / 00000 | 대소문자 주의 (전부 소문자) |

### 2.3 법정동코드 (국토교통부_전국 법정동)

| 항목 | 내용 |
|---|---|
| 데이터셋 | data.go.kr 15063424 (파일데이터, CSV, 연간 갱신) |
| 사용 파일 | `국토교통부_전국 법정동_20260630.csv` (UTF-8 BOM) |
| 컬럼 | `법정동코드, 시도명, 시군구명, 읍면동명, 리명, 순번, 생성일자` |
| 행 수 | 20,561 (시도 16 / 시군구 269 / 읍면동 5,067 / 리 15,209). 서울 493 (구 25, 동 467, 리 없음) |
| 특이사항 | 현존 코드만 포함 (폐지 여부 컬럼 없음). 순번 공란 272행. 전국 `(시군구5자리, 읍면동명)` 중복 없음 |
| 용도 | 실거래 API 는 법정동을 **이름(`umdNm`)** 으로만 주므로 `(sggCd, umdNm)` → 10자리 법정동코드 매칭. 샘플(강남·송파 2024-10) 25개 동 100% 매칭 확인 |

---

## 3. 핵심 설계 결정

| ID | 결정 | 근거 |
|---|---|---|
| D1 | 3계층 ELT: `raw` → `core` → `mart` | 정제 로직 중복 제거, 재계산 가능 |
| D2 | 계층별 **PostgreSQL 스키마 분리** (`raw`, `core`, `mart`). Spring Batch 메타/Flyway 이력은 `public` | 권한·백업·조회 범위를 계층 단위로 관리 |
| D3 | raw 컬럼은 API 필드 1:1, **전부 길이 제한 없는 `VARCHAR`**, 값은 받은 그대로(공백 포함, trim 안 함) | 원본 보존. 길이 초과로 적재 실패하는 일이 없도록. PostgreSQL 에서 `VARCHAR`/`VARCHAR(n)` 성능 차이 없음 |
| D4 | raw 는 **append-only 스냅샷**. 수집 단위 `(api_type, LAWD_CD, DEAL_YMD)` 마다 `collect_job` 1건, 그 job 의 행들이 해당 단위의 스냅샷 | 신고 지연(30일)·사후 해제로 같은 월 데이터가 바뀜. API 에 거래 고유 ID 가 없어 행 단위 upsert 불가 |
| D5 | core 는 수집 단위 **delete → insert 교체**. 단위별 **가장 최근 SUCCESS job** 만 반영 | 거래 자연키가 없으므로 단위 통째로 교체가 가장 정확 |
| D6 | core 에서 **중복 제거하지 않음** | 같은 단지·층·면적·일자·금액의 실제 별개 거래가 존재할 수 있음. 스냅샷 중복은 D5 로 이미 해결 |
| D7 | 해제 거래는 core 에 **남기고 `is_canceled=true`**, mart 집계에서 제외 | 해제율 분석 여지 보존 |
| D8 | 단지 마스터 `core.apt_complex` 자연키 = `(sgg_cd, umd_nm, jibun, apt_nm)`, `apt_seq` 는 nullable 보조키 | 매매에 aptSeq 없음. 전월세는 aptSeq 로 보강 |
| D9 | mart 는 영향받은 `(sgg_cd, deal_ym)` 단위 **delete → insert 재계산** | core 교체 단위와 일치, 증분 로직 불필요 |
| D10 | `core.region` 은 **수집 대상 시군구 설정**만 담당 (서울 25개 구). 이름은 `core.legal_dong` 에서 조회 | 지역 속성 중복 제거 |
| D11 | Spring Batch 메타 테이블도 Flyway 로 관리, `spring.batch.jdbc.initialize-schema=never` | 스키마 관리 주체 단일화 |
| D12 | 금액은 `BIGINT`(만원), 면적 `NUMERIC(8,2)`, 날짜 `DATE`, 시각 `TIMESTAMPTZ` | 정밀도 손실 방지 |
| D13 | 수집 범위: 서울 25개 구, 매매 2006-01~, 전월세 2011-01~ | 실측 제공 시작월. 트래픽 한도 내 1~2일이면 전체 적재 가능 |
| D14 | 법정동 마스터 `core.legal_dong` 에 **전국** 법정동(시도~리 전 단계) 적재. 출처는 국토교통부_전국 법정동 CSV | 2만 행 수준으로 부담 없음. 수집 대상 확장 시 마스터 변경 불필요 |
| D15 | 법정동 데이터는 **Flyway 마이그레이션(seed SQL)** 으로 적재. 연 1회 신규 파일은 새 버전 마이그레이션으로 반영 | 연 1회 갱신이라 배치 불필요. DB 재생성 시 자동 재현 |
| D16 | 신규 파일에서 사라진 코드는 **삭제하지 않고 `is_active=false`**. 신규 코드 insert, 이름 변경은 update | 과거 거래·단지가 참조 중일 수 있음 |
| D17 | `core.apt_trade`, `core.apt_complex` 에 `bjd_cd`(10자리) 부여. `(sgg_cd, umd_nm)` 매칭, 실패 시 NULL. 법정동 mart 는 `bjd_cd` 기준 | 이름이 아닌 코드로 집계·조인 |
| D18 | 법정동은 raw 계층 없이 **core 에 직접 적재** (CSV → 타입 변환·`level` 계산을 seed 시점에 수행) | 외부 API 스트림이 아닌 연 1회 갱신 기준정보. 원본 파일은 data.go.kr 에서 재다운로드 가능 |
| D19 | 모든 테이블·컬럼에 **한글 `COMMENT`** 를 각 마이그레이션 하단에 작성. raw 컬럼 주석은 `[API필드명] 의미` 형식 | DB 툴에서 바로 의미 확인. API 필드 추적 |
| D20 | 전월세 단지는 매매와 **같은 자연키**로 `core.apt_complex` 공유. `aptSeq` 는 보조 정보로만 채움 | 실측 매매 단지의 80.6% 가 전월세와 자연키 일치. 매매에 aptSeq 가 없어 aptSeq 우선 매칭은 매매와 단지가 갈라짐 |
| D21 | 전월세 mart 는 `rent_type`(JEONSE/WOLSE) 을 grain 에 포함 | 전세 보증금과 월세 보증금은 분포가 달라 섞으면 무의미 |
| D22 | raw 테이블명은 **`{출처기관}_{데이터}_raw`** 형식. 국토교통부 실거래가 → `raw.molit_apt_trade_raw`, `raw.molit_apt_rent_raw` | 테이블명만으로 데이터 출처 식별. 다른 기관 데이터 추가 시 이름 충돌 방지 |

---

## 4. ERD

> 실제 DB 에서 생성한 전체 ERD(모든 컬럼·설명 포함)는 [docs/erd](../erd/README.md) 참고. 아래는 설계 요약도.

```mermaid
erDiagram
    LEGAL_DONG ||--o| REGION : "bjd_cd"
    LEGAL_DONG ||--o{ APT_COMPLEX : "bjd_cd"
    LEGAL_DONG ||--o{ APT_TRADE : "bjd_cd"
    LEGAL_DONG ||--o{ TRADE_MONTHLY_UMD : "bjd_cd"
    REGION ||--o{ COLLECT_JOB : "lawd_cd"
    COLLECT_JOB ||--o{ MOLIT_APT_TRADE_RAW : "스냅샷"
    COLLECT_JOB ||--o{ MOLIT_APT_RENT_RAW : "스냅샷"
    REGION ||--o{ APT_COMPLEX : "sgg_cd"
    APT_COMPLEX ||--o{ APT_TRADE : ""
    APT_COMPLEX ||--o{ APT_RENT : ""
    MOLIT_APT_TRADE_RAW ||--o| APT_TRADE : "raw_id"
    MOLIT_APT_RENT_RAW ||--o| APT_RENT : "raw_id"
    LEGAL_DONG ||--o{ APT_RENT : "bjd_cd"
    APT_RENT }o--|| RENT_MONTHLY_SGG : "집계"
    APT_RENT }o--|| RENT_MONTHLY_UMD : "집계"
    APT_RENT }o--|| RENT_MONTHLY_COMPLEX : "집계"
    APT_TRADE }o--|| TRADE_MONTHLY_SGG : "집계"
    APT_TRADE }o--|| TRADE_MONTHLY_UMD : "집계"
    APT_TRADE }o--|| TRADE_MONTHLY_COMPLEX : "집계"

    LEGAL_DONG {
        varchar bjd_cd PK "10자리"
        varchar sido_cd "generated"
        varchar sgg_cd "generated"
        varchar level "generated"
        varchar sido_nm
        varchar sgg_nm
        varchar umd_nm
        varchar ri_nm
        boolean is_active
    }
    REGION {
        varchar sgg_cd PK
        varchar bjd_cd FK "generated"
        boolean collect_enabled
    }
    COLLECT_JOB {
        bigint collect_job_id PK
        varchar api_type
        varchar lawd_cd FK
        varchar deal_ymd
        varchar status
        int total_count
        timestamptz finished_at
        timestamptz core_applied_at
    }
    MOLIT_APT_TRADE_RAW {
        bigint raw_id PK
        bigint collect_job_id FK
        varchar "API 필드 20개 (전부 varchar)"
    }
    MOLIT_APT_RENT_RAW {
        bigint raw_id PK
        bigint collect_job_id FK
        varchar "API 필드 25개 (전부 varchar)"
    }
    APT_COMPLEX {
        bigint complex_id PK
        varchar sgg_cd FK
        varchar umd_nm
        varchar bjd_cd FK "nullable"
        varchar jibun
        varchar apt_nm
        varchar apt_seq "nullable, unique"
    }
    APT_TRADE {
        bigint trade_id PK
        bigint complex_id FK
        varchar bjd_cd FK "nullable"
        date deal_date
        bigint deal_amount
        numeric exclu_use_ar
        boolean is_canceled
    }
    APT_RENT {
        bigint rent_id PK
        bigint complex_id FK
        varchar bjd_cd FK "nullable"
        date deal_date
        bigint deposit
        bigint monthly_rent
        varchar rent_type
    }
    TRADE_MONTHLY_SGG {
        varchar deal_ym PK
        varchar sgg_cd PK
    }
    TRADE_MONTHLY_UMD {
        varchar deal_ym PK
        varchar bjd_cd PK
        varchar sgg_cd
    }
    TRADE_MONTHLY_COMPLEX {
        varchar deal_ym PK
        bigint complex_id PK
        varchar area_band PK
    }
    RENT_MONTHLY_SGG {
        varchar deal_ym PK
        varchar sgg_cd PK
        varchar rent_type PK
    }
    RENT_MONTHLY_UMD {
        varchar deal_ym PK
        varchar bjd_cd PK
        varchar rent_type PK
    }
    RENT_MONTHLY_COMPLEX {
        varchar deal_ym PK
        bigint complex_id PK
        varchar area_band PK
        varchar rent_type PK
    }
```

---

## 5. 테이블 명세

### 5.0 `core.legal_dong` — 법정동 마스터 (전국)

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| bjd_cd | VARCHAR(10) | PK, CHECK 10자리 숫자 | 법정동코드 = 시도2 + 시군구3 + 읍면동3 + 리2 |
| sido_cd | VARCHAR(2) | GENERATED (`substr(bjd_cd,1,2)`) | |
| sgg_cd | VARCHAR(5) | GENERATED (`substr(bjd_cd,1,5)`) | = API `LAWD_CD` / `sggCd` |
| level | VARCHAR(4) | GENERATED | `RI` ← 리명 있음, `UMD` ← 읍면동명, `SGG` ← 시군구명, 그 외 `SIDO` |
| sido_nm | VARCHAR(20) | NOT NULL | CSV 시도명 |
| sgg_nm | VARCHAR(20) | | CSV 시군구명 (빈 값 → NULL) |
| umd_nm | VARCHAR(20) | | CSV 읍면동명 |
| ri_nm | VARCHAR(20) | | CSV 리명 |
| seq | INTEGER | | CSV 순번 (공란 존재) |
| created_date | DATE | NOT NULL | CSV 생성일자 |
| is_active | BOOLEAN | NOT NULL DEFAULT true | 최신 파일에 존재 여부 (D16) |
| source_date | DATE | NOT NULL | 마지막 반영 파일 기준일 (현재 2026-06-30) |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

인덱스
- `uk_legal_dong_umd (sgg_cd, umd_nm) WHERE level='UMD'` — UNIQUE. 실거래 `(sggCd, umdNm)` → `bjd_cd` 매칭
- `ix_legal_dong_sgg (sgg_cd)`

갱신 절차 (연 1회, 신규 CSV 수령 시): 새 버전 마이그레이션에서
1. 신규 파일을 임시 테이블에 적재
2. 신규 코드 INSERT, 기존 코드는 이름·순번·`source_date` UPDATE, `is_active=true`
3. 신규 파일에 없는 코드 `is_active=false` (삭제 금지)

### 5.1 `core.region` — 수집 대상 시군구

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| sgg_cd | VARCHAR(5) | PK | 시군구코드 = API `LAWD_CD` |
| bjd_cd | VARCHAR(10) | GENERATED (`sgg_cd \|\| '00000'`), FK → core.legal_dong | 법정동 마스터의 시군구 행 |
| collect_enabled | BOOLEAN | NOT NULL DEFAULT true | 수집 대상 여부 |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

Seed: `core.legal_dong` 에서 `sido_cd='11' AND level='SGG'` 25행 (서울 25개 구). 구 이름은 `JOIN core.legal_dong USING (bjd_cd)` 로 조회.

### 5.2 `raw.collect_job` — 수집 단위 로그

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| collect_job_id | BIGINT IDENTITY | PK | |
| api_type | VARCHAR(20) | NOT NULL, CHECK IN ('APT_TRADE','APT_RENT') | |
| lawd_cd | VARCHAR(5) | NOT NULL, FK → core.region | |
| deal_ymd | VARCHAR(6) | NOT NULL | YYYYMM |
| status | VARCHAR(20) | NOT NULL, CHECK IN ('RUNNING','SUCCESS','FAILED') | |
| total_count | INTEGER | | API `totalCount` |
| page_count | INTEGER | | 호출한 페이지 수 |
| loaded_count | INTEGER | | 실제 적재 행 수 (= total_count 여야 SUCCESS) |
| result_code | VARCHAR(10) | | API `resultCode` |
| result_msg | VARCHAR(200) | | API `resultMsg` |
| error_message | TEXT | | |
| batch_job_execution_id | BIGINT | | Spring Batch 실행 ID (FK 미설정, 느슨한 참조) |
| started_at | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| finished_at | TIMESTAMPTZ | | |
| core_applied_at | TIMESTAMPTZ | | core 반영 시각. NULL 이면 미반영 |

인덱스
- `ix_collect_job_unit (api_type, lawd_cd, deal_ymd, finished_at DESC) WHERE status = 'SUCCESS'` — 단위별 최신 성공 job 조회
- `ix_collect_job_pending (api_type) WHERE status = 'SUCCESS' AND core_applied_at IS NULL` — core 반영 대기 조회

규칙
- 한 job 은 한 단위의 **모든 페이지**를 수집한다. 중간 실패 시 `FAILED`, 해당 job 의 raw 행은 core 반영 대상에서 제외(삭제는 보존 정책에 따름).
- `loaded_count <> total_count` 이면 `FAILED` 처리.

### 5.3 `raw.molit_apt_trade_raw` — 매매 원본

공통 메타 컬럼

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| raw_id | BIGINT IDENTITY | PK | |
| collect_job_id | BIGINT | NOT NULL, FK → raw.collect_job | |
| item_no | INTEGER | NOT NULL | 수집 job 전체 순번 = `(pageNo-1) × numOfRows + 페이지 내 순번` |
| collected_at | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

API 필드 컬럼 (전부 `VARCHAR`, NULL 허용, 원문 그대로)

| 컬럼 | API 필드 |
|---|---|
| sgg_cd | sggCd |
| umd_nm | umdNm |
| apt_nm | aptNm |
| jibun | jibun |
| apt_dong | aptDong |
| build_year | buildYear |
| deal_year | dealYear |
| deal_month | dealMonth |
| deal_day | dealDay |
| deal_amount | dealAmount |
| exclu_use_ar | excluUseAr |
| floor | floor |
| dealing_gbn | dealingGbn |
| estate_agent_sgg_nm | estateAgentSggNm |
| rgst_date | rgstDate |
| cdeal_type | cdealType |
| cdeal_day | cdealDay |
| sler_gbn | slerGbn |
| buyer_gbn | buyerGbn |
| land_leasehold_gbn | landLeaseholdGbn |

제약: `UNIQUE (collect_job_id, item_no)` — 같은 job 내 페이지 재시도 시 중복 적재 방지

인덱스: **위 UNIQUE 하나만** 둔다. 선두 컬럼 `collect_job_id` 로 job 단위 조회(core 반영 시 유일한 읽기 패턴)를 커버한다. raw 는 쓰기 위주라 구·계약일 등 추가 인덱스를 두지 않는다. 구·월 조회는 `collect_job` 인덱스 → `collect_job_id` 경로로, 날짜 범위 조회는 core 에서 한다.

> 응답에 미정의 필드가 새로 추가되면 적재 시 무시되고 로그만 남긴다. 필드 추가는 새 마이그레이션으로 컬럼 추가.

### 5.4 `raw.molit_apt_rent_raw` — 전월세 원본

공통 메타 컬럼은 5.3 과 동일. API 필드 컬럼:

`sgg_cd, umd_nm, apt_nm, jibun, apt_seq, build_year, deal_year, deal_month, deal_day, deposit, monthly_rent, exclu_use_ar, floor, contract_term, contract_type, use_rr_right, pre_deposit, pre_monthly_rent, road_nm, road_nm_sgg_cd, road_nm_cd, road_nm_seq, road_nm_bcd, road_nm_bonbun, road_nm_bubun`

(API 의 `roadnm*` 소문자 필드 → `road_nm_*` snake_case 로 매핑). 메타 컬럼·인덱스 원칙은 5.3 과 동일 (`UNIQUE (collect_job_id, item_no)` 하나만).

### 5.5 `core.apt_complex` — 단지 마스터

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| complex_id | BIGINT IDENTITY | PK | |
| sgg_cd | VARCHAR(5) | NOT NULL, FK → core.region | |
| umd_nm | VARCHAR(50) | NOT NULL | |
| bjd_cd | VARCHAR(10) | FK → core.legal_dong, NULL 허용 | `(sgg_cd, umd_nm)` 매칭, 실패 시 NULL |
| jibun | VARCHAR(50) | NOT NULL | 공백이면 `''` 로 정규화 |
| apt_nm | VARCHAR(100) | NOT NULL | trim 후 저장 |
| apt_seq | VARCHAR(20) | UNIQUE, NULL 허용 | 전월세에서 채움 |
| build_year | SMALLINT | | 최초 관측값 |
| road_nm | VARCHAR(100) | | 전월세에서 채움 |
| first_seen_ym | VARCHAR(6) | NOT NULL | |
| last_seen_ym | VARCHAR(6) | NOT NULL | |
| created_at / updated_at | TIMESTAMPTZ | NOT NULL | |

제약: `UNIQUE (sgg_cd, umd_nm, jibun, apt_nm)`

생성 규칙: core 적재 시 자연키로 조회 → 없으면 insert. 전월세 적재 시 `apt_seq` 가 비어 있으면 채움.

### 5.6 `core.apt_trade` — 매매 정제

| 컬럼 | 타입 | 제약 | 변환 규칙 (raw → core) |
|---|---|---|---|
| trade_id | BIGINT IDENTITY | PK | |
| complex_id | BIGINT | NOT NULL, FK | 자연키 매칭 |
| sgg_cd | VARCHAR(5) | NOT NULL | |
| umd_nm | VARCHAR(50) | NOT NULL | trim |
| bjd_cd | VARCHAR(10) | FK → core.legal_dong, NULL 허용 | `legal_dong` 에서 `level='UMD' AND sgg_cd=sggCd AND umd_nm=umdNm` 매칭, 실패 시 NULL |
| deal_ym | VARCHAR(6) | NOT NULL | = 수집 단위 DEAL_YMD |
| deal_date | DATE | NOT NULL | dealYear+dealMonth+dealDay |
| deal_amount | BIGINT | NOT NULL | 콤마 제거, 만원 |
| exclu_use_ar | NUMERIC(8,2) | NOT NULL | |
| area_band | VARCHAR(10) | NOT NULL | §5.8 면적대 규칙 |
| floor | SMALLINT | | |
| apt_dong | VARCHAR(20) | | 공백 → NULL |
| build_year | SMALLINT | | |
| dealing_gbn | VARCHAR(10) | | 공백 → NULL |
| sler_gbn | VARCHAR(10) | | |
| buyer_gbn | VARCHAR(10) | | |
| estate_agent_sgg_nm | VARCHAR(200) | | |
| rgst_date | DATE | | `yy.MM.dd` → 20yy |
| is_canceled | BOOLEAN | NOT NULL | cdealType = 'O' |
| cancel_date | DATE | | cdealDay |
| is_land_leasehold | BOOLEAN | NOT NULL | landLeaseholdGbn = 'Y' |
| collect_job_id | BIGINT | NOT NULL | 출처 job |
| raw_id | BIGINT | NOT NULL | 출처 행 (FK 미설정: raw 보존 정책으로 삭제될 수 있음) |
| loaded_at | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

인덱스
- `ix_apt_trade_sgg_date (sgg_cd, deal_date)` — 구 + 날짜 범위 조회. 단위 교체 시에도 `deal_date` 월 범위 조건으로 사용
- `ix_apt_trade_complex (complex_id, deal_date)`

변환 실패 행(숫자 파싱 불가 등)은 core 에 넣지 않고 배치 skip 로그로 남긴다.

### 5.7 `core.apt_rent` — 전월세 정제

5.6 과 동일 패턴 (단위 delete→insert, `bjd_cd` 매칭, `area_band`, 출처 `collect_job_id`/`raw_id`). 해제 개념 없음. 전월세 고유 컬럼:

| 컬럼 | 타입 | 제약 | 변환 규칙 (raw → core) |
|---|---|---|---|
| rent_type | VARCHAR(10) | NOT NULL, CHECK IN ('JEONSE','WOLSE') | `monthlyRent = 0` → JEONSE, 그 외 WOLSE |
| deposit | BIGINT | NOT NULL | 콤마 제거, 만원 |
| monthly_rent | BIGINT | NOT NULL | 콤마 제거, 만원 |
| contract_type | VARCHAR(10) | | 신규/갱신, 공백 → NULL (실측 4.5% 공백) |
| contract_start_ym | VARCHAR(6) | | `contractTerm` 의 `~` 앞 `yy.MM` → `20yyMM`. 실측 형식: `25.02~27.02`(89%), `~26.10`(시작 생략 6%), 공백(4.5%) |
| contract_end_ym | VARCHAR(6) | | `~` 뒤 |
| is_rr_right_used | BOOLEAN | | `useRRRight='사용'` → TRUE, 계약구분 있고 미사용 → FALSE, 계약구분 없음 → NULL (정보 없음) |
| pre_deposit / pre_monthly_rent | BIGINT | | 종전계약 보증금/월세, 공백 → NULL |

인덱스: `ix_apt_rent_sgg_date (sgg_cd, deal_date)`, `ix_apt_rent_complex (complex_id, deal_date)`

단지 매칭 (전월세 적재 시 `core.apt_complex` upsert)
- 매매와 **같은 자연키** `(sgg_cd, umd_nm, jibun, apt_nm)` 로 매칭 → 매매·전월세가 같은 단지 행을 공유
- `apt_seq`, `road_nm`, `build_year` 는 비어 있을 때만 채움
- `apt_seq` 는 UNIQUE 이므로 이미 다른 단지가 쓰는 값이거나 같은 배치에서 다른 자연키가 먼저 차지한 값이면 채우지 않음
- 실측(서울 2024-10): 매매 단지 1,899 중 1,530(80.6%)이 전월세와 동일 자연키. 지번 같고 이름만 다른 경우 1건(`(토지임대부아파트)` 접미). `aptSeq` 1개 → 자연키 여러 개 0건, 자연키 1개 → `aptSeq` 2개 1건

### 5.8 mart — 매매 월별 집계

공통 규칙
- `is_canceled = false` 인 거래만 집계
- 평당가 = `deal_amount / exclu_use_ar * 3.3058` (만원/3.3㎡)
- 중위값은 `percentile_cont(0.5)`
- 면적대(`area_band`, 전용면적 기준): `~40`, `40~60`, `60~85`, `85~102`, `102~135`, `135~` (하한 초과·상한 이하)

공통 지표 컬럼

| 컬럼 | 타입 |
|---|---|
| trade_count | INTEGER NOT NULL |
| avg_amount | BIGINT |
| median_amount | BIGINT |
| min_amount | BIGINT |
| max_amount | BIGINT |
| avg_price_per_pyeong | BIGINT |
| median_price_per_pyeong | BIGINT |
| refreshed_at | TIMESTAMPTZ NOT NULL |

| 테이블 | PK (grain) |
|---|---|
| `mart.trade_monthly_sgg` | (deal_ym, sgg_cd) |
| `mart.trade_monthly_umd` | (deal_ym, bjd_cd) — `bjd_cd` 매칭된 거래만 집계. `sgg_cd` 는 단위 재계산용 일반 컬럼 |
| `mart.trade_monthly_complex` | (deal_ym, complex_id, area_band) |

### 5.9 mart — 전월세 월별 집계

공통 규칙: 임대 유형(`rent_type`)을 grain 에 포함. 평당 보증금 = `deposit / exclu_use_ar * 3.3058`.

| 테이블 | PK (grain) |
|---|---|
| `mart.rent_monthly_sgg` | (deal_ym, sgg_cd, rent_type) |
| `mart.rent_monthly_umd` | (deal_ym, bjd_cd, rent_type) — `bjd_cd` 매칭 거래만. `sgg_cd` 일반 컬럼 |
| `mart.rent_monthly_complex` | (deal_ym, complex_id, area_band, rent_type) — `sgg_cd` 일반 컬럼 |

지표: `rent_count, avg/median/min/max_deposit, median_deposit_per_pyeong, avg/median_monthly_rent, renewal_count(갱신), rr_right_used_count(갱신요구권 사용), refreshed_at`

전세가율·월세 전환율은 §9 O6.

---

## 6. 데이터 흐름 / 갱신 규칙

```
[API] ──수집──▶ raw.collect_job (RUNNING→SUCCESS/FAILED)
                raw.molit_apt_trade_raw (append)
                      │  status=SUCCESS AND core_applied_at IS NULL
                      ▼
          단위(lawd_cd, deal_ymd)의 "최신 SUCCESS job" 인 경우에만:
            DELETE core.apt_trade WHERE sgg_cd=? AND deal_date >= 월초 AND deal_date < 익월초
            INSERT ... FROM raw.molit_apt_trade_raw WHERE collect_job_id=?
            (단지 마스터 upsert)
          collect_job.core_applied_at = now()   ※ 최신이 아닌 job 도 표시만
                      │
                      ▼
          영향받은 (sgg_cd, deal_ym) 에 대해 mart 3종 DELETE→INSERT
```

재수집 주기 (운영 가정, 배치 SDD 에서 확정)
- 매일: 최근 3개월
- 매월: 최근 12개월 (사후 해제 반영)

---

## 7. raw 보존 정책

재수집 스냅샷 누적으로 raw 가 빠르게 커진다 (전월세 서울 기준 월 수만 건 × 매일 3개월 재수집).

- 단위별 **최신 SUCCESS job 의 행은 영구 보존**
- 그 외 job(과거 스냅샷, FAILED)의 행은 **30일 후 삭제**
- 삭제는 job 단위로 수행 (`DELETE ... WHERE collect_job_id IN (...)`), `collect_job` 레코드 자체는 남긴다

---

## 8. Flyway 마이그레이션 계획

위치: `src/main/resources/db/migration`

| 버전 | 파일 | 내용 |
|---|---|---|
| V1 | `V1__create_schemas.sql` | `CREATE SCHEMA raw, core, mart` |
| V2 | `V2__create_spring_batch_meta.sql` | spring-batch-core jar 의 `schema-postgresql.sql` 을 **사용 중 버전에서 그대로 복사** |
| V3 | `V3__create_legal_dong.sql` | `core.legal_dong` |
| V4 | `V4__seed_legal_dong.sql` | 법정동 20,561행 (CSV 에서 생성한 INSERT, 약 2MB) |
| V5 | `V5__create_region.sql` | `core.region` + 서울 25개 구 seed (legal_dong 에서 선택) |
| V6 | `V6__create_collect_job.sql` | `raw.collect_job` |
| V7 | `V7__create_molit_apt_trade_raw.sql` | `raw.molit_apt_trade_raw` |
| V8 | `V8__create_apt_complex.sql` | `core.apt_complex` |
| V9 | `V9__create_apt_trade.sql` | `core.apt_trade` |
| V10 | `V10__create_trade_mart.sql` | mart 3종 |
| V11 | `V11__create_molit_apt_rent_raw.sql` | `raw.molit_apt_rent_raw` |
| V12 | `V12__create_apt_rent.sql` | `core.apt_rent` |
| V13 | `V13__create_rent_mart.sql` | 전월세 mart 3종 |
| (후속) V14~ | | 법정동 연간 갱신, 교차 지표 |

설정 (application.yaml, 구현 시)
```yaml
spring:
  config:
    import: optional:file:.env[.properties]
  flyway:
    enabled: true
    locations: classpath:db/migration
  batch:
    jdbc:
      initialize-schema: never
  jpa:
    hibernate:
      ddl-auto: validate
```

원칙
- 적용된 마이그레이션 파일은 수정 금지, 변경은 새 버전으로
- JPA 는 `ddl-auto: validate` — 엔티티와 스키마 불일치 시 기동 실패

---

## 9. 열린 이슈

| # | 이슈 | 현재 처리 | 결정 필요 시점 |
|---|---|---|---|
| O1 | ~~매매 API 에 `aptSeq`/법정동코드/도로명 없음~~ | **결정(2026-11-22): 상세 API 활용신청 안 함.** 자연키 `(sgg_cd, umd_nm, jibun, apt_nm)` 로 단지 식별 | 종결 |
| O2 | 매매/전월세 간 `apt_nm` 표기 차이로 같은 단지가 두 개로 갈라질 수 있음 | **측정 완료(서울 2024-10)**: 같은 지번에서 이름만 다른 경우 1건. 자연키 매칭 유지 | 장기 이력(단지명 변경) 적재 후 재측정 |
| O6 | 전세가율(전세 중위 보증금 ÷ 매매 중위가), 월세 전환율 | 미구현. `trade_monthly_complex` 와 `rent_monthly_complex` 가 같은 grain(월·단지·면적대)이라 조인으로 산출 가능 | 화면 요구사항 확정 시 mart 추가 여부 결정 |
| O3 | 2006년대 초기 데이터의 필드 구성/공백 패턴이 최근과 다를 수 있음 | raw 는 전부 VARCHAR 이라 영향 없음 | core 변환 구현 시 연도별 샘플 검증 |
| O5 | 법정동 CSV 는 현존 코드만 포함 → 2006년 이후 폐지·개명된 동 이름의 과거 거래는 `bjd_cd` 매칭 실패 가능 | `bjd_cd` NULL 로 적재, 법정동 mart 에서 제외 | 전체 이력 적재 후 매칭 실패 건수 확인 → 필요 시 별칭(구 동명→현 코드) 매핑 테이블 추가 |
| O4 | ~~DB 접속 정보 미설정~~ | 로컬: `compose.yaml` 의 postgres:17 (`localhost:5434`, ziplog/ziplog). `DB_URL`/`DB_USERNAME`/`DB_PASSWORD` 로 덮어쓰기 가능 | 종결 |

---

## 10. 수용 기준

- [x] 빈 PostgreSQL 에 기동 시 V1~V10 이 순서대로 적용되고 `flyway_schema_history` 에 기록된다
- [x] `core.legal_dong` 에 20,561행, `core.region` 에 25행이 존재한다
- [x] 샘플 거래(강남·송파 2024-10, 563건)의 `bjd_cd` 매칭률 100%
- [ ] Spring Batch 메타 테이블이 Flyway 로 생성되고, `initialize-schema=never` 상태에서 Job 실행이 가능하다
- [x] 실측 응답(서울 25개 구 2024-10 매매 3,941건)을 raw 에 적재 시 컬럼 누락·길이 오류 없이 들어간다
- [x] 동일 단위를 두 번 수집 후 core 반영 시 core 행 수가 증가하지 않고 최신 스냅샷 기준으로 교체된다 (강남·송파 재수집: raw 4,504 / core 3,941)
- [x] 서울 25개 구 2024-10 전월세 20,546건이 raw→core→mart 로 적재되고 `bjd_cd` 매칭률 100%
- [x] 모든 테이블·컬럼에 한글 주석 존재 (누락 0)
- [x] 해제 거래(`cdealType='O'`, 서울 2024-10 실측 218건)가 core 에 `is_canceled=true` 로 존재하고 mart 집계에서 제외된다
