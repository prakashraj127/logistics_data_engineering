# Logistics Data Engineering Pipeline

An end-to-end logistics data engineering project that ingests cargo
tracking data, validates it with Python, stores it in AWS S3, loads it
into Snowflake, transforms it with dbt, validates the transformed data,
and orchestrates the workflow with Apache Airflow running in Docker.

## Project Overview

This project demonstrates a complete ETL/ELT workflow for logistics and
shipment analytics.

The pipeline uses:

-   **Python + Pandas** for extraction and source-data validation
-   **AWS S3** for cloud object storage
-   **Snowflake** as the cloud data warehouse
-   **dbt** for SQL transformations, reusable macros, snapshots, and
    data-quality tests
-   **Apache Airflow** for workflow orchestration and scheduling
-   **Docker** for a reproducible Airflow environment
-   **Power BI** for analytics/reporting

The source cargo-tracking dataset contains approximately **3,943 rows
and 98 columns**.

------------------------------------------------------------------------

## Architecture

``` text
                         Cargo Tracking CSV
                                |
                                v
                    +------------------------+
                    | Python / Pandas        |
                    | Extraction & Validation|
                    +-----------+------------+
                                |
                                v
                     Validated CSV Dataset
                                |
                                v
                         +-------------+
                         |   AWS S3    |
                         +------+------+
                                |
                                v
                    +-----------------------+
                    | Snowflake RAW Layer   |
                    | RAW_CARGO_TRACKING    |
                    +----------+------------+
                               |
                               v
                    +-----------------------+
                    | dbt BRONZE            |
                    | Raw source view       |
                    +----------+------------+
                               |
                               v
                    +-----------------------+
                    | dbt SILVER            |
                    | Shipment Legs         |
                    | Leg Hops              |
                    +----------+------------+
                               |
                               v
                    +-----------------------+
                    | dbt GOLD              |
                    | Facts / Dimensions    |
                    | SLA Reporting Mart    |
                    +----------+------------+
                               |
                               v
                     dbt Data Quality Tests
                               |
                               v
                          Power BI
```

### Airflow orchestration

``` text
validate_data
      |
      v
upload_to_s3
      |
      v
load_to_snowflake
      |
      v
dbt_run
      |
      v
dbt_test
```

The Airflow DAG is scheduled daily and configured with **2 retries** and
a **5-minute retry delay**.

------------------------------------------------------------------------

## Technology Stack

  Technology       Purpose
  ---------------- -----------------------------------------------
  Python           Extraction, validation, and ingestion logic
  Pandas           CSV processing and data validation
  AWS S3           Cloud storage / landing zone
  Snowflake        Cloud data warehouse
  SQL              Warehouse loading and transformations
  dbt              Data modeling, macros, snapshots, and testing
  dbt-utils        Reusable dbt utility macros
  Apache Airflow   Workflow orchestration
  Docker           Containerized Airflow environment
  Power BI         Logistics analytics and reporting
  Git / GitHub     Source control

------------------------------------------------------------------------

## Pipeline Workflow

### 1. Extract

Python reads the source cargo-tracking CSV using Pandas.

The source dataset is:

``` text
data/raw/cargo_tracking-data.csv
```

The current dataset contains approximately:

``` text
Rows:    3,943
Columns: 98
```

### 2. Validate

The Python validation layer performs checks including:

-   Replaces `?` placeholders with null values
-   Reports row and column counts
-   Checks duplicate rows
-   Reports missing values
-   Reports completely empty columns
-   Checks required columns
-   Logs data types
-   Writes a validated CSV when validation succeeds

Validated output:

``` text
data/validated/cargo_tracking_validated.csv
```

### 3. Upload to AWS S3

The validated CSV is uploaded to the S3 landing path:

``` text
logistics-data/validated/cargo_tracking_validated.csv
```

### 4. Load into Snowflake

Snowflake loads the validated file from an external stage into:

``` text
LOGISTICS_DB.RAW.RAW_CARGO_TRACKING
```

The Snowflake setup scripts are provided under:

``` text
snowflake/
```

### 5. dbt Bronze Layer

The Bronze model creates a source-level view over the Snowflake RAW
table.

``` text
RAW_CARGO_TRACKING
        |
        v
bronze_cargo_tracking
```

The Bronze layer is intentionally close to the source data.

### 6. dbt Silver Layer

The Silver layer converts the wide logistics source into
analytics-friendly shipment and leg structures.

#### `silver_shipments_legs`

Creates one record per shipment and used leg:

``` text
i1
i2
i3
o
```

It includes:

-   Shipment ID
-   Leg type
-   Outbound-leg flag
-   Leg ID
-   RCS planned/effective timestamps
-   DLV planned/effective timestamps
-   Hop count
-   RCS delay in minutes
-   DLV delay in minutes
-   Surrogate leg key

#### `silver_leg_hops`

Creates one record per shipment, leg, and hop.

It handles:

-   Departure events
-   Receipt events
-   Place codes
-   Planned/effective timestamps
-   Delay calculations
-   Surrogate hop keys

Jinja loops are used to generate the repeated leg/hop transformations.

### 7. dbt Gold Layer

The Gold layer contains analytics-ready models.

#### `gold_fact_leg_performance`

Provides leg-level operational performance including:

-   RCS delay
-   DLV delay
-   SLA status
-   Hop count
-   Leg attributes

#### `gold_fact_shipment_performance`

Aggregates performance at shipment level, including:

-   Number of legs used
-   Worst leg delay
-   Average leg delay
-   Final outbound delivery performance
-   Final delivery SLA status

#### `gold_dim_place`

Creates a place-level dimension-style dataset with hop touch counts.

#### `gold_mart_sla_summary`

Provides SLA reporting by leg type:

-   Total legs
-   On-time legs
-   Delayed legs
-   Unknown legs
-   On-time percentage
-   Average delay

------------------------------------------------------------------------

## dbt Macros

The project uses reusable Jinja/dbt macros for common transformation
logic.

### Missing-value cleanup

``` text
clean_missing_numeric
clean_missing_text
```

These convert source `?` placeholders into appropriate null values.

### Delay calculation

``` text
calculate_delay_minutes
```

Calculates the difference between planned and effective timestamps.

### Surrogate keys

``` text
generate_leg_key
```

Uses `dbt_utils.generate_surrogate_key` to create stable keys.

### SLA classification

``` text
sla_status
```

Classifies delay results as:

``` text
ON_TIME
DELAYED
UNKNOWN
```

------------------------------------------------------------------------

## Historical Tracking

The project includes a dbt snapshot:

``` text
snap_shipment_leg_status
```

It uses a `check` strategy and tracks changes to:

-   `rcs_effective`
-   `dlv_effective`
-   `dlv_delay_minutes`

This provides a historical record when shipment-leg status changes over
time.

------------------------------------------------------------------------

## Data Quality

dbt tests are defined for the Silver and Gold models.

Examples include:

-   `not_null`
-   `unique`
-   `accepted_values`

Examples of tested business fields include:

``` text
leg_key
hop_key
shipment_id
shipment_nr
place_code
leg_type
hop_number
```

The Airflow pipeline executes:

``` text
dbt run
   |
   v
dbt test
```

So transformation and post-transformation data-quality validation are
part of the orchestrated workflow.

------------------------------------------------------------------------

## Airflow DAG

DAG ID:

``` text
logistics_pipeline
```

Current task dependency:

``` text
validate_data
      >>
upload_to_s3
      >>
load_to_snowflake
      >>
dbt_run
      >>
dbt_test
```

### Scheduling

The DAG is configured with:

``` text
0 2 * * *
```

which represents a daily 2:00 AM schedule in the Airflow scheduler's
configured timezone.

### Retry configuration

``` text
Retries:       2
Retry delay:   5 minutes
```

### Airflow connection

The Snowflake task uses an Airflow connection with ID:

``` text
snowflake
```

Credentials should be stored in Airflow's connection management rather
than committed to Git.

------------------------------------------------------------------------

## Docker

Airflow runs in Docker using:

``` text
apache/airflow:2.10.5
```

The custom Docker image installs:

-   `apache-airflow-providers-snowflake`
-   `dbt-snowflake`

The compose configuration mounts:

``` text
airflow/dags     -> /opt/airflow/dags
python           -> /opt/airflow/python
data             -> /opt/airflow/data
logistics_dbt    -> /opt/airflow/dbt
```

Airflow UI:

``` text
http://localhost:8080
```

------------------------------------------------------------------------

## Project Structure

``` text
logistics-data-engineering/
│
├── airflow/
│   └── dags/
│       ├── logistics_pipeline.py
│       ├── upload_to_s3.py
│       └── logger.py
│
├── aws/
│   └── s3_structure.md
│
├── data/
│   ├── raw/
│   │   └── cargo_tracking-data.csv
│   └── validated/
│       └── cargo_tracking_validated.csv
│
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yaml
│
├── logistics_dbt/
│   ├── models/
│   │   ├── bronze/
│   │   ├── silver/
│   │   └── gold/
│   ├── macros/
│   ├── snapshots/
│   ├── tests/
│   ├── dbt_project.yml
│   └── packages.yml
│
├── powerbi/
│   └── logistics_dashboard.pbix
│
├── python/
│   ├── extract.py
│   ├── validate.py
│   ├── upload_to_s3.py
│   └── logger.py
│
├── snowflake/
│   ├── 01_create_database.sql
│   ├── 02_create_schema.sql
│   ├── 03_create_stage.sql
│   └── 04_copy_into.sql
│
├── tests/
│   └── python_tests/
│
├── .gitignore
└── README.md
```

------------------------------------------------------------------------

## Setup

### 1. Clone the repository

``` bash
git clone <your-repository-url>
cd logistics-data-engineering
```

### 2. Python environment

Create and activate a virtual environment if running the Python
validation scripts locally.

Install the required Python packages used by the project, such as:

``` bash
pip install pandas boto3
```

### 3. AWS configuration

Configure AWS credentials securely using the AWS CLI or
environment-based credentials.

Do not place access keys directly in source code.

The project expects the validated file to be uploaded to the configured
S3 bucket/path.

### 4. Snowflake

Create the database and RAW schema using the scripts in:

``` text
snowflake/
```

Configure the Snowflake stage to access the S3 location.

**Never commit real AWS credentials or Snowflake credentials.**

### 5. dbt

From the dbt project directory:

``` bash
dbt debug
dbt run
dbt test
```

The dbt project uses the Snowflake adapter and `dbt_utils`.

### 6. Start Airflow with Docker

From the `docker` directory:

``` bash
docker compose up -d --build
```

Check the DAG:

``` bash
docker compose exec airflow airflow dags list
```

Check import errors:

``` bash
docker compose exec airflow airflow dags list-import-errors
```

Run dbt manually inside the Airflow container:

``` bash
docker compose exec airflow bash -c "cd /opt/airflow/dbt && dbt run"
```

Run dbt tests:

``` bash
docker compose exec airflow bash -c "cd /opt/airflow/dbt && dbt test"
```

------------------------------------------------------------------------

## Security

Do not commit:

-   AWS access keys
-   AWS secret keys
-   Snowflake passwords
-   Airflow passwords
-   `.env` files
-   private keys
-   `profiles.yml` containing credentials

Use Airflow Connections, environment variables, AWS credential
configuration, or another secrets-management mechanism for credentials.

------------------------------------------------------------------------

## Important Repository Cleanup

Before publishing the repository, remove generated/runtime artifacts
such as:

``` text
__pycache__/
*.pyc
etl.log
docker/logs/
logistics_dbt/target/
logistics_dbt/dbt_packages/
```

These are generated files and do not belong in the source repository.

Also keep only one production copy of reusable modules such as
`upload_to_s3.py`.

------------------------------------------------------------------------

## Current Project Status

### Implemented

-   [x] Python extraction
-   [x] Python data validation
-   [x] AWS S3 upload
-   [x] Snowflake RAW loading
-   [x] dbt Bronze model
-   [x] dbt Silver models
-   [x] dbt Gold models
-   [x] dbt macros
-   [x] dbt snapshot
-   [x] dbt data-quality tests
-   [x] Airflow orchestration
-   [x] Airflow retries
-   [x] Dockerized Airflow
-   [x] Power BI project file

### Recommended next improvements

-   [ ] Make Python paths environment/config based instead of
    machine-specific Windows paths
-   [ ] Make validation failures return a non-zero process exit code so
    Airflow correctly marks the task as failed
-   [ ] Make S3 upload failures raise an exception instead of returning
    `False`
-   [ ] Move AWS/Snowflake configuration to environment variables or
    Airflow Connections
-   [ ] Remove generated dbt `target/` and `dbt_packages/` artifacts
    from Git
-   [ ] Add automated Python unit tests
-   [ ] Add CI/CD checks
-   [ ] Add monitoring/alerting
-   [ ] Add a production-ready Power BI dashboard if the current `.pbix`
    is only a placeholder

------------------------------------------------------------------------

## Learning Outcomes

This project demonstrates practical experience with:

-   ETL and ELT architecture
-   Cloud data ingestion
-   Data validation
-   AWS S3
-   Snowflake data warehousing
-   Dimensional-style data modeling
-   dbt transformations
-   Jinja templating
-   dbt macros
-   dbt snapshots
-   Data-quality testing
-   Airflow DAG design
-   Task dependencies
-   Retry handling
-   Docker
-   SQL
-   Git/GitHub

------------------------------------------------------------------------

## Author

**Prakash Raj**

BCA Student \| Aspiring Data Engineer / ETL Developer
