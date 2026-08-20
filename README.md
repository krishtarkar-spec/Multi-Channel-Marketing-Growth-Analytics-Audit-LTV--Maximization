# 📊 Multi-Channel Growth Marketing Audit & LTV Maximization Engine
### End-to-End Financial Diagnostics Across 1.28 Million Records

---

> Retail margin erosion is rarely visible until it's too late. This system quantifies $24.3M in refund leakage — 74% of it concentrated in a single price tier of a single category — maps 36-month customer decay, and models a prescriptive path to $6.1M in profit recovery.

---

## 📌 Project Overview

This project delivers an end-to-end financial and operational audit of a **100,000-user retail ecosystem**. A custom data engine was developed in Python to simulate an enterprise-scale environment with **1.28 million records**, then **Advanced SQL** was used to diagnose margin erosion, track customer retention, and identify high-impact growth opportunities across five digital marketing channels and fifty individual campaigns.

Every dollar figure in this README is computed from the generated dataset. Revenue, leakage, and margin totals are reconciled across independently written queries at different grains — the campaign, segment, and category workstreams all resolve to the same $164,450,947.25 net revenue.

---

## 🛠️ Technical Architecture

The three layers below form a full analytics lifecycle: simulation generates the data environment, SQL workstreams extract the intelligence, and Power BI surfaces the decisions.

```
┌─────────────────────────────────────────────────────────────┐
│  [1] Data Simulation  →  [2] SQL Analytical Workstreams     │
│                                       ↓                     │
│              [3] Power BI Executive Dashboard               │
└─────────────────────────────────────────────────────────────┘
```

**1. Data Engineering — The Simulation**
Built a high-performance Python script generating a synchronized **3-table relational schema** with built-in *"dirty data"* (currency formatting anomalies) to simulate real-world ETL challenges. The generator models category-level price and refund profiles, per-campaign and per-region performance differences, Q4 seasonality, and exponential post-signup decay.
`Core Script: Synthetic Data.py`

- `dim_users` — 100,000 records with UTM attribution, **campaign-level attribution keys**, regional data, and device types
- `fact_transactions` — 965,266 records with intentional data quality issues
- `fact_marketing_spend` — 219,200 records of daily campaign × region spend across 5 channels and 50 campaigns

The `campaign_id` key on `dim_users` is what makes true CAC and LTV:CAC computable — spend can be tied to the specific users it acquired, not just to a channel.

**2. SQL Analytical Workstreams**
Six purpose-built SQL workstreams diagnose every layer of the business — from campaign-level ROI down to individual product refund triggers.
`SQL Scripts: Workstreams A–E + Cohort Decay`

**3. Strategic Visualization (Power BI)** *(in progress)*
An executive dashboard built on a **curated reporting layer**: transformation and aggregation logic is pushed down into SQL, and the Power BI model consumes purpose-built mart tables (`mart_campaign_monthly`, `mart_category_pricetier`, segment, cross-sell, and cohort outputs) alongside three conformed dimensions (`dim_region`, `dim_campaign`, `dim_year`) that drive cross-page slicers. DAX is reserved for ratio recomputation and time intelligence rather than transformation.

This is a deliberate architectural choice. Aggregating in SQL keeps a single, version-controlled definition of every metric and makes each figure reconcilable against the source query. The trade-off is that the analytical grain of each mart is fixed at design time rather than explorable at query time.

---

## 📊 Key Results & Impact

| Metric | Result |
|---|---|
| Net Revenue Analyzed | $164.45M across 50 campaigns, 4 regions, and 36 months |
| Refund Leakage Identified | **$24.27M** — 12.86% of gross revenue |
| Leakage Concentration | **76%** of all leakage originates in Electronics alone |
| Single Highest-Impact Cell | Electronics Premium (>$200) — 157,045 orders at a 17.08% refund rate, producing **$17.94M (74% of total leakage) from 16% of orders** |
| Profit Recovery Modeled | **$6.07M** under a 25% prescriptive leakage-reduction scenario |
| Retention Mapped | 36-month cohort decay across 100,000 customers |
| Critical Churn Point | **25% drop-off at Month 1**, decaying to 28% retention by Month 9 |

---

## 🔗 SQL Analytical Workstreams — Deep Dive

Six workstreams form the analytical core of this project, each targeting a distinct business question:

- **Workstream A — Master Query** — Aggregates spend and revenue to a common **campaign × region × month** grain (7,200 rows), calculating contribution profit, ROAS, CAC, and gross margin. Spend is pre-aggregated before joining to avoid fan-out.
- **Workstream B — Strategic Segmentation** — Classifies users into Platinum Whales, Steady Growers, and Margin Drainers using `NTILE(10)` deciles on **margin-based LTV**, at region × fiscal year × segment grain
- **Workstream C — Recovery Simulation** — A prescriptive model calculating the financial impact of a 25% refund-rate reduction
- **Workstream D — Cross-Sell Engine** — A transition matrix identifying 1st-to-2nd purchase paths using sequence-based self-joins
- **Workstream E — Refund Triggers** — A diagnostic audit isolating refund volume and price sensitivity by category × price tier
- **Cohort Decay Analysis** — A 36-month retention heatmap built on a generated calendar spine, so months with zero returning customers render as true zeros rather than missing rows, and each cohort is observed only over its available window

This turns a flat transaction log into a ranked set of financial interventions — pricing, retention, and spend reallocation decisions that can be actioned independently.

---

## 💡 Strategic Insights Summary

**Price drives refunds, independent of category.** The refund rate rises monotonically with price tier inside *every* one of the five categories — roughly 2.5× from Budget to Premium in each:

| Category | Budget (<$50) | Mid-Range ($50–200) | Premium (>$200) |
|---|---|---|---|
| Beauty | 2.07% | 3.27% | 5.76% |
| Sports | 3.13% | 4.68% | 7.88% |
| Home & Kitchen | 3.81% | 5.98% | 9.58% |
| Fashion | 6.09% | 9.12% | 15.19% |
| Electronics | 7.57% | 10.47% | 17.08% |

Because the gradient holds *within* categories, this is a genuine price effect rather than a composition artifact of Electronics simply being expensive. Two separable effects — category and price — both measurable.

**The intervention is narrow, not company-wide.** A 25% reduction scoped to Electronics Premium alone captures ~$4.48M of the $6.07M total opportunity. That is a single operational policy change — tightened return terms or improved pre-purchase specification detail on premium electronics — rather than a portfolio-wide overhaul.

**Revenue-ranked LTV points at the wrong cohort.** Platinum Whales run ~29% gross margin against ~37% for Low-Value and Dormant segments. The highest-revenue tier is the *least* margin-efficient, because whales concentrate in high-ASP Electronics, which carries the highest refund rate. Segmenting on revenue rather than margin systematically over-rewards the least profitable customers.

**No cross-sell affinity exists — a negative result.** Repeat-category purchasing runs ~4.6× baseline (diagonal ~9,000 per cell vs ~1,950 off-diagonal), but conditional on switching categories, the next category chosen is statistically indistinguishable from random: all 20 off-diagonal cells fall within a 7% band. There is no basis for an affinity-driven recommendation engine here. The leverage is in **within-category retention**, not cross-sell.

**Cohort decay is confounded by seasonality.** Q4 demand spikes surface as apparent retention "recoveries" — the January 2023 cohort decays cleanly from 100% to 28% by Month 9, then rebounds to 62% at Month 10 and 58% at Month 11 (November and December), before collapsing to 17% at Month 12. The same bump repeats at Months 22–23. Because the spike lands at a different month offset for every cohort, raw cohort curves are **not comparable across cohorts** without seasonal adjustment or matched-calendar-month comparison.

---

## ⚠️ Analytical Caveats

Stated explicitly, because they affect how the numbers should be read:

- **The 25% recovery rate is an assumed scenario input, not a measured result.** Nothing in the data establishes that a policy change would reduce refunds by 25%. The $6.07M is a sensitivity output. A predictive refund-risk model (planned) would replace this assumption with a measurement.
- **This is synthetic data.** The behavioral relationships surfaced above were modeled into the generator deliberately; the analysis correctly detects and quantifies them. They are findings about this dataset, not discoveries about real consumers.
- **`active_customers` is non-additive across time periods.** Summing pre-aggregated rows double-counts returning customers — Power BI measures must use `DISTINCTCOUNT`, and all ratio columns must be recomputed via `DIVIDE(SUM(), SUM())` rather than averaged.
- **4,554 signups never transacted** and are excluded from revenue-based segmentation (95,446 purchasing users of 100,000 total).
- **Value tiers are assigned globally, not per region.** `NTILE(10)` ranks all customers on absolute margin LTV, so lower-ASP regions surface proportionally fewer Platinum Whales. This is intentional — a whale is defined in absolute contribution terms — but it means tier counts are not comparable across regions.
- **Category and price effects are separable but correlated.** Electronics carries the highest refund rate at every price tier *and* is overwhelmingly a premium-priced category, so its blended rate reflects both effects. The within-category gradient above isolates the price effect from the composition effect.

---

## 🚀 How to Run

**Prerequisites:** Python 3.9+, PostgreSQL, Power BI Desktop

**Step 1: Environment Setup**
```bash
git clone <your-repo-url>
cd marketing-analytics-audit
pip install pandas numpy
```

**Step 2: Generate the Data Environment**
```bash
# Generate the full 1.28M row relational dataset
python "Synthetic Data.py"
```

**Step 3: Database & Visualization**
```bash
# Execute schema and import scripts in your PostgreSQL instance
psql -U <user> -d <database> -f schema.sql

# Run workstreams in sequence
psql -U <user> -d <database> -f Workstream_A_Master.sql
psql -U <user> -d <database> -f Workstream_B_Segmentation.sql
psql -U <user> -d <database> -f Workstream_C_Recovery.sql
psql -U <user> -d <database> -f Workstream_D_CrossSell.sql
psql -U <user> -d <database> -f Workstream_E_Refunds.sql
psql -U <user> -d <database> -f Aggregated_Cohort_Decay.sql
```

> **Note on large queries:** the master query spills to temp storage. Set `temp_tablespaces`, raise `work_mem`, and disable parallel gather in the *same session* as the query to avoid `53100` disk errors.

---

## 📂 Repository Structure

```
├── Synthetic Data.py              # Data simulation engine (1.28M records, 3-table schema)
├── Workstream_A_Master.sql        # Campaign × region × month P&L (7,200 rows)
├── Workstream_B_Segmentation.sql  # Platinum Whales / Steady Growers / Margin Drainers
├── Workstream_C_Recovery.sql      # $6.07M prescriptive profit recovery model
├── Workstream_D_CrossSell.sql     # Sequence-based cross-sell transition matrix
├── Workstream_E_Refunds.sql       # Refund trigger audit by category × price tier
├── Aggregated_Cohort_Decay.sql    # 36-month retention heatmap (FIRST_VALUE window fn)
├── Marts/                         # CREATE TABLE scripts for the Power BI reporting layer
├── Datasets/                      # Generated CSVs (dim_users, fact_transactions, spend)
└── Dashboard/                     # Power BI executive dashboard
```

---

## 🧰 Tech Stack

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)
![NumPy](https://img.shields.io/badge/NumPy-013243?style=for-the-badge&logo=numpy&logoColor=white)
