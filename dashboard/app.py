"""
RetailPulse Dashboard
Streamlit app visualizing e-commerce sales & customer analytics.
"""

import os
import pandas as pd
import streamlit as st
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = quote_plus(os.getenv("DB_PASSWORD"))

engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

st.set_page_config(page_title="RetailPulse", layout="wide")
st.title("📊 RetailPulse — E-Commerce Sales & Customer Analytics")
st.caption("Olist Brazilian E-Commerce Dataset | End-to-end SQL + Python analytics project")

# ============================================
# 1. Revenue Trend (shown first, big picture)
# ============================================
st.header("Monthly Revenue Trend")

revenue_query = """
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp) AS order_month,
        SUM(order_total_value) AS revenue
    FROM order_summary
    WHERE order_status = 'delivered'
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
)
SELECT
    order_month,
    revenue,
    LAG(revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0) * 100
    , 2) AS pct_change_mom
FROM monthly_revenue
ORDER BY order_month;
"""

df_revenue = pd.read_sql(text(revenue_query), engine)

col1, col2, col3 = st.columns(3)
col1.metric("Total Revenue", f"R$ {df_revenue['revenue'].sum():,.2f}")
col2.metric("Avg Monthly Revenue", f"R$ {df_revenue['revenue'].mean():,.2f}")
latest_change = df_revenue['pct_change_mom'].iloc[-1]
col3.metric("Latest MoM Change", f"{latest_change:.1f}%" if pd.notna(latest_change) else "N/A")

st.line_chart(df_revenue.set_index("order_month")["revenue"])

with st.expander("View raw revenue data"):
    st.dataframe(df_revenue)

st.divider()

# ============================================
# 2. Customer Segments (RFM)
# ============================================
st.header("Customer Segments (RFM)")

rfm_query = """
WITH customer_rfm AS (
    SELECT
        customer_unique_id,
        MAX(order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(order_total_value) AS monetary,
        (SELECT MAX(order_purchase_timestamp) FROM order_summary) - MAX(order_purchase_timestamp) AS recency_gap
    FROM order_summary
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
)
SELECT
    customer_unique_id,
    EXTRACT(DAY FROM recency_gap) AS recency_days,
    frequency,
    monetary,
    CASE
        WHEN EXTRACT(DAY FROM recency_gap) <= 90 AND frequency >= 2 THEN 'Loyal / Active'
        WHEN EXTRACT(DAY FROM recency_gap) <= 90 AND frequency = 1 THEN 'New Customer'
        WHEN EXTRACT(DAY FROM recency_gap) > 90 AND frequency >= 2 THEN 'At Risk'
        ELSE 'Churned'
    END AS customer_segment
FROM customer_rfm;
"""

df_rfm = pd.read_sql(text(rfm_query), engine)

col1, col2 = st.columns([1, 2])
with col1:
    segment_counts = df_rfm["customer_segment"].value_counts()
    st.bar_chart(segment_counts)
with col2:
    segment_revenue = df_rfm.groupby("customer_segment")["monetary"].sum().sort_values(ascending=False)
    st.dataframe(segment_revenue.reset_index().rename(columns={"monetary": "total_revenue"}))

st.divider()

# ============================================
# 3. Product Category Performance
# ============================================
st.header("Top Product Categories by Revenue")

category_query = """
SELECT
    t.product_category_name_english AS category,
    SUM(oi.price) AS category_revenue,
    COUNT(DISTINCT oi.order_id) AS num_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY category_revenue DESC
LIMIT 15;
"""

df_category = pd.read_sql(text(category_query), engine)
st.bar_chart(df_category.set_index("category")["category_revenue"])

st.divider()

# ============================================
# 4. Delivery Performance vs Review Score
# ============================================
st.header("Delivery Performance vs. Customer Satisfaction")

delivery_query = """
SELECT
    CASE
        WHEN delivery_delay_days IS NULL THEN 'Not Delivered'
        WHEN delivery_delay_days <= -7 THEN 'Very Early (7+ days)'
        WHEN delivery_delay_days < 0 THEN 'Early'
        WHEN delivery_delay_days = 0 THEN 'On Time'
        ELSE 'Late'
    END AS delivery_bucket,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    COUNT(*) AS num_orders
FROM order_summary
WHERE order_status = 'delivered'
GROUP BY delivery_bucket
ORDER BY avg_review_score DESC;
"""

df_delivery = pd.read_sql(text(delivery_query), engine)
col1, col2 = st.columns([1, 1])
with col1:
    st.bar_chart(df_delivery.set_index("delivery_bucket")["avg_review_score"])
with col2:
    st.dataframe(df_delivery)

st.caption("Key insight: late deliveries correlate with meaningfully lower review scores.")