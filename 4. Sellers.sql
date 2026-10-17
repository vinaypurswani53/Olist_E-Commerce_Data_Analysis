-- 4.1 Total Sellers

SELECT
    COUNT(DISTINCT seller_id) AS total_sellers
FROM sellers_dataset;

--------------------------------------------------------

-- 4.2 Orders BY Sellers

SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS total_orders

FROM order_items AS oi

GROUP BY
    oi.seller_id

ORDER BY
    total_orders DESC;

----------------------------------------------------------

-- 4.3 Revenue By Seller

SELECT
    oi.seller_id,
    SUM(oi.price) AS total_revenue

FROM order_items AS oi

GROUP BY
    oi.seller_id

ORDER BY
    total_revenue DESC;

-----------------------------------------------------------

-- 4.4 Top Sellers By Revenue

SELECT TOP 20
    oi.seller_id,
    SUM(oi.price) AS total_revenue

FROM order_items AS oi

GROUP BY
    oi.seller_id

ORDER BY
    total_revenue DESC;

------------------------------------------------------------