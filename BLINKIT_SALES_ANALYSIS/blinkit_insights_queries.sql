-- Blinkit Analytics SQL Script
-- This file contains queries to extract key insights

-- 1. Basic sanity check: total orders & customers
SELECT COUNT(DISTINCT order_id) AS total_orders,
       COUNT(DISTINCT customer_id) AS total_customers
FROM blinkit_orders;

-- 2. Average Order Value (AOV)
SELECT ROUND(SUM(oi.price*oi.quantity)/COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM blinkit_orders o
JOIN blinkit_order_items oi ON o.order_id = oi.order_id;

-- 3. Repeat Customer Rate
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS order_count
    FROM blinkit_orders
    GROUP BY customer_id
)
SELECT ROUND(100.0 * SUM(CASE WHEN order_count>1 THEN 1 ELSE 0 END)/COUNT(*),2) AS repeat_customer_rate
FROM customer_orders;

-- 4. New Order Share
WITH first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM blinkit_orders
    GROUP BY customer_id
)
SELECT ROUND(100.0 * COUNT(DISTINCT o.order_id) / (SELECT COUNT(*) FROM blinkit_orders),2) AS new_order_share
FROM blinkit_orders o
JOIN first_orders f ON o.customer_id=f.customer_id AND o.order_date=f.first_order_date;

-- 5. On-Time Delivery Rate
SELECT ROUND(100.0 * SUM(CASE WHEN delivery_status='On Time' THEN 1 ELSE 0 END)/COUNT(*),2) AS on_time_delivery_rate
FROM blinkit_delivery_performance;

-- 6. Average Delivery Time (mins)
SELECT ROUND(AVG(delivery_time_minutes),2) AS avg_delivery_time
FROM blinkit_delivery_performance;

-- 7. Customer Satisfaction (Low rating %)
SELECT ROUND(100.0 * SUM(CASE WHEN rating<=3 THEN 1 ELSE 0 END)/COUNT(*),2) AS low_rating_percent
FROM blinkit_customer_feedback;

-- 8. Top 5 Bestselling Products
SELECT p.product_name, SUM(oi.quantity) AS total_qty
FROM blinkit_order_items oi
JOIN blinkit_products p ON oi.product_id=p.product_id
GROUP BY p.product_name
ORDER BY total_qty DESC
LIMIT 5;

-- 9. Inventory Stock-out Risk (products with low inventory)
SELECT product_id, stock, reorder_level
FROM blinkit_inventory
WHERE stock < reorder_level
ORDER BY stock ASC;

-- 10. Marketing Campaign ROI (if spend & revenue available)
SELECT campaign_id,
       SUM(conversions) AS total_conversions,
       SUM(spend) AS total_spend,
       SUM(revenue) AS total_revenue,
       ROUND(SUM(revenue)/NULLIF(SUM(spend),0),2) AS ROI
FROM blinkit_marketing_performance
GROUP BY campaign_id
ORDER BY ROI DESC;
