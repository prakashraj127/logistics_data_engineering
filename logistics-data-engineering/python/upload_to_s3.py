

import boto3
from logger import logging

def upload_to_s3():

    try:
        logging.info("Uploading to S3...")
        bucket_name = "snow-bucket-01-aj"
        local_file_path = "/opt/airflow/data/validated/cargo_tracking_validated.csv"
        s3 = boto3.resource('s3')
        s3.Bucket(bucket_name).upload_file(
            local_file_path,
            "logistics-data/validated/cargo_tracking_validated.csv"
        )
        logging.info("Upload to S3 completed successfully.")
        return True
    except Exception as e:
        logging.error(f"Error occurred while uploading to S3: {e}")
        return False

if __name__ == "__main__":
    upload_to_s3()