"""
RetailPulse ETL Script
Extracts raw Olist CSV files and loads them into PostgreSQL.
Run this AFTER schema.sql has been executed (tables must already exist).
"""

import os
import pandas as pd
from urllib.parse import quote_plus
from sqlalchemy import create_engine
from dotenv import load_dotenv

# Load DB credentials from .env
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = quote_plus(os.getenv("DB_PASSWORD"))

# Build connection string and engine
connection_string = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(connection_string)

# Map: CSV file -> table name (order matters — parents before children)
FILE_TABLE_MAP = [
    ("data/olist_customers_dataset.csv", "customers"),
    ("data/olist_sellers_dataset.csv", "sellers"),
    ("data/product_category_name_translation.csv", "product_category_name_translation"),
    ("data/olist_products_dataset.csv", "products"),
    ("data/olist_orders_dataset.csv", "orders"),
    ("data/olist_order_items_dataset.csv", "order_items"),
    ("data/olist_order_payments_dataset.csv", "payments"),
    ("data/olist_order_reviews_dataset.csv", "reviews"),
    ("data/olist_geolocation_dataset.csv", "geolocation"),
]


def load_csv_to_table(csv_path: str, table_name: str, dedupe_subset=None):
    """Read a CSV and append it into the matching Postgres table."""
    print(f"Loading {csv_path} -> {table_name} ...")

    df = pd.read_csv(csv_path)

    before = len(df)
    df = df.drop_duplicates(subset=dedupe_subset)
    after = len(df)
    if before != after:
        print(f"  Dropped {before - after} duplicate rows (subset={dedupe_subset or 'all columns'})")

    df.to_sql(table_name, engine, if_exists="append", index=False)
    print(f"  Loaded {len(df)} rows into '{table_name}'")

def patch_missing_categories():
    """Find product categories missing from the translation table and insert them."""
    products_df = pd.read_csv("data/olist_products_dataset.csv")
    translation_df = pd.read_csv("data/product_category_name_translation.csv")

    product_categories = set(products_df["product_category_name"].dropna().unique())
    known_categories = set(translation_df["product_category_name"].unique())

    missing = product_categories - known_categories

    if missing:
        print(f"Found {len(missing)} category names missing from translation table: {missing}")
        missing_df = pd.DataFrame({
            "product_category_name": list(missing),
            "product_category_name_english": list(missing)  # placeholder: same as Portuguese name
        })
        missing_df.to_sql("product_category_name_translation", engine, if_exists="append", index=False)
        print(f"  Inserted {len(missing)} missing categories as placeholders")
    else:
        print("No missing categories found.")

def main():
    for csv_path, table_name in FILE_TABLE_MAP:
        if table_name == "products":
            patch_missing_categories()

        if table_name == "reviews":
            load_csv_to_table(csv_path, table_name, dedupe_subset=["review_id"])
        else:
            load_csv_to_table(csv_path, table_name)

    print("\nAll files loaded successfully.")


if __name__ == "__main__":
    main()