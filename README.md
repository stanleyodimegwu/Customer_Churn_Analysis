# Telco Customer Churn Analysis (Google BigQuery / SQL)

End-to-end churn analysis on the IBM Telco Customer Churn dataset (7,043 customers), built entirely in Google BigQuery SQL — from raw data audit through cleaning, staging, and business-focused analysis.

## Why this project

The goal of the project was not just to demonstate technical skills but to solve business problems. Churn is one of the highest-leverage problems a subscription business can solve: a small drop in churn compounds into significant revenue gains. I treated this dataset the way it would actually show up at a real company(messy) and walked it through a steo by step cleansing process before performing any analysis and drawing any conclusions from it.

## Tech stack

- **Google BigQuery** — cloud data warehouse, all SQL run natively (no local tooling)
- **SQL** — CTEs, window functions, subqueries, CASE-based segmentation
- **Power BI** — dashboard layer, connected directly to BigQuery
- **Dataset**: [IBM Telco Customer Churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) (extended version, 7,043 rows)

## Repo structure

```
├── 01_data_cleaning.sql        -- Audit raw table, validate, build clean staging table
├── 02_analysis_queries.sql     -- 9 business questions across 4 sections
├── 03_dashboard.pbix           -- Power BI dashboard displaying insights
├── screenshots/
│   ├── page1_executive_overview.jpg
│   └── page2_customer_revenue_analysis.jpg
└── README.md
```

**Project path:** `customer-churn-analysis-499807.customer_churn`
**Raw table:** `telco_churn` → **Clean table:** `stg_telco_clean`

## 01_data_cleaning.sql

Before drawing any conclusions, the raw table is audited and validated in nine steps:

1. Initial inspection
2. Row count check (expected 7,043)
3. Duplicate check on `CustomerID`
4. Full null audit across every retained column
5. Whitespace audit on every text column
6. Data type / range validation (negative charges, out-of-range churn scores, bad casts)
7. Category inspection on every categorical and binary flag column
8. Build `stg_telco_clean` via `CREATE OR REPLACE TABLE`
9. Post-clean validation: row count parity, uniqueness, no stray casing, no unexpected nulls

Key transformations: lowercased/trimmed all text categories, cast `BOOL` fields (`Phone Service`, `Churn Label`) to readable `yes`/`no` strings, replaced blank `Total Charges` with `0.0` for zero-tenure customers, and defaulted missing `Churn Reason` to `'not churned'`.

## 02_analysis_queries.sql

Ten queries across four sections, each with a written insight:

**Section 1 — Total Summary**
- Overall churn rate, revenue at risk
- Churn rate by contract type

**Section 2 — Customer Analysis**
- Churn rate by tenure cohort
- Churn rate by internet service
- Churn rate by payment method

**Section 3 — Revenue Impact**
- Monthly revenue at risk by contract × internet service segment (CTE + `RANK()`)
- High-value at-risk customers: not yet churned, high churn score, above-average CLTV (dynamic subquery benchmark)

**Section 4 — Deeper Analysis**
- Cumulative churn rate by tenure month (CTE + `SUM() OVER()` running total)
- Churn reason comparison (CTE + `LAG()` to compare each reason against the next)

**SQL techniques demonstrated:** CTEs, window functions (`RANK()`, `SUM() OVER()`, `LAG()`), `CASE WHEN` segmentation and cohorting, dynamic subquery benchmarks, defensive `ELSE 0` handling in aggregates.

## Key findings

- **26.54% overall churn rate** — roughly 1 in 4 customers leave
- **Month-to-month contracts churn at 42.71%** vs. 11.27% for annual contracts
- **52.9% of churn happens in the first 6 months** — the highest-leverage retention window
- **Fiber optic customers churn at 41.89%**, disproportionately hurting revenue given their higher monthly charges
- **Electronic check users churn at ~45%**, well above baseline — a case for pushing autopay adoption
- **Approximately $100K in monthly revenue at risk** concentrated in month-to-month, fiber-optic customers
- Competitor-driven churn is the leading stated reason, ahead of product dissatisfaction

## Dashboard

A Power BI dashboard (`03_dashboard.pbix`) sits on top of `stg_telco_clean` (connected directly to BigQuery) to make the churn story accessible at a glance for non-technical stakeholders. It covers:

- Overall churn rate, revenue at risk, and headline KPIs
- Churn by contract, internet service, and payment method
- Tenure cohort breakdown (early-tenure churn window)
- Revenue-at-risk by segment, drillable by contract × internet service

**[\[https://app.powerbi.com/groups/me/reports/de930586-c2d1-40c6-b46e-e6aee0ee2926/ce3c0400b59f4de762e3?experience=power-bi ]\]**

## Next steps

- README-linked walkthrough video
- Additional portfolio project(s) building on this workflow

---
**Analyst:** Stanley Odimegwu
