"""Airflow DAG for the Alzheimer decision analytics pipeline."""

from __future__ import annotations

from datetime import timedelta

import pendulum
from airflow.sdk import dag, task

from src.config import SOURCE_FILE
from src.ingest import ingest_to_bronze
from src.quality_checks import run_quality_checks


@dag(
    dag_id="alzheimers_decision_pipeline",
    description="Ingestion and quality-control pipeline for the Alzheimer dataset",
    schedule=None,
    start_date=pendulum.datetime(2026, 8, 1, tz="UTC"),
    catchup=False,
    default_args={
        "owner": "chaima",
        "retries": 1,
        "retry_delay": timedelta(minutes=2),
    },
    tags=["alzheimer", "data-quality", "medallion"],
)
def alzheimers_decision_pipeline():
    """Define the first version of the Alzheimer data pipeline."""

    @task
    def check_source_file() -> dict:
        """Verify that the source CSV exists before ingestion."""

        if not SOURCE_FILE.exists():
            raise FileNotFoundError(
                f"Source dataset not found: {SOURCE_FILE}"
            )

        if SOURCE_FILE.suffix.lower() != ".csv":
            raise ValueError(
                f"Expected a CSV file, received: {SOURCE_FILE.name}"
            )

        return {
            "status": "source_available",
            "file_name": SOURCE_FILE.name,
            "file_size_bytes": SOURCE_FILE.stat().st_size,
        }

    @task
    def ingest_bronze() -> dict:
        """Copy the source dataset into the Bronze layer."""

        metadata = ingest_to_bronze()

        return {
            "status": "bronze_created",
            "row_count": metadata["row_count"],
            "column_count": metadata["column_count"],
            "sha256": metadata["sha256"],
        }

    @task
    def validate_bronze_quality() -> dict:
        """Execute all quality checks on the Bronze dataset."""

        report = run_quality_checks()

        if report["overall_status"] == "FAIL":
            raise ValueError(
                "Critical data-quality checks failed. "
                "Review reports/quality/data_quality_report.json."
            )

        return {
            "status": report["overall_status"],
            "row_count": report["row_count"],
            "column_count": report["column_count"],
            "failed_check_count": report["failed_check_count"],
            "warning_count": report["warning_count"],
        }

    source_check = check_source_file()
    bronze_ingestion = ingest_bronze()
    quality_validation = validate_bronze_quality()

    source_check >> bronze_ingestion >> quality_validation


alzheimers_decision_pipeline()
