{{ config(
    materialized='table',
    schema='marts_product'
) }}

-- This mart identifies and ranks other items that are frequently purchased
-- in the same transaction as 'Google Tee Yellow' (item_id: GGOEGXXX0905).
-- It joins `stg_ga4_items` with `stg_ga4_events_base` to correctly
-- access the `transaction_id` from the top-level ecommerce record.

WITH purchase_events_with_items AS (
    SELECT
        items.event_timestamp,
        items.event_name,
        items.user_pseudo_id,
        items.item_id,
        items.item_name,
        items.quantity,
        items.item_revenue_usd,
        events.ecommerce_transaction_id
    FROM
        {{ ref('stg_ga4_items') }} AS items
    INNER JOIN
        {{ ref('stg_ga4_events_base') }} AS events
        ON items.event_timestamp = events.event_timestamp
        AND items.user_pseudo_id = events.user_pseudo_id
        AND items.event_name = events.event_name -- Match events strictly
    WHERE
        items.event_name = 'purchase' -- Only consider purchase events
        AND events.ecommerce_transaction_id IS NOT NULL -- Ensure a valid transaction ID exists
),
google_tee_transactions AS (
    SELECT DISTINCT ecommerce_transaction_id AS transaction_id
    FROM
        purchase_events_with_items
    WHERE
        item_id = 'GGOEGXXX0905' -- Filtered the target item
),
all_items_in_these_transactions AS (
    SELECT
        t.ecommerce_transaction_id AS transaction_id,
        t.item_id,
        t.item_name,
        t.quantity AS item_quantity,
        t.item_revenue_usd AS item_revenue_in_usd
    FROM
        purchase_events_with_items AS t
    INNER JOIN
        google_tee_transactions AS gtt
        ON t.ecommerce_transaction_id = gtt.transaction_id
)
SELECT
    item_id,
    item_name,
    COUNT(DISTINCT transaction_id) AS number_of_transactions_co_purchased,
    SUM(item_quantity) AS total_quantity_co_purchased,
    SUM(item_revenue_in_usd) AS total_revenue_co_purchased_usd
FROM
    all_items_in_these_transactions
WHERE
    item_id != 'GGOEGXXX0905' -- Excluded 'Google Tee Yellow' from the co-purchased list
GROUP BY
    item_id,
    item_name
ORDER BY
    number_of_transactions_co_purchased DESC
LIMIT 10;

