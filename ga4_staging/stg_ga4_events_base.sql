{{ config(
    materialized='view', -- Materialized as a view for direct access to core event data without storage cost
    schema='staging_ga4' -- Defined a new schema for staging models
) }}

SELECT
    CONCAT(SUBSTRING(event_date, 1, 4) || '-', SUBSTRING(event_date, 5, 2), '-', SUBSTRING(event_date, 7, 2)) AS event_date
    event_timestamp,
    event_name,
    event_previous_timestamp,
    event_value_in_usd,
    event_bundle_sequence_id,
    event_server_timestamp_offset,

    user_id,
    user_pseudo_id,

    device.category AS device_category,
    device.mobile_brand_name AS device_mobile_brand_name,
    device.mobile_model_name AS device_mobile_model_name,
    device.operating_system AS device_operating_system,
    device.operating_system_version AS device_operating_system_version,
    device.language AS device_language,
    device.is_limited_ad_tracking AS device_is_limited_ad_tracking,
    device.web_info.browser AS device_browser,
    device.web_info.browser_version AS device_browser_version,

    geo.continent AS geo_continent,
    geo.country AS geo_country,
    geo.region AS geo_region,
    geo.city AS geo_city,
    geo.sub_continent AS geo_sub_continent,
    geo.metro AS geo_metro,

    traffic_source.source AS traffic_source_source,
    traffic_source.medium AS traffic_source_medium,
    traffic_source.name AS traffic_source_name,
    traffic_source.platform AS traffic_source_platform,

    ecommerce.total_item_quantity AS ecommerce_total_item_quantity,
    ecommerce.purchase_revenue_in_usd AS ecommerce_purchase_revenue_in_usd,
    ecommerce.refund_value_in_usd AS ecommerce_refund_value_in_usd,
    ecommerce.shipping_value_in_usd AS ecommerce_shipping_value_in_usd,
    ecommerce.tax_value_in_usd AS ecommerce_tax_value_in_usd,
    ecommerce.unique_items AS ecommerce_unique_items,
    ecommerce.transaction_id AS ecommerce_transaction_id,

    -- User LTV Information
    user_ltv.revenue AS user_ltv_revenue,
    user_ltv.currency AS user_ltv_currency,

    -- Privacy Information (from privacy_info RECORD)
    privacy_info.analytics_storage AS privacy_analytics_storage,
    privacy_info.ads_storage AS privacy_ads_storage,
    privacy_info.uses_transient_token AS privacy_uses_transient_token,

    -- Other Top-Level Fields
    user_first_touch_timestamp,
    stream_id,
    platform 

FROM
-- Reference the 'events' table from the 'ga4_raw' source
    {{ source('ga4_raw', 'events') }} AS t

