"""Airflow DAG for the Alzheimer decision analytics pipeline."""

from __future__ import annotations

from datetime import timedelta

import pendulum
from airflow.sdk import dag, task

from src.config import SOURCE_FILE
from src.ingest import ingest_to_bronze
from src.quality_checks import run_quality_checks
from src.transform import transform_to_silver


@dag(
    dag_id="alzheimers_decision_pipeline",
    description=(
        "Bronze ingestion, data-quality validation "
        "and Silver transformation"
    ),
    schedule=None,
    start_date=pendulum.datetime(
        2026,
        8,
        1,
        tz="UTC",
    ),
    catchup=False,
    default_args={
        "owner": "chaima",
        "retries": 1,
        "retry_delay": timedelta(minutes=2),
    },
    tags=[
        "alzheimer",
        "medallion",
        "bronze",
        "silver",
        "data-quality",
    ],
)
def alzheimers_decision_pipeline():
    """Define the Alzheimer decision analytics pipeline."""

    @task
    def check_source_file() -> dict:
        """Verify that the source CSV exists."""

        if not SOURCE_FILE.exists():
            raise FileNotFoundError(
                f"Source dataset not found: {SOURCE_FILE}"
            )

        if SOURCE_FILE.suffix.lower() != ".csv":
            raise ValueError(
                "The source file must be a CSV file. "
                f"Received: {SOURCE_FILE.name}"
            )

        return {
            "status": "source_available",
            "file_name": SOURCE_FILE.name,
            "file_size_bytes": SOURCE_FILE.stat().st_size,
        }

    @task
    def ingest_bronze() -> dict:
        """Copy the original dataset into Bronze."""

        metadata = ingest_to_bronze()

        return {
            "status": "bronze_created",
            "row_count": metadata["row_count"],
            "column_count": metadata["column_count"],
            "sha256": metadata["sha256"],
        }

    @task
    def validate_bronze_quality() -> dict:
        """Run quality controls on the Bronze dataset."""

        report = run_quality_checks()

        if report["overall_status"] == "FAIL":
            raise ValueError(
                "Critical data-quality checks failed. "
                "Review the quality report before continuing."
            )

        return {
            "status": report["overall_status"],
            "row_count": report["row_count"],
            "column_count": report["column_count"],
            "failed_check_count": (
                report["failed_check_count"]
            ),
            "warning_count": report["warning_count"],
        }

    @task
    def transform_silver() -> dict:
        """Create the cleaned and enriched Silver dataset."""

        metadata = transform_to_silver()

        if (
            metadata["bronze_row_count"]
            != metadata["silver_row_count"]
        ):
            raise ValueError(
                "The Silver row count differs "
                "from the Bronze row count."
            )

        if metadata["missing_values"] != 0:
            raise ValueError(
                "The Silver dataset contains missing values."
            )

        if metadata["duplicate_patient_ids"] != 0:
            raise ValueError(
                "The Silver dataset contains "
                "duplicated patient identifiers."
            )

        return {
            "status": "silver_created",
            "row_count": metadata["silver_row_count"],
            "column_count": metadata["silver_column_count"],
            "removed_columns": metadata["removed_columns"],
            "new_columns": metadata["new_columns"],
            "missing_values": metadata["missing_values"],
        }

    source_check = check_source_file()
    bronze_ingestion = ingest_bronze()
    quality_validation = validate_bronze_quality()
    silver_transformation = transform_silver()

    (
        source_check
        >> bronze_ingestion
        >> quality_validation
        >> silver_transformation
    )


alzheimers_decision_pipeline()
