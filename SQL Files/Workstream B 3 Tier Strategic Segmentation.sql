-- WORKSTREAM B: 3-TIER STRATEGIC SEGMENTATION
-- Uses your D: drive for the heavy lifting
SET temp_tablespaces = 'd_drive_temp';

WITH user_behavior AS (
    SELECT 
        user_id,
        SUM(REPLACE(REPLACE(order_value, '$ ', ''), ',', '')::NUMERIC) AS gross_ltv,
        AVG(CASE WHEN is_refunded = 1 THEN 1.0 ELSE 0.0 END) AS refund_rate
    FROM fact_transactions 
    GROUP BY 1
),
tiered_users AS (
    SELECT 
        u.user_id, 
        u.region,
        CASE 
            WHEN b.gross_ltv > 7000 AND b.refund_rate < 0.1 THEN 'Platinum Whale'
            WHEN b.refund_rate > 0.4 THEN 'Margin Drainer (At-Risk)'
            ELSE 'Steady Grower'
        END AS segment
    FROM dim_users u
    JOIN user_behavior b ON u.user_id = b.user_id
)
SELECT 
    s.region,
    s.segment,
    EXTRACT(YEAR FROM t.order_date) AS fiscal_year,
    COUNT(DISTINCT t.user_id) AS active_customer_count,
    ROUND(SUM(REPLACE(REPLACE(t.order_value, '$ ', ''), ',', '')::NUMERIC), 2) AS net_revenue
FROM fact_transactions t
JOIN tiered_users s ON t.user_id = s.user_id
WHERE t.is_refunded = 0
GROUP BY 1, 2, 3
ORDER BY 1, 3, 5 DESC;