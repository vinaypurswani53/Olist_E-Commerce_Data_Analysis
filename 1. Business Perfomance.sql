use olist_database_2

--1.1 Overall KPIs
WITH payment_summary AS
(
    SELECT 
        order_id,
        SUM(payment_value) AS order_revenue
    FROM order_payments_dataset
    GROUP BY order_id
),

order_level AS
(
    SELECT
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        p.order_revenue
    FROM orders_dataset AS o
    LEFT JOIN payment_summary AS p
        ON o.order_id = p.order_id
)

SELECT
    COUNT(*) AS total_orders,
    SUM(order_revenue) AS total_revenue,
    AVG(order_revenue) AS AOV
FROM order_level;

----------------------------------------------------------------------

-- 1.2 Monthly Orders, Revenue and Average Order Value
WITH payment_summary AS
(
    SELECT
        order_id,
        SUM(payment_value) AS order_revenue
    FROM order_payments_dataset
    GROUP BY order_id
),

monthly_performance AS
(
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,
        MONTH(o.order_purchase_timestamp) AS order_month,
        o.order_id,
        p.order_revenue
    FROM orders_dataset AS o
    LEFT JOIN payment_summary AS p
        ON o.order_id = p.order_id
)

SELECT
    order_year,
    order_month,
    COUNT(*) AS total_orders,
    SUM(order_revenue) AS total_revenue,
    AVG(order_revenue) AS AOV
FROM monthly_performance
GROUP BY
    order_year,
    order_month
ORDER BY
    order_year,
    order_month;

---------------------------------------------------------------------------

-- 1.3 Dataset Date Range
SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders_dataset;

---------------------------------------------------------------------------

-- 1.4 Order Status Distribution
SELECT
    order_status,
    COUNT(*) AS total_orders,

    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS percentage_of_orders

FROM orders_dataset

GROUP BY
    order_status

ORDER BY
    total_orders DESC;

-------------------------------------------------------------
-- 1.5 Monthly Canccellation Rate

SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'canceled'
            THEN 1
            ELSE 0
        END
    ) AS canceled_orders,

    CAST(
        SUM(
            CASE
                WHEN order_status = 'canceled'
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS cancellation_rate

FROM orders_dataset

GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)

ORDER BY
    order_year,
    order_month;

--------------------------------------------------------------
-- 1.6 Category Order Comparison
SELECT
    pct.product_category_name_english AS category,

    COUNT(DISTINCT CASE
        WHEN YEAR(o.order_purchase_timestamp) = 2017
         AND MONTH(o.order_purchase_timestamp) = 1
        THEN o.order_id
    END) AS january_orders,

    COUNT(DISTINCT CASE
        WHEN YEAR(o.order_purchase_timestamp) = 2017
         AND MONTH(o.order_purchase_timestamp) = 2
        THEN o.order_id
    END) AS february_orders,

    COUNT(DISTINCT CASE
        WHEN YEAR(o.order_purchase_timestamp) = 2017
         AND MONTH(o.order_purchase_timestamp) = 2
        THEN o.order_id
    END)
    -
    COUNT(DISTINCT CASE
        WHEN YEAR(o.order_purchase_timestamp) = 2017
         AND MONTH(o.order_purchase_timestamp) = 1
        THEN o.order_id
    END) AS order_increase

FROM orders_dataset AS o

JOIN order_items AS oi
    ON o.order_id = oi.order_id

JOIN products AS p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_translation AS pct
    ON p.product_category_name = pct.product_category_name

WHERE
    YEAR(o.order_purchase_timestamp) = 2017
    AND MONTH(o.order_purchase_timestamp) IN (1, 2)

GROUP BY
    pct.product_category_name_english

ORDER BY
    order_increase DESC;

---------------------------------------------------------------------
-- 1.7 Category Wise Revenue Comparison

SELECT
    pct.product_category_name_english AS category,

    SUM(
        CASE
            WHEN YEAR(o.order_purchase_timestamp) = 2017
             AND MONTH(o.order_purchase_timestamp) = 1
            THEN oi.price
            ELSE 0
        END
    ) AS january_revenue,

    SUM(
        CASE
            WHEN YEAR(o.order_purchase_timestamp) = 2017
             AND MONTH(o.order_purchase_timestamp) = 2
            THEN oi.price
            ELSE 0
        END
    ) AS february_revenue,

    SUM(
        CASE
            WHEN YEAR(o.order_purchase_timestamp) = 2017
             AND MONTH(o.order_purchase_timestamp) = 2
            THEN oi.price
            ELSE 0
        END
    )
    -
    SUM(
        CASE
            WHEN YEAR(o.order_purchase_timestamp) = 2017
             AND MONTH(o.order_purchase_timestamp) = 1
            THEN oi.price
            ELSE 0
        END
    ) AS revenue_increase

FROM orders_dataset AS o

JOIN order_items AS oi
    ON o.order_id = oi.order_id

JOIN products AS p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_translation AS pct
    ON p.product_category_name = pct.product_category_name

WHERE
    YEAR(o.order_purchase_timestamp) = 2017
    AND MONTH(o.order_purchase_timestamp) IN (1, 2)

GROUP BY
    pct.product_category_name_english

ORDER BY
    revenue_increase DESC;

------------------------------------------------------------------