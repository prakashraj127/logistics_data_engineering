
import pandas as pd
from logger import logging
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
INPUT_FILE = PROJECT_ROOT / "data" / "raw" / "cargo_tracking-data.csv"

def extract_data():
    try:
        logging.info("starting data extraction")
        df = pd.read_csv(INPUT_FILE)
        logging.info("data is extracted")
        logging.info(f"number of rows executed : {len(df)}")
        logging.info(f"number of columns executed : {len(df.columns)}")
        return df

    except Exception as e:
        logging.error(f"Extraction failed : {e}")
        return None

if __name__ == "__main__":
    extract_data()