"""Load the Silver Parquet dataset into a DuckDB analytical warehouse."""

from __future__ import annotations

import json
from datetime import datetime, timezone

import duckdb

from src.config import (
    DUCKDB_FILE,
    DUCKDB_METADATA_FILE,
    SILVER_PARQUET_FILE,
    WAREHOUSE_DIR,
)


TARGET_TABLE = "silver_alzheimer_patients"


def load_silver_to_duckdb() -> dict:
    """Load Silver data into DuckDB and validate the resulting table."""

    if not SILVER_PARQUET_FILE.exists():
        raise FileNotFoundError(
            "The Silver Parquet file does not exist. "
            "Run: python -m src.transform"
        )

    WAREHOUSE_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    parquet_path = (
        str(SILVER_PARQUET_FILE)
        .replace("\\", "/")
        .replace("'", "''")
    )

    load_timestamp = datetime.now(
        timezone.utc
    ).isoformat()

    connection = duckdb.connect(
        database=str(DUCKDB_FILE)
    )

    try:
        connection.execute(
            f"""
            CREATE OR REPLACE TABLE {TARGET_TABLE} AS
            SELECT *
            FROM read_parquet('{parquet_path}')
            """
        )

        connection.execute(
            f"""
            CREATE UNIQUE INDEX IF NOT EXISTS
            idx_silver_patient_id
            ON {TARGET_TABLE}(PatientID)
            """
        )

        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS warehouse_load_audit (
                load_timestamp_utc VARCHAR,
                source_file VARCHAR,
                target_table VARCHAR,
                row_count BIGINT,
                column_count INTEGER,
                status VARCHAR
            )
            """
        )

        row_count = connection.execute(
            f"""
            SELECT COUNT(*)
            FROM {TARGET_TABLE}
            """
        ).fetchone()[0]

        column_count = len(
            connection.execute(
                f"""
                PRAGMA table_info('{TARGET_TABLE}')
                """
            ).fetchall()
        )

        distinct_patient_ids = connection.execute(
            f"""
            SELECT COUNT(DISTINCT PatientID)
            FROM {TARGET_TABLE}
            """
        ).fetchone()[0]

        null_patient_ids = connection.execute(
            f"""
            SELECT COUNT(*)
            FROM {TARGET_TABLE}
            WHERE PatientID IS NULL
            """
        ).fetchone()[0]

        diagnosed_patients = connection.execute(
            f"""
            SELECT COUNT(*)
            FROM {TARGET_TABLE}
            WHERE Diagnosis = 1
            """
        ).fetchone()[0]

        if row_count == 0:
            raise ValueError(
                "The DuckDB table contains no records."
            )

        if distinct_patient_ids != row_count:
            raise ValueError(
                "PatientID is not unique in the DuckDB table."
            )

        if null_patient_ids != 0:
            raise ValueError(
                "The DuckDB table contains null PatientID values."
            )

        connection.execute(
            """
            INSERT INTO warehouse_load_audit
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            [
                load_timestamp,
                SILVER_PARQUET_FILE.name,
                TARGET_TABLE,
                row_count,
                column_count,
                "SUCCESS",
            ],
        )

        metadata = {
            "generated_at_utc": load_timestamp,
            "database_file": DUCKDB_FILE.name,
            "source_file": SILVER_PARQUET_FILE.name,
            "target_table": TARGET_TABLE,
            "row_count": int(row_count),
            "column_count": int(column_count),
            "distinct_patient_ids": int(
                distinct_patient_ids
            ),
            "null_patient_ids": int(
                null_patient_ids
            ),
            "diagnosed_patients": int(
                diagnosed_patients
            ),
            "non_diagnosed_patients": int(
                row_count - diagnosed_patients
            ),
            "status": "SUCCESS",
        }

        with DUCKDB_METADATA_FILE.open(
            "w",
            encoding="utf-8",
        ) as file:
            json.dump(
                metadata,
                file,
                indent=4,
                ensure_ascii=False,
            )

        return metadata

    finally:
        connection.close()


if __name__ == "__main__":
    result = load_silver_to_duckdb()

    print("DuckDB load completed successfully.")
    print(
        json.dumps(
            result,
            indent=4,
            ensure_ascii=False,
        )
    )
