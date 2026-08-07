"""Export DuckDB analytical models into Power BI-ready CSV files."""

from __future__ import annotations

import json
from datetime import datetime, timezone

import duckdb

from src.config import (
    DUCKDB_FILE,
    POWERBI_EXPORT_DIR,
    POWERBI_EXPORT_METADATA_FILE,
)


EXPORT_QUERIES = {
    "dim_patient.csv": """
        SELECT *
        FROM analytics.dim_patient
        ORDER BY patient_id
    """,
    "dim_diagnosis.csv": """
        SELECT *
        FROM analytics.dim_diagnosis
        ORDER BY diagnosis_code
    """,
    "fct_patient_assessment.csv": """
        SELECT *
        FROM analytics.fct_patient_assessment
        ORDER BY patient_id
    """,
    "gold_kpi_overview.csv": """
        SELECT *
        FROM analytics.gold_kpi_overview
    """,
    "gold_demographics.csv": """
        SELECT *
        FROM analytics.gold_demographics
        ORDER BY group_type_order, category_order
    """,
    "gold_risk_factors.csv": """
        SELECT *
        FROM analytics.gold_risk_factors
        ORDER BY display_order
    """,
    "gold_symptoms.csv": """
        SELECT *
        FROM analytics.gold_symptoms
        ORDER BY display_order
    """,
}


EXPECTED_ROW_COUNTS = {
    "dim_patient.csv": 2149,
    "dim_diagnosis.csv": 2,
    "fct_patient_assessment.csv": 2149,
    "gold_kpi_overview.csv": 1,
    "gold_demographics.csv": 13,
    "gold_risk_factors.csv": 7,
    "gold_symptoms.csv": 7,
}


REQUIRED_TABLES = {
    "dim_patient",
    "dim_diagnosis",
    "fct_patient_assessment",
    "gold_kpi_overview",
    "gold_demographics",
    "gold_risk_factors",
    "gold_symptoms",
}


def validate_required_tables(
    connection: duckdb.DuckDBPyConnection,
) -> None:
    """Confirm that all required dbt models exist."""

    available_tables = {
        row[0]
        for row in connection.execute(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'analytics'
            """
        ).fetchall()
    }

    missing_tables = sorted(
        REQUIRED_TABLES - available_tables
    )

    if missing_tables:
        raise RuntimeError(
            "Required dbt models are missing: "
            f"{missing_tables}. Run dbt build first."
        )


def export_powerbi_data() -> dict:
    """Export Power BI-ready CSV files and metadata."""

    if not DUCKDB_FILE.exists():
        raise FileNotFoundError(
            "The DuckDB warehouse does not exist. "
            "Run: python -m src.load_duckdb"
        )

    POWERBI_EXPORT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    generated_at = datetime.now(
        timezone.utc
    ).isoformat()

    connection = duckdb.connect(
        database=str(DUCKDB_FILE),
        read_only=True,
    )

    try:
        validate_required_tables(connection)

        exported_files = {}

        for file_name, query in EXPORT_QUERIES.items():
            dataframe = connection.execute(query).df()

            expected_rows = EXPECTED_ROW_COUNTS[file_name]
            actual_rows = len(dataframe)

            if actual_rows != expected_rows:
                raise ValueError(
                    f"{file_name} contains {actual_rows} rows; "
                    f"expected {expected_rows}."
                )

            if dataframe.columns.duplicated().any():
                raise ValueError(
                    f"{file_name} contains duplicate column names."
                )

            output_path = (
                POWERBI_EXPORT_DIR / file_name
            )

            dataframe.to_csv(
                output_path,
                index=False,
                encoding="utf-8-sig",
            )

            exported_files[file_name] = {
                "path": str(output_path),
                "row_count": int(dataframe.shape[0]),
                "column_count": int(dataframe.shape[1]),
                "file_size_bytes": output_path.stat().st_size,
            }

        patient_rows = exported_files[
            "dim_patient.csv"
        ]["row_count"]

        fact_rows = exported_files[
            "fct_patient_assessment.csv"
        ]["row_count"]

        if patient_rows != fact_rows:
            raise ValueError(
                "Patient dimension and fact table row counts "
                "do not match."
            )

        overview = connection.execute(
            """
            SELECT
                total_patients,
                diagnosed_patients,
                not_diagnosed_patients
            FROM analytics.gold_kpi_overview
            """
        ).fetchone()

        total_patients = int(overview[0])
        diagnosed_patients = int(overview[1])
        not_diagnosed_patients = int(overview[2])

        if (
            diagnosed_patients
            + not_diagnosed_patients
            != total_patients
        ):
            raise ValueError(
                "Gold overview patient counts are inconsistent."
            )

        metadata = {
            "generated_at_utc": generated_at,
            "source_database": DUCKDB_FILE.name,
            "export_directory": str(
                POWERBI_EXPORT_DIR
            ),
            "exported_file_count": len(
                exported_files
            ),
            "total_patients": total_patients,
            "diagnosed_patients": diagnosed_patients,
            "not_diagnosed_patients": (
                not_diagnosed_patients
            ),
            "files": exported_files,
            "status": "SUCCESS",
        }

        with POWERBI_EXPORT_METADATA_FILE.open(
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
    result = export_powerbi_data()

    print("Power BI export completed successfully.")
    print(
        json.dumps(
            result,
            indent=4,
            ensure_ascii=False,
        )
    )
