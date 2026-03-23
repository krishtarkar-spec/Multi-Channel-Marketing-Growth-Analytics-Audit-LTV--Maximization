-- WORKSTREAM E: PRICE SENSITIVITY & REFUND TRIGGERS
SET temp_tablespaces = 'd_drive_temp';

SELECT 
    category,
    CASE 
        WHEN REPLACE(REPLACE(order_value, '$ ', ''), ',', '')::NUMERIC < 50 THEN '1. Budget (<$50)'
        WHEN REPLACE(REPLACE(order_value, '$ ', ''), ',', '')::NUMERIC BETWEEN 50 AND 200 THEN '2. Mid-Range ($50-200)'
        ELSE '3. Premium (>$200)'
    END AS price_tier,
    COUNT(*) as total_orders,
    ROUND(AVG(CASE WHEN is_refunded = 1 THEN 1.0 ELSE 0.0 END) * 100, 2) as refund_rate_pct,
    SUM(CASE WHEN is_refunded = 1 THEN REPLACE(REPLACE(order_value, '$ ', ''), ',', '')::NUMERIC ELSE 0 END) as lost_revenue
FROM fact_transactions
GROUP BY 1, 2
ORDER BY 1, 2;