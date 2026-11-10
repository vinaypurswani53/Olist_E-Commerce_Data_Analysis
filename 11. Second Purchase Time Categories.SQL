WITH OrderHistory AS
(
    -- One row per delivered order and customer
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
    FROM orders_dataset o
    INNER JOIN customers_dataset c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),

RankedPurchases AS
(
    -- Number each customer's purchases chronologically
    SELECT
        order_id,
        customer_unique_id,
        order_purchase_timestamp,

        ROW_NUMBER() OVER
        (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp, order_id
        ) AS purchase_number

    FROM OrderHistory
),

CustomerPurchasePairs AS
(
    -- Identify each customer's first and second purchases
    SELECT
        customer_unique_id,

        MAX(CASE
            WHEN purchase_number = 1
            THEN order_id
        END) AS first_order_id,

        MAX(CASE
            WHEN purchase_number = 2
            THEN order_id
        END) AS second_order_id,

        MAX(CASE
            WHEN purchase_number = 1
            THEN order_purchase_timestamp
        END) AS first_purchase_date,

        MAX(CASE
            WHEN purchase_number = 2
            THEN order_purchase_timestamp
        END) AS second_purchase_date

    FROM RankedPurchases
    GROUP BY customer_unique_id
),

CustomerCounts AS
(
    -- Customers without an observed second purchase
    SELECT
        COUNT(*) AS total_customers,

        SUM(CASE
            WHEN second_order_id IS NULL THEN 1
            ELSE 0
        END) AS customers_without_second_purchase

    FROM CustomerPurchasePairs
),

DatasetBoundary AS
(
    -- Last purchase timestamp available in the dataset
    SELECT
        MAX(order_purchase_timestamp) AS dataset_end_date
    FROM orders_dataset
),

SecondPurchaseCategories AS
(
    -- Identify categories in each customer's second order
    SELECT DISTINCT
        cpp.customer_unique_id,
        cpp.first_purchase_date,
        cpp.second_purchase_date,

        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS category_name

    FROM CustomerPurchasePairs cpp

    INNER JOIN order_items_dataset oi
        ON cpp.second_order_id = oi.order_id

    INNER JOIN products_dataset p
        ON oi.product_id = p.product_id

    LEFT JOIN product_category_name_translation t
        ON p.product_category_name =
           t.product_category_name

    WHERE cpp.second_order_id IS NOT NULL
)

-- Final category-level analysis
SELECT
    spc.category_name,

    COUNT(DISTINCT spc.customer_unique_id)
        AS customers_with_second_purchase,

    AVG(
        DATEDIFF_BIG(
            SECOND,
            spc.first_purchase_date,
            spc.second_purchase_date
        ) / 86400.0
    ) AS average_days_to_second_purchase,

    cc.total_customers,

    cc.customers_without_second_purchase,

    db.dataset_end_date

FROM SecondPurchaseCategories spc

CROSS JOIN CustomerCounts cc
CROSS JOIN DatasetBoundary db

GROUP BY
    spc.category_name,
    cc.total_customers,
    cc.customers_without_second_purchase,
    db.dataset_end_date

ORDER BY
    average_days_to_second_purchase ASC;