-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Sukuk Portfolio Analytics
-- ============================================================================
USE DATABASE ISLAMIC_SUKUK_PORTFOLIO;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.PORTFOLIO_DOCS_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, ISSUER, STRUCTURE_TYPE
  WAREHOUSE = SUKUK_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.PORTFOLIO_DOCS
);
