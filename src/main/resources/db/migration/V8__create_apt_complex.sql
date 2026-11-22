CREATE TABLE core.apt_complex (
    complex_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sgg_cd        VARCHAR(5)   NOT NULL REFERENCES core.region (sgg_cd),
    umd_nm        VARCHAR(50)  NOT NULL,
    bjd_cd        VARCHAR(10)  REFERENCES core.legal_dong (bjd_cd),
    jibun         VARCHAR(50)  NOT NULL,
    apt_nm        VARCHAR(100) NOT NULL,
    apt_seq       VARCHAR(20)  UNIQUE,
    build_year    SMALLINT,
    road_nm       VARCHAR(100),
    first_seen_ym VARCHAR(6)   NOT NULL,
    last_seen_ym  VARCHAR(6)   NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uk_apt_complex_natural UNIQUE (sgg_cd, umd_nm, jibun, apt_nm)
);

-- ===== 한글 주석 =====
COMMENT ON TABLE core.apt_complex                                       IS '아파트 단지 마스터. 자연키 (시군구, 법정동명, 지번, 단지명)';
COMMENT ON COLUMN core.apt_complex.complex_id                           IS '단지 ID';
COMMENT ON COLUMN core.apt_complex.sgg_cd                               IS '시군구코드';
COMMENT ON COLUMN core.apt_complex.umd_nm                               IS '법정동명';
COMMENT ON COLUMN core.apt_complex.bjd_cd                               IS '법정동코드 10자리 (시군구+법정동명으로 매칭, 실패 시 NULL)';
COMMENT ON COLUMN core.apt_complex.jibun                                IS '지번 (없으면 빈 문자열)';
COMMENT ON COLUMN core.apt_complex.apt_nm                               IS '단지명';
COMMENT ON COLUMN core.apt_complex.apt_seq                              IS '단지 일련번호 (전월세 API 에만 존재, 전월세 적재 시 채움)';
COMMENT ON COLUMN core.apt_complex.build_year                           IS '건축년도';
COMMENT ON COLUMN core.apt_complex.road_nm                              IS '도로명주소 (전월세 API 에서 채움)';
COMMENT ON COLUMN core.apt_complex.first_seen_ym                        IS '최초 거래 관측 년월 YYYYMM';
COMMENT ON COLUMN core.apt_complex.last_seen_ym                         IS '최근 거래 관측 년월 YYYYMM';
COMMENT ON COLUMN core.apt_complex.created_at                           IS '등록 시각';
COMMENT ON COLUMN core.apt_complex.updated_at                           IS '수정 시각';
