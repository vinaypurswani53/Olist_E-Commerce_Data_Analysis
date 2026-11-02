WITH OrderStages AS
(
    -- One row per order, containing all four timestamps
    SELECT
        order_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date
    FROM orders_dataset
    WHERE order_status = 'delivered'
),

StageDurations AS
(
    -- Convert the three fulfilment stages into individual rows
    SELECT
        os.order_id,
        s.stage_name,

        DATEDIFF_BIG(
            SECOND,
            s.start_timestamp,
            s.end_timestamp
        ) / 86400.0 AS elapsed_days

    FROM OrderStages os

    CROSS APPLY
    (
        VALUES
        (
            'Purchase to Approval',
            os.order_purchase_timestamp,
            os.order_approved_at
        ),
        (
            'Approval to Carrier',
            os.order_approved_at,
            os.order_delivered_carrier_date
        ),
        (
            'Carrier to Customer',
            os.order_delivered_carrier_date,
            os.order_delivered_customer_date
        )
    ) s(stage_name, start_timestamp, end_timestamp)

    WHERE s.start_timestamp IS NOT NULL
      AND s.end_timestamp IS NOT NULL
      AND s.end_timestamp >= s.start_timestamp
),

StagePercentiles AS
(
    SELECT
        stage_name,

        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY elapsed_days)
        OVER (PARTITION BY stage_name) AS median_days,

        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY elapsed_days)
        OVER (PARTITION BY stage_name) AS p90_days,

        PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY elapsed_days)
        OVER (PARTITION BY stage_name) AS p95_days

    FROM StageDurations
),

StageSummary AS
(
    SELECT
        stage_name,
        COUNT(*) AS total_orders,
        AVG(elapsed_days) AS average_days,
        MIN(elapsed_days) AS minimum_days,
        MAX(elapsed_days) AS maximum_days

    FROM StageDurations
    GROUP BY stage_name
)

SELECT
    ss.stage_name,
    ss.total_orders,

    ROUND(ss.average_days, 2) AS average_days,
    ROUND(MAX(sp.median_days), 2) AS median_days,
    ROUND(MAX(sp.p90_days), 2) AS p90_days,
    ROUND(MAX(sp.p95_days), 2) AS p95_days,

    ROUND(ss.maximum_days, 2) AS maximum_days

FROM StageSummary ss

INNER JOIN StagePercentiles sp
    ON ss.stage_name = sp.stage_name

GROUP BY
    ss.stage_name,
    ss.total_orders,
    ss.average_days,
    ss.maximum_days

ORDER BY
    median_days DESC;
