-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Sukuk Portfolio Analytics
-- ============================================================================
USE DATABASE ISLAMIC_SUKUK_PORTFOLIO;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.SUKUK_PORTFOLIO_ANALYTICS
  COMMENT = 'Sukuk portfolio performance, yield, and risk analytics'
AS
  TABLES (
    CURATED.PORTFOLIO_SUMMARY AS portfolio_summary,CURATED.YIELD_CURVES AS yield_curves,CURATED.COUNTERPARTY_RISK AS counterparty_risk,CURATED.MATURITY_LADDER AS maturity_ladder
  );
