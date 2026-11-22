-- 법정동 마스터 (전국). 출처: 국토교통부_전국 법정동 (data.go.kr 15063424)
CREATE TABLE core.legal_dong (
    bjd_cd       VARCHAR(10) PRIMARY KEY CHECK (bjd_cd ~ '^[0-9]{10}$'),
    sido_cd      VARCHAR(2)  GENERATED ALWAYS AS (substr(bjd_cd, 1, 2)) STORED,
    sgg_cd       VARCHAR(5)  GENERATED ALWAYS AS (substr(bjd_cd, 1, 5)) STORED,
    level        VARCHAR(4)  GENERATED ALWAYS AS (
                     CASE WHEN ri_nm  IS NOT NULL THEN 'RI'
                          WHEN umd_nm IS NOT NULL THEN 'UMD'
                          WHEN sgg_nm IS NOT NULL THEN 'SGG'
                          ELSE 'SIDO' END) STORED,
    sido_nm      VARCHAR(20) NOT NULL,
    sgg_nm       VARCHAR(20),
    umd_nm       VARCHAR(20),
    ri_nm        VARCHAR(20),
    seq          INTEGER,
    created_date DATE        NOT NULL,
    is_active    BOOLEAN     NOT NULL DEFAULT TRUE,
    source_date  DATE        NOT NULL,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 실거래 API 의 (sggCd, umdNm) -> 법정동코드 매칭용
CREATE UNIQUE INDEX uk_legal_dong_umd ON core.legal_dong (sgg_cd, umd_nm) WHERE level = 'UMD';
CREATE INDEX ix_legal_dong_sgg ON core.legal_dong (sgg_cd);

-- ===== 한글 주석 =====
COMMENT ON TABLE core.legal_dong                                        IS '법정동 마스터 (전국, 시도/시군구/읍면동/리). 출처: 국토교통부_전국 법정동 CSV';
COMMENT ON COLUMN core.legal_dong.bjd_cd                                IS '법정동코드 10자리 (시도2 + 시군구3 + 읍면동3 + 리2)';
COMMENT ON COLUMN core.legal_dong.sido_cd                               IS '시도코드 2자리 (bjd_cd 앞 2자리, 자동 계산)';
COMMENT ON COLUMN core.legal_dong.sgg_cd                                IS '시군구코드 5자리 (bjd_cd 앞 5자리, 자동 계산) = 실거래 API LAWD_CD';
COMMENT ON COLUMN core.legal_dong.level                                 IS '단계: SIDO/SGG/UMD/RI (이름이 채워진 단계로 자동 계산)';
COMMENT ON COLUMN core.legal_dong.sido_nm                               IS '시도명';
COMMENT ON COLUMN core.legal_dong.sgg_nm                                IS '시군구명';
COMMENT ON COLUMN core.legal_dong.umd_nm                                IS '읍면동명';
COMMENT ON COLUMN core.legal_dong.ri_nm                                 IS '리명';
COMMENT ON COLUMN core.legal_dong.seq                                   IS 'CSV 순번 (일부 행 공란)';
COMMENT ON COLUMN core.legal_dong.created_date                          IS '법정동 생성일자';
COMMENT ON COLUMN core.legal_dong.is_active                             IS '현존 여부. 최신 원본 파일에서 사라진 코드는 삭제하지 않고 FALSE';
COMMENT ON COLUMN core.legal_dong.source_date                           IS '이 행을 마지막으로 반영한 원본 파일 기준일';
COMMENT ON COLUMN core.legal_dong.updated_at                            IS '수정 시각';
