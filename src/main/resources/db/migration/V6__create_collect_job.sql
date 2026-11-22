CREATE TABLE raw.collect_job (
    collect_job_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    api_type               VARCHAR(20)  NOT NULL CHECK (api_type IN ('APT_TRADE', 'APT_RENT')),
    lawd_cd                VARCHAR(5)   NOT NULL REFERENCES core.region (sgg_cd),
    deal_ymd               VARCHAR(6)   NOT NULL CHECK (deal_ymd ~ '^[0-9]{6}$'),
    status                 VARCHAR(20)  NOT NULL CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED')),
    total_count            INTEGER,
    page_count             INTEGER,
    loaded_count           INTEGER,
    result_code            VARCHAR(10),
    result_msg             VARCHAR(200),
    error_message          TEXT,
    batch_job_execution_id BIGINT,
    started_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    finished_at            TIMESTAMPTZ,
    core_applied_at        TIMESTAMPTZ
);

CREATE INDEX ix_collect_job_unit
    ON raw.collect_job (api_type, lawd_cd, deal_ymd, finished_at DESC)
    WHERE status = 'SUCCESS';

CREATE INDEX ix_collect_job_pending
    ON raw.collect_job (api_type)
    WHERE status = 'SUCCESS' AND core_applied_at IS NULL;

-- ===== 한글 주석 =====
COMMENT ON TABLE raw.collect_job                                        IS '수집 단위 로그. 단위 = (API 종류, 시군구, 계약년월), 1 job = 1 스냅샷';
COMMENT ON COLUMN raw.collect_job.collect_job_id                        IS '수집 job ID';
COMMENT ON COLUMN raw.collect_job.api_type                              IS 'API 종류 (APT_TRADE: 아파트 매매, APT_RENT: 아파트 전월세)';
COMMENT ON COLUMN raw.collect_job.lawd_cd                               IS '요청 시군구코드 (API LAWD_CD)';
COMMENT ON COLUMN raw.collect_job.deal_ymd                              IS '요청 계약년월 YYYYMM (API DEAL_YMD)';
COMMENT ON COLUMN raw.collect_job.status                                IS '수집 상태 (RUNNING/SUCCESS/FAILED)';
COMMENT ON COLUMN raw.collect_job.total_count                           IS 'API 응답 전체 건수 (totalCount)';
COMMENT ON COLUMN raw.collect_job.page_count                            IS '호출한 페이지 수';
COMMENT ON COLUMN raw.collect_job.loaded_count                          IS '실제 적재 건수 (total_count 와 같아야 SUCCESS)';
COMMENT ON COLUMN raw.collect_job.result_code                           IS 'API 결과 코드 (resultCode)';
COMMENT ON COLUMN raw.collect_job.result_msg                            IS 'API 결과 메시지 (resultMsg)';
COMMENT ON COLUMN raw.collect_job.error_message                         IS '실패 시 오류 내용';
COMMENT ON COLUMN raw.collect_job.batch_job_execution_id                IS 'Spring Batch Job 실행 ID (느슨한 참조)';
COMMENT ON COLUMN raw.collect_job.started_at                            IS '수집 시작 시각';
COMMENT ON COLUMN raw.collect_job.finished_at                           IS '수집 종료 시각';
COMMENT ON COLUMN raw.collect_job.core_applied_at                       IS 'core 반영 시각 (NULL 이면 미반영)';
