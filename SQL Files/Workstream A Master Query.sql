-- ============================================================
-- WORKSTREAM A -- MASTER QUERY (v3)
-- Grain: campaign_id x region x month
-- This is the single table Power BI feeds on.
-- ============================================================
SET temp_tablespaces = 'd_drive_temp';
SET work_mem = '256MB';
SET max_parallel_workers_per_gather = 0;

WITH txn AS (
    SELECT
        t.user_id, t.order_date, t.is_refunded, t.category,
        REPLACE(REPLACE(t.order_value,   '$ ', ''), ',', '')::NUMERIC AS order_value,
        REPLACE(REPLACE(t.unit_cost,     '$ ', ''), ',', '')::NUMERIC AS unit_cost,
        REPLACE(REPLACE(t.shipping_cost, '$ ', ''), ',', '')::NUMERIC AS shipping_cost,
        u.campaign_id, u.utm_source AS channel, u.region
    FROM fact_transactions t
    JOIN dim_users u ON u.user_id = t.user_id
),
-- Revenue side, by activity month
rev AS (
    SELECT
        campaign_id, channel, region,
        DATE_TRUNC('month', order_date)::DATE                          AS month,
        COUNT(*)                                                       AS orders,
        COUNT(*) FILTER (WHERE is_refunded = 1)                        AS refunded_orders,
        COUNT(DISTINCT user_id)                                        AS active_customers,
        SUM(order_value)               FILTER (WHERE is_refunded = 0)  AS net_revenue,
        SUM(order_value)               FILTER (WHERE is_refunded = 1)  AS refund_leakage,
        SUM(order_value - unit_cost)   FILTER (WHERE is_refunded = 0)  AS gross_margin,
        SUM(shipping_cost)             FILTER (WHERE is_refunded = 0)  AS shipping_cost
    FROM txn
    GROUP BY 1,2,3,4
),
-- Spend side, natively at campaign x region x month
spd AS (
    SELECT
        campaign_id, utm_source AS channel, region,
        DATE_TRUNC('month', date)::DATE                                AS month,
        SUM(REPLACE(REPLACE(total_spend, '$ ', ''), ',', '')::NUMERIC) AS marketing_spend,
        SUM(impressions)                                               AS impressions,
        SUM(clicks)                                                    AS clicks
    FROM fact_marketing_spend
    GROUP BY 1,2,3,4
),
-- New signups, by SIGNUP month (acquisition, not activity)
acq AS (
    SELECT
        campaign_id, utm_source AS channel, region,
        DATE_TRUNC('month', signup_timestamp)::DATE                    AS month,
        COUNT(*)                                                       AS new_users
    FROM dim_users
    GROUP BY 1,2,3,4
)
SELECT
    COALESCE(s.campaign_id, r.campaign_id, a.campaign_id)              AS campaign_id,
    COALESCE(s.channel, r.channel, a.channel)                          AS channel,
    COALESCE(s.region, r.region, a.region)                             AS region,
    COALESCE(s.month, r.month, a.month)                                AS month,
    EXTRACT(YEAR  FROM COALESCE(s.month, r.month, a.month))::INT       AS fiscal_year,
    EXTRACT(MONTH FROM COALESCE(s.month, r.month, a.month))::INT       AS month_number,

    -- VOLUME
    COALESCE(a.new_users, 0)                                           AS new_users,
    COALESCE(r.active_customers, 0)                                    AS active_customers,
    COALESCE(r.orders, 0)                                              AS orders,
    COALESCE(s.impressions, 0)                                         AS impressions,
    COALESCE(s.clicks, 0)                                              AS clicks,

    -- MONEY
    ROUND(COALESCE(r.net_revenue, 0), 2)                               AS net_revenue,
    ROUND(COALESCE(r.refund_leakage, 0), 2)                            AS refund_leakage,
    ROUND(COALESCE(r.gross_margin, 0), 2)                              AS gross_margin,
    ROUND(COALESCE(s.marketing_spend, 0), 2)                           AS marketing_spend,
    ROUND(COALESCE(r.gross_margin, 0) - COALESCE(r.shipping_cost, 0)
          - COALESCE(s.marketing_spend, 0), 2)                         AS contribution_profit,

    -- RATIOS (recompute in DAX when aggregating; these are per-row only)
    ROUND(COALESCE(r.net_revenue,0) / NULLIF(s.marketing_spend,0), 2)  AS roas,
    ROUND(COALESCE(s.marketing_spend,0) / NULLIF(a.new_users,0), 2)    AS cac,
    ROUND(100.0 * COALESCE(r.gross_margin,0)
          / NULLIF(r.net_revenue,0), 2)                                AS gross_margin_pct,
    ROUND(100.0 * COALESCE(r.refunded_orders,0)
          / NULLIF(r.orders,0), 2)                                     AS refund_rate_pct,
    ROUND(COALESCE(r.net_revenue,0)
          / NULLIF(r.active_customers,0), 2)                           AS revenue_per_customer
FROM       spd s
FULL JOIN  rev r ON r.campaign_id = s.campaign_id AND r.region = s.region AND r.month = s.month
FULL JOIN  acq a ON a.campaign_id = COALESCE(s.campaign_id, r.campaign_id)
                AND a.region      = COALESCE(s.region, r.region)
                AND a.month       = COALESCE(s.month, r.month)
ORDER BY campaign_id, region, month;
