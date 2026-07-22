# RetailPulse — Data Dictionary

Reference for every table in the schema (`sql/schema.sql`) and the derived view (`sql/transformations.sql`). Source: [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

## customers

| Column | Type | Description |
|---|---|---|
| `customer_id` (PK) | VARCHAR(50) | Order-scoped customer key — a new one is generated per order, even for the same person |
| `customer_unique_id` | VARCHAR(50) | Stable identifier for a real person across multiple orders. Use this for customer-level analysis (e.g. RFM, repeat-purchase rate) |
| `customer_zip_code_prefix` | VARCHAR(10) | First digits of the customer's zip code |
| `customer_city` | VARCHAR(100) | Customer's city |
| `customer_state` | VARCHAR(5) | Customer's state (2-letter Brazilian state code) |

## sellers

| Column | Type | Description |
|---|---|---|
| `seller_id` (PK) | VARCHAR(50) | Unique seller identifier |
| `seller_zip_code_prefix` | VARCHAR(10) | First digits of the seller's zip code |
| `seller_city` | VARCHAR(100) | Seller's city |
| `seller_state` | VARCHAR(5) | Seller's state |

## product_category_name_translation

| Column | Type | Description |
|---|---|---|
| `product_category_name` (PK) | VARCHAR(100) | Category name in Portuguese, as it appears in `products` |
| `product_category_name_english` | VARCHAR(100) | English translation used for reporting |

## products

| Column | Type | Description |
|---|---|---|
| `product_id` (PK) | VARCHAR(50) | Unique product identifier |
| `product_category_name` (FK) | VARCHAR(100) | References `product_category_name_translation` |
| `product_name_lenght` | INT | Character length of the product name (as published by Olist, typo included) |
| `product_description_lenght` | INT | Character length of the product description |
| `product_photos_qty` | INT | Number of photos on the product listing |
| `product_weight_g` | INT | Product weight in grams |
| `product_length_cm` / `product_height_cm` / `product_width_cm` | INT | Package dimensions in centimeters |

## orders

| Column | Type | Description |
|---|---|---|
| `order_id` (PK) | VARCHAR(50) | Unique order identifier |
| `customer_id` (FK) | VARCHAR(50) | References `customers` |
| `order_status` | VARCHAR(20) | e.g. `delivered`, `shipped`, `canceled`. Most analysis filters to `delivered` |
| `order_purchase_timestamp` | TIMESTAMP | When the order was placed |
| `order_approved_at` | TIMESTAMP | When payment was approved |
| `order_delivered_carrier_date` | TIMESTAMP | When the order was handed off to the shipping carrier |
| `order_delivered_customer_date` | TIMESTAMP | When the customer actually received the order |
| `order_estimated_delivery_date` | TIMESTAMP | The delivery date promised to the customer at purchase time |

## order_items

| Column | Type | Description |
|---|---|---|
| `order_id` (PK, FK) | VARCHAR(50) | References `orders` |
| `order_item_id` (PK) | INT | Line-item number within the order (an order can contain multiple items) |
| `product_id` (FK) | VARCHAR(50) | References `products` |
| `seller_id` (FK) | VARCHAR(50) | References `sellers` — each line item can be fulfilled by a different seller |
| `shipping_limit_date` | TIMESTAMP | Deadline by which the seller must hand this item to the carrier |
| `price` | NUMERIC(10,2) | Item price (must be >= 0) |
| `freight_value` | NUMERIC(10,2) | Shipping cost for this item (must be >= 0) |

## payments

| Column | Type | Description |
|---|---|---|
| `order_id` (PK, FK) | VARCHAR(50) | References `orders` |
| `payment_sequential` (PK) | INT | Sequence number — an order can be paid via multiple methods/installments |
| `payment_type` | VARCHAR(20) | e.g. `credit_card`, `boleto`, `voucher` |
| `payment_installments` | INT | Number of installments the payment was split into |
| `payment_value` | NUMERIC(10,2) | Amount paid in this installment/method (must be >= 0) |

## reviews

| Column | Type | Description |
|---|---|---|
| `review_id` (PK) | VARCHAR(50) | Unique review identifier |
| `order_id` (FK) | VARCHAR(50) | References `orders`. Some orders have more than one review row — `order_summary` takes the latest by `review_creation_date` |
| `review_score` | INT | 1–5 star rating |
| `review_comment_title` / `review_comment_message` | VARCHAR/TEXT | Free-text review content (often blank) |
| `review_creation_date` | TIMESTAMP | When the review request was sent |
| `review_answer_timestamp` | TIMESTAMP | When the customer submitted the review |

## geolocation

| Column | Type | Description |
|---|---|---|
| `geolocation_zip_code_prefix` | VARCHAR(10) | Zip code prefix — not unique; the raw dataset has many lat/lng samples per prefix |
| `geolocation_lat` / `geolocation_lng` | NUMERIC(10,6) | Latitude/longitude sample for that zip prefix |
| `geolocation_city` | VARCHAR(100) | City name |
| `geolocation_state` | VARCHAR(5) | State code — used in `analysis_queries.sql` to build one representative lat/lng per state for the dashboard map |

## order_summary (view, built by `sql/transformations.sql`)

One row per order, rolling up items/payments/reviews so most analysis queries don't need to repeat those joins.

| Column | Description |
|---|---|
| `order_id`, `customer_id`, `customer_unique_id`, `customer_city`, `customer_state` | From `orders`/`customers` |
| `order_status`, `order_purchase_timestamp`, `order_delivered_customer_date`, `order_estimated_delivery_date` | From `orders` |
| `delivery_delay_days` | `order_delivered_customer_date - order_estimated_delivery_date`, in days. Negative = delivered early, positive = late |
| `num_items`, `total_item_price`, `total_freight_value` | Rolled up from `order_items` |
| `order_total_value` | `total_item_price + total_freight_value` |
| `payment_type`, `max_installments`, `total_payment_value` | Rolled up from `payments` (most common `payment_type` per order via `MODE()`) |
| `review_score` | Latest review score for the order, if any |
