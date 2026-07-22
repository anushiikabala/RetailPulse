# RetailPulse — E-Commerce Sales & Customer Analytics

An end-to-end analytics project that takes raw, messy e-commerce transaction data and turns it into business-ready insights — covering the full path from database design to stakeholder recommendations.

## Overview

RetailPulse ingests raw e-commerce order, customer, payment, and review data and answers real business questions: revenue trends, customer segmentation (RFM), repeat-purchase behavior, product category performance, and delivery/satisfaction correlation. It's built to mirror how data actually flows in a real analytics team — from messy raw files, to a validated query-ready database, to a live dashboard, to a decision-focused recommendation memo.

**Dataset:** [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## What This Project Demonstrates

- **Database design** — normalized relational schema built from scratch, with primary/foreign keys, constraints, and a [documented data dictionary](docs/data_dictionary.md)
- **Lightweight ETL (ELT pattern)** — Python script extracts raw CSVs and loads them into PostgreSQL; transformation happens via SQL after load
- **Data quality testing** — SQL-based validation (orphaned foreign keys, duplicate records, null checks, range checks) before any analysis is trusted
- **SQL analysis** — aggregations, window functions (`RANK`, `LAG`/`LEAD`), `CASE WHEN` segmentation, subqueries vs. CTEs, pivoted summary tables, geospatial rollups, seller-level performance
- **Business framing** — a one-page recommendation memo translating SQL findings into an actual business decision
- **Dashboard** — interactive Streamlit dashboard with revenue trends, RFM customer segments, category performance, delivery-vs-satisfaction analysis, a geographic revenue/delivery bubble map, and seller performance scorecards

## Tech Stack

| Layer | Tool |
|---|---|
| Database | PostgreSQL |
| ETL / Scripting | Python (pandas, SQLAlchemy) |
| Analysis | SQL |
| Dashboard | Streamlit, Plotly |
| Data Quality | SQL test scripts |
| Diagramming | dbdiagram.io |

## Setup & Running Locally

1. **Install dependencies** (Python 3.11+, PostgreSQL running locally):
   ```
   python -m venv venv
   venv\Scripts\activate        # Windows; use `source venv/bin/activate` on macOS/Linux
   pip install -r requirements.txt
   ```
2. **Create a `.env` file** in the project root with your database credentials:
   ```
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=retailpulse
   DB_USER=postgres
   DB_PASSWORD=your_password
   ```
3. **Download the dataset** from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and place the CSVs in `data/` (gitignored — not checked into this repo).
4. **Create the database and schema:**
   ```
   createdb retailpulse
   psql -d retailpulse -f sql/schema.sql
   ```
5. **Load the data:**
   ```
   python etl/load_data.py
   ```
6. **Build the transformation view:**
   ```
   psql -d retailpulse -f sql/transformations.sql
   ```
7. **(Optional) Run data quality checks** — every query in `sql/data_quality_checks.sql` should return 0 rows:
   ```
   psql -d retailpulse -f sql/data_quality_checks.sql
   ```
8. **Launch the dashboard:**
   ```
   streamlit run dashboard/app.py
   ```

## Project Structure

```
RetailPulse/
├── data/                          # Raw Olist CSVs (gitignored, downloaded from Kaggle)
├── dashboard/
│   └── app.py                     # Streamlit dashboard
├── docs/
│   ├── data_dictionary.md         # Column-by-column reference for every table
│   ├── er_diagram.png             # Entity-relationship diagram
│   └── recommendation_memo.md     # Business recommendation memo
├── etl/
│   └── load_data.py                # Loads raw CSVs into PostgreSQL
├── sql/
│   ├── schema.sql                  # Table definitions, keys, constraints
│   ├── transformations.sql         # order_summary view (analysis-ready rollup)
│   ├── data_quality_checks.sql     # Validation queries (should return 0 rows)
│   └── analysis_queries.sql        # Business-question SQL (RFM, repeat rate, state/seller performance)
├── .env                            # Local DB credentials (gitignored)
├── requirements.txt
└── README.md
```
