--6.1 Average Review Score 

use olist_database_2
SELECT
    AVG(CAST(review_score AS DECIMAL(10,2))) AS average_review_score
FROM order_reviews_dataset;

-----------------------------------------------------------------------

-- 6.2 Review Score Distribution

SELECT
    review_score,
    COUNT(*) AS total_reviews,

    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS percentage_of_reviews

FROM order_reviews_dataset

GROUP BY
    review_score

ORDER BY
    review_score;

----------------------------------------------------------------------

--6.3 On Time vs Late Review Score

SELECT
    CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 'On Time / Early'

        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late'
    END AS delivery_status,

    COUNT(*) AS total_orders,

    AVG(
        CAST(r.review_score AS DECIMAL(10,2))
    ) AS average_review_score

FROM orders_dataset AS o

JOIN order_reviews_dataset AS r
    ON o.order_id = r.order_id

WHERE
    o.order_delivered_customer_date IS NOT NULL

GROUP BY
    CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 'On Time / Early'

        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late'
    END

ORDER BY
    average_review_score DESC;

--------------------------------------------------------------------------------------

--6.4 Delay vs Review Score

SELECT
    r.review_score,

    COUNT(*) AS total_orders,

    AVG(
        DATEDIFF(
            DAY,
            o.order_estimated_delivery_date,
            o.order_delivered_customer_date
        )
    ) AS average_delay_days

FROM orders_dataset AS o

JOIN order_reviews_dataset AS r
    ON o.order_id = r.order_id

WHERE
    o.order_delivered_customer_date IS NOT NULL

GROUP BY
    r.review_score

ORDER BY
    r.review_score;

---------------------------------------------------------------------------------------

