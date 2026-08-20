-- WORKSTREAM C: OPERATIONAL EFFICIENCY & RECOVERY SIMULATION
SET temp_tablespaces = 'd_drive_temp';

SELECT 
    u.region,
    t.category,
    EXTRACT(YEAR FROM t.order_date) AS fiscal_year,
    -- Scale Metric
    SUM(REPLACE(REPLACE(t.order_value, '$ ', ''), ',', '')::NUMERIC) AS total_gross_revenue,
    -- Leakage Metric (The "Problem")
    SUM(CASE WHEN t.is_refunded = 1 THEN REPLACE(REPLACE(t.order_value, '$ ', ''), ',', '')::NUMERIC ELSE 0 END) AS refund_leakage,
    -- Efficiency Metric (The "Why")
    ROUND(AVG(CASE WHEN t.is_refunded = 1 THEN 1.0 ELSE 0.0 END) * 100, 2) AS refund_rate_percentage,
    -- The FAANG Recommendation (The "Solution")
    -- Simulating a 25% reduction in leakage via policy optimization
    ROUND(SUM(CASE WHEN t.is_refunded = 1 THEN REPLACE(REPLACE(t.order_value, '$ ', ''), ',', '')::NUMERIC ELSE 0 END) * 0.25, 2) AS projected_profit_recovery
FROM fact_transactions t
JOIN dim_users u ON t.user_id = u.user_id
GROUP BY 1, 2, 3
ORDER BY 5 DESC;
