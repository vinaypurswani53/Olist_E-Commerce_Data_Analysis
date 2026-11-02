
WITH CategoryMonthly AS (
    SELECT
        COALESCE(
            pct.product_category_name_english,
            'Unknown'
        ) AS category,

        COUNT(DISTINCT CASE
            WHEN o.order_purchase_timestamp >= '20170101'
             AND o.order_purchase_timestamp <  '20170201'
            THEN o.order_id
        END) AS January_Orders,

        COUNT(DISTINCT CASE
            WHEN o.order_purchase_timestamp >= '20170201'
             AND o.order_purchase_timestamp <  '20170301'
            THEN o.order_id
        END) AS February_Orders,

        SUM(CASE
            WHEN o.order_purchase_timestamp >= '20170101'
             AND o.order_purchase_timestamp <  '20170201'
            THEN oi.price ELSE 0
        END) AS January_Revenue,

        SUM(CASE
            WHEN o.order_purchase_timestamp >= '20170201'
             AND o.order_purchase_timestamp <  '20170301'
            THEN oi.price ELSE 0
        END) AS February_Revenue

    FROM orders_dataset o
    JOIN order_items_dataset oi
        ON o.order_id = oi.order_id
    JOIN products_dataset p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation pct
        ON p.product_category_name =
           pct.product_category_name

    WHERE o.order_purchase_timestamp >= '20170101'
      AND o.order_purchase_timestamp <  '20170301'

    GROUP BY
        COALESCE(
            pct.product_category_name_english,
            'Unknown'
        )
)
SELECT
    category,
    January_Orders,
    February_Orders,
    February_Orders - January_Orders AS Order_Change,
    January_Revenue,
    February_Revenue,
    February_Revenue - January_Revenue AS Revenue_Change,
    CAST(
        100.0 * (February_Revenue - January_Revenue)
        / NULLIF(January_Revenue, 0)
        AS DECIMAL(10,2)
    ) AS Revenue_Change_Percentage
FROM CategoryMonthly
ORDER BY Revenue_Change DESC;
