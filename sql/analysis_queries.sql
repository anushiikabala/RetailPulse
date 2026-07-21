-- ============================================
-- 2. RFM Customer Segmentation (CASE WHEN + aggregation)
-- Uses customer_unique_id since customer_id resets per order in this dataset
-- ============================================
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
FROM customer_rfm
ORDER BY monetary DESC;


-- ============================================
-- 3. Repeat Purchase Rate
-- Uses customer_unique_id since customer_id resets per order in this dataset
-- ============================================
WITH order_counts AS (
    SELECT customer_unique_id, COUNT(DISTINCT order_id) AS num_orders
    FROM order_summary
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*) FILTER (WHERE num_orders > 1) AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*) FILTER (WHERE num_orders > 1)::NUMERIC / COUNT(*) * 100
    , 2) AS repeat_purchase_rate_pct
FROM order_counts;