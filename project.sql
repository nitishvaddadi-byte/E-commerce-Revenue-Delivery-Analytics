CREATE DATABASE IF NOT EXISTS project_phoenix;

USE project_phoenix;

USE project_phoenix;

CREATE TABLE order_analysis (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    purchase_timestamp DATETIME,
    approved_at DATETIME,
    delivered_carrier_date DATETIME,
    delivered_customer_date DATETIME,
    estimated_delivery_date DATETIME,
    item_revenue DECIMAL(12,2),
    item_freight DECIMAL(12,2),
    item_count INT,
    payment_total DECIMAL(12,2),
    payment_record_count INT,
    has_items BOOLEAN,
    has_payment BOOLEAN,
    item_plus_freight DECIMAL(12,2),
    payment_difference DECIMAL(12,2),
    reconciliation_status VARCHAR(50),
    order_month VARCHAR(7)
);


USE project_phoenix;


SHOW VARIABLES LIKE 'local_infile';





USE project_phoenix;

SHOW TABLES;


SELECT * FROM order_analysis;

SELECT
    VERSION() AS mysql_version,
    @@local_infile AS local_infile;
    
USE project_phoenix;

SHOW VARIABLES LIKE 'secure_file_priv';

SHOW VARIABLES LIKE 'secure_file_priv';

USE project_phoenix;

ALTER TABLE order_analysis
MODIFY has_items VARCHAR(5),
MODIFY has_payment VARCHAR(5);





USE project_phoenix;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_analysis.csv'
INTO TABLE order_analysis
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    customer_id,
    order_status,
    @purchase_ts,
    @approved_at,
    @carrier_date,
    @customer_date,
    @estimated_date,
    @revenue,
    @freight,
    @item_count,
    @payment_total,
    @payment_count,
    has_items,
    has_payment,
    @item_plus_freight,
    @payment_difference,
    reconciliation_status,
    order_month
)
SET
    purchase_timestamp = NULLIF(@purchase_ts, ''),
    approved_at = NULLIF(@approved_at, ''),
    delivered_carrier_date = NULLIF(@carrier_date, ''),
    delivered_customer_date = NULLIF(@customer_date, ''),
    estimated_delivery_date = NULLIF(@estimated_date, ''),
    item_revenue = NULLIF(@revenue, ''),
    item_freight = NULLIF(@freight, ''),
    item_count = NULLIF(@item_count, ''),
    payment_total = NULLIF(@payment_total, ''),
    payment_record_count = NULLIF(@payment_count, ''),
    item_plus_freight = NULLIF(@item_plus_freight, ''),
    payment_difference = NULLIF(@payment_difference, '');
    
    
    SELECT COUNT(*) AS total_rows
FROM project_phoenix.order_analysis;

USE project_phoenix;

TRUNCATE TABLE order_analysis;

SELECT 'order_analysis' AS table_name, COUNT(*) AS total_rows
FROM order_analysis

UNION ALL

SELECT 'monthly_business', COUNT(*)
FROM monthly_business

UNION ALL

SELECT 'category_performance', COUNT(*)
FROM category_performance

UNION ALL

SELECT 'customer_purchase_counts', COUNT(*)
FROM customer_purchase_counts

UNION ALL

SELECT 'monthly_delivery', COUNT(*)
FROM monthly_delivery

UNION ALL

SELECT 'state_delivery_summary', COUNT(*)
FROM state_delivery_summary

UNION ALL

SELECT 'project_kpi_summary', COUNT(*)
FROM project_kpi_summary;


#1)What is the overall business performance?
USE project_phoenix;
SELECT
    COUNT(*) AS total_orders,
    ROUND(SUM(item_revenue), 2) AS total_revenue,
    ROUND(AVG(item_revenue), 2) AS avg_revenue_per_order
FROM order_analysis;

#2)How does revenue change month by month?
SELECT
    order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(item_revenue), 2) AS monthly_revenue,
    ROUND(AVG(item_revenue), 2) AS avg_revenue_per_order
FROM order_analysis
GROUP BY order_month
ORDER BY order_month;

#3)Which product categories generate the most revenue?
SELECT
    product_category_clean,
    item_revenue,
    item_count,
    revenue_share_pct
FROM category_performance
ORDER BY item_revenue DESC
LIMIT 10;

#4)How many customers purchase repeatedly?
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE
        WHEN total_orders = 1 THEN 1
        ELSE 0
    END) AS one_time_customers,
    SUM(CASE
        WHEN total_orders > 1 THEN 1
        ELSE 0
    END) AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE
            WHEN total_orders > 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS repeat_customer_pct
FROM customer_purchase_counts;

#5)Which states have the most delivery delays?
SELECT
    customer_state,
    orders_analyzed,
    late_orders,
    ROUND(late_delivery_percentage, 2) AS late_delivery_pct
FROM state_delivery_summary
WHERE orders_analyzed >= 100
ORDER BY late_delivery_percentage DESC
LIMIT 10;

#6)Which orders have payment and item revenue mismatches?
SELECT
    reconciliation_status,
    COUNT(*) AS total_orders
FROM order_analysis
GROUP BY reconciliation_status
ORDER BY total_orders DESC;

#7)Which orders have the largest payment differences?
SELECT
    order_id,
    item_plus_freight,
    payment_total,
    payment_difference,
    reconciliation_status
FROM order_analysis
WHERE payment_difference IS NOT NULL
ORDER BY ABS(payment_difference) DESC
LIMIT 10;

#8)Which months have the highest revenue?
SELECT
    order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(item_revenue), 2) AS monthly_revenue
FROM order_analysis
GROUP BY order_month
ORDER BY monthly_revenue DESC
LIMIT 5;

#9)Which orders have the longest delivery times?
SELECT
    order_id,
    order_status,
    DATE(purchase_timestamp) AS purchase_date,
    DATE(delivered_customer_date) AS delivery_date,
    DATEDIFF(
        delivered_customer_date,
        purchase_timestamp
    ) AS delivery_days
FROM order_analysis
WHERE delivered_customer_date IS NOT NULL
ORDER BY delivery_days DESC
LIMIT 10;

#10)Which months had the highest late-delivery rates?
SELECT
    order_month,
    orders_analyzed,
    late_orders,
    ROUND(late_delivery_percentage, 2) AS late_delivery_pct
FROM monthly_delivery
ORDER BY late_delivery_percentage DESC
LIMIT 10;

#11)Which order statuses have the highest number of orders?
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM order_analysis),
        2
    ) AS order_percentage
FROM order_analysis
GROUP BY order_status
ORDER BY total_orders DESC;

#12)Which months generated the highest average revenue per order?
SELECT
    order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(item_revenue), 2) AS monthly_revenue,
    ROUND(AVG(item_revenue), 2) AS avg_revenue_per_order
FROM order_analysis
WHERE item_revenue IS NOT NULL
GROUP BY order_month
ORDER BY avg_revenue_per_order DESC
LIMIT 10;

#13)Which orders have a payment mismatch?
SELECT
    order_id,
    item_plus_freight,
    payment_total,
    payment_difference,
    reconciliation_status
FROM order_analysis
WHERE ABS(payment_difference) > 0.01
ORDER BY ABS(payment_difference) DESC
LIMIT 10;

SHOW TABLES;
DESCRIBE order_analysis;
DESCRIBE state_delivery_summary;

#14)Which order statuses have the highest late-delivery rate?
SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN delivered_customer_date > estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN delivered_customer_date > estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_delivery_pct
FROM order_analysis
WHERE delivered_customer_date IS NOT NULL
GROUP BY order_status
ORDER BY late_delivery_pct DESC;

#15)Which orders have the highest payment differences by absolute value?
SELECT
    reconciliation_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(payment_difference), 2) AS avg_difference,
    ROUND(MAX(ABS(payment_difference)), 2) AS max_abs_difference
FROM order_analysis
WHERE payment_difference IS NOT NULL
GROUP BY reconciliation_status
ORDER BY max_abs_difference DESC;

#16)How many orders have missing item or payment data?
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN item_revenue IS NULL THEN 1 ELSE 0 END)
        AS missing_item_revenue,
    SUM(CASE WHEN payment_total IS NULL THEN 1 ELSE 0 END)
        AS missing_payment_total,
    SUM(CASE WHEN item_revenue IS NULL
              AND payment_total IS NULL THEN 1 ELSE 0 END)
        AS missing_both
FROM order_analysis;

#17)Are there any duplicate orders in the dataset?
SELECT
    order_id,
    COUNT(*) AS record_count
FROM order_analysis
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

#18)What is the overall on-time delivery rate?
SELECT
    COUNT(*) AS delivered_orders,
    SUM(
        CASE
            WHEN delivered_customer_date <= estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS on_time_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN delivered_customer_date <= estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS on_time_delivery_pct
FROM order_analysis
WHERE delivered_customer_date IS NOT NULL
  AND estimated_delivery_date IS NOT NULL;

#19)Which months had the highest order volumes?
SELECT
    order_month,
    COUNT(*) AS total_orders
FROM order_analysis
GROUP BY order_month
ORDER BY total_orders DESC
LIMIT 10;

#20)What is the monthly revenue growth percentage?
WITH monthly_revenue AS (
    SELECT
        order_month,
        SUM(item_revenue) AS revenue
    FROM order_analysis
    GROUP BY order_month
),
revenue_with_previous AS (
    SELECT
        order_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY order_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    order_month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS revenue_growth_pct
FROM revenue_with_previous
ORDER BY order_month;

#21)Which months had the largest revenue decreases compared with the previous month?
WITH monthly_revenue AS (
    SELECT
        order_month,
        SUM(item_revenue) AS revenue
    FROM order_analysis
    GROUP BY order_month
),
revenue_comparison AS (
    SELECT
        order_month,
        revenue,
        LAG(revenue) OVER (ORDER BY order_month) AS previous_revenue
    FROM monthly_revenue
)
SELECT
    order_month,
    ROUND(previous_revenue, 2) AS previous_revenue,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(
        100.0 * (revenue - previous_revenue)
        / NULLIF(previous_revenue, 0),
        2
    ) AS revenue_growth_pct
FROM revenue_comparison
WHERE previous_revenue IS NOT NULL
  AND revenue < previous_revenue
ORDER BY revenue_growth_pct ASC
LIMIT 10;

#22)Which orders have the highest freight cost?
SELECT
    order_id,
    item_revenue,
    item_freight,
    ROUND(
        100.0 * item_freight / NULLIF(item_revenue, 0),
        2
    ) AS freight_percentage
FROM order_analysis
WHERE item_freight IS NOT NULL
  AND item_revenue > 0
ORDER BY item_freight DESC
LIMIT 10;

#23)Which orders have the highest freight cost relative to item revenue?
SELECT
    order_id,
    item_revenue,
    item_freight,
    ROUND(
        100.0 * item_freight / NULLIF(item_revenue, 0),
        2
    ) AS freight_percentage
FROM order_analysis
WHERE item_freight IS NOT NULL
  AND item_revenue > 0
ORDER BY freight_percentage DESC
LIMIT 10;

#final query 
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders,
    SUM(item_revenue IS NULL) AS missing_item_revenue,
    SUM(payment_total IS NULL) AS missing_payment_total,
    SUM(delivered_customer_date IS NULL) AS missing_delivery_date
FROM order_analysis;
