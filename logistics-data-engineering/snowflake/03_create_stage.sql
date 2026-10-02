CREATE OR REPLACE STAGE snowstage
FILE_FORMAT = csv_format
URL='s3://snow-bucket-01-aj/logistics-data/validated/'
CREDENTIALS = (AWS_KEY_ID='your_aws_access_key' AWS_SECRET_KEY='your_aws_secret_key')
