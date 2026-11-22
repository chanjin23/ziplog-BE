CREATE TABLE core.apt_rent (
    rent_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    complex_id        BIGINT        NOT NULL REFERENCES core.apt_complex (complex_id),
    sgg_cd            VARCHAR(5)    NOT NULL,
    umd_nm            VARCHAR(50)   NOT NULL,
    bjd_cd            VARCHAR(10)   REFERENCES core.legal_dong (bjd_cd),
    deal_ym           VARCHAR(6)    NOT NULL,
    deal_date         DATE          NOT NULL,
    rent_type         VARCHAR(10)   NOT NULL CHECK (rent_type IN ('JEONSE', 'WOLSE')),
    deposit           BIGINT        NOT NULL,
    monthly_rent      BIGINT        NOT NULL,
    exclu_use_ar      NUMERIC(8, 2) NOT NULL,
    area_band         VARCHAR(10)   NOT NULL CHECK (area_band IN ('LE40', 'LE60', 'LE85', 'LE102', 'LE135', 'GT135')),
    floor             SMALLINT,
    build_year        SMALLINT,
    contract_type     VARCHAR(10),
    contract_start_ym VARCHAR(6),
    contract_end_ym   VARCHAR(6),
    is_rr_right_used  BOOLEAN,
    pre_deposit       BIGINT,
    pre_monthly_rent  BIGINT,
    collect_job_id    BIGINT        NOT NULL,
    raw_id            BIGINT        NOT NULL,
    loaded_at         TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX ix_apt_rent_sgg_date ON core.apt_rent (sgg_cd, deal_date);
CREATE INDEX ix_apt_rent_complex  ON core.apt_rent (complex_id, deal_date);

-- ===== 한글 주석 =====
COMMENT ON TABLE  core.apt_rent                   IS '아파트 전월세 정제. (시군구, 계약년월) 단위로 delete -> insert 교체';
COMMENT ON COLUMN core.apt_rent.rent_id           IS '전월세 거래 ID';
COMMENT ON COLUMN core.apt_rent.complex_id        IS '단지 ID';
COMMENT ON COLUMN core.apt_rent.sgg_cd            IS '시군구코드';
COMMENT ON COLUMN core.apt_rent.umd_nm            IS '법정동명';
COMMENT ON COLUMN core.apt_rent.bjd_cd            IS '법정동코드 10자리 (시군구+법정동명으로 매칭, 실패 시 NULL)';
COMMENT ON COLUMN core.apt_rent.deal_ym           IS '계약년월 YYYYMM (수집 단위)';
COMMENT ON COLUMN core.apt_rent.deal_date         IS '계약일자';
COMMENT ON COLUMN core.apt_rent.rent_type         IS '임대 유형 (JEONSE: 전세 = 월세 0, WOLSE: 월세)';
COMMENT ON COLUMN core.apt_rent.deposit           IS '보증금 (만원)';
COMMENT ON COLUMN core.apt_rent.monthly_rent      IS '월세 (만원, 전세는 0)';
COMMENT ON COLUMN core.apt_rent.exclu_use_ar      IS '전용면적 (㎡)';
COMMENT ON COLUMN core.apt_rent.area_band         IS '전용면적대 (LE40: 40이하, LE60, LE85, LE102, LE135, GT135: 135초과)';
COMMENT ON COLUMN core.apt_rent.floor             IS '층';
COMMENT ON COLUMN core.apt_rent.build_year        IS '건축년도';
COMMENT ON COLUMN core.apt_rent.contract_type     IS '계약구분 (신규/갱신, 미제공 시 NULL)';
COMMENT ON COLUMN core.apt_rent.contract_start_ym IS '계약 시작 년월 YYYYMM (원본 contractTerm 앞부분)';
COMMENT ON COLUMN core.apt_rent.contract_end_ym   IS '계약 종료 년월 YYYYMM (원본 contractTerm 뒷부분)';
COMMENT ON COLUMN core.apt_rent.is_rr_right_used  IS '갱신요구권 사용 여부 (사용=TRUE, 계약구분 있고 미사용=FALSE, 정보 없음=NULL)';
COMMENT ON COLUMN core.apt_rent.pre_deposit       IS '종전계약 보증금 (만원)';
COMMENT ON COLUMN core.apt_rent.pre_monthly_rent  IS '종전계약 월세 (만원)';
COMMENT ON COLUMN core.apt_rent.collect_job_id    IS '출처 수집 job ID';
COMMENT ON COLUMN core.apt_rent.raw_id            IS '출처 원본 행 ID (raw 보존 정책으로 삭제될 수 있어 FK 미설정)';
COMMENT ON COLUMN core.apt_rent.loaded_at         IS '적재 시각';
