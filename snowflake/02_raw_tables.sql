-- Synthetic holding-day observations for a fictional investor's sukuk holding.
-- A holding is one sukuk series held by the investor and serviced by one
-- fictional custodian. Each day the back office processes settlement and
-- periodic-distribution instructions for the holding; a settlement break is an
-- instruction that does not match on the first pass.
-- Nothing is seeded as a prediction. Randomness is HASH-seeded, so every rebuild
-- is reproducible: per-holding break propensity, drift between position
-- reconciliations, missed reconciliations, type-weighted break reasons, breaks
-- cleared without escalation, and two custodian-wide system outages.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.HOLDINGS AS
WITH holdings AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS HOLDING_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT HOLDING_INDEX,
         MOD(ABS(HASH(HOLDING_INDEX, 'age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(HOLDING_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(HOLDING_INDEX, 'recon')), 1000000) / 1e6 AS U_RECON,
         MOD(ABS(HASH(HOLDING_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(HOLDING_INDEX, 'tier')), 1000000) / 1e6 AS U_TIER
  FROM holdings
)
SELECT 'MYS-' || LPAD(HOLDING_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic sukuk holding ' || LPAD(HOLDING_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (5 and 8 are coprime): every custodian and sukuk
       -- type is present. Custodians are fictional; all holdings are in MYR.
       CASE MOD(HOLDING_INDEX, 5) WHEN 0 THEN 'Custodian Kuala Lumpur' WHEN 1 THEN 'Custodian George Town'
            WHEN 2 THEN 'Custodian Johor Bahru' WHEN 3 THEN 'Custodian Kota Kinabalu' ELSE 'Custodian Kuching' END AS CUSTODIAN,
       CASE MOD(HOLDING_INDEX, 8) WHEN 0 THEN 'Sovereign murabahah' WHEN 1 THEN 'Sovereign murabahah'
            WHEN 2 THEN 'Sovereign murabahah' WHEN 3 THEN 'Sovereign wakalah'
            WHEN 4 THEN 'Sovereign wakalah' WHEN 5 THEN 'Retail sukuk wakalah'
            WHEN 6 THEN 'Corporate ijarah' ELSE 'Corporate musharakah' END AS CATEGORY,
       HOLDING_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.2 + U_AGE * 5.8, 1) AS YEARS_HELD,
       -- Base daily probability of an escalated settlement break 0.4%-3%; ~15%
       -- of holdings are chronically difficult to settle (x3).
       (0.004 + U_RATE * 0.026) * IFF(U_RATE > 0.85, 3, 1) AS BASE_ESCALATION_RATE,
       7 * (1 + FLOOR(U_RECON * 3)) AS RECON_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS RECON_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.HOLDING_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), custodian_events AS (
  -- Two custodian-wide system outages; every holding at that custodian raises
  -- a break that clears once the custodian's system recovers.
  SELECT * FROM VALUES (27, 'Custodian Kuala Lumpur'), (64, 'Custodian Kota Kinabalu') AS o(DAY_INDEX, CUSTODIAN)
), base AS (
  SELECT r.ID AS ENTITY_ID, r.HOLDING_INDEX, r.CATEGORY, r.CUSTODIAN, r.YEARS_HELD,
         r.BASE_ESCALATION_RATE, r.RECON_INTERVAL_DAYS, r.RECON_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + r.HOLDING_INDEX * 5, r.RECON_INTERVAL_DAYS) AS DAYS_SINCE_RECON,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'fail')), 1000000) / 1e6 AS U_FAIL,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'clear')), 1000000) / 1e6 AS U_CLEAR,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'type')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'sla')), 1000000) / 1e6 AS U_SLA,
         e.CUSTODIAN IS NOT NULL AS CUSTODIAN_EVENT
  FROM RAW.HOLDINGS r CROSS JOIN days d
  LEFT JOIN custodian_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.CUSTODIAN = r.CUSTODIAN
), recon AS (
  SELECT *,
         IFF(DAYS_SINCE_RECON = 0, 1, 0) AS RECON_DUE,
         IFF(DAYS_SINCE_RECON = 0 AND U_DONE < RECON_COMPLETION_PROB, 1, 0) AS RECON_COMPLETED,
         -- Position drift builds up between reconciliations with the custodian;
         -- weak reconciliation discipline carries it over.
         DAYS_SINCE_RECON / RECON_INTERVAL_DAYS + (1 - RECON_COMPLETION_PROB) AS DRIFT
  FROM base
), stress AS (
  SELECT *,
         CASE WHEN U_FAIL < LEAST(0.5, BASE_ESCALATION_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + YEARS_HELD))) / 4 THEN 2
              WHEN U_FAIL < LEAST(0.5, BASE_ESCALATION_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + YEARS_HELD))) THEN 1
              ELSE 0 END AS STRESS_COUNT
  FROM recon
), cases AS (
  SELECT *,
         -- About 85% of stressed instructions break and are escalated to a
         -- custodian investigation; the rest settle on a later pass.
         IFF(CUSTODIAN_EVENT, 0, IFF(U_DETECT < 0.85, STRESS_COUNT, 0)) AS ESCALATED_COUNT,
         -- Breaks cleared by the back office without escalation.
         IFF(CUSTODIAN_EVENT, 1, IFF(U_CLEAR < CASE CATEGORY WHEN 'Retail sukuk wakalah' THEN 0.20
                                                 WHEN 'Corporate ijarah' THEN 0.12
                                                 WHEN 'Corporate musharakah' THEN 0.14 ELSE 0.08 END, 1, 0)) AS RESOLVED_COUNT
  FROM stress
), measured AS (
  SELECT *,
         ESCALATED_COUNT + RESOLVED_COUNT AS BREAK_COUNT,
         ROUND(CASE CATEGORY WHEN 'Sovereign murabahah' THEN 40 WHEN 'Sovereign wakalah' THEN 25
                             WHEN 'Retail sukuk wakalah' THEN 90 WHEN 'Corporate ijarah' THEN 15 ELSE 8 END
               * (0.7 + 0.6 * U_VOLUME) * (1 + 0.8 * STRESS_COUNT)) AS SETTLEMENT_COUNT,
         CASE CATEGORY WHEN 'Sovereign murabahah' THEN 5000000 WHEN 'Sovereign wakalah' THEN 3000000
                       WHEN 'Retail sukuk wakalah' THEN 50000 WHEN 'Corporate ijarah' THEN 2000000
                       ELSE 1500000 END
           * (0.8 + 0.4 * U_NOISE) AS AVG_SETTLEMENT_MYR
  FROM cases
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       SETTLEMENT_COUNT,
       ROUND(SETTLEMENT_COUNT * AVG_SETTLEMENT_MYR, 0) AS VALUE_MYR,
       BREAK_COUNT, ESCALATED_COUNT,
       IFF(ESCALATED_COUNT > 0 AND U_SLA < 0.6, 1, 0) AS SLA_BREACHED,
       CASE WHEN BREAK_COUNT = 0 THEN 'None'
            WHEN CUSTODIAN_EVENT THEN 'Custodian system outage'
            WHEN CATEGORY = 'Sovereign murabahah' THEN IFF(U_TYPE < 0.5, 'Price or yield mismatch', IFF(U_TYPE < 0.8, 'Late counterparty confirmation', 'Settlement instruction mismatch'))
            WHEN CATEGORY = 'Sovereign wakalah' THEN IFF(U_TYPE < 0.45, 'Late counterparty confirmation', IFF(U_TYPE < 0.8, 'Price or yield mismatch', 'Quantity mismatch'))
            WHEN CATEGORY = 'Retail sukuk wakalah' THEN IFF(U_TYPE < 0.55, 'Distribution amount mismatch', 'Holder record mismatch')
            WHEN CATEGORY = 'Corporate ijarah' THEN IFF(U_TYPE < 0.45, 'Distribution amount mismatch', IFF(U_TYPE < 0.8, 'Late counterparty confirmation', 'Quantity mismatch'))
            ELSE IFF(U_TYPE < 0.5, 'Profit-share calculation query', IFF(U_TYPE < 0.75, 'Late counterparty confirmation', 'Settlement instruction mismatch')) END AS BREAK_REASON,
       RECON_DUE, RECON_COMPLETED,
       ROUND(0.5 + 2.0 * DRIFT + 3.0 * STRESS_COUNT + U_NOISE * 0.8, 2) AS AUTOMATCH_FAIL_PCT,
       ROUND(18 + 12 * DRIFT + 14 * STRESS_COUNT + U_NOISE * 6, 1) AS AVG_BREAK_AGE_HOURS,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Holding file document coverage per holding (snapshot).
CREATE TABLE RAW.HOLDING_DOCUMENTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Sovereign murabahah' THEN 'Series terms summary'
                     WHEN 'Sovereign wakalah' THEN 'Series terms summary'
                     WHEN 'Retail sukuk wakalah' THEN 'Sub-account holder register'
                     WHEN 'Corporate ijarah' THEN 'Issuer information memorandum'
                     ELSE 'Profit-share calculation statement' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'file')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'file')), 5) < 1 + MOD(ABS(HASH(ID, 'req')), 4),
           MOD(ABS(HASH(ID, 'pending')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.HOLDINGS;
