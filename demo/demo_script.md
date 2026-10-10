# Sukuk Portfolio Settlement Operations

**Malaysia - Sukuk Portfolio Operations**
Use case: Settlement breaks, escalation to custodian investigation and back-office controls

> Settlement monitoring for 40 sukuk holdings in a fictional Malaysian investor's portfolio, serviced by 5 fictional custodians: dynamic tables, a holdout-evaluated escalation classifier, a break-volume forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile instructions processed, settlement breaks, escalations, resolution SLA breaches and position reconciliation compliance from RAW holding data, with checks in `run_core.py`
- **Escalation classification** gives a holdout-evaluated next-7-day probability per holding
- **Break forecast** projects 14 days of portfolio-wide break volume with prediction intervals, for back-office staffing
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live settlements**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.HOLDINGS` (40 rows) |
| Fact table | `RAW.HOLDING_DAILY` (3,600 holding-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `BREAK_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.ESCALATION_RISK_SCORES`, `ML.ESCALATION_RISK_HOLDOUT_METRICS`, `ML.BREAK_FORECAST`, `ML.AUTOMATCH_FAIL_ANOMALIES` |

Custodians (fictional, one per Malaysian city): Custodian Kuala Lumpur, Custodian George Town, Custodian Johor Bahru, Custodian Kota Kinabalu, Custodian Kuching (MYR).
Sukuk types: Sovereign murabahah, Sovereign wakalah, Retail sukuk wakalah, Corporate ijarah, Corporate musharakah.

Type notes, for the presenter: murabahah is a cost-plus sale structure; ijarah is a lease-based structure; wakalah is an agency-based structure; musharakah is a profit-sharing structure, so its periodic distribution depends on reported results. The demo describes settlement operations only; it makes no Shariah or regulatory rulings, gives no investment advice and predicts no prices. No real issuer or series is modelled.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Settlement Match Rate | 99.57% |
| Settlement Breaks | 572 |
| Escalated to Custodian Investigation | 177 |
| Escalation Rate | 30.9% |
| Resolution SLA Breaches | 93 |
| Settled Value (MYR B) | 370.16 |
| Instructions Processed | 133,804 |
| Position Reconciliation Compliance | 79.6% |
| Holdings Monitored | 40 |
| Holding File Coverage | 57.6% |
| Holding Documents Pending | 22 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily settlement breaks against escalations, breaks and escalations by reason, holding table
2. Predictive: holdout metrics, risk bands, 14-day break forecast, auto-match failure rate anomalies
3. Controls: position reconciliation compliance, holding file coverage and pending documents, reconciliation compliance against escalated breaks, then generate the action memo
4. Live Settlements: run `CALL APP.SIMULATE_SETTLEMENTS(20)` (Snowflake only) or `python aws/publish_settlements.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_BREAK_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 99.57% of instructions match on the first pass; the 572 settlement breaks are where back-office time goes, and 30.9% of them are escalated to custodian investigation.
- Late counterparty confirmation produces the most escalations (51 of 144 breaks). Custodian system outages hit every holding at one custodian at once and always clear without escalation.
- The risk model is evaluated on a time-based holdout: precision 48.0% and recall 27.7% at 0.5, against a 21.7% base rate. Present it as operations triage, not a verdict, and not a view on the sukuk itself.
- Custodian system outages are excluded from model training, because they are not holding-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
