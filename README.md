E-Commerce-Revenue-Assurance-Loss-Mitigation-Analytics
Strategic Revenue Recovery & Fraud Operations Analytics
A single wave of fraudulent or canceled orders can silently erode millions in revenue. This system surfaces exactly where, when, and why leakage occurs — identifying the specific products driving 80% of the financial damage and prescribing where to focus recovery efforts first.

📌 Project Overview
This project addresses the critical challenge of revenue leakage from order cancellations and suspected fraud in global retail operations. By combining SQL-driven aggregation, Pareto-based loss attribution, and a Power BI Control Tower, the system transforms raw transactional data into a prioritized intervention list for high-level stakeholders.

The pipeline covers three years of transactional data (2015–2017), analyzing performance across over 180,000 raw records (157K+ analyzed transactions after filtering) spanning global geographies, product categories, and order statuses.

🛠️ Technical Architecture
The three layers below form a closed-loop analytics pipeline: raw transactions are aggregated in SQL, structured into analytical datasets, and surfaced in an executive Power BI dashboard.

┌──────────────────────────────────────────────────────────────┐
│  [1] PostgreSQL (sales_data)  →  [2] SQL Aggregation Layer   │
│                                              ↓               │
│  [4] Power BI Control Tower  ←  [3] Analytical CSV Outputs   │
└──────────────────────────────────────────────────────────────┘
1. Source Data (PostgreSQL) Analysis is driven from a centralized sales_data table containing over 180,000 raw records (157K+ analyzed transactions after filtering). Return-related events are strictly defined as orders with a status of CANCELED or SUSPECTED_FRAUD.

2. SQL Aggregation Layer Three purpose-built SQL queries transform raw transactions into analytical insights:

Main Table — Aggregates annual KPIs at the product and geography grain, tracking Active Users, Revenue Lost, and Profit Lost
Monthly YoY Returns — Tracks monthly trends by category to surface seasonality and Loss Intensity %
Pareto Analysis — A window function CTE that isolates the top products driving 80% of revenue loss per category per year
3. Power BI Control Tower An executive dashboard that unifies these datasets into a single interface — combining high-level KPI cards, geographic heatmaps, and Pareto charts into a cross-functional view of sales health and revenue risk.

📊 Key Results & Impact

| Metric | Result |
|---|---|
| Total Leakage Quantified | $1.4M from 3,411 cancelled and suspected-fraud orders |
| Revenue Under Management | $36.4M tracked at 3.8% loss intensity |
| Recovery Modeled | 30% loss-reduction scenario projecting $419K revenue recovery and $48K profit uplift |
| Revenue Loss Attribution | Pareto logic isolates the 24% of SKUs responsible for ~80% of return-driven revenue loss across 118 products |
| Regional Seasonality | YoY engine across 10 states and 36 months isolating $550K in peak-month regional leakage |
| Fraud Detection Signal | Separates CANCELED vs. SUSPECTED_FRAUD orders to enable targeted investigations by risk type |
| YoY Trend Visibility | Surfaces critical spikes — e.g. May 2017, where "Other" goods faced a peak 5.05% loss intensity |
| Geographic Precision | Drill-down metrics available at the Country → State → City level for localized operational response |

🔗 Pareto Loss Attribution Logic
The most analytically novel element of this system is the Pareto Analysis query — a two-CTE design that calculates cumulative revenue loss per product, partitioned by year and category.

Priority Focus — Products appearing in the Pareto output (≤ 80% cumulative loss threshold) are the highest-priority targets for fraud review, supplier audits, or return policy changes
Category Benchmarking — Expresses each product's loss as a share of its category total, enabling fair comparison across diverse product lines like "Sports Goods" and "High-end Electronics"
This transforms a raw list of canceled orders into a ranked, actionable intervention list — a capability typically missing from standard returns reporting.

🚀 How to Run
Prerequisites: PostgreSQL, Power BI Desktop

Step 1: Database Setup

# Load your sales_data table into PostgreSQL
# Ensure order_date, order_status, sales, and product fields are present
Step 2: Run the SQL Queries

# Execute each query against your PostgreSQL instance
psql -U <user> -d <database> -f Main_Table.sql
psql -U <user> -d <database> -f Monthly_YoY_Returns.sql
psql -U <user> -d <database> -f Pareto_Analysis.sql

# Export each result to its corresponding CSV
Step 3: Load the Dashboard

# Open Project.pbix in Power BI Desktop
# Update the data source connection under:
#   Home → Transform Data → Data Source Settings
# Refresh to load the latest query outputs
📂 Repository Structure
├── Main_Table.sql                 # Annual KPI aggregation by product & geography
├── Monthly_YoY_Returns.sql        # Monthly YoY return and loss trend query
├── Pareto_Analysis.sql            # 80/20 revenue loss attribution (window CTE)
├── Project.pbix                   # Power BI executive Control Tower
└── Datasets/
    ├── Main_Table.csv             # Core sales & returns dataset
    ├── Monthly_YoY_Returns.csv    # Monthly trend dataset
    └── Pareto_Analysis.csv        # Pareto-filtered loss dataset
🧰 Tech Stack
PostgreSQL Power BI SQL

Database: PostgreSQL — CTEs, Window Functions, FILTER Clauses Visualization: Power BI — Executive Dashboards, Trend Analysis, Geospatial Mapping Analytics: Pareto Modeling, YoY Growth Analysis, Revenue Assurance
