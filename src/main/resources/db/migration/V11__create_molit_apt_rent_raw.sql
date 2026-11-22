-- 전월세 원본: API 필드 1:1, 전부 길이 제한 없는 VARCHAR, 받은 값 그대로 (trim 안 함)
CREATE TABLE raw.molit_apt_rent_raw (
    raw_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    collect_job_id   BIGINT      NOT NULL REFERENCES raw.collect_job (collect_job_id),
    item_no          INTEGER     NOT NULL,
    collected_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- API 필드
    sgg_cd           VARCHAR,  -- sggCd
    umd_nm           VARCHAR,  -- umdNm
    apt_nm           VARCHAR,  -- aptNm
    jibun            VARCHAR,  -- jibun
    apt_seq          VARCHAR,  -- aptSeq
    build_year       VARCHAR,  -- buildYear
    deal_year        VARCHAR,  -- dealYear
    deal_month       VARCHAR,  -- dealMonth
    deal_day         VARCHAR,  -- dealDay
    deposit          VARCHAR,  -- deposit (만원, 콤마 포함)
    monthly_rent     VARCHAR,  -- monthlyRent (만원)
    exclu_use_ar     VARCHAR,  -- excluUseAr
    floor            VARCHAR,  -- floor
    contract_term    VARCHAR,  -- contractTerm (yy.MM~yy.MM)
    contract_type    VARCHAR,  -- contractType (신규/갱신)
    use_rr_right     VARCHAR,  -- useRRRight (사용)
    pre_deposit      VARCHAR,  -- preDeposit
    pre_monthly_rent VARCHAR,  -- preMonthlyRent
    road_nm          VARCHAR,  -- roadnm
    road_nm_sgg_cd   VARCHAR,  -- roadnmsggcd
    road_nm_cd       VARCHAR,  -- roadnmcd
    road_nm_seq      VARCHAR,  -- roadnmseq
    road_nm_bcd      VARCHAR,  -- roadnmbcd
    road_nm_bonbun   VARCHAR,  -- roadnmbonbun
    road_nm_bubun    VARCHAR,  -- roadnmbubun
    CONSTRAINT uk_molit_apt_rent_raw_item UNIQUE (collect_job_id, item_no)
);
-- 인덱스는 uk_molit_apt_rent_raw_item 하나만 둔다 (매매 raw 와 동일 원칙)

-- ===== 한글 주석 =====
COMMENT ON TABLE  raw.molit_apt_rent_raw                  IS '국토교통부(MOLIT) 아파트 전월세 실거래가 원본 (RTMSDataSvcAptRent). API 필드 1:1, 받은 값 그대로';
COMMENT ON COLUMN raw.molit_apt_rent_raw.raw_id           IS '원본 행 ID';
COMMENT ON COLUMN raw.molit_apt_rent_raw.collect_job_id   IS '수집 job ID';
COMMENT ON COLUMN raw.molit_apt_rent_raw.item_no          IS '수집 job 내 순번 = (pageNo-1) * numOfRows + 페이지 내 순번';
COMMENT ON COLUMN raw.molit_apt_rent_raw.collected_at     IS '수집 시각';
COMMENT ON COLUMN raw.molit_apt_rent_raw.sgg_cd           IS '[sggCd] 시군구코드';
COMMENT ON COLUMN raw.molit_apt_rent_raw.umd_nm           IS '[umdNm] 법정동명';
COMMENT ON COLUMN raw.molit_apt_rent_raw.apt_nm           IS '[aptNm] 단지명';
COMMENT ON COLUMN raw.molit_apt_rent_raw.jibun            IS '[jibun] 지번';
COMMENT ON COLUMN raw.molit_apt_rent_raw.apt_seq          IS '[aptSeq] 단지 일련번호';
COMMENT ON COLUMN raw.molit_apt_rent_raw.build_year       IS '[buildYear] 건축년도';
COMMENT ON COLUMN raw.molit_apt_rent_raw.deal_year        IS '[dealYear] 계약년도';
COMMENT ON COLUMN raw.molit_apt_rent_raw.deal_month       IS '[dealMonth] 계약월';
COMMENT ON COLUMN raw.molit_apt_rent_raw.deal_day         IS '[dealDay] 계약일';
COMMENT ON COLUMN raw.molit_apt_rent_raw.deposit          IS '[deposit] 보증금 (만원, 천 단위 콤마 포함)';
COMMENT ON COLUMN raw.molit_apt_rent_raw.monthly_rent     IS '[monthlyRent] 월세 (만원, 0 이면 전세)';
COMMENT ON COLUMN raw.molit_apt_rent_raw.exclu_use_ar     IS '[excluUseAr] 전용면적 (㎡)';
COMMENT ON COLUMN raw.molit_apt_rent_raw.floor            IS '[floor] 층';
COMMENT ON COLUMN raw.molit_apt_rent_raw.contract_term    IS '[contractTerm] 계약기간 (yy.MM~yy.MM, 시작 생략 가능)';
COMMENT ON COLUMN raw.molit_apt_rent_raw.contract_type    IS '[contractType] 계약구분 (신규/갱신)';
COMMENT ON COLUMN raw.molit_apt_rent_raw.use_rr_right     IS '[useRRRight] 갱신요구권 사용 (사용)';
COMMENT ON COLUMN raw.molit_apt_rent_raw.pre_deposit      IS '[preDeposit] 종전계약 보증금 (만원)';
COMMENT ON COLUMN raw.molit_apt_rent_raw.pre_monthly_rent IS '[preMonthlyRent] 종전계약 월세 (만원)';
COMMENT ON COLUMN raw.molit_apt_rent_raw.road_nm          IS '[roadnm] 도로명주소';
COMMENT ON COLUMN raw.molit_apt_rent_raw.road_nm_sgg_cd   IS '[roadnmsggcd] 도로명 시군구코드';
COMMENT ON COLUMN raw.molit_apt_rent_raw.road_nm_cd       IS '[roadnmcd] 도로명코드';
COMMENT ON COLUMN raw.molit_apt_rent_raw.road_nm_seq      IS '[roadnmseq] 도로명 일련번호';
COMMENT ON COLUMN raw.molit_apt_rent_raw.road_nm_bcd      IS '[roadnmbcd] 도로명 지상/지하 코드';
COMMENT ON COLUMN raw.molit_apt_rent_raw.road_nm_bonbun   IS '[roadnmbonbun] 도로명 건물 본번';
COMMENT ON COLUMN raw.molit_apt_rent_raw.road_nm_bubun    IS '[roadnmbubun] 도로명 건물 부번';
