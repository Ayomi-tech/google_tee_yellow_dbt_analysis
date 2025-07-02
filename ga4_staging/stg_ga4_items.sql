{{ config(
    materialized='view',
    schema='staging_ga4'
) }}

SELECT
    CONCAT(SUBSTRING(event_date, 1, 4) || '-', SUBSTRING(event_date, 5, 2), '-', SUBSTRING(event_date, 7, 2)) AS event_date,
    event_timestamp,
    event_name,
    user_pseudo_id,
    ecommerce.transaction_id AS transaction_id,

    items.item_id,
    items.item_name,
    COALESCE(NULLIF(items.item_brand, '(not set)'), 'Unknown') AS item_brand, -- Normalized brand of product
    items.item_variant,
    CASE
           WHEN REGEXP_CONTAINS(LOWER(items.item_category), r'(home|homme).*sale') THEN 'Home/Sale'
           WHEN LOWER(items.item_category) = 'sale' THEN 'Sale'
           ELSE 'Other'
        END AS item_category, -- Primary category of the product but without the backslash 
    items.item_category2,
    items.item_category3,
    items.item_category4,
    items.item_category5,
    items.price_in_usd AS item_price_usd,
    items.price AS item_price_local_currency,
    items.quantity,
    items.item_revenue_in_usd AS item_revenue_usd,
    items.item_revenue AS item_revenue_local_currency,
    items.item_refund_in_usd AS item_refund_usd,
    items.item_refund AS item_refund_local_currency,
    items.coupon,
    items.affiliation,
    items.discount,
    items.location_id,
    items.item_list_id,
    items.item_list_name,
    items.promotion_id,
    items.promotion_name

FROM
    -- Reference the 'events' table from the 'ga4_raw' source
    {{ source('ga4_raw', 'events') }} AS t,
    UNNEST(t.items) AS items

