CREATE TABLE core.apt_trade (
    trade_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    complex_id          BIGINT        NOT NULL REFERENCES core.apt_complex (complex_id),
    sgg_cd              VARCHAR(5)    NOT NULL,
    umd_nm              VARCHAR(50)   NOT NULL,
    bjd_cd              VARCHAR(10)   REFERENCES core.legal_dong (bjd_cd),
    deal_ym             VARCHAR(6)    NOT NULL,
    deal_date           DATE          NOT NULL,
    deal_amount         BIGINT        NOT NULL,
    exclu_use_ar        NUMERIC(8, 2) NOT NULL,
    area_band           VARCHAR(10)   NOT NULL CHECK (area_band IN ('LE40', 'LE60', 'LE85', 'LE102', 'LE135', 'GT135')),
    floor               SMALLINT,
    apt_dong            VARCHAR(20),
    build_year          SMALLINT,
    dealing_gbn         VARCHAR(10),
    sler_gbn            VARCHAR(10),
    buyer_gbn           VARCHAR(10),
    estate_agent_sgg_nm VARCHAR(200),
    rgst_date           DATE,
    is_canceled         BOOLEAN       NOT NULL,
    cancel_date         DATE,
    is_land_leasehold   BOOLEAN       NOT NULL,
    collect_job_id      BIGINT        NOT NULL,
    raw_id              BIGINT        NOT NULL,
    loaded_at           TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- 구 + 날짜 범위 조회 및 단위(구, 월) 교체 시 deal_date 범위 조건으로 사용
CREATE INDEX ix_apt_trade_sgg_date ON core.apt_trade (sgg_cd, deal_date);
CREATE INDEX ix_apt_trade_complex  ON core.apt_trade (complex_id, deal_date);

-- ===== 한글 주석 =====
COMMENT ON TABLE core.apt_trade                                         IS '아파트 매매 정제. (시군구, 계약년월) 단위로 delete -> insert 교체';
COMMENT ON COLUMN core.apt_trade.trade_id                               IS '매매 거래 ID';
COMMENT ON COLUMN core.apt_trade.complex_id                             IS '단지 ID';
COMMENT ON COLUMN core.apt_trade.sgg_cd                                 IS '시군구코드';
COMMENT ON COLUMN core.apt_trade.umd_nm                                 IS '법정동명';
COMMENT ON COLUMN core.apt_trade.bjd_cd                                 IS '법정동코드 10자리 (시군구+법정동명으로 매칭, 실패 시 NULL)';
COMMENT ON COLUMN core.apt_trade.deal_ym                                IS '계약년월 YYYYMM (수집 단위)';
COMMENT ON COLUMN core.apt_trade.deal_date                              IS '계약일자';
COMMENT ON COLUMN core.apt_trade.deal_amount                            IS '거래금액 (만원)';
COMMENT ON COLUMN core.apt_trade.exclu_use_ar                           IS '전용면적 (㎡)';
COMMENT ON COLUMN core.apt_trade.area_band                              IS '전용면적대 (LE40: 40이하, LE60, LE85, LE102, LE135, GT135: 135초과)';
COMMENT ON COLUMN core.apt_trade.floor                                  IS '층';
COMMENT ON COLUMN core.apt_trade.apt_dong                               IS '동';
COMMENT ON COLUMN core.apt_trade.build_year                             IS '건축년도';
COMMENT ON COLUMN core.apt_trade.dealing_gbn                            IS '거래유형 (중개거래/직거래)';
COMMENT ON COLUMN core.apt_trade.sler_gbn                               IS '매도자 구분';
COMMENT ON COLUMN core.apt_trade.buyer_gbn                              IS '매수자 구분';
COMMENT ON COLUMN core.apt_trade.estate_agent_sgg_nm                    IS '중개사소재지';
COMMENT ON COLUMN core.apt_trade.rgst_date                              IS '등기일자';
COMMENT ON COLUMN core.apt_trade.is_canceled                            IS '해제 여부 (원본 cdealType = O)';
COMMENT ON COLUMN core.apt_trade.cancel_date                            IS '해제사유발생일';
COMMENT ON COLUMN core.apt_trade.is_land_leasehold                      IS '토지임대부 아파트 여부';
COMMENT ON COLUMN core.apt_trade.collect_job_id                         IS '출처 수집 job ID';
COMMENT ON COLUMN core.apt_trade.raw_id                                 IS '출처 원본 행 ID (raw 보존 정책으로 삭제될 수 있어 FK 미설정)';
COMMENT ON COLUMN core.apt_trade.loaded_at                              IS '적재 시각';
