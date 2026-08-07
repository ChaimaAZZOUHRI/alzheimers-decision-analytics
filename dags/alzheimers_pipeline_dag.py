# pyright: reportMissingImports=false

"""End-to-end Airflow pipeline for Alzheimer decision analytics."""

from __future__ import annotations

import subprocess
from datetime import timedelta

import pendulum
from airflow.sdk import dag, task

from src.config import SOURCE_FILE
from src.export_powerbi import export_powerbi_data
from src.ingest import ingest_to_bronze
from src.load_duckdb import load_silver_to_duckdb
from src.quality_checks import run_quality_checks
from src.transform import transform_to_silver


@dag(
    dag_id="alzheimers_decision_pipeline",
    description=(
        "End-to-end Alzheimer decision analytics pipeline: "
        "Bronze, quality, Silver, DuckDB, dbt Gold and Power BI export"
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
        "duckdb",
        "dbt",
        "powerbi",
    ],
)
def alzheimers_decision_pipeline():
    """Define the complete decision analytics pipeline."""

    @task
    def check_source_file() -> dict:
        """Verify that the source CSV exists."""

        if not SOURCE_FILE.exists():
            raise FileNotFoundError(
                f"Source dataset not found: {SOURCE_FILE}"
            )

        if SOURCE_FILE.suffix.lower() != ".csv":
            raise ValueError(
                f"Expected CSV source, received: {SOURCE_FILE.name}"
            )

        return {
            "status": "source_available",
            "file_name": SOURCE_FILE.name,
            "file_size_bytes": SOURCE_FILE.stat().st_size,
        }

    @task
    def ingest_bronze() -> dict:
        """Copy source data into the Bronze layer."""

        metadata = ingest_to_bronze()

        return {
            "status": "bronze_created",
            "row_count": metadata["row_count"],
            "column_count": metadata["column_count"],
            "sha256": metadata["sha256"],
        }

    @task
    def validate_bronze_quality() -> dict:
        """Execute Bronze quality checks."""

        report = run_quality_checks()

        if report["overall_status"] == "FAIL":
            raise ValueError(
                "Critical Bronze data-quality checks failed."
            )

        return {
            "status": report["overall_status"],
            "row_count": report["row_count"],
            "column_count": report["column_count"],
            "failed_check_count": report["failed_check_count"],
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
                "Silver row count differs from Bronze."
            )

        if metadata["missing_values"] != 0:
            raise ValueError(
                "Silver dataset contains missing values."
            )

        if metadata["duplicate_patient_ids"] != 0:
            raise ValueError(
                "Silver dataset contains duplicated PatientID values."
            )

        return {
            "status": "silver_created",
            "row_count": metadata["silver_row_count"],
            "column_count": metadata["silver_column_count"],
        }

    @task
    def load_duckdb() -> dict:
        """Load the Silver dataset into DuckDB."""

        metadata = load_silver_to_duckdb()

        if metadata["status"] != "SUCCESS":
            raise ValueError(
                "DuckDB warehouse load failed."
            )

        return {
            "status": metadata["status"],
            "target_table": metadata["target_table"],
            "row_count": metadata["row_count"],
            "column_count": metadata["column_count"],
        }

    @task
    def run_dbt_models() -> dict:
        """Build and test dbt staging, dimensional and Gold models."""

        command = [
            "dbt",
            "build",
            "--no-partial-parse",
            "--project-dir",
            "/opt/airflow/dbt_project",
            "--profiles-dir",
            "/opt/airflow/dbt_project",
        ]

        result = subprocess.run(
            command,
            cwd="/opt/airflow",
            capture_output=True,
            text=True,
            check=False,
        )

        print(result.stdout)

        if result.stderr:
            print(result.stderr)

        if result.returncode != 0:
            raise RuntimeError(
                "dbt build failed. Review the Airflow task logs."
            )

        return {
            "status": "SUCCESS",
            "return_code": result.returncode,
        }

    @task
    def export_powerbi() -> dict:
        """Export analytical tables for Power BI."""

        metadata = export_powerbi_data()

        if metadata["status"] != "SUCCESS":
            raise ValueError(
                "Power BI export failed."
            )

        if metadata["exported_file_count"] != 7:
            raise ValueError(
                "Expected seven Power BI export files."
            )

        return {
            "status": metadata["status"],
            "exported_file_count": metadata[
                "exported_file_count"
            ],
            "total_patients": metadata["total_patients"],
        }

    source_check = check_source_file()
    bronze_ingestion = ingest_bronze()
    quality_validation = validate_bronze_quality()
    silver_transformation = transform_silver()
    warehouse_load = load_duckdb()
    dbt_build = run_dbt_models()
    powerbi_export = export_powerbi()

    (
        source_check
        >> bronze_ingestion
        >> quality_validation
        >> silver_transformation
        >> warehouse_load
        >> dbt_build
        >> powerbi_export
    )


alzheimers_decision_pipeline()
