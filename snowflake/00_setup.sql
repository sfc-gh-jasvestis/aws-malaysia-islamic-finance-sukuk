-- Generated from generator/demo_specs/aws-malaysia-islamic-finance-sukuk.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-malaysia-islamic-finance-sukuk
-- This is the schema that is actually deployed for MY_ISLAMIC_FINANCE_SUKUK.

-- MY_ISLAMIC_FINANCE_SUKUK  (Sukuk Portfolio Analytics)
-- generated from generator/demo_specs/aws-malaysia-islamic-finance-sukuk.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS MY_ISLAMIC_FINANCE_SUKUK;
CREATE SCHEMA IF NOT EXISTS MY_ISLAMIC_FINANCE_SUKUK.RAW;
CREATE SCHEMA IF NOT EXISTS MY_ISLAMIC_FINANCE_SUKUK.CURATED;
CREATE SCHEMA IF NOT EXISTS MY_ISLAMIC_FINANCE_SUKUK.APP;
USE DATABASE MY_ISLAMIC_FINANCE_SUKUK;

-- 5 real regions; entity names carry their region so the two always agree
