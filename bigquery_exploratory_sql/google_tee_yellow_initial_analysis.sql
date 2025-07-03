
-- The below query analyse the product name: 'Google Tee Yellow' (item_id: GGOEGXXX0905) by calculating its key engagement and purchase.

-- CTE: flattened_items
-- Purpose: The Coomo Table Expression (CTE) is the first step. it flattens the nested 'items' array from the GA4 event data, 
-- so each row represent target product and relevant e-commerce event types, which signigicantly query performance. 


WITH flattened_items AS (
SELECT 
       CONCAT(SUBSTRING(event_date, 1, 4) || '-', SUBSTRING(event_date, 5, 2), '-', SUBSTRING(event_date, 7, 2)) AS event_date,
       event_name, 
       user_pseudo_id,                     -- Pseudonymous identifier for a user
       geo.country AS user_country,        -- Country of the user
       device.category AS device_category, -- Device type (mobile, desktop, tablet)
       traffic_source.source AS traffic_source_platform, -- Source of the user's traffic
       ecommerce.transaction_id AS ecommerce_transaction_id,           -- Unique ID for purchase transactions
       items.item_id,                      -- Unique identifier for the product
       items.item_name,                    -- Name of product
       COALESCE(NULLIF(items.item_brand, '(not set)'), 'Unknown') AS item_brand, -- Normalized brand of product
       CASE
           WHEN REGEXP_CONTAINS(LOWER(items.item_category), r'(home|homme).*sale') THEN 'Home/Sale'
           WHEN LOWER(items.item_category) = 'sale' THEN 'Sale'
           ELSE 'Other'
        END AS item_category, -- Primary category of the product but without the backslash 
       items.price_in_usd AS item_price_usd, -- Price of a single unit of the item (at the time of event)
       items.quantity AS item_quatity_in_event, -- Quantity of this item in the specific event
       items.item_revenue_in_usd AS item_revenue_event_usd, -- Revenue for the item in the event (e.g, for purchase)
       items.item_refund_in_usd AS item_refund_usd

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131` AS t,
UNNEST(t.items) AS items --UNNEST is used for accessing individual elments within nested record('items')
WHERE items.item_id = 'GGOEGXXX0905'
AND event_name IN (
  'view_item',         -- When a user views a product's details page
  'select_item',       -- When a user select a product from a list/search results
  'add_to_cart',       -- When a user adds a producct to their cart
  'begin_checkout',    -- When a user starts the checkput process
  'add_shipping_info', -- When a user adds shipping information during checkout
  'add_payment_info',  -- When a user adds payment information during checkout
  'purchase'           -- When a user completes a purchase
   )
),
product_performance_metrics AS (
  SELECT 
        item_id,
        item_name,
        item_brand,
        item_category,

        -- Engagement Metrics: Count based on specific vent types
        COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id END) AS unique_viewers,
        COUNT(CASE WHEN event_name = 'view_item' THEN 1 END) AS total_item_views,
        COUNT(DISTINCT CASE WHEN event_name = 'select_item' THEN user_pseudo_id END) AS unique_selectors,
        COUNT(CASE WHEN event_name = 'select_item' THEN 1 END) AS total_item_selections,
        COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_pseudo_id END) AS unique_add_to_cart_users,
        COUNT(CASE WHEN event_name = 'add_to_cart' THEN 1 END) AS total_add_to_cart,
        ROUND((SUM(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) * 100.0 
         / NULLIF(SUM(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END), 0)),2) AS add_to_cart_rate,
        COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN user_pseudo_id END) AS unique_begin_checkouts_users,
        COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN 1 END) AS total_degin_checkouts,
        COUNT(CASE WHEN event_name = 'add_shipping_info' THEN 1 END) AS total_add_shipping_info,
        COUNT(CASE WHEN event_name = 'add_payment_info' THEN 1 END) AS total_add_payment_info,
        COUNT(CASE WHEN event_name = 'remove_from_cart' THEN 1 END) AS total_remove_from_cart,

        -- Purchase Metrics: Calculations based on 'purchase' events
        COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN ecommerce_transaction_id END) AS total_unique_purchase,
        SUM(CASE WHEN event_name = 'purchase' THEN item_quatity_in_event ELSE 0 END) AS total_units_sold,
        SUM(CASE WHEN event_name = 'purchase' THEN item_revenue_event_usd ELSE 0 END) AS total_purchase_revenue_usd,
        AVG(CASE WHEN event_name = 'purchase' THEN item_price_usd END) AS average_selling_price_usd,

        -- Refund Metrics: Now based on item_refund_usd > 0, regardless of event_name
    SUM(CASE WHEN item_refund_usd IS NOT NULL AND item_refund_usd > 0 THEN item_refund_usd ELSE 0 END) AS total_refund_amount_usd,
    COUNT(DISTINCT CASE WHEN item_refund_usd IS NOT NULL AND item_refund_usd > 0 THEN ecommerce_transaction_id END) AS total_unique_refund_transactions

  FROM flattened_items
  GROUP BY 
      item_id,
      item_name,
      item_brand,
      item_category
)
SELECT *
FROM product_performance_metrics ;







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






















