# Sukuk Portfolio Analytics

**Malaysia - Islamic Finance**
Use case: Sukuk Portfolio Management

> Real-time Sukuk portfolio management for Malaysia's world-leading Islamic capital market — Dynamic Tables build portfolio views, Iceberg enables cross-institution analysis, and Cortex Analyst answers portfolio questions.

## Why Snowflake

Snowflake delivers real-time Sukuk portfolio intelligence — Dynamic Tables aggregate 500 holdings, ML.FORECAST projects yield curves, Iceberg shares data cross-institution, and Cortex Analyst answers portfolio questions in natural language

- **ML.FORECAST on Sukuk yield curves** - Only demo forecasting Islamic bond yields by structure type (Ijara, Murabahah, Wakala, Musharakah)
- **Iceberg for cross-institution portfolio sharing** - Only demo using open table format for Islamic fund collaboration without data movement
- **Dynamic Tables for real-time portfolio valuation** - Rebuilds portfolio views from 50,000 market data points every 2 hours
- **Cortex Analyst for portfolio natural language** - CIO asks portfolio questions in natural language — no SQL required
- **Malaysian Sukuk market context** - World's largest Sukuk market (51% share) with authentic Malaysian Islamic finance terminology

## What is deployed

| | |
|---|---|
| Database | `MY_ISLAMIC_FINANCE_SUKUK` |
| Service | `MY_ISLAMIC_FINANCE_SUKUK_APP` |
| Compute pool | `SEA_DEMOS_MALAYSIA_POOL` |
| Dimension table | `RAW.PORTFOLIO_DOCS` (20 rows) |
| Fact table | `RAW.MARKET_DATA` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | MYR (RM) |

Regions in play: Selangor, Johor, Penang, Sabah, Sarawak
Segments: Government Investment Issue, Corporate Sukuk, SRI Sukuk, Quasi-Sovereign

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh MY_ISLAMIC_FINANCE_SUKUK
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Outstanding Sukuk | `RM 1.2T` | total across Portfolio Docs |
| New Issuance (YTD) | `RM 184B` | total across Portfolio Docs |
| Avg Yield | `3.8%` | average per event |
| Active Issuers | `84` | total across Portfolio Docs |
| Foreign Holdings | `24%` | average per event |
| Avg Tenor | `5.4 yrs` | average per event |
| Spread vs MGS | `+42 bps` | average per event |


## Demo flow

1. Portfolio Overview
2. Yield Analytics
3. Risk Management
4. Ask AI
5. Architecture & Data

## Talking points

- **RM 2.3B** - Sukuk portfolio AUM across 4 structures
- **500 holdings** - across Ijara, Murabahah, Wakala, and Musharakah
- **12.3%** - weighted average yield (180bps above benchmark)
- **3 issuers** - on watchlist following credit rating review
- **50,000 data points** - market data refreshed every 2 hours

## Business impact

- Malaysia held 51% of global Sukuk outstanding (US$539B) in 2023 (Securities Commission Malaysia)
- Malaysia's Islamic fund management industry grew 12.8% YoY to RM 250B AUM (MIFC)
- Real-time portfolio analytics reduces risk reporting latency from days to minutes (McKinsey Asset Management)
- Open data formats (Iceberg) reduce cross-institution data sharing costs by 60-80% (Snowflake)

---
Generated from `generator/demo_specs/aws-malaysia-islamic-finance-sukuk.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-malaysia-islamic-finance-sukuk` instead.
