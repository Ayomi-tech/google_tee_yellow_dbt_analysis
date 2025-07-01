{{ config(
    materialized='view',
    schema='staging_ga4'
) }}

SELECT
    CONCAT(SUBSTRING(event_date, 1, 4) || '-', SUBSTRING(event_date, 5, 2), '-', SUBSTRING(event_date, 7, 2)) AS event_date,
    event_timestamp,
    event_name,
    user_pseudo_id,
    event_params.key AS param_key,
    COALESCE(
        event_params.value.string_value,
        CAST(event_params.value.int_value AS STRING),
        CAST(event_params.value.double_value AS STRING),
        CAST(event_params.value.float_value AS STRING)
    ) AS param_value,
    event_params.value.int_value AS param_value_int,
    event_params.value.double_value AS param_value_double,
    event_params.value.float_value AS param_value_float,
    event_params.value.string_value AS param_value_string

FROM
    -- Reference the 'events' table from the 'ga4_raw' source
    {{ source('ga4_raw', 'events') }} AS t,
    UNNEST(t.event_params) AS event_params

