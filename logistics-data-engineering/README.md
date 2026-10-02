# LOGISTICS DATA ENGINEERING

## Project Overview

End-to-end logistics and shipment analytics pipeline using Python, AWS S3, Snowflake, dbt, Power BI, Airflow, and Docker.

## Architecture

CSV → Python → AWS S3 → Snowflake → dbt → Power BI

Airflow orchestrates the pipeline.

## Build Order

1. Python extraction and validation
2. Upload raw data to S3
3. Load raw data into Snowflake
4. Transform with dbt
5. Build Power BI dashboard
6. Automate with Airflow
7. Containerize with Docker

## Data

Place the source file at:

`data/raw/cargo_tracking.csv`

## Security

Do not commit passwords, access keys, private keys, or other secrets.
