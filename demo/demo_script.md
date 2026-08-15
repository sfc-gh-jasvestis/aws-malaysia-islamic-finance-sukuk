# Demo Script: Sukuk Portfolio Analytics
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake delivers real-time Sukuk portfolio intelligence — Dynamic Tables aggregate 500 holdings, ML.FORECAST projects yield curves, Iceberg shares data cross-institution, and Cortex Analyst answers portfolio questions in natural language"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Tan Sri Ahmad Zulkifli** | CIO Islamic Fund | React App (SPCS) | Portfolio performance, yield optimization, counterparty risk, Shariah-compliant asset allocation |
| **Amir bin Razak** | Portfolio Manager | Amazon QuickSight | Daily valuations, maturity profiles, liquidity risk, market data feeds, trade execution |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 5 tables | SUKUK_HOLDINGS (500), VALUATIONS (10000), COUNTERPARTIES (200), MARKET_DATA (50000), PORTFOLIO_DOCS (40) |
| **CURATED** | 4 Dynamic Tables | PORTFOLIO_SUMMARY, YIELD_CURVES, COUNTERPARTY_RISK, MATURITY_LADDER |
| **ML** | ML.FORECAST | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_EXTRACT, SUMMARIZE | Classification + extraction |
| **Search** | Cortex Search | 40 documents indexed |
| **Agent** | SUKUK_PORTFOLIO_AGENT | Semantic View + Search tools |


---

## The Story

Malaysia dominates the global Sukuk market with 51% market share. A leading Islamic fund manages RM 2.3 billion across 500 holdings in 4 Shariah-compliant structures. With yields projected to compress and 3 counterparties on the watchlist, the CIO needs real-time portfolio intelligence — but siloed systems across custodians mean the full risk picture takes days to assemble manually.

---

## Script

### [0:00–0:45] PORTFOLIO OVERVIEW

**Show**: Portfolio Overview tab

> "RM 2.3 billion Sukuk portfolio across 500 holdings in 4 Shariah-compliant structures."

**Action**: Point at RM 2.3B AUM KPI

### [0:45–1:30] YIELD ANALYTICS

**Show**: Yield Analytics tab

> "Dynamic Tables rebuild yield curves every 2 hours from 50,000 market data points."

**Action**: Show yield curve by structure type

### [1:30–2:15] RISK MANAGEMENT

**Show**: Risk Management tab

> "Three counterparties on watchlist: combined exposure RM 340M (14.8% of portfolio)."

**Action**: Show counterparty exposure heatmap

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Tan Sri Ahmad asks: 'What is our total exposure to BBB-rated issuers?'"

**Action**: Type portfolio question

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Six Snowflake capabilities, five AWS services in the dual-build architecture."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.FORECAST on Sukuk yield curves** — Only demo forecasting Islamic bond yields by structure type (Ijara, Murabahah, Wakala, Musharakah)
2. **Iceberg for cross-institution portfolio sharing** — Only demo using open table format for Islamic fund collaboration without data movement
3. **Dynamic Tables for real-time portfolio valuation** — Rebuilds portfolio views from 50,000 market data points every 2 hours
4. **Cortex Analyst for portfolio natural language** — CIO asks portfolio questions in natural language — no SQL required
5. **Malaysian Sukuk market context** — World's largest Sukuk market (51% share) with authentic Malaysian Islamic finance terminology


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SUKUK_PORTFOLIO.RAW.SUKUK_HOLDINGS` → 500
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SUKUK_PORTFOLIO.RAW.VALUATIONS` → 10000
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SUKUK_PORTFOLIO.RAW.MARKET_DATA` → 50000
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SUKUK_PORTFOLIO.CURATED.COUNTERPARTY_RISK WHERE ON_WATCHLIST = TRUE` → >=3

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SUKUK_PORTFOLIO.ML.YIELD_CURVE_FORECAST_RESULTS` → >0

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SUKUK_PORTFOLIO.AI.DOC_EXTRACT_RESULTS` → 40

