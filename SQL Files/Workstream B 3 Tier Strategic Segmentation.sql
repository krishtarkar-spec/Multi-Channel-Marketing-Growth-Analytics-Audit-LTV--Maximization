-- ============================================================
-- WORKSTREAM B: 3-TIER STRATEGIC SEGMENTATION 
SET timezone = 'UTC';
SET temp_tablespaces = 'd_drive_temp';
SET work_mem = '256MB';
SET max_parallel_workers_per_gather = 0;

WITH txn AS (
    SELECT
        user_id, order_date, is_refunded,
        REPLACE(REPLACE(order_value, '$ ', ''), ',', '')::NUMERIC AS order_value,
        REPLACE(REPLACE(unit_cost,   '$ ', ''), ',', '')::NUMERIC AS unit_cost
    FROM fact_transactions
),
user_behavior AS (
    SELECT
        user_id,
        COUNT(*) FILTER (WHERE is_refunded = 0)                     AS net_orders,
        SUM(order_value)             FILTER (WHERE is_refunded = 0) AS net_ltv,
        SUM(order_value - unit_cost) FILTER (WHERE is_refunded = 0) AS margin_ltv,
        AVG(is_refunded::NUMERIC)                                   AS refund_rate
    FROM txn
    GROUP BY 1
),
tiered_users AS (
    SELECT
        b.user_id,
        u.region,
        CASE
            WHEN NTILE(10) OVER (ORDER BY COALESCE(b.margin_ltv, 0) DESC) = 1  THEN 'Platinum Whale'
            WHEN NTILE(10) OVER (ORDER BY COALESCE(b.margin_ltv, 0) DESC) <= 4 THEN 'Steady Grower'
            ELSE 'Low-Value / Dormant'
        END                                                         AS segment,
        (PERCENT_RANK() OVER (ORDER BY b.refund_rate DESC) <= 0.15) AS is_at_risk
    FROM user_behavior b
    JOIN dim_users u ON u.user_id = b.user_id
),
agg AS (
    SELECT
        s.region,
        s.segment,
        EXTRACT(YEAR FROM t.order_date)::INT                               AS fiscal_year,
        COUNT(DISTINCT t.user_id)                                          AS active_customers,
        COUNT(DISTINCT t.user_id) FILTER (WHERE s.is_at_risk)              AS at_risk_customers,
        COUNT(*)                                                           AS orders,
        COUNT(*) FILTER (WHERE t.is_refunded = 1)                          AS refunded_orders,
        SUM(t.order_value)               FILTER (WHERE t.is_refunded = 0)  AS net_revenue,
        SUM(t.order_value - t.unit_cost) FILTER (WHERE t.is_refunded = 0)  AS gross_margin_dollars,
        SUM(t.order_value)               FILTER (WHERE t.is_refunded = 1)  AS refund_leakage
    FROM txn t
    JOIN tiered_users s ON s.user_id = t.user_id
    GROUP BY 1, 2, 3
)
SELECT
    region, segment, fiscal_year,
    active_customers, at_risk_customers, orders,
    ROUND(net_revenue, 2)                                              AS net_revenue,
    ROUND(gross_margin_dollars, 2)                                     AS gross_margin_dollars,
    ROUND(refund_leakage, 2)                                           AS refund_leakage,
    ROUND(100.0 * gross_margin_dollars / NULLIF(net_revenue, 0), 2)    AS gross_margin_pct,
    ROUND(100.0 * refunded_orders / NULLIF(orders, 0), 2)              AS refund_rate_pct,
    ROUND(net_revenue / NULLIF(active_customers, 0), 2)                AS revenue_per_customer,
    ROUND(100.0 * net_revenue
          / NULLIF(SUM(net_revenue) OVER (PARTITION BY region, fiscal_year), 0), 2)
                                                                       AS pct_of_region_year,
    ROUND(100.0 * net_revenue
          / NULLIF(SUM(net_revenue) OVER (), 0), 2)                    AS pct_of_total
FROM agg
ORDER BY region, fiscal_year, net_revenue DESC;
