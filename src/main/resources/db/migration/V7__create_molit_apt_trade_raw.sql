-- 매매 원본: API 필드 1:1, 전부 길이 제한 없는 VARCHAR, 받은 값 그대로 (trim 안 함)
CREATE TABLE raw.molit_apt_trade_raw (
    raw_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    collect_job_id      BIGINT      NOT NULL REFERENCES raw.collect_job (collect_job_id),
    item_no             INTEGER     NOT NULL,  -- 수집 job 전체 순번 = (pageNo-1)*numOfRows + 페이지 내 순번
    collected_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- API 필드
    sgg_cd              VARCHAR,  -- sggCd
    umd_nm              VARCHAR,  -- umdNm
    apt_nm              VARCHAR,  -- aptNm
    jibun               VARCHAR,  -- jibun
    apt_dong            VARCHAR,  -- aptDong
    build_year          VARCHAR,  -- buildYear
    deal_year           VARCHAR,  -- dealYear
    deal_month          VARCHAR,  -- dealMonth
    deal_day            VARCHAR,  -- dealDay
    deal_amount         VARCHAR,  -- dealAmount (만원, 콤마 포함)
    exclu_use_ar        VARCHAR,  -- excluUseAr
    floor               VARCHAR,  -- floor
    dealing_gbn         VARCHAR,  -- dealingGbn
    estate_agent_sgg_nm VARCHAR,  -- estateAgentSggNm
    rgst_date           VARCHAR,  -- rgstDate (yy.MM.dd)
    cdeal_type          VARCHAR,  -- cdealType ('O' = 해제)
    cdeal_day           VARCHAR,  -- cdealDay (yy.MM.dd)
    sler_gbn            VARCHAR,  -- slerGbn
    buyer_gbn           VARCHAR,  -- buyerGbn
    land_leasehold_gbn  VARCHAR,  -- landLeaseholdGbn
    CONSTRAINT uk_molit_apt_trade_raw_item UNIQUE (collect_job_id, item_no)
);

-- 인덱스는 uk_molit_apt_trade_raw_item 하나만 둔다 (선두 컬럼 collect_job_id 로 job 단위 조회 커버). 쓰기 위주 테이블이라 추가 인덱스 지양

-- ===== 한글 주석 =====
COMMENT ON TABLE raw.molit_apt_trade_raw                                      IS '국토교통부(MOLIT) 아파트 매매 실거래가 원본 (RTMSDataSvcAptTrade). API 필드 1:1, 받은 값 그대로';
COMMENT ON COLUMN raw.molit_apt_trade_raw.raw_id                              IS '원본 행 ID';
COMMENT ON COLUMN raw.molit_apt_trade_raw.collect_job_id                      IS '수집 job ID';
COMMENT ON COLUMN raw.molit_apt_trade_raw.item_no                             IS '수집 job 내 순번 = (pageNo-1) * numOfRows + 페이지 내 순번';
COMMENT ON COLUMN raw.molit_apt_trade_raw.collected_at                        IS '수집 시각';
COMMENT ON COLUMN raw.molit_apt_trade_raw.sgg_cd                              IS '[sggCd] 시군구코드';
COMMENT ON COLUMN raw.molit_apt_trade_raw.umd_nm                              IS '[umdNm] 법정동명';
COMMENT ON COLUMN raw.molit_apt_trade_raw.apt_nm                              IS '[aptNm] 단지명';
COMMENT ON COLUMN raw.molit_apt_trade_raw.jibun                               IS '[jibun] 지번';
COMMENT ON COLUMN raw.molit_apt_trade_raw.apt_dong                            IS '[aptDong] 동 (등기 완료 건만 공개)';
COMMENT ON COLUMN raw.molit_apt_trade_raw.build_year                          IS '[buildYear] 건축년도';
COMMENT ON COLUMN raw.molit_apt_trade_raw.deal_year                           IS '[dealYear] 계약년도';
COMMENT ON COLUMN raw.molit_apt_trade_raw.deal_month                          IS '[dealMonth] 계약월';
COMMENT ON COLUMN raw.molit_apt_trade_raw.deal_day                            IS '[dealDay] 계약일';
COMMENT ON COLUMN raw.molit_apt_trade_raw.deal_amount                         IS '[dealAmount] 거래금액 (만원, 천 단위 콤마 포함)';
COMMENT ON COLUMN raw.molit_apt_trade_raw.exclu_use_ar                        IS '[excluUseAr] 전용면적 (㎡)';
COMMENT ON COLUMN raw.molit_apt_trade_raw.floor                               IS '[floor] 층';
COMMENT ON COLUMN raw.molit_apt_trade_raw.dealing_gbn                         IS '[dealingGbn] 거래유형 (중개거래/직거래)';
COMMENT ON COLUMN raw.molit_apt_trade_raw.estate_agent_sgg_nm                 IS '[estateAgentSggNm] 중개사소재지';
COMMENT ON COLUMN raw.molit_apt_trade_raw.rgst_date                           IS '[rgstDate] 등기일자 (yy.MM.dd)';
COMMENT ON COLUMN raw.molit_apt_trade_raw.cdeal_type                          IS '[cdealType] 해제여부 (O: 해제)';
COMMENT ON COLUMN raw.molit_apt_trade_raw.cdeal_day                           IS '[cdealDay] 해제사유발생일 (yy.MM.dd)';
COMMENT ON COLUMN raw.molit_apt_trade_raw.sler_gbn                            IS '[slerGbn] 매도자 구분 (개인/법인/기타 등)';
COMMENT ON COLUMN raw.molit_apt_trade_raw.buyer_gbn                           IS '[buyerGbn] 매수자 구분 (개인/법인/기타 등)';
COMMENT ON COLUMN raw.molit_apt_trade_raw.land_leasehold_gbn                  IS '[landLeaseholdGbn] 토지임대부 아파트 여부 (Y/N)';
