
-- This below query identifies and ranks other items that are frequently purchased
-- in the same transaction as 'Google Tee Yellow' (item_id: GGOEGXXX0905).

-- CTE: google_tee_transactions
-- purpose: Identifies all unique transaction IDs where the 'Google Tell Yellow' was part
-- od a purchase event. 

WITH google_tee_transactions AS (
SELECT 
      DISTINCT t.ecommerce.transaction_id AS ecommerce_transaction_id    -- Referencing transaction_id from ecommerce nested data
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131` AS t,
UNNEST(items) AS items
WHERE 
     event_name = 'purchase'
     AND items.item_id = 'GGOEGXXX0905' -- Filtering the targeted item id
     AND t.ecommerce.transaction_id IS NOT NULL -- Ensuring a valid transaction ID exits
),
-- CTE: all_items_in_these_transations
-- purpose: Retrives all items (including 'Google Tee Yellow' itself)that were part of the
-- purchase transactions indentified in the 'google_tee_transaction' CTE
-- This is done by joining back to the raw events table on transaction_id


all_items_in_these_transactions AS (
SELECT
      t.ecommerce.transaction_id AS ecommerce_transaction_id,
      items.item_id,
      items.item_name,
      items.quantity AS item_quantity,
      items.item_revenue_in_usd AS item_revenue_in_usd
      
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`  AS t,
UNNEST(items) AS items     
INNER JOIN google_tee_transactions AS gtt
    ON t.ecommerce.transaction_id = gtt.ecommerce_transaction_id
WHERE
     t.event_name = 'purchase' ---- Checking for purchase events 
)
-- Final SELECT statement: Aggregates the co-purchased items, excluding the target product itself
-- And ranking them by now many transactions they appeared in alongside 'google Tee Yellow'
SELECT 
      item_id,
      item_name,
      COUNT(DISTINCT ecommerce_transaction_id) AS number_of_transaction_co_purchased,
      SUM(item_quantity) AS total_quantity_co_purchased,
      SUM(item_revenue_in_usd) AS total_revenue_co_purchased_usd

FROM all_items_in_these_transactions
WHERE
     item_id != 'GGOEGXXX0905' -- Excluded 'Google Tell Yellow' from the co-purchased list

GROUP BY 
       item_id,
       item_name
ORDER BY 
       number_of_transaction_co_purchased DESC
LIMIT 10 ;      

