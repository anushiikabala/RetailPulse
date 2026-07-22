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


-- ============================================
-- 4. Revenue & Delivery Performance by State
-- Aggregates geolocation to one representative lat/lng per state
-- so it can be joined onto customer_state for a bubble map
-- ============================================
WITH state_metrics AS (
    SELECT
        customer_state,
        SUM(order_total_value) AS revenue,
        COUNT(DISTINCT order_id) AS num_orders,
        ROUND(AVG(delivery_delay_days), 2) AS avg_delivery_delay_days,
        ROUND(AVG(review_score), 2) AS avg_review_score
    FROM order_summary
    WHERE order_status = 'delivered'
    GROUP BY customer_state
),
state_geo AS (
    SELECT
        geolocation_state AS state,
        ROUND(AVG(geolocation_lat), 6) AS lat,
        ROUND(AVG(geolocation_lng), 6) AS lng
    FROM geolocation
    GROUP BY geolocation_state
)
SELECT
    sm.customer_state AS state,
    sm.revenue,
    sm.num_orders,
    sm.avg_delivery_delay_days,
    sm.avg_review_score,
    sg.lat,
    sg.lng
FROM state_metrics sm
LEFT JOIN state_geo sg ON sm.customer_state = sg.state
ORDER BY sm.revenue DESC;


-- ============================================
-- 5. Seller Performance: late shipment rate vs. review score
-- Late shipment = carrier handoff happened after the seller's shipping_limit_date
-- Sellers with < 5 delivered orders are excluded (too little signal per seller)
-- ============================================
WITH seller_orders AS (
    SELECT
        oi.seller_id,
        oi.order_id,
        oi.price,
        (o.order_delivered_carrier_date > oi.shipping_limit_date) AS is_late_shipment,
        (o.order_delivered_carrier_date IS NOT NULL) AS has_carrier_date
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
),
seller_agg AS (
    SELECT
        seller_id,
        COUNT(DISTINCT order_id) AS num_orders,
        SUM(price) AS total_revenue,
        ROUND(
            COUNT(*) FILTER (WHERE is_late_shipment)::NUMERIC
            / NULLIF(COUNT(*) FILTER (WHERE has_carrier_date), 0) * 100
        , 2) AS late_shipment_rate_pct
    FROM seller_orders
    GROUP BY seller_id
),
seller_review_agg AS (
    -- Aggregated separately (one row per seller) before joining, since
    -- joining raw order-level reviews onto seller_orders by seller_id
    -- would fan out and inflate num_orders/total_revenue
    SELECT
        oi.seller_id,
        ROUND(AVG(r.review_score), 2) AS avg_review_score
    FROM order_items oi
    JOIN reviews r ON oi.order_id = r.order_id
    GROUP BY oi.seller_id
)
SELECT
    sa.seller_id,
    sa.num_orders,
    sa.total_revenue,
    sa.late_shipment_rate_pct,
    sr.avg_review_score
FROM seller_agg sa
LEFT JOIN seller_review_agg sr ON sa.seller_id = sr.seller_id
WHERE sa.num_orders >= 5
ORDER BY sa.total_revenue DESC;