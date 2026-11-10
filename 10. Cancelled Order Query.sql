WITH CancelledOrderItems AS
(
    SELECT
        o.order_id,
        oi.order_item_id,
        oi.seller_id,
        oi.price,

        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS category_name

    FROM orders_dataset o

    INNER JOIN order_items_dataset oi
        ON o.order_id = oi.order_id

    LEFT JOIN products_dataset p
        ON oi.product_id = p.product_id

    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name

    WHERE o.order_status = 'canceled'
)

SELECT
    category_name,
    COUNT(DISTINCT order_id) AS cancelled_orders,
    COUNT(*) AS total_items,
    SUM(price) AS associated_item_value,
    AVG(price) AS average_item_price

FROM CancelledOrderItems

GROUP BY category_name

ORDER BY associated_item_value DESC;