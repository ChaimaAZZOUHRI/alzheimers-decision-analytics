"""Unit tests for the Bronze-to-Silver transformation."""

import pandas as pd
import pytest

from src.transform import transform_dataframe


def make_transform_dataframe() -> pd.DataFrame:
    """Create a small dataframe for Silver transformation tests."""

    return pd.DataFrame(
        {
            "PatientID": [1001, 1002],
            "Age": [65, 82],
            "Gender": [0, 1],
            "Ethnicity": [0, 2],
            "EducationLevel": [1, 3],
            "MMSE": [9.0, 27.0],
            "FunctionalAssessment": [3.5, 8.0],
            "ADL": [5.0, 9.0],
            "Diagnosis": [0, 1],
            "FamilyHistoryAlzheimers": [1, 1],
            "CardiovascularDisease": [0, 1],
            "Diabetes": [0, 0],
            "Depression": [1, 0],
            "HeadInjury": [0, 0],
            "Hypertension": [0, 1],
            "MemoryComplaints": [1, 1],
            "BehavioralProblems": [0, 1],
            "Confusion": [0, 1],
            "Disorientation": [0, 1],
            "PersonalityChanges": [0, 0],
            "DifficultyCompletingTasks": [1, 1],
            "Forgetfulness": [1, 1],
            "DoctorInCharge": ["XXXConfid", "XXXConfid"],
        }
    )


def test_transform_preserves_row_count():
    bronze = make_transform_dataframe()

    silver = transform_dataframe(bronze)

    assert len(silver) == len(bronze)


def test_constant_doctor_column_is_removed():
    bronze = make_transform_dataframe()

    silver = transform_dataframe(bronze)

    assert "DoctorInCharge" not in silver.columns


def test_category_labels_are_created():
    silver = transform_dataframe(make_transform_dataframe())

    assert silver.loc[0, "GenderLabel"] == "Male"
    assert silver.loc[1, "GenderLabel"] == "Female"

    assert silver.loc[0, "EthnicityLabel"] == "Caucasian"
    assert silver.loc[1, "EthnicityLabel"] == "Asian"

    assert silver.loc[0, "EducationLabel"] == "High School"
    assert silver.loc[1, "EducationLabel"] == "Higher Education"

    assert silver.loc[0, "DiagnosisLabel"] == "Not Diagnosed"
    assert silver.loc[1, "DiagnosisLabel"] == "Diagnosed"


def test_age_groups_are_created_correctly():
    silver = transform_dataframe(make_transform_dataframe())

    assert str(silver.loc[0, "AgeGroup"]) == "60-69"
    assert str(silver.loc[1, "AgeGroup"]) == "80-90"


def test_score_bands_are_created_correctly():
    silver = transform_dataframe(make_transform_dataframe())

    assert str(silver.loc[0, "MMSEBand"]) == "0-9"
    assert str(silver.loc[1, "MMSEBand"]) == "25-30"

    assert (
        str(silver.loc[0, "FunctionalAssessmentBand"])
        == "0-3.99"
    )
    assert (
        str(silver.loc[1, "FunctionalAssessmentBand"])
        == "7-10"
    )

    assert str(silver.loc[0, "ADLBand"]) == "4-6.99"
    assert str(silver.loc[1, "ADLBand"]) == "7-10"


def test_history_and_symptom_counts_are_created():
    silver = transform_dataframe(make_transform_dataframe())

    assert silver.loc[0, "MedicalHistoryCount"] == 2
    assert silver.loc[1, "MedicalHistoryCount"] == 3

    assert silver.loc[0, "SymptomCount"] == 3
    assert silver.loc[1, "SymptomCount"] == 6


def test_lineage_columns_are_created():
    silver = transform_dataframe(make_transform_dataframe())

    assert silver["ProcessingTimestampUTC"].notna().all()
    assert (
        silver["SourceFileName"]
        == "alzheimers_disease_data_bronze.csv"
    ).all()


def test_missing_required_column_raises_error():
    bronze = make_transform_dataframe().drop(columns=["MMSE"])

    with pytest.raises(KeyError):
        transform_dataframe(bronze)


def test_duplicate_patient_id_raises_error():
    bronze = make_transform_dataframe()
    bronze.loc[1, "PatientID"] = bronze.loc[0, "PatientID"]

    with pytest.raises(ValueError, match="PatientID"):
        transform_dataframe(bronze)
