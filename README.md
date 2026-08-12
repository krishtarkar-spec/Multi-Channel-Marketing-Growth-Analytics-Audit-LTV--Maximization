# 📊 Multi-Channel Growth Marketing Audit & LTV Maximization Engine
### End-to-End Financial Diagnostics Across 1.1 Million Records

---

> Retail margin erosion is rarely visible until it's too late. This system surfaces $19.2M in hidden refund leakage, maps 24-month customer decay patterns, and prescribes a data-driven path to $4.8M in annual profit recovery.

---

## 📌 Project Overview

This project delivers an end-to-end financial and operational audit of a **100,000-user retail ecosystem**. A custom data engine was developed in Python to simulate an enterprise-scale environment with **1.1 million records**, then **Advanced SQL** was used to diagnose margin erosion, track customer retention, and identify high-impact growth opportunities across five digital marketing channels.

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
Built a high-performance Python script generating a synchronized **3-table relational schema** with built-in *"dirty data"* (currency formatting anomalies) to simulate real-world ETL challenges.
`Core Script: Synthetic Data.py`

- `dim_users` — 100,000 records with UTM attribution, regional data, and device types
- `fact_transactions` — 1,000,000 records with intentional data quality issues
- `fact_marketing_spend` — 54,800 records of daily campaign-level spend across 5 digital channels

**2. SQL Analytical Workstreams**
Five purpose-built SQL workstreams diagnose every layer of the business — from top-line channel ROI down to individual product refund triggers.
`SQL Scripts: Workstreams A–E`

**3. Strategic Visualization (Power BI)**
Built an executive-level dashboard using a **Star Schema** with DAX-powered financial simulation, surfacing margin, retention, and recovery metrics in a single control view.

---

## 📊 Key Results & Impact

| Metric | Result |
|---|---|
| Refund Leakage Identified | $19.2M in operational leakage across 5 marketing channels, driven primarily by high-value Electronics |
| Profit Recovery Projected | $4.8M annual recovery modeled via a 25% prescriptive leakage reduction across 4 regions and 5 categories |
| Retention Mapped | 24-month cohort decay analysis across 100,000 unique customers |
| Critical Churn Point | 77% decay at Month 1 — identifying the highest-leverage re-engagement window |
| High-LTV Segment Value | Platinum Whale cohort drove $74.9M in net revenue at a 93.6% profit margin |

---

## 🔗 SQL Analytical Workstreams — Deep Dive

Five workstreams form the analytical core of this project, each targeting a distinct business question:

- **Workstream A — Master Query** — Joins 1.1M rows to calculate Net Profit and Channel ROI by deducting marketing spend and refund losses
- **Workstream B — Strategic Segmentation** — Classifies users into Platinum Whales, Steady Growers, and Margin Drainers based on annual net revenue
- **Workstream C — Recovery Simulation** — A prescriptive model calculating the financial ROI of reducing refund rates by 25%
- **Workstream D — Cross-Sell Engine** — A transition matrix identifying the most frequent 1st-to-2nd purchase paths using sequence-based self-joins
- **Workstream E — Refund Triggers** — A diagnostic audit isolating refund volume and price sensitivity by product category
- **Cohort Decay Analysis** — A 24-month retention heatmap using `FIRST_VALUE` window functions to analyze customer "stickiness" over time

This turns a flat transaction log into a ranked set of financial interventions — pricing, retention, and spend reallocation decisions that can be actioned independently.

---

## 💡 Strategic Insights Summary

**High-Value Leakage** — High-ASP (Average Selling Price) Electronics accounted for the largest share of margin erosion, suggesting a need for a tiered Quality Control framework targeting items with the highest return-on-intervention.

**The Churn Cliff** — A 77% decay at Month 1 identifies the single most critical window for automated re-engagement and loyalty workflows — fixing this one drop-off point has outsized impact on lifetime retention curves.

**Segment Reallocation** — By isolating "Margin Drainer" segments with high CAC and elevated refund rates, marketing spend can be systematically reallocated toward "Platinum Whale" cohorts to improve overall LTV:CAC ratios across the portfolio.

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
# Generate the full 1.1M row relational dataset
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

# Open Dashboard/*.pbix in Power BI Desktop and refresh the data source
```

---

## 📂 Repository Structure

```
├── Synthetic Data.py              # Data simulation engine (1.1M records, 3-table schema)
├── Workstream_A_Master.sql        # Net Profit & Channel ROI across 1.1M rows
├── Workstream_B_Segmentation.sql  # Platinum Whales / Steady Growers / Margin Drainers
├── Workstream_C_Recovery.sql      # $4.8M prescriptive profit recovery model
├── Workstream_D_CrossSell.sql     # Sequence-based cross-sell transition matrix
├── Workstream_E_Refunds.sql       # Refund trigger audit by product & price sensitivity
├── Aggregated_Cohort_Decay.sql    # 24-month retention heatmap (FIRST_VALUE window fn)
├── Datasets/                      # Generated CSVs (dim_users, fact_transactions, spend)
└── Dashboard/                     # Power BI .pbix executive dashboard
```

---

## 🧰 Tech Stack


![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)
![NumPy](https://img.shields.io/badge/NumPy-013243?style=for-the-badge&logo=numpy&logoColor=white)
