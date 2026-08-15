-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Sukuk Portfolio Analytics
-- ============================================================================
USE DATABASE ISLAMIC_SUKUK_PORTFOLIO;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_INGEST_MARKET_DATA
  WAREHOUSE = SUKUK_WH
  SCHEDULE = 'USING CRON 0 */2 * * * UTC'
  COMMENT = 'Ingest latest market data and Islamic interbank rates'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_REVALUE_PORTFOLIO
  WAREHOUSE = SUKUK_WH
  AFTER APP.TASK_INGEST_MARKET_DATA
  COMMENT = 'Revalue all Sukuk holdings at current market'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_FORECAST_YIELDS
  WAREHOUSE = SUKUK_WH
  AFTER APP.TASK_REVALUE_PORTFOLIO
  COMMENT = 'Run ML.FORECAST on yield curves'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_FORECAST_YIELDS RESUME;
ALTER TASK APP.TASK_REVALUE_PORTFOLIO RESUME;
ALTER TASK APP.TASK_INGEST_MARKET_DATA RESUME;
