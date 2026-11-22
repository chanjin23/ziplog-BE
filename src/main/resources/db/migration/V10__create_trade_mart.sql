-- 매매 월별 집계. 해제 거래 제외. 평당가 = 만원 / 3.3058㎡
CREATE TABLE mart.trade_monthly_sgg (
    deal_ym                 VARCHAR(6)  NOT NULL,
    sgg_cd                  VARCHAR(5)  NOT NULL,
    trade_count             INTEGER     NOT NULL,
    avg_amount              BIGINT,
    median_amount           BIGINT,
    min_amount              BIGINT,
    max_amount              BIGINT,
    avg_price_per_pyeong    BIGINT,
    median_price_per_pyeong BIGINT,
    refreshed_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (deal_ym, sgg_cd)
);

-- 법정동 단위: bjd_cd 매칭된 거래만 집계 (매칭 실패 거래는 제외)
CREATE TABLE mart.trade_monthly_umd (
    deal_ym                 VARCHAR(6)  NOT NULL,
    bjd_cd                  VARCHAR(10) NOT NULL,
    sgg_cd                  VARCHAR(5)  NOT NULL,
    trade_count             INTEGER     NOT NULL,
    avg_amount              BIGINT,
    median_amount           BIGINT,
    min_amount              BIGINT,
    max_amount              BIGINT,
    avg_price_per_pyeong    BIGINT,
    median_price_per_pyeong BIGINT,
    refreshed_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (deal_ym, bjd_cd)
);

CREATE TABLE mart.trade_monthly_complex (
    deal_ym                 VARCHAR(6)  NOT NULL,
    complex_id              BIGINT      NOT NULL,
    area_band               VARCHAR(10) NOT NULL,
    sgg_cd                  VARCHAR(5)  NOT NULL,
    trade_count             INTEGER     NOT NULL,
    avg_amount              BIGINT,
    median_amount           BIGINT,
    min_amount              BIGINT,
    max_amount              BIGINT,
    avg_price_per_pyeong    BIGINT,
    median_price_per_pyeong BIGINT,
    refreshed_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (deal_ym, complex_id, area_band)
);

CREATE INDEX ix_trade_monthly_complex_sgg ON mart.trade_monthly_complex (sgg_cd, deal_ym);

-- ===== 한글 주석 =====
COMMENT ON TABLE mart.trade_monthly_sgg                                 IS '아파트 매매 월별 집계 - 시군구 단위 (해제 거래 제외)';
COMMENT ON COLUMN mart.trade_monthly_sgg.deal_ym                        IS '계약년월 YYYYMM';
COMMENT ON COLUMN mart.trade_monthly_sgg.sgg_cd                         IS '시군구코드';
COMMENT ON COLUMN mart.trade_monthly_sgg.trade_count                    IS '거래 건수 (해제 거래 제외)';
COMMENT ON COLUMN mart.trade_monthly_sgg.avg_amount                     IS '평균 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_sgg.median_amount                  IS '중위 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_sgg.min_amount                     IS '최저 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_sgg.max_amount                     IS '최고 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_sgg.avg_price_per_pyeong           IS '평균 평당가 (만원/3.3㎡, 전용면적 기준)';
COMMENT ON COLUMN mart.trade_monthly_sgg.median_price_per_pyeong        IS '중위 평당가 (만원/3.3㎡, 전용면적 기준)';
COMMENT ON COLUMN mart.trade_monthly_sgg.refreshed_at                   IS '집계 갱신 시각';
COMMENT ON TABLE mart.trade_monthly_umd                                 IS '아파트 매매 월별 집계 - 법정동 단위 (해제 거래 및 법정동코드 미매칭 거래 제외)';
COMMENT ON COLUMN mart.trade_monthly_umd.deal_ym                        IS '계약년월 YYYYMM';
COMMENT ON COLUMN mart.trade_monthly_umd.bjd_cd                         IS '법정동코드 10자리';
COMMENT ON COLUMN mart.trade_monthly_umd.sgg_cd                         IS '시군구코드 (단위 재계산용)';
COMMENT ON COLUMN mart.trade_monthly_umd.trade_count                    IS '거래 건수 (해제 거래 제외)';
COMMENT ON COLUMN mart.trade_monthly_umd.avg_amount                     IS '평균 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_umd.median_amount                  IS '중위 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_umd.min_amount                     IS '최저 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_umd.max_amount                     IS '최고 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_umd.avg_price_per_pyeong           IS '평균 평당가 (만원/3.3㎡, 전용면적 기준)';
COMMENT ON COLUMN mart.trade_monthly_umd.median_price_per_pyeong        IS '중위 평당가 (만원/3.3㎡, 전용면적 기준)';
COMMENT ON COLUMN mart.trade_monthly_umd.refreshed_at                   IS '집계 갱신 시각';
COMMENT ON TABLE mart.trade_monthly_complex                             IS '아파트 매매 월별 집계 - 단지 x 전용면적대 단위 (해제 거래 제외)';
COMMENT ON COLUMN mart.trade_monthly_complex.deal_ym                    IS '계약년월 YYYYMM';
COMMENT ON COLUMN mart.trade_monthly_complex.complex_id                 IS '단지 ID';
COMMENT ON COLUMN mart.trade_monthly_complex.area_band                  IS '전용면적대';
COMMENT ON COLUMN mart.trade_monthly_complex.sgg_cd                     IS '시군구코드 (단위 재계산용)';
COMMENT ON COLUMN mart.trade_monthly_complex.trade_count                IS '거래 건수 (해제 거래 제외)';
COMMENT ON COLUMN mart.trade_monthly_complex.avg_amount                 IS '평균 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_complex.median_amount              IS '중위 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_complex.min_amount                 IS '최저 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_complex.max_amount                 IS '최고 거래금액 (만원)';
COMMENT ON COLUMN mart.trade_monthly_complex.avg_price_per_pyeong       IS '평균 평당가 (만원/3.3㎡, 전용면적 기준)';
COMMENT ON COLUMN mart.trade_monthly_complex.median_price_per_pyeong    IS '중위 평당가 (만원/3.3㎡, 전용면적 기준)';
COMMENT ON COLUMN mart.trade_monthly_complex.refreshed_at               IS '집계 갱신 시각';
