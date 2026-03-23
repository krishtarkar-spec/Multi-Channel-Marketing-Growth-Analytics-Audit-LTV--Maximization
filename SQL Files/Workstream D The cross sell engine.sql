-- WORKSTREAM D: THE CROSS-SELL ENGINE
SET temp_tablespaces = 'd_drive_temp';

WITH purchase_sequence AS (
    SELECT 
        user_id,
        category,
        order_date,
        RANK() OVER (PARTITION BY user_id ORDER BY order_date ASC) as purchase_number
    FROM fact_transactions
)
SELECT 
    p1.category as first_purchase,
    p2.category as second_purchase,
    COUNT(DISTINCT p1.user_id) as customer_count
FROM purchase_sequence p1
JOIN purchase_sequence p2 ON p1.user_id = p2.user_id
WHERE p1.purchase_number = 1 
  AND p2.purchase_number = 2
GROUP BY 1, 2
ORDER BY 3 DESC;