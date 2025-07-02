{{ config(
    materialized='table',
    schema='marts_product'
) }}

-- This mart provides a comprehensive summary of engagement, sales, and refund metrics
-- for the 'Google Tee Yellow' product (item_id: GGOEGXXX0905).
-- It joins `stg_ga4_items` with `stg_ga4_events_base` to get transaction details.

WITH product_data AS (
    SELECT
        items.event_name,
        items.user_pseudo_id,
        items.item_id,
        items.item_name,
        COALESCE(NULLIF(items.item_brand, '(not set)'), 'Unknown') AS item_brand, -- Normalized brand of product
        CASE
           WHEN REGEXP_CONTAINS(LOWER(items.item_category), r'(home|homme).*sale') THEN 'Home/Sale'
           WHEN LOWER(items.item_category) = 'sale' THEN 'Sale'
           ELSE 'Other'
        END AS item_category, -- Primary category of the product but without the backslash 
        items.quantity,
        items.item_price_usd,
        items.item_revenue_usd,
        items.item_refund_usd,
        events.ecommerce_transaction_id
    FROM
        {{ ref('stg_ga4_items') }} AS items
    INNER JOIN
        {{ ref('stg_ga4_events_base') }} AS events
        ON items.event_timestamp = events.event_timestamp
        AND items.user_pseudo_id = events.user_pseudo_id
        AND items.event_name = events.event_name -- Joining on event_name too for stricter match
    WHERE
        items.item_id = 'GGOEGXXX0905'
        AND items.event_name IN (
            'view_item',
            'select_item',
            'add_to_cart',
            'remove_from_cart',
            'begin_checkout',
            'add_shipping_info',
            'add_payment_info',
            'purchase',
            'refund'
        )
),
WITH product_performance_metrics AS (
SELECT
    -- Product Identifiers
    item_id,
    item_name,
    item_brand,
    item_category,

    -- Engagement Metrics: Counts based on specific event types
    COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id END) AS unique_viewers,
    COUNT(CASE WHEN event_name = 'view_item' THEN 1 END) AS total_item_views,
    COUNT(DISTINCT CASE WHEN event_name = 'select_item' THEN user_pseudo_id END) AS unique_selectors,
    COUNT(CASE WHEN event_name = 'select_item' THEN 1 END) AS total_item_selections,
    COUNT(CASE WHEN event_name = 'add_to_cart' THEN 1 END) AS total_adds_to_cart,
    COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_pseudo_id END) AS unique_add_to_cart_users,
    COUNT(CASE WHEN event_name = 'begin_checkout' THEN 1 END) AS total_begin_checkouts,
    COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN user_pseudo_id END) AS unique_begin_checkout_users,
    COUNT(CASE WHEN event_name = 'add_shipping_info' THEN 1 END) AS total_add_shipping_info,
    COUNT(CASE WHEN event_name = 'add_payment_info' THEN 1 END) AS total_add_payment_info,
    COUNT(CASE WHEN event_name = 'remove_from_cart' THEN 1 END) AS total_removes_from_cart,

    -- Purchase Metrics
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN ecommerce_transaction_id END) AS total_unique_purchases, 
    SUM(CASE WHEN event_name = 'purchase' THEN quantity ELSE 0 END) AS total_units_sold,
    SUM(CASE WHEN event_name = 'purchase' THEN item_revenue_usd ELSE 0 END) AS total_purchase_revenue_usd,
    AVG(CASE WHEN event_name = 'purchase' THEN item_price_usd END) AS average_selling_price_usd,

     -- Refund Metrics: Now based on item_refund_usd > 0, regardless of event_name
    SUM(CASE WHEN item_refund_usd IS NOT NULL AND item_refund_usd > 0 THEN item_refund_usd ELSE 0 END) AS total_refund_amount_usd,
    COUNT(DISTINCT CASE WHEN item_refund_usd IS NOT NULL AND item_refund_usd > 0 THEN ecommerce_transaction_id END) AS total_unique_refund_transactions
FROM
    product_data
GROUP BY
    item_id,
    item_name,
    item_brand,
    item_category
)
SELECT * FROM product_performance_metrics;

