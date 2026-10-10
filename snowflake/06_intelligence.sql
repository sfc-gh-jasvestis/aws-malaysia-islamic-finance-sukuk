-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-break alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_SETTLEMENTS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic sukuk operations knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.BREAK_DOCS AS
WITH types AS (
  SELECT DISTINCT r.BREAK_REASON, a.CATEGORY
  FROM RAW.HOLDING_DAILY r JOIN RAW.HOLDINGS a ON a.ID = r.ENTITY_ID
  WHERE r.ESCALATED_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, BREAK_REASON)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  BREAK_REASON,
  CATEGORY || ' - ' || BREAK_REASON || ' break handling' AS TITLE,
  'Synthetic demo SOP for a fictional investor''s sukuk back office. It does not state any regulatory or Shariah requirement and is not investment advice. Sukuk type: ' || CATEGORY
  || '. Break reason: ' || BREAK_REASON || '. '
  || 'Step 1: open a break record, link the unmatched instruction and assign a settlement officer within one working day. '
  || 'Step 2: ' || CASE
       WHEN BREAK_REASON = 'Price or yield mismatch' THEN 'compare the agreed price or yield on the trade ticket with the counterparty confirmation, and ask the front office to confirm the dealt terms before amending the instruction.'
       WHEN BREAK_REASON = 'Late counterparty confirmation' THEN 'chase the counterparty through its registered operations contact, log each attempt, and tell the custodian that settlement may move to the next cycle.'
       WHEN BREAK_REASON = 'Settlement instruction mismatch' THEN 'compare the standing settlement instructions on file with those in the custodian message, correct the static data after four-eyes approval, and resend the instruction.'
       WHEN BREAK_REASON = 'Quantity mismatch' THEN 'reconcile the nominal amount on the trade ticket, the custodian position and the counterparty confirmation, and hold the instruction until all three agree.'
       WHEN BREAK_REASON = 'Distribution amount mismatch' THEN 'recalculate the expected periodic distribution from the series terms summary and the position held on the record date, then raise a query with the custodian or paying agent.'
       WHEN BREAK_REASON = 'Holder record mismatch' THEN 'compare the sub-account holder register with the custodian record, correct the register after four-eyes approval, and reprocess the distribution instruction.'
       WHEN BREAK_REASON = 'Profit-share calculation query' THEN 'request the profit-share calculation statement from the issuer''s agent, because the distribution on a musharakah sukuk depends on reported results, and escalate if it is not received within 10 working days.'
       ELSE 'review the break against the holding profile and escalate if unexplained.'
     END
  || ' Step 3: if the auto-match failure rate on the holding exceeds 5% or the average break age exceeds 40 hours after triage, keep the break open and request a static-data review with the custodian. '
  || 'Step 4: record the resolution; if the break was escalated or missed its resolution SLA, log it for the operations report.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.BREAK_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, BREAK_REASON
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, BREAK_REASON, CONTENT FROM SEARCH.BREAK_DOCS);

-- ---------- Auto-match failure rate anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.AUTOMATCH_FAIL_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, AUTOMATCH_FAIL_PCT::FLOAT AS AUTOMATCH_FAIL
FROM RAW.HOLDING_DAILY;
CREATE OR REPLACE VIEW ML.AUTOMATCH_FAIL_TRAIN AS
SELECT * FROM ML.AUTOMATCH_FAIL_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.AUTOMATCH_FAIL_SERIES);
CREATE OR REPLACE VIEW ML.AUTOMATCH_FAIL_DETECT AS
SELECT * FROM ML.AUTOMATCH_FAIL_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.AUTOMATCH_FAIL_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.AUTOMATCH_FAIL_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.AUTOMATCH_FAIL_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'AUTOMATCH_FAIL',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.AUTOMATCH_FAIL_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS AUTOMATCH_FAIL, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.AUTOMATCH_FAIL_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.AUTOMATCH_FAIL_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'AUTOMATCH_FAIL'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.SUKUK_ANALYTICS
  TABLES (
    holdings AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      COMMENT = 'One row per sukuk holding (one sukuk series at one custodian), 90-day totals',
    risk AS ML.ESCALATION_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day break escalation probability per holding',
    reasons AS CURATED.BREAK_SUMMARY PRIMARY KEY (BREAK_REASON)
      COMMENT = 'Settlement breaks, escalations and resolution SLA breaches by break reason, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Portfolio-wide totals per day'
  )
  RELATIONSHIPS (risk_holding AS risk (ENTITY_ID) REFERENCES holdings)
  FACTS (
    holdings.breaks_f AS BREAK_COUNT,
    holdings.escalated_f AS ESCALATED_COUNT,
    holdings.breaches_f AS SLA_BREACH_COUNT,
    holdings.settlements_f AS SETTLEMENT_COUNT,
    holdings.value_f AS VALUE_MYR,
    holdings.recon_due_f AS RECON_DUE,
    holdings.recon_done_f AS RECON_COMPLETED,
    risk.escalation_prob_f AS ESCALATION_PROB_7D,
    reasons.reason_break_f AS BREAK_COUNT,
    reasons.reason_escalated_f AS ESCALATED_COUNT,
    reasons.reason_breaches_f AS SLA_BREACH_COUNT,
    reasons.reason_value_f AS EXPOSED_VALUE_MYR,
    daily.day_break_f AS BREAK_COUNT,
    daily.day_escalated_f AS ESCALATED_COUNT,
    daily.day_value_f AS VALUE_MYR
  )
  DIMENSIONS (
    holdings.holding_id AS ENTITY_ID WITH SYNONYMS = ('holding', 'sukuk holding', 'series', 'entity'),
    holdings.holding_name AS ENTITY_NAME,
    holdings.custodian AS CUSTODIAN WITH SYNONYMS = ('custodian', 'custodian bank', 'region')
      COMMENT = 'Fictional custodian that services the holding',
    holdings.sukuk_type AS CATEGORY WITH SYNONYMS = ('sukuk type', 'type', 'structure')
      COMMENT = 'Sovereign murabahah, Sovereign wakalah, Retail sukuk wakalah, Corporate ijarah or Corporate musharakah',
    holdings.risk_tier AS RISK_TIER COMMENT = 'Settlement complexity grade 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    reasons.break_reason AS BREAK_REASON WITH SYNONYMS = ('break reason', 'reason', 'cause'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    holdings.holding_count AS COUNT(holdings.holding_id)
      WITH SYNONYMS = ('number of holdings', 'entities', 'number of entities'),
    holdings.settlement_match_pct AS 100 * (SUM(holdings.settlements_f) - SUM(holdings.breaks_f)) / NULLIF(SUM(holdings.settlements_f), 0)
      WITH SYNONYMS = ('settlement match rate', 'match rate')
      COMMENT = 'Instructions without a settlement break / instructions processed',
    holdings.escalation_rate_pct AS 100 * SUM(holdings.escalated_f) / NULLIF(SUM(holdings.breaks_f), 0)
      COMMENT = 'Settlement breaks escalated to custodian investigation / settlement breaks',
    holdings.break_cases AS SUM(holdings.breaks_f) WITH SYNONYMS = ('breaks', 'unmatched instructions'),
    holdings.escalated_cases AS SUM(holdings.escalated_f) WITH SYNONYMS = ('escalations', 'custodian investigations'),
    holdings.sla_breaches AS SUM(holdings.breaches_f) WITH SYNONYMS = ('resolution SLA misses'),
    holdings.instructions_processed AS SUM(holdings.settlements_f),
    holdings.total_value_myr AS SUM(holdings.value_f) WITH SYNONYMS = ('settled value', 'value in MYR'),
    holdings.recon_compliance_pct AS 100 * SUM(holdings.recon_done_f) / NULLIF(SUM(holdings.recon_due_f), 0)
      COMMENT = 'Position reconciliations completed / reconciliations due',
    risk.avg_escalation_prob AS AVG(risk.escalation_prob_f),
    reasons.reason_break AS SUM(reasons.reason_break_f),
    reasons.reason_escalated AS SUM(reasons.reason_escalated_f),
    reasons.reason_breaches AS SUM(reasons.reason_breaches_f),
    reasons.reason_escalation_rate_pct AS 100 * SUM(reasons.reason_escalated_f) / NULLIF(SUM(reasons.reason_break_f), 0),
    daily.daily_break AS SUM(daily.day_break_f),
    daily.daily_escalated AS SUM(daily.day_escalated_f),
    daily.daily_value_myr AS SUM(daily.day_value_f)
  )
  COMMENT = 'Synthetic Malaysia sukuk portfolio operations analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.SUKUK_AGENT
  COMMENT = 'Sukuk operations assistant over a synthetic investor sukuk portfolio'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give holding IDs and numbers with units (MYR, %). Do not give Shariah rulings, regulatory or investment advice, or price predictions."
  orchestration: "Use sukuk_analyst for settlement instructions, settlement breaks, escalations, resolution SLA breaches, settlement match rate, position reconciliation compliance, holdings, custodians, sukuk types, break reasons and escalation risk. Use sop_search for break-handling procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: sukuk_analyst
      description: "Settlement instructions processed, settled value in MYR, settlement breaks, escalations to custodian investigation, resolution SLA breaches, settlement match rate, position reconciliation compliance, break reasons and escalation risk scores by holding, custodian and sukuk type"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic break-handling SOPs by sukuk type and break reason"
tool_resources:
  sukuk_analyst:
    semantic_view: __DEMO_DB__.APP.SUKUK_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.BREAK_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-break alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), HOLDING_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, AMOUNT_MYR FLOAT, HOURS_UNMATCHED FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION MY_ISLAMIC_FINANCE_SUKUK_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (HOLDING_ID, EVENT_TS, AMOUNT_MYR, HOURS_UNMATCHED, SOP_HINT)
    SELECT p.HOLDING_ID, p.EVENT_TS, p.AMOUNT_MYR, p.HOURS_UNMATCHED,
           'Check ' || r.CATEGORY || ' break SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_SETTLEMENTS p
    JOIN RAW.HOLDINGS r ON r.ID = p.HOLDING_ID
    LEFT JOIN ML.ESCALATION_RISK_SCORES s ON s.ENTITY_ID = p.HOLDING_ID
    WHERE p.STATUS = 'BREAK'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.HOLDING_ID = p.HOLDING_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('MY_ISLAMIC_FINANCE_SUKUK_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Settlement break alert',
      'New settlement breaks logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_BREAK_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_SETTLEMENTS p
    WHERE p.STATUS = 'BREAK'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.HOLDING_ID = p.HOLDING_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();
-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.BREAK_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.ESCALATION_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.ESCALATION_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.ESCALATION_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'YEARS_HELD', YEARS_HELD,
             'AUTOMATCH_FAIL_PCT', AUTOMATCH_FAIL_PCT, 'AVG_BREAK_AGE_HOURS', AVG_BREAK_AGE_HOURS,
             'AUTOMATCH_FAIL_7D', AUTOMATCH_FAIL_7D, 'ESCALATED_30D', ESCALATED_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:ESCALATED::FLOAT, 4) AS ESCALATION_PROB_7D,
         CASE WHEN PRED:probability:ESCALATED::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:ESCALATED::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
