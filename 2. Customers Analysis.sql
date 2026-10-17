-- 2.1 Total Customers
SELECT
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers_dataset;

-----------------------------------------------------------------

-- 2.2 Customers By State

SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers_dataset
GROUP BY
    customer_state
ORDER BY
    total_customers DESC;

-------------------------------------------------------------------

-- 2.3 Customers By City

SELECT
    customer_city,
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers_dataset
GROUP BY
    customer_city
ORDER BY
    total_customers DESC;

-----------------------------------------------------------------------

--2.4 Orders By State

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers_dataset AS c

JOIN orders_dataset AS o
    ON c.customer_id = o.customer_id

GROUP BY
    c.customer_state

ORDER BY
    total_orders DESC;

--------------------------------------------------------------------------

--2.5 Revenue By State

WITH payment_summary AS
(
    SELECT
        order_id,
        SUM(payment_value) AS order_revenue
    FROM order_payments_dataset
    GROUP BY
        order_id
)

SELECT
    c.customer_state,
    SUM(p.order_revenue) AS total_revenue

FROM customers_dataset AS c

JOIN orders_dataset AS o
    ON c.customer_id = o.customer_id

JOIN payment_summary AS p
    ON o.order_id = p.order_id

GROUP BY
    c.customer_state

ORDER BY
    total_revenue DESC;

-------------------------------------------------------------------------------

--2.6 Orders Per Customer

SELECT
    AVG(order_count) AS average_orders_per_customer
FROM
(
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count

    FROM customers_dataset AS c

    JOIN orders_dataset AS o
        ON c.customer_id = o.customer_id

    GROUP BY
        c.customer_unique_id
) AS customer_orders;

------------------------------------------------------------------------------------

-- 2.7 One Time vs Repeat Customers

SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,

    COUNT(*) AS customers

FROM
(
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count

    FROM customers_dataset AS c

    JOIN orders_dataset AS o
        ON c.customer_id = o.customer_id

    GROUP BY
        c.customer_unique_id
) AS customer_orders

GROUP BY
    CASE
        WHEN order_count = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END;

----------------------------------------------------------------------------






