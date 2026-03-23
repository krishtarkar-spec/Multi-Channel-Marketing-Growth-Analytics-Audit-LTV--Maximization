SET temp_tablespaces = 'd_drive_temp';

WITH user_revenue AS (
    -- Step 1: Using COUNT(*) since order_id isn't in your schema
    SELECT 
        user_id,
        SUM(CASE WHEN is_refunded = 0 THEN REPLACE(REPLACE(order_value, '$ ', ''), ',', '')::NUMERIC ELSE 0 END) AS net_rev,
        SUM(CASE WHEN is_refunded = 1 THEN REPLACE(REPLACE(order_value, '$ ', ''), ',', '')::NUMERIC ELSE 0 END) AS refund_loss,
        COUNT(*) as order_count
    FROM fact_transactions
    GROUP BY 1
),
channel_totals AS (
    -- Step 2: Bridge to the UTM Source
    SELECT 
        TRIM(UPPER(u.utm_source)) AS channel,
        SUM(r.net_rev) AS total_net_revenue,
        SUM(r.refund_loss) AS total_refund_loss,
        SUM(r.order_count) AS total_orders,
        COUNT(DISTINCT u.user_id) AS total_customers
    FROM dim_users u
    JOIN user_revenue r ON u.user_id = r.user_id
    GROUP BY 1
)
-- Step 3: Final Join with the 50 Campaigns
SELECT 
    s.campaign_id,
    s.utm_source AS channel,
    REPLACE(REPLACE(s.total_spend, '$ ', ''), ',', '')::NUMERIC AS campaign_cost,
    c.total_customers,
    c.total_orders,
    c.total_net_revenue,
    c.total_refund_loss,
    -- Profit & Unit Economics
    (COALESCE(c.total_net_revenue,0) - COALESCE(c.total_refund_loss,0) - REPLACE(REPLACE(s.total_spend, '$ ', ''), ',', '')::NUMERIC) AS total_profit,
    ROUND(((COALESCE(c.total_net_revenue,0) - COALESCE(c.total_refund_loss,0) - REPLACE(REPLACE(s.total_spend, '$ ', ''), ',', '')::NUMERIC) / NULLIF(c.total_net_revenue, 0)) * 100, 2) AS profit_margin_pct,
    ROUND(((COALESCE(c.total_net_revenue,0) - COALESCE(c.total_refund_loss,0) - REPLACE(REPLACE(s.total_spend, '$ ', ''), ',', '')::NUMERIC) / NULLIF(c.total_orders, 0)), 2) AS profit_per_order
FROM fact_marketing_spend s
LEFT JOIN channel_totals c ON TRIM(UPPER(s.utm_source)) = c.channel
ORDER BY total_profit DESC;