-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Sukuk Portfolio Analytics
-- Country: MALAYSIA | Currency: MYR
-- ============================================================================
USE DATABASE ISLAMIC_SUKUK_PORTFOLIO;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- SUKUK_HOLDINGS: 500 rows — Sukuk portfolio holdings across 4 structures (Ijara, Murabahah, Wakala, Musharakah)
-- VALUATIONS: 10,000 rows — Daily mark-to-market valuations for all holdings
-- COUNTERPARTIES: 200 rows — Issuer and counterparty profiles with credit ratings
-- MARKET_DATA: 50,000 rows — Islamic interbank rates, benchmark yields, and market indicators
-- PORTFOLIO_DOCS: 40 rows — Investment committee papers, term sheets, and prospectuses
