SET timezone = 'UTC';
SET temp_tablespaces = 'd_drive_temp';
SET work_mem = '256MB';
SET max_parallel_workers_per_gather = 0;

WITH first_purchase AS (
    SELECT user_id, MIN(DATE_TRUNC('month', order_date::DATE))::DATE AS cohort_month
    FROM fact_transactions
    GROUP BY 1
),
retention_map AS (
    SELECT
        t.user_id,
        f.cohort_month,
        (EXTRACT(year  FROM t.order_date::DATE) - EXTRACT(year  FROM f.cohort_month))::INT * 12 +
        (EXTRACT(month FROM t.order_date::DATE) - EXTRACT(month FROM f.cohort_month))::INT AS month_number
    FROM fact_transactions t
    JOIN first_purchase f ON t.user_id = f.user_id
    WHERE t.is_refunded = 0
),
base AS (
    SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_size
    FROM retention_map
    WHERE month_number = 0
    GROUP BY 1
),
spine AS (
    SELECT b.cohort_month, b.cohort_size, gs.month_number
    FROM base b
    CROSS JOIN LATERAL generate_series(
        0,
        (EXTRACT(year  FROM DATE '2025-12-01') - EXTRACT(year  FROM b.cohort_month))::INT * 12 +
        (EXTRACT(month FROM DATE '2025-12-01') - EXTRACT(month FROM b.cohort_month))::INT
    ) AS gs(month_number)
),
actual AS (
    SELECT cohort_month, month_number, COUNT(DISTINCT user_id) AS retained_users
    FROM retention_map
    GROUP BY 1, 2
)
SELECT
    s.cohort_month,
    s.month_number,
    s.cohort_size,
    COALESCE(a.retained_users, 0)                                   AS retained_users,
    ROUND(100.0 * COALESCE(a.retained_users, 0) / s.cohort_size, 2) AS retention_rate
FROM spine s
LEFT JOIN actual a
       ON a.cohort_month = s.cohort_month
      AND a.month_number = s.month_number
ORDER BY 1, 2;
