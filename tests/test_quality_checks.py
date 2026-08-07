"""Unit tests for Bronze data-quality checks."""

import pandas as pd

from src.quality_checks import (
    check_binary_columns,
    check_category_columns,
    check_duplicates,
    check_missing_values,
    check_numeric_ranges,
    check_schema,
)


def make_valid_dataframe() -> pd.DataFrame:
    """Create a small valid dataset matching the expected Bronze schema."""

    return pd.DataFrame(
        {
            "PatientID": [1001, 1002],
            "Age": [65, 82],
            "Gender": [0, 1],
            "Ethnicity": [0, 2],
            "EducationLevel": [1, 3],
            "BMI": [22.0, 28.0],
            "Smoking": [0, 1],
            "AlcoholConsumption": [5.0, 10.0],
            "PhysicalActivity": [4.0, 7.0],
            "DietQuality": [6.0, 8.0],
            "SleepQuality": [7.0, 8.0],
            "FamilyHistoryAlzheimers": [0, 1],
            "CardiovascularDisease": [0, 1],
            "Diabetes": [0, 0],
            "Depression": [0, 1],
            "HeadInjury": [0, 0],
            "Hypertension": [0, 1],
            "SystolicBP": [120, 140],
            "DiastolicBP": [80, 90],
            "CholesterolTotal": [180.0, 220.0],
            "CholesterolLDL": [90.0, 130.0],
            "CholesterolHDL": [60.0, 50.0],
            "CholesterolTriglycerides": [110.0, 180.0],
            "MMSE": [27.0, 18.0],
            "FunctionalAssessment": [8.0, 5.0],
            "MemoryComplaints": [0, 1],
            "BehavioralProblems": [0, 1],
            "ADL": [8.0, 6.0],
            "Confusion": [0, 1],
            "Disorientation": [0, 1],
            "PersonalityChanges": [0, 1],
            "DifficultyCompletingTasks": [0, 1],
            "Forgetfulness": [0, 1],
            "Diagnosis": [0, 1],
            "DoctorInCharge": ["XXXConfid", "XXXConfid"],
        }
    )


def test_valid_dataframe_passes_schema_checks():
    dataframe = make_valid_dataframe()

    checks = check_schema(dataframe)

    assert all(check["status"] == "PASS" for check in checks)


def test_valid_dataframe_has_no_missing_values():
    dataframe = make_valid_dataframe()

    check = check_missing_values(dataframe)[0]

    assert check["status"] == "PASS"
    assert check["observed"] == 0


def test_valid_dataframe_has_unique_patient_ids():
    dataframe = make_valid_dataframe()

    checks = {
        check["check_name"]: check
        for check in check_duplicates(dataframe)
    }

    assert checks["duplicated_rows"]["status"] == "PASS"
    assert checks["duplicated_patient_ids"]["status"] == "PASS"
    assert checks["null_patient_ids"]["status"] == "PASS"


def test_duplicate_patient_id_fails():
    dataframe = make_valid_dataframe()
    dataframe.loc[1, "PatientID"] = dataframe.loc[0, "PatientID"]

    checks = {
        check["check_name"]: check
        for check in check_duplicates(dataframe)
    }

    assert checks["duplicated_patient_ids"]["status"] == "FAIL"


def test_invalid_binary_value_fails():
    dataframe = make_valid_dataframe()
    dataframe.loc[0, "Smoking"] = 2

    checks = {
        check["check_name"]: check
        for check in check_binary_columns(dataframe)
    }

    assert checks["binary_domain_Smoking"]["status"] == "FAIL"
    assert checks["binary_domain_Smoking"]["observed"] == [2]


def test_valid_categories_pass():
    dataframe = make_valid_dataframe()

    checks = check_category_columns(dataframe)

    assert all(check["status"] == "PASS" for check in checks)


def test_valid_numeric_ranges_pass():
    dataframe = make_valid_dataframe()

    checks = check_numeric_ranges(dataframe)

    assert all(check["status"] == "PASS" for check in checks)


def test_out_of_range_age_fails():
    dataframe = make_valid_dataframe()
    dataframe.loc[0, "Age"] = 95

    checks = {
        check["check_name"]: check
        for check in check_numeric_ranges(dataframe)
    }

    assert checks["numeric_range_Age"]["status"] == "FAIL"
    assert (
        checks["numeric_range_Age"]["observed"]["out_of_range_count"]
        == 1
    )
