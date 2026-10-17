-- 3.1 Orders BY Category

SELECT
    pct.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders

FROM order_items AS oi

JOIN products AS p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_translation AS pct
    ON p.product_category_name = pct.product_category_name

GROUP BY
    pct.product_category_name_english

ORDER BY
    total_orders DESC;

-----------------------------------------------------------------------------

--3.2 Revenue By Category

SELECT
    pct.product_category_name_english AS category,
    SUM(oi.price) AS total_revenue

FROM order_items AS oi

JOIN products AS p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_translation AS pct
    ON p.product_category_name = pct.product_category_name

GROUP BY
    pct.product_category_name_english

ORDER BY
    total_revenue DESC;

----------------------------------------------------------------------------

-- 3.3 Average Product Price By Category

SELECT
    pct.product_category_name_english AS category,
    AVG(oi.price) AS average_product_price

FROM order_items AS oi

JOIN products AS p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_translation AS pct
    ON p.product_category_name = pct.product_category_name

GROUP BY
    pct.product_category_name_english

ORDER BY
    average_product_price DESC;

 -----------------------------------------------------------------------------

 -- 3.4 Freight BY Category

 SELECT
    pct.product_category_name_english AS category,
    SUM(oi.freight_value) AS total_freight,
    AVG(oi.freight_value) AS average_freight

FROM order_items AS oi

JOIN products AS p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_translation AS pct
    ON p.product_category_name = pct.product_category_name

GROUP BY
    pct.product_category_name_english

ORDER BY
    total_freight DESC;

----------------------------------------------------------------------------------
