# RetailPulse — E-Commerce Sales & Customer Analytics

An end-to-end analytics project that takes raw, messy e-commerce transaction data and turns it into business-ready insights — covering the full path from database design to stakeholder recommendations.

## Overview

RetailPulse ingests raw e-commerce order, customer, payment, and review data and answers real business questions: revenue trends, customer segmentation (RFM), repeat-purchase behavior, product category performance, and delivery/satisfaction correlation. It's built to mirror how data actually flows in a real analytics team — from messy raw files, to a validated query-ready database, to a live dashboard, to a decision-focused recommendation memo.

**Dataset:** [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## What This Project Demonstrates

- **Database design** — normalized relational schema built from scratch, with primary/foreign keys, constraints, and a documented data dictionary
- **Lightweight ETL (ELT pattern)** — Python script extracts raw CSVs and loads them into PostgreSQL; transformation happens via SQL after load
- **Data quality testing** — SQL-based validation (orphaned foreign keys, duplicate records, null checks, range checks) before any analysis is trusted
- **SQL analysis** — aggregations, window functions (`RANK`, `LAG`/`LEAD`), `CASE WHEN` segmentation, subqueries vs. CTEs, pivoted summary tables
- **Business framing** — a one-page recommendation memo translating SQL findings into an actual business decision
- **Dashboard** — interactive Streamlit dashboard for key metrics

## Tech Stack

| Layer | Tool |
|---|---|
| Database | PostgreSQL |
| ETL / Scripting | Python (pandas, SQLAlchemy) |
| Analysis | SQL |
| Dashboard | Streamlit |
| Data Quality | SQL test scripts |
| Diagramming | dbdiagram.io |

## Project Structure
