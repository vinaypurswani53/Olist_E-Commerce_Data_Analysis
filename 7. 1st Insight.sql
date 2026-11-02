use olist_database_2

DROP TABLE IF EXISTS #SalesBase;
DROP TABLE IF EXISTS #CategoryMonthly;
DROP TABLE IF EXISTS #ProductMonthly;
DROP TABLE IF EXISTS #StreakSummary;

-- STEP 1: Prepare item-level sales data
SELECT
    DATEFROMPARTS(
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp),
        1
    ) AS sales_month,
    o.order_id,
    oi.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category_name,
    oi.price
INTO #SalesBase
FROM dbo.orders_dataset o
INNER JOIN dbo.order_items_dataset oi
    ON o.order_id = oi.order_id
INNER JOIN dbo.products_dataset p
    ON oi.product_id = p.product_id
LEFT JOIN dbo.product_category_name_translation t
    ON p.product_category_name =
       t.product_category_name
WHERE o.order_purchase_timestamp >= '20170101'
  AND o.order_purchase_timestamp <  '20180901';

-- STEP 2: Monthly category performance
SELECT
    sales_month,
    category_name,
    SUM(price) AS monthly_revenue,
    COUNT(DISTINCT order_id) AS monthly_orders,
    COUNT(*) AS monthly_item_lines
INTO #CategoryMonthly
FROM #SalesBase
GROUP BY
    sales_month,
    category_name;

-- STEP 3: Monthly product performance
SELECT
    sales_month,
    category_name,
    product_id,
    SUM(price) AS product_revenue,
    COUNT(DISTINCT order_id) AS product_orders,
    COUNT(*) AS product_item_lines
INTO #ProductMonthly
FROM #SalesBase
GROUP BY
    sales_month,
    category_name,
    product_id;

-- Quick checks
SELECT COUNT(*) AS category_month_rows
FROM #CategoryMonthly;

SELECT COUNT(*) AS product_month_rows
FROM #ProductMonthly;



-- STEP 4: Compare each month with the previous month
;WITH MonthlyHistory AS (
    SELECT
        *,
        LAG(sales_month) OVER (
            PARTITION BY category_name
            ORDER BY sales_month
        ) AS previous_month,

        LAG(monthly_revenue) OVER (
            PARTITION BY category_name
            ORDER BY sales_month
        ) AS previous_revenue,

        LAG(monthly_orders) OVER (
            PARTITION BY category_name
            ORDER BY sales_month
        ) AS previous_orders
    FROM #CategoryMonthly
),
MonthlyGrowth AS (
    SELECT
        *,
        CASE
            WHEN previous_month IS NOT NULL
             AND DATEDIFF(
                    MONTH, previous_month, sales_month
                 ) = 1
             AND monthly_revenue > previous_revenue
            THEN 1 ELSE 0
        END AS revenue_increased,

        CASE
            WHEN previous_month IS NOT NULL
             AND DATEDIFF(
                    MONTH, previous_month, sales_month
                 ) = 1
             AND monthly_orders > previous_orders
            THEN 1 ELSE 0
        END AS orders_increased,

        100.0 * (monthly_revenue - previous_revenue)
            / NULLIF(previous_revenue, 0)
            AS revenue_growth_pct,

        100.0 * (monthly_orders - previous_orders)
            / NULLIF(previous_orders, 0)
            AS order_growth_pct
    FROM MonthlyHistory
),
StreakGroups AS (
    SELECT
        *,
        SUM(
            CASE WHEN revenue_increased = 0
                 THEN 1 ELSE 0 END
        ) OVER (
            PARTITION BY category_name
            ORDER BY sales_month
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS streak_group
    FROM MonthlyGrowth
),
Streaks AS (
    SELECT
        category_name,
        streak_group,
        MIN(sales_month) AS streak_start_month,
        MAX(sales_month) AS streak_end_month,
        COUNT(*) AS consecutive_increases,
        SUM(orders_increased) AS months_orders_also_increased
    FROM StreakGroups
    WHERE revenue_increased = 1
    GROUP BY
        category_name,
        streak_group
    HAVING COUNT(*) >= 3
)
SELECT
    s.category_name,
    s.streak_start_month,
    s.streak_end_month,
    s.consecutive_increases,
    s.months_orders_also_increased,

    baseline.monthly_revenue AS baseline_revenue,
    ending.monthly_revenue AS ending_revenue,

    ending.monthly_revenue - baseline.monthly_revenue
        AS revenue_increase_amount,

    CAST(
        100.0 * (
            ending.monthly_revenue - baseline.monthly_revenue
        ) / NULLIF(baseline.monthly_revenue, 0)
        AS DECIMAL(10, 2)
    ) AS total_revenue_growth_pct,

    baseline.monthly_orders AS baseline_orders,
    ending.monthly_orders AS ending_orders,

    ending.monthly_orders - baseline.monthly_orders
        AS order_increase_amount,

    CAST(
        100.0 * (
            ending.monthly_orders - baseline.monthly_orders
        ) / NULLIF(baseline.monthly_orders, 0)
        AS DECIMAL(10, 2)
    ) AS total_order_growth_pct,

    CAST(
        100.0 * s.months_orders_also_increased
        / NULLIF(s.consecutive_increases, 0)
        AS DECIMAL(10, 2)
    ) AS pct_of_increases_with_order_growth

INTO #StreakSummary
FROM Streaks s
LEFT JOIN #CategoryMonthly baseline
    ON baseline.category_name = s.category_name
   AND baseline.sales_month =
       DATEADD(MONTH, -1, s.streak_start_month)
LEFT JOIN #CategoryMonthly ending
    ON ending.category_name = s.category_name
   AND ending.sales_month = s.streak_end_month;

-- STEP 5: Review qualifying category streaks
SELECT *
FROM #StreakSummary
ORDER BY
    total_revenue_growth_pct DESC,
    consecutive_increases DESC;

-- STEP 6: Category revenue over each streak
;WITH CategoryStreakRevenue AS (
    SELECT
        s.category_name,
        s.streak_start_month,
        s.streak_end_month,
        SUM(cm.monthly_revenue) AS category_revenue_during_streak
    FROM #StreakSummary s
    INNER JOIN #CategoryMonthly cm
        ON cm.category_name = s.category_name
       AND cm.sales_month BETWEEN
           s.streak_start_month AND s.streak_end_month
    GROUP BY
        s.category_name,
        s.streak_start_month,
        s.streak_end_month
),
ProductContribution AS (
    SELECT
        s.category_name,
        s.streak_start_month,
        s.streak_end_month,
        pm.product_id,

        SUM(pm.product_revenue) AS product_revenue_during_streak,

        COUNT(DISTINCT pm.sales_month) AS months_with_sales,

        DATEDIFF(
            MONTH, s.streak_start_month, s.streak_end_month
        ) + 1 AS total_streak_months,

        cr.category_revenue_during_streak

    FROM #StreakSummary s
    INNER JOIN #ProductMonthly pm
        ON pm.category_name = s.category_name
       AND pm.sales_month BETWEEN
           s.streak_start_month AND s.streak_end_month

    INNER JOIN CategoryStreakRevenue cr
        ON cr.category_name = s.category_name
       AND cr.streak_start_month = s.streak_start_month
       AND cr.streak_end_month = s.streak_end_month

    GROUP BY
        s.category_name,
        s.streak_start_month,
        s.streak_end_month,
        pm.product_id,
        cr.category_revenue_during_streak
),
ConsistentProducts AS (
    SELECT
        *,
        CAST(
            100.0 * months_with_sales
            / NULLIF(total_streak_months, 0)
            AS DECIMAL(10, 2)
        ) AS pct_months_with_sales,

        CAST(
            100.0 * product_revenue_during_streak
            / NULLIF(category_revenue_during_streak, 0)
            AS DECIMAL(10, 2)
        ) AS category_revenue_share_pct

    FROM ProductContribution
    WHERE months_with_sales >=
          CEILING(total_streak_months * 0.70)
),
RankedProducts AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                category_name,
                streak_start_month,
                streak_end_month
            ORDER BY
                product_revenue_during_streak DESC,
                months_with_sales DESC,
                product_id
        ) AS product_rank
    FROM ConsistentProducts
)
SELECT
    category_name,
    streak_start_month,
    streak_end_month,
    product_rank,
    product_id,
    product_revenue_during_streak,
    months_with_sales,
    total_streak_months,
    pct_months_with_sales,
    category_revenue_share_pct
FROM RankedProducts
WHERE product_rank <= 5
ORDER BY
    category_name,
    streak_start_month,
    product_rank;

-- STEP 6: Category revenue over each streak
;WITH CategoryStreakRevenue AS (
    SELECT
        s.category_name,
        s.streak_start_month,
        s.streak_end_month,
        SUM(cm.monthly_revenue) AS category_revenue_during_streak
    FROM #StreakSummary s
    INNER JOIN #CategoryMonthly cm
        ON cm.category_name = s.category_name
       AND cm.sales_month BETWEEN
           s.streak_start_month AND s.streak_end_month
    GROUP BY
        s.category_name,
        s.streak_start_month,
        s.streak_end_month
),
ProductContribution AS (
    SELECT
        s.category_name,
        s.streak_start_month,
        s.streak_end_month,
        pm.product_id,

        SUM(pm.product_revenue) AS product_revenue_during_streak,

        COUNT(DISTINCT pm.sales_month) AS months_with_sales,

        DATEDIFF(
            MONTH, s.streak_start_month, s.streak_end_month
        ) + 1 AS total_streak_months,

        cr.category_revenue_during_streak

    FROM #StreakSummary s
    INNER JOIN #ProductMonthly pm
        ON pm.category_name = s.category_name
       AND pm.sales_month BETWEEN
           s.streak_start_month AND s.streak_end_month

    INNER JOIN CategoryStreakRevenue cr
        ON cr.category_name = s.category_name
       AND cr.streak_start_month = s.streak_start_month
       AND cr.streak_end_month = s.streak_end_month

    GROUP BY
        s.category_name,
        s.streak_start_month,
        s.streak_end_month,
        pm.product_id,
        cr.category_revenue_during_streak
),
ConsistentProducts AS (
    SELECT
        *,
        CAST(
            100.0 * months_with_sales
            / NULLIF(total_streak_months, 0)
            AS DECIMAL(10, 2)
        ) AS pct_months_with_sales,

        CAST(
            100.0 * product_revenue_during_streak
            / NULLIF(category_revenue_during_streak, 0)
            AS DECIMAL(10, 2)
        ) AS category_revenue_share_pct

    FROM ProductContribution
    WHERE months_with_sales >=
          CEILING(total_streak_months * 0.70)
),
RankedProducts AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                category_name,
                streak_start_month,
                streak_end_month
            ORDER BY
                product_revenue_during_streak DESC,
                months_with_sales DESC,
                product_id
        ) AS product_rank
    FROM ConsistentProducts
)
SELECT
    category_name,
    streak_start_month,
    streak_end_month,
    product_rank,
    product_id,
    product_revenue_during_streak,
    months_with_sales,
    total_streak_months,
    pct_months_with_sales,
    category_revenue_share_pct
FROM RankedProducts
WHERE product_rank <= 5
ORDER BY
    category_name,
    streak_start_month,
    product_rank;


    -- STEP 7: Monthly trend data for qualifying streaks
SELECT
    s.category_name,
    s.streak_start_month,
    s.streak_end_month,
    cm.sales_month,
    cm.monthly_revenue,
    cm.monthly_orders,
    cm.monthly_item_lines
FROM #StreakSummary s
INNER JOIN #CategoryMonthly cm
    ON cm.category_name = s.category_name
   AND cm.sales_month BETWEEN
       DATEADD(MONTH, -1, s.streak_start_month)
       AND s.streak_end_month
ORDER BY
    s.category_name,
    cm.sales_month;