-- 5.1 Delivery Time 

SELECT
    AVG(
        DATEDIFF(
            DAY,
            order_purchase_timestamp,
            order_delivered_customer_date
        )
    ) AS average_delivery_days

FROM orders_dataset

WHERE
    order_delivered_customer_date IS NOT NULL;

-----------------------------------------------------------

-- 5.2 Actual vs Estimated Delivery Time 

SELECT
    AVG(
        DATEDIFF(
            DAY,
            order_purchase_timestamp,
            order_delivered_customer_date
        )
    ) AS average_actual_delivery_days,

    AVG(
        DATEDIFF(
            DAY,
            order_purchase_timestamp,
            order_estimated_delivery_date
        )
    ) AS average_estimated_delivery_days

FROM orders_dataset

WHERE
    order_delivered_customer_date IS NOT NULL;

-------------------------------------------------------------------

-- 5.3 Early/On-time/Late Orders

SELECT
    CASE
        WHEN order_delivered_customer_date < order_estimated_delivery_date
            THEN 'Early'

        WHEN order_delivered_customer_date = order_estimated_delivery_date
            THEN 'On Time'

        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
    END AS delivery_status,

    COUNT(*) AS total_orders

FROM orders_dataset

WHERE
    order_delivered_customer_date IS NOT NULL

GROUP BY
    CASE
        WHEN order_delivered_customer_date < order_estimated_delivery_date
            THEN 'Early'

        WHEN order_delivered_customer_date = order_estimated_delivery_date
            THEN 'On Time'

        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
    END

ORDER BY
    total_orders DESC;

-----------------------------------------------------------------------------------

--5.4 Average Delivery Delay

SELECT
    AVG(
        DATEDIFF(
            DAY,
            order_estimated_delivery_date,
            order_delivered_customer_date
        )
    ) AS average_delay_days

FROM orders_dataset

WHERE
    order_delivered_customer_date IS NOT NULL;

--------------------------------------------------------------------------------------
