"""Transform validated Bronze data into an analysis-ready Silver dataset."""

from __future__ import annotations

import json
from datetime import datetime, timezone

import pandas as pd

from src.config import (
    BRONZE_FILE,
    SILVER_CSV_FILE,
    SILVER_METADATA_FILE,
    SILVER_PARQUET_FILE,
    create_directories,
)


GENDER_LABELS = {
    0: "Male",
    1: "Female",
}

ETHNICITY_LABELS = {
    0: "Caucasian",
    1: "African American",
    2: "Asian",
    3: "Other",
}

EDUCATION_LABELS = {
    0: "None",
    1: "High School",
    2: "Bachelor's",
    3: "Higher Education",
}

DIAGNOSIS_LABELS = {
    0: "Not Diagnosed",
    1: "Diagnosed",
}

MEDICAL_HISTORY_COLUMNS = [
    "FamilyHistoryAlzheimers",
    "CardiovascularDisease",
    "Diabetes",
    "Depression",
    "HeadInjury",
    "Hypertension",
]

SYMPTOM_COLUMNS = [
    "MemoryComplaints",
    "BehavioralProblems",
    "Confusion",
    "Disorientation",
    "PersonalityChanges",
    "DifficultyCompletingTasks",
    "Forgetfulness",
]


def validate_required_columns(dataframe: pd.DataFrame) -> None:
    """Ensure that all columns needed for the transformation exist."""

    required_columns = {
        "PatientID",
        "Age",
        "Gender",
        "Ethnicity",
        "EducationLevel",
        "MMSE",
        "FunctionalAssessment",
        "ADL",
        "Diagnosis",
        *MEDICAL_HISTORY_COLUMNS,
        *SYMPTOM_COLUMNS,
    }

    missing_columns = sorted(
        required_columns - set(dataframe.columns)
    )

    if missing_columns:
        raise KeyError(
            "The following columns are required for Silver "
            f"transformation: {missing_columns}"
        )


def transform_dataframe(
    dataframe: pd.DataFrame,
) -> pd.DataFrame:
    """Clean, decode and enrich the Bronze dataframe."""

    validate_required_columns(dataframe)

    silver = dataframe.copy()

    # DoctorInCharge is constant and provides no analytical value.
    silver = silver.drop(
        columns=["DoctorInCharge"],
        errors="ignore",
    )

    # Decode coded variables while preserving the original numeric columns.
    silver["GenderLabel"] = silver["Gender"].map(
        GENDER_LABELS
    )

    silver["EthnicityLabel"] = silver["Ethnicity"].map(
        ETHNICITY_LABELS
    )

    silver["EducationLabel"] = silver["EducationLevel"].map(
        EDUCATION_LABELS
    )

    silver["DiagnosisLabel"] = silver["Diagnosis"].map(
        DIAGNOSIS_LABELS
    )

    # Create demographic segmentation.
    silver["AgeGroup"] = pd.cut(
        silver["Age"],
        bins=[59, 69, 79, 90],
        labels=[
            "60-69",
            "70-79",
            "80-90",
        ],
        include_lowest=True,
    )

    # Count medical-history conditions for each patient.
    silver["MedicalHistoryCount"] = (
        silver[MEDICAL_HISTORY_COLUMNS]
        .sum(axis=1)
        .astype("int64")
    )

    # Count reported cognitive and behavioural symptoms.
    silver["SymptomCount"] = (
        silver[SYMPTOM_COLUMNS]
        .sum(axis=1)
        .astype("int64")
    )

    # Create explicit score bands without clinical interpretation.
    silver["MMSEBand"] = pd.cut(
        silver["MMSE"],
        bins=[-0.001, 10, 20, 25, 30.001],
        labels=[
            "0-9",
            "10-19",
            "20-24",
            "25-30",
        ],
        right=False,
        include_lowest=True,
    )

    silver["FunctionalAssessmentBand"] = pd.cut(
        silver["FunctionalAssessment"],
        bins=[-0.001, 4, 7, 10.001],
        labels=[
            "0-3.99",
            "4-6.99",
            "7-10",
        ],
        right=False,
        include_lowest=True,
    )

    silver["ADLBand"] = pd.cut(
        silver["ADL"],
        bins=[-0.001, 4, 7, 10.001],
        labels=[
            "0-3.99",
            "4-6.99",
            "7-10",
        ],
        right=False,
        include_lowest=True,
    )

    processing_timestamp = datetime.now(
        timezone.utc
    ).isoformat()

    silver["ProcessingTimestampUTC"] = (
        processing_timestamp
    )

    silver["SourceFileName"] = BRONZE_FILE.name

    derived_columns = [
        "GenderLabel",
        "EthnicityLabel",
        "EducationLabel",
        "DiagnosisLabel",
        "AgeGroup",
        "MMSEBand",
        "FunctionalAssessmentBand",
        "ADLBand",
    ]

    missing_derived_values = (
        silver[derived_columns]
        .isna()
        .sum()
        .sum()
    )

    if missing_derived_values > 0:
        raise ValueError(
            "Some Silver labels or score bands could not "
            "be generated. Review source categories and ranges."
        )

    if silver["PatientID"].duplicated().any():
        raise ValueError(
            "PatientID is no longer unique after transformation."
        )

    if len(silver) != len(dataframe):
        raise ValueError(
            "The Silver transformation changed the row count."
        )

    return silver


def transform_to_silver() -> dict:
    """Read Bronze, create Silver and save CSV, Parquet and metadata."""

    create_directories()

    if not BRONZE_FILE.exists():
        raise FileNotFoundError(
            "The Bronze dataset does not exist. "
            "Run: python -m src.ingest"
        )

    bronze = pd.read_csv(BRONZE_FILE)

    silver = transform_dataframe(bronze)

    silver.to_csv(
        SILVER_CSV_FILE,
        index=False,
        encoding="utf-8-sig",
    )

    silver.to_parquet(
        SILVER_PARQUET_FILE,
        index=False,
        engine="pyarrow",
    )

    new_columns = [
        column
        for column in silver.columns
        if column not in bronze.columns
    ]

    removed_columns = [
        column
        for column in bronze.columns
        if column not in silver.columns
    ]

    metadata = {
        "generated_at_utc": datetime.now(
            timezone.utc
        ).isoformat(),
        "source_file": BRONZE_FILE.name,
        "silver_csv_file": SILVER_CSV_FILE.name,
        "silver_parquet_file": SILVER_PARQUET_FILE.name,
        "bronze_row_count": int(bronze.shape[0]),
        "silver_row_count": int(silver.shape[0]),
        "bronze_column_count": int(bronze.shape[1]),
        "silver_column_count": int(silver.shape[1]),
        "removed_columns": removed_columns,
        "new_columns": new_columns,
        "missing_values": int(
            silver.isna().sum().sum()
        ),
        "duplicate_patient_ids": int(
            silver["PatientID"].duplicated().sum()
        ),
    }

    with SILVER_METADATA_FILE.open(
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


if __name__ == "__main__":
    result = transform_to_silver()

    print("Silver transformation completed successfully.")
    print(
        json.dumps(
            result,
            indent=4,
            ensure_ascii=False,
        )
    )
