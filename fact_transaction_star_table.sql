CREATE TABLE fact_transactions_star AS
SELECT
    t.*,
    u.campaign_id,
    u.region,
    u.utm_source AS channel
FROM fact_transactions t
JOIN dim_users u ON u.user_id = t.user_id;