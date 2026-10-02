import os
import pandas as pd
from extract import extract_data
from pathlib import Path
from logger import logging

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_FILE = PROJECT_ROOT / "data" / "validated" / "cargo_tracking_validated.csv"



def validate(df):
    logging.info("\n========== DATA VALIDATION ==========")

    df = df.replace("?",pd.NA)
    logging.info("relace ? to Na")

    logging.info(f"Rows    : {df.shape[0]}")
    logging.info(f"Columns : {df.shape[1]}")


    logging.info(f"check columns name : {df.columns.tolist()}")


    duplicates = df.duplicated().sum()
    logging.info(f"count Duplicates : {duplicates}")

    missing = df.isnull().sum()
    missing = missing[missing > 0].sort_values(ascending=False)
    logging.info(f"count missing values :{missing}")

    logging.info(f"total missing values : {df.isnull().sum().sum()}")

    logging.info(f"data type : {df.dtypes}")

    empty_columns = df.columns[df.isnull().all()].tolist()
    logging.info(f"Completely Empty Columns : {empty_columns}")

    required_columns = [
        "nr",
        "i1_legid",
        "i1_rcs_p",
        "i1_rcs_e",
        "i1_dlv_p",
        "i1_dlv_e",
        "i1_hops",

        "legs"
    ]

    missing_required = [
        col for col in required_columns
        if col not in df.columns
    ]

    logging.info(" Required Column Check")

    if missing_required:
        logging.info(f"Missing required columns : {missing_required}")
    else:
        logging.info("All required columns exist.")


    logging.info("========== VALIDATION RESULT ==========")

    if duplicates == 0 and not missing_required:
        logging.info("VALIDATION PASSED")

        validated_folder = OUTPUT_FILE.parent
        os.makedirs(validated_folder, exist_ok=True)


        validated_file = os.path.join(
            validated_folder,
            "cargo_tracking_validated.csv"
        )

        df.to_csv(validated_file, index=False)

        logging.info(f"Validated file created: {validated_file}")

        return True

    else:
        logging.info("VALIDATION FAILED")
        return False


df = extract_data()

if df is not None:
    validation_result = validate(df)

    if validation_result:
        logging.info("Data is ready for next stage")
    else:
        logging.error("Data validation failed")

