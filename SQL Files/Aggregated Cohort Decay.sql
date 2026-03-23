-- VERSION 1: AGGREGATED COHORT
WITH first_purchase AS (
    SELECT user_id, MIN(DATE_TRUNC('month', order_date)) as cohort_month
    FROM fact_transactions
    GROUP BY 1
),
retention_map AS (
    SELECT 
        t.user_id,
        f.cohort_month,
        (EXTRACT(year FROM t.order_date) - EXTRACT(year FROM f.cohort_month)) * 12 +
        (EXTRACT(month FROM t.order_date) - EXTRACT(month FROM f.cohort_month)) as month_number
    FROM fact_transactions t
    JOIN first_purchase f ON t.user_id = f.user_id
    WHERE t.is_refunded = 0 -- Excluding refunds to show "True" retention
)
SELECT 
    cohort_month,
    month_number,
    COUNT(DISTINCT user_id) as retained_users,
    -- Added retention_rate calculation here:
    ROUND(
        COUNT(DISTINCT user_id)::numeric / 
        FIRST_VALUE(COUNT(DISTINCT user_id)) OVER (PARTITION BY cohort_month ORDER BY month_number) * 100, 
        2
    ) as retention_rate
FROM retention_map
WHERE month_number <= 24
GROUP BY 1, 2
ORDER BY 1, 2;