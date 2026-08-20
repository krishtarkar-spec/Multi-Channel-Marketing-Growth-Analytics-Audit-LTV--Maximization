DROP TABLE IF EXISTS mart_category_pricetier;
-- WORKSTREAM E
CREATE TABLE mart_category_pricetier AS
SELECT
    region,
    EXTRACT(YEAR FROM order_date)::INT                                        AS fiscal_year,
    category,
    CASE
        WHEN order_value < 50  THEN '1. Budget (<$50)'
        WHEN order_value < 200 THEN '2. Mid-Range ($50-200)'
        ELSE                        '3. Premium (>$200)'
    END                                                                       AS price_tier,
    COUNT(*)                                                                  AS total_orders,
    COUNT(*) FILTER (WHERE is_refunded = 1)                                   AS refunded_orders,
    ROUND(COALESCE(SUM(order_value) FILTER (WHERE is_refunded = 1), 0), 2)    AS lost_revenue,
    ROUND(COALESCE(SUM(order_value) FILTER (WHERE is_refunded = 0), 0), 2)    AS net_revenue,
    ROUND(COALESCE(SUM(order_value - unit_cost)
          FILTER (WHERE is_refunded = 0), 0), 2)                              AS gross_margin,
    ROUND(AVG(order_value), 2)                                                AS avg_order_value
FROM fact_transactions_star
GROUP BY 1, 2, 3, 4;
