-- 수집 대상 시군구 설정. 이름 등 속성은 core.legal_dong 의 시군구 행에서 조회
CREATE TABLE core.region (
    sgg_cd          VARCHAR(5)  PRIMARY KEY,
    bjd_cd          VARCHAR(10) GENERATED ALWAYS AS (sgg_cd || '00000') STORED
                        REFERENCES core.legal_dong (bjd_cd),
    collect_enabled BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 서울 25개 구
INSERT INTO core.region (sgg_cd)
SELECT sgg_cd FROM core.legal_dong
WHERE sido_cd = '11' AND level = 'SGG'
ORDER BY sgg_cd;

-- ===== 한글 주석 =====
COMMENT ON TABLE core.region                                            IS '실거래 수집 대상 시군구 설정';
COMMENT ON COLUMN core.region.sgg_cd                                    IS '시군구코드 5자리 = 실거래 API LAWD_CD';
COMMENT ON COLUMN core.region.bjd_cd                                    IS '법정동 마스터의 시군구 행 코드 (sgg_cd || 00000, 자동 계산)';
COMMENT ON COLUMN core.region.collect_enabled                           IS '수집 대상 여부';
COMMENT ON COLUMN core.region.created_at                                IS '등록 시각';
