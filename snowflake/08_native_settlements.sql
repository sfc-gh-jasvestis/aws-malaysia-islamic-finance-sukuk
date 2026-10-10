-- ============================================================================
-- 08_native_settlements.sql - Snowflake-only build: live settlement feed without AWS.
-- Creates RAW.LIVE_SETTLEMENTS (same columns as the Snowpipe target created by
-- aws/setup_aws.py) and APP.SIMULATE_SETTLEMENTS(N), which inserts synthetic
-- settlement events with the same value ranges and ~10% BREAK rate as
-- aws/publish_settlements.py. Rows are inserted directly; this simulates an
-- settlement feed and is not Snowpipe Streaming.
-- Run before 06_intelligence.sql (the alert reads RAW.LIVE_SETTLEMENTS).
-- Idempotent: safe to run in the AWS build too.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS APP;

CREATE TABLE IF NOT EXISTS RAW.LIVE_SETTLEMENTS (
  HOLDING_ID VARCHAR, EVENT_TS TIMESTAMP_NTZ, AMOUNT_MYR FLOAT, HOURS_UNMATCHED FLOAT,
  STATUS VARCHAR, SENT_TS TIMESTAMP_NTZ, SOURCE_FILE VARCHAR,
  LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE APP.SIMULATE_SETTLEMENTS(N NUMBER)
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  IF (N < 1 OR N > 1000) THEN
    RETURN 0;
  END IF;
  INSERT INTO RAW.LIVE_SETTLEMENTS (HOLDING_ID, EVENT_TS, AMOUNT_MYR, HOURS_UNMATCHED, STATUS, SENT_TS, SOURCE_FILE)
    WITH g AS (
      SELECT 'MYS-' || LPAD(UNIFORM(0, 39, RANDOM())::VARCHAR, 4, '0') AS HOLDING_ID,
             UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.1 AS IS_BREAK,
             SYSDATE() AS TS, SEQ4() AS I
      FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    )
    -- NORMAL() needs constant arguments, so the break offset is applied outside it.
    SELECT HOLDING_ID, TS,
           ROUND(IFF(IS_BREAK, 4000000, 2500000) * EXP(NORMAL(0, 0.5, RANDOM())), 0),
           ROUND(IFF(IS_BREAK, 12, 0.3) * EXP(NORMAL(0, 0.4, RANDOM())), 0),
           IFF(IS_BREAK, 'BREAK', 'MATCHED'), TS, 'APP.SIMULATE_SETTLEMENTS'
    FROM g
    WHERE I < :N;
  RETURN SQLROWCOUNT;
END;
$$;

-- Optional continuous feed for longer demos (suspended; RESUME to start, SUSPEND after).
CREATE OR REPLACE TASK APP.TASK_SIMULATE_SETTLEMENTS
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '1 MINUTE'
AS
  CALL APP.SIMULATE_SETTLEMENTS(5);
