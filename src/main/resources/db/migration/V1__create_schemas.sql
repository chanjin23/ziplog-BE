-- 계층별 스키마: raw(원천) -> core(정제) -> mart(집계)
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS mart;

-- ===== 한글 주석 =====
COMMENT ON SCHEMA raw                                                   IS '원천 계층: 외부 데이터를 받은 그대로 보관';
COMMENT ON SCHEMA core                                                  IS '정제 계층: 타입 변환·정규화된 분석 기준 데이터 및 마스터';
COMMENT ON SCHEMA mart                                                  IS '집계 계층: 화면/분석용 집계 결과';
