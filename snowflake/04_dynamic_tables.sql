-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Sukuk Portfolio Analytics
-- ============================================================================
USE DATABASE ISLAMIC_SUKUK_PORTFOLIO;
USE SCHEMA CURATED;

-- PORTFOLIO_SUMMARY: Real-time portfolio AUM, weighted yield, and allocation breakdown
-- Source: SUKUK_HOLDINGS, VALUATIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.PORTFOLIO_SUMMARY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SUKUK_WH
AS
SELECT * FROM RAW.SUKUK_HOLDINGS;
-- TODO: Replace with actual join/aggregation logic per demo

-- YIELD_CURVES: Sukuk yield curve construction by structure type
-- Source: MARKET_DATA, VALUATIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.YIELD_CURVES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SUKUK_WH
AS
SELECT * FROM RAW.MARKET_DATA;
-- TODO: Replace with actual join/aggregation logic per demo

-- COUNTERPARTY_RISK: Counterparty exposure and credit risk aggregation
-- Source: SUKUK_HOLDINGS, COUNTERPARTIES
CREATE OR REPLACE DYNAMIC TABLE CURATED.COUNTERPARTY_RISK
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SUKUK_WH
AS
SELECT * FROM RAW.SUKUK_HOLDINGS;
-- TODO: Replace with actual join/aggregation logic per demo

-- MATURITY_LADDER: Cash flow and maturity profile for liquidity planning
-- Source: SUKUK_HOLDINGS, VALUATIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.MATURITY_LADDER
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SUKUK_WH
AS
SELECT * FROM RAW.SUKUK_HOLDINGS;
-- TODO: Replace with actual join/aggregation logic per demo

