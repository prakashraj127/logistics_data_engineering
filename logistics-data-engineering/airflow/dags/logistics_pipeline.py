from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import subprocess
from upload_to_s3 import upload_to_s3
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook


def load_to_snowflake():
    hook = SnowflakeHook(snowflake_conn_id='snowflake')
    hook.run("""COPY INTO RAW_CARGO_TRACKING
            FROM @snowstage
            FILES = ('cargo_tracking_validated.csv');
            """)




def validate_task():
    subprocess.run(["python", "/opt/airflow/python/validate.py"], check=True)


def dbt_run_task():
    subprocess.run(
        [
            "bash",
            "-c",
            "cd /opt/airflow/dbt && dbt run"
        ],
        check=True
    )

def dbt_test_task():
    subprocess.run(
        [
            "bash",
            "-c",
            "cd /opt/airflow/dbt && dbt test"
        ],
        check=True
    )


default_args = {
    "owner": "data-engineering",
    "retries": 2,
    "retry_delay": timedelta(minutes=5)
}


with DAG(
    dag_id="logistics_pipeline",
    default_args= default_args,
    start_date=datetime(2023, 1, 1),
    schedule ="0 2 * * *",
    catchup=False
) as dag:


    
    validation_task = PythonOperator(
        task_id="validate_data",
        python_callable=validate_task
    )
    upload_to_s3=PythonOperator(
        task_id="upload_to_s3",
        python_callable=upload_to_s3
    )
    load_to_snowflake=PythonOperator(
        task_id="load_to_snowflake",
        python_callable=load_to_snowflake
    )
    dbt_run_task=PythonOperator(
        task_id="dbt_run",
        python_callable= dbt_run_task
    )
    dbt_test_task=PythonOperator(
        task_id="dbt_test",
        python_callable= dbt_test_task
    )

    validation_task >> upload_to_s3 >> load_to_snowflake >> dbt_run_task >> dbt_test_task
