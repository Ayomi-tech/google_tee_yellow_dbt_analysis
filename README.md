# Product Performance Analysis: Google Tee Yellow


## Overview
This project showcases a data analysis conducted on Google Analytics 4 (GA4) BigQuery export data to understand the performance of a specific product, 'Google Tee Yellow' (item_id: GGOEGXXX0905). My objective was to extract key product metrics, identify performance bottlenecks, and propose actionable recommendations, while also demonstrating robust data transformation design and preparation using dbt.

## Data Source
The analysis is based on raw event data exported from Google Analytics 4 (GA4) to Google BigQuery. This raw data contains detailed user interactions and e-commerce events. The insights derived are based on a specific query output provided for 'Google Tee Yellow'.

## Key Questions Addressed
This analysis addresses the following core questions:

Product Performance: What key insights can be derived about the 'Google Tee Yellow' product's engagement and conversion from the available data?

Data Modeling Approach: Does it make sense to build a data transformation pipeline using dbt for this task, and how is that pipeline structured?

Analytical Assumptions: What underlying assumptions are necessary when conducting this type of product performance analysis?

## Methodology
My approach involved the following key steps:

Data Transformation (dbt Design & Preparation):

I designed and prepared dbt models to transform the raw GA4 data into a clean, analyst-friendly format, as if connected to BigQuery. This demonstrates my ability to build a robust and maintainable data pipeline, even without direct execution access.

## The dbt models include:

Staging Models (stg_*): For initial cleaning and flattening of raw GA4 event and item data (e.g., **stg_ga4_events_base.sql, stg_ga4_event_params.sql, stg_ga4_items.sql**).

Mart Models (mart_*): For aggregating and preparing data into analytical marts, such as **mart_google_tee_yellow_performance.sql**, specifically tailored for product performance analysis.

Schema Definition & Testing: Utilizing schema.yml to define columns, descriptions, and ensure data quality through test definitions.

## Data Extraction & Analysis (SQL Interpretation):

My analysis is based on interpreting the results of a specific SQL query provided for 'Google Tee Yellow', simulating the extraction of key product metrics.

I focused on interpreting these aggregated metrics and identifying patterns or anomalies relevant to product performance.

