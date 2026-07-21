-- ============================================
-- RetailPulse Transformation Layer
-- Builds order_summary: one row per order, analysis-ready
-- ============================================

CREATE OR REPLACE VIEW order_summary AS
WITH item_agg AS (
    -- Roll up order_items to one row per order
    SELECT
        order_id,
        COUNT(*) AS num_items,
        SUM(price) AS total_item_price,
        SUM(freight_value) AS total_freight_value
    FROM order_items
    GROUP BY order_id
),
payment_agg AS (
    -- Roll up payments to one row per order (some orders split across installments/methods)
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value,
        MAX(payment_installments) AS max_installments,
        -- Pick the most common payment type per order
        MODE() WITHIN GROUP (ORDER BY payment_type) AS payment_type
    FROM payments
    GROUP BY order_id
),
review_agg AS (
    -- Some orders have more than one review row; take the latest one
    SELECT DISTINCT ON (order_id)
        order_id,
        review_score,
        review_creation_date
    FROM reviews
    ORDER BY order_id, review_creation_date DESC
)

SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- Delivery performance: negative = early, positive = late
    EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) AS delivery_delay_days,

    ia.num_items,
    ia.total_item_price,
    ia.total_freight_value,
    (ia.total_item_price + ia.total_freight_value) AS order_total_value,

    pa.payment_type,
    pa.max_installments,
    pa.total_payment_value,

    ra.review_score

FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN item_agg ia ON o.order_id = ia.order_id
LEFT JOIN payment_agg pa ON o.order_id = pa.order_id
LEFT JOIN review_agg ra ON o.order_id = ra.order_id;