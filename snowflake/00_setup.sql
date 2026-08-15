-- ============================================================================
-- Sukuk Portfolio Analytics
-- Real-time Sukuk portfolio management for Malaysia's world-leading Islamic capital market — Dynamic Tables build portfolio views, Iceberg enables cross-institution analysis, and Cortex Analyst answers portfolio questions.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS ISLAMIC_SUKUK_PORTFOLIO;
CREATE WAREHOUSE IF NOT EXISTS SUKUK_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE ISLAMIC_SUKUK_PORTFOLIO;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE SUKUK_WH;
