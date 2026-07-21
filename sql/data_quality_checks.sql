-- ============================================
-- RetailPulse Data Quality Checks
-- Each query should return 0 rows if data is clean.
-- Any rows returned indicate an issue to investigate.
-- ============================================

-- 1. Orphaned orders: customer_id in orders that doesn't exist in customers
SELECT o.order_id, o.customer_id
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 2. Orphaned order_items: product_id that doesn't exist in products
SELECT oi.order_id, oi.product_id
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 3. Orphaned order_items: seller_id that doesn't exist in sellers
SELECT oi.order_id, oi.seller_id
FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- 4. Orphaned payments: order_id that doesn't exist in orders
SELECT p.order_id
FROM payments p
LEFT JOIN orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 5. Orphaned reviews: order_id that doesn't exist in orders
SELECT r.order_id
FROM reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 6. Duplicate order_ids in orders (should be impossible due to PK, but confirms PK is doing its job)
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 7. Negative or zero prices in order_items (data integrity check)
SELECT order_id, product_id, price
FROM order_items
WHERE price <= 0;

-- 8. Negative payment values
SELECT order_id, payment_value
FROM payments
WHERE payment_value < 0;

-- 9. Orders where delivered date is BEFORE purchase date (impossible in reality)
SELECT order_id, order_purchase_timestamp, order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 10. Review scores outside valid range (should be impossible due to CHECK constraint)
SELECT review_id, review_score
FROM reviews
WHERE review_score NOT BETWEEN 1 AND 5;

-- 11. Orders missing a purchase timestamp (should never happen)
SELECT order_id
FROM orders
WHERE order_purchase_timestamp IS NULL;

-- 12. Count of orders by status (not a "zero rows" check — just a sanity view
--     to confirm delivered/canceled/shipped statuses look reasonable)
SELECT order_status, COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;