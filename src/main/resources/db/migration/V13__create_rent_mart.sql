-- 전월세 월별 집계. 임대 유형(전세/월세) 별로 분리. 평당 보증금 = 만원 / 3.3058㎡

CREATE TABLE mart.rent_monthly_sgg (
    deal_ym                    VARCHAR(6)  NOT NULL,
    sgg_cd                     VARCHAR(5)  NOT NULL,
    rent_type                  VARCHAR(10) NOT NULL,
    rent_count                 INTEGER     NOT NULL,
    avg_deposit                BIGINT,
    median_deposit             BIGINT,
    min_deposit                BIGINT,
    max_deposit                BIGINT,
    median_deposit_per_pyeong  BIGINT,
    avg_monthly_rent           BIGINT,
    median_monthly_rent        BIGINT,
    renewal_count              INTEGER     NOT NULL,
    rr_right_used_count        INTEGER     NOT NULL,
    refreshed_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (deal_ym, sgg_cd, rent_type)
);

CREATE TABLE mart.rent_monthly_umd (
    deal_ym                    VARCHAR(6)  NOT NULL,
    bjd_cd                     VARCHAR(10) NOT NULL,
    rent_type                  VARCHAR(10) NOT NULL,
    sgg_cd                     VARCHAR(5)  NOT NULL,
    rent_count                 INTEGER     NOT NULL,
    avg_deposit                BIGINT,
    median_deposit             BIGINT,
    min_deposit                BIGINT,
    max_deposit                BIGINT,
    median_deposit_per_pyeong  BIGINT,
    avg_monthly_rent           BIGINT,
    median_monthly_rent        BIGINT,
    renewal_count              INTEGER     NOT NULL,
    rr_right_used_count        INTEGER     NOT NULL,
    refreshed_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (deal_ym, bjd_cd, rent_type)
);

CREATE TABLE mart.rent_monthly_complex (
    deal_ym                    VARCHAR(6)  NOT NULL,
    complex_id                 BIGINT      NOT NULL,
    area_band                  VARCHAR(10) NOT NULL,
    rent_type                  VARCHAR(10) NOT NULL,
    sgg_cd                     VARCHAR(5)  NOT NULL,
    rent_count                 INTEGER     NOT NULL,
    avg_deposit                BIGINT,
    median_deposit             BIGINT,
    min_deposit                BIGINT,
    max_deposit                BIGINT,
    median_deposit_per_pyeong  BIGINT,
    avg_monthly_rent           BIGINT,
    median_monthly_rent        BIGINT,
    renewal_count              INTEGER     NOT NULL,
    rr_right_used_count        INTEGER     NOT NULL,
    refreshed_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (deal_ym, complex_id, area_band, rent_type)
);

CREATE INDEX ix_rent_monthly_complex_sgg ON mart.rent_monthly_complex (sgg_cd, deal_ym);

-- ===== 한글 주석 =====
COMMENT ON TABLE  mart.rent_monthly_sgg                         IS '아파트 전월세 월별 집계 - 시군구 x 임대유형';
COMMENT ON COLUMN mart.rent_monthly_sgg.deal_ym                 IS '계약년월 YYYYMM';
COMMENT ON COLUMN mart.rent_monthly_sgg.sgg_cd                  IS '시군구코드';
COMMENT ON COLUMN mart.rent_monthly_sgg.rent_type               IS '임대 유형 (JEONSE/WOLSE)';
COMMENT ON COLUMN mart.rent_monthly_sgg.rent_count              IS '거래 건수';
COMMENT ON COLUMN mart.rent_monthly_sgg.avg_deposit             IS '평균 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_sgg.median_deposit          IS '중위 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_sgg.min_deposit             IS '최저 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_sgg.max_deposit             IS '최고 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_sgg.median_deposit_per_pyeong IS '중위 평당 보증금 (만원/3.3㎡, 전용면적 기준)';
COMMENT ON COLUMN mart.rent_monthly_sgg.avg_monthly_rent        IS '평균 월세 (만원, 전세는 0)';
COMMENT ON COLUMN mart.rent_monthly_sgg.median_monthly_rent     IS '중위 월세 (만원, 전세는 0)';
COMMENT ON COLUMN mart.rent_monthly_sgg.renewal_count           IS '갱신 계약 건수';
COMMENT ON COLUMN mart.rent_monthly_sgg.rr_right_used_count     IS '갱신요구권 사용 건수';
COMMENT ON COLUMN mart.rent_monthly_sgg.refreshed_at            IS '집계 갱신 시각';
COMMENT ON TABLE  mart.rent_monthly_umd                         IS '아파트 전월세 월별 집계 - 법정동 (법정동코드 미매칭 거래 제외) x 임대유형';
COMMENT ON COLUMN mart.rent_monthly_umd.deal_ym                 IS '계약년월 YYYYMM';
COMMENT ON COLUMN mart.rent_monthly_umd.bjd_cd                  IS '법정동코드 10자리';
COMMENT ON COLUMN mart.rent_monthly_umd.rent_type               IS '임대 유형 (JEONSE/WOLSE)';
COMMENT ON COLUMN mart.rent_monthly_umd.sgg_cd                  IS '시군구코드 (단위 재계산용)';
COMMENT ON COLUMN mart.rent_monthly_umd.rent_count              IS '거래 건수';
COMMENT ON COLUMN mart.rent_monthly_umd.avg_deposit             IS '평균 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_umd.median_deposit          IS '중위 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_umd.min_deposit             IS '최저 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_umd.max_deposit             IS '최고 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_umd.median_deposit_per_pyeong IS '중위 평당 보증금 (만원/3.3㎡, 전용면적 기준)';
COMMENT ON COLUMN mart.rent_monthly_umd.avg_monthly_rent        IS '평균 월세 (만원, 전세는 0)';
COMMENT ON COLUMN mart.rent_monthly_umd.median_monthly_rent     IS '중위 월세 (만원, 전세는 0)';
COMMENT ON COLUMN mart.rent_monthly_umd.renewal_count           IS '갱신 계약 건수';
COMMENT ON COLUMN mart.rent_monthly_umd.rr_right_used_count     IS '갱신요구권 사용 건수';
COMMENT ON COLUMN mart.rent_monthly_umd.refreshed_at            IS '집계 갱신 시각';
COMMENT ON TABLE  mart.rent_monthly_complex                     IS '아파트 전월세 월별 집계 - 단지 x 전용면적대 x 임대유형';
COMMENT ON COLUMN mart.rent_monthly_complex.deal_ym             IS '계약년월 YYYYMM';
COMMENT ON COLUMN mart.rent_monthly_complex.complex_id          IS '단지 ID';
COMMENT ON COLUMN mart.rent_monthly_complex.area_band           IS '전용면적대';
COMMENT ON COLUMN mart.rent_monthly_complex.rent_type           IS '임대 유형 (JEONSE/WOLSE)';
COMMENT ON COLUMN mart.rent_monthly_complex.sgg_cd              IS '시군구코드 (단위 재계산용)';
COMMENT ON COLUMN mart.rent_monthly_complex.rent_count          IS '거래 건수';
COMMENT ON COLUMN mart.rent_monthly_complex.avg_deposit         IS '평균 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_complex.median_deposit      IS '중위 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_complex.min_deposit         IS '최저 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_complex.max_deposit         IS '최고 보증금 (만원)';
COMMENT ON COLUMN mart.rent_monthly_complex.median_deposit_per_pyeong IS '중위 평당 보증금 (만원/3.3㎡, 전용면적 기준)';
COMMENT ON COLUMN mart.rent_monthly_complex.avg_monthly_rent    IS '평균 월세 (만원, 전세는 0)';
COMMENT ON COLUMN mart.rent_monthly_complex.median_monthly_rent IS '중위 월세 (만원, 전세는 0)';
COMMENT ON COLUMN mart.rent_monthly_complex.renewal_count       IS '갱신 계약 건수';
COMMENT ON COLUMN mart.rent_monthly_complex.rr_right_used_count IS '갱신요구권 사용 건수';
COMMENT ON COLUMN mart.rent_monthly_complex.refreshed_at        IS '집계 갱신 시각';
