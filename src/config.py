"""Central configuration for the Alzheimer decision analytics project."""

from pathlib import Path


# Project folders
PROJECT_ROOT = Path(__file__).resolve().parents[1]

DATA_DIR = PROJECT_ROOT / "data"
SOURCE_DIR = DATA_DIR / "source"
BRONZE_DIR = DATA_DIR / "bronze"
SILVER_DIR = DATA_DIR / "silver"
GOLD_DIR = DATA_DIR / "gold"

REPORTS_DIR = PROJECT_ROOT / "reports"
QUALITY_REPORT_DIR = REPORTS_DIR / "quality"

LOG_DIR = PROJECT_ROOT / "logs"


# Input and output files
SOURCE_FILE = SOURCE_DIR / "alzheimers_disease_data.csv"

BRONZE_FILE = (
    BRONZE_DIR / "alzheimers_disease_data_bronze.csv"
)

BRONZE_METADATA_FILE = (
    BRONZE_DIR / "alzheimers_disease_data_bronze_metadata.json"
)

QUALITY_JSON_FILE = (
    QUALITY_REPORT_DIR / "data_quality_report.json"
)

QUALITY_CSV_FILE = (
    QUALITY_REPORT_DIR / "data_quality_checks.csv"
)

PIPELINE_LOG_FILE = LOG_DIR / "pipeline.log"


# Expected source columns
EXPECTED_COLUMNS = [
    "PatientID",
    "Age",
    "Gender",
    "Ethnicity",
    "EducationLevel",
    "BMI",
    "Smoking",
    "AlcoholConsumption",
    "PhysicalActivity",
    "DietQuality",
    "SleepQuality",
    "FamilyHistoryAlzheimers",
    "CardiovascularDisease",
    "Diabetes",
    "Depression",
    "HeadInjury",
    "Hypertension",
    "SystolicBP",
    "DiastolicBP",
    "CholesterolTotal",
    "CholesterolLDL",
    "CholesterolHDL",
    "CholesterolTriglycerides",
    "MMSE",
    "FunctionalAssessment",
    "MemoryComplaints",
    "BehavioralProblems",
    "ADL",
    "Confusion",
    "Disorientation",
    "PersonalityChanges",
    "DifficultyCompletingTasks",
    "Forgetfulness",
    "Diagnosis",
    "DoctorInCharge",
]


# Variables that should contain only 0 or 1
BINARY_COLUMNS = [
    "Gender",
    "Smoking",
    "FamilyHistoryAlzheimers",
    "CardiovascularDisease",
    "Diabetes",
    "Depression",
    "HeadInjury",
    "Hypertension",
    "MemoryComplaints",
    "BehavioralProblems",
    "Confusion",
    "Disorientation",
    "PersonalityChanges",
    "DifficultyCompletingTasks",
    "Forgetfulness",
    "Diagnosis",
]


# Valid category codes
CATEGORY_RULES = {
    "Ethnicity": {0, 1, 2, 3},
    "EducationLevel": {0, 1, 2, 3},
}


# Expected numerical ranges
RANGE_RULES = {
    "Age": (60, 90),
    "BMI": (15, 40),
    "AlcoholConsumption": (0, 20),
    "PhysicalActivity": (0, 10),
    "DietQuality": (0, 10),
    "SleepQuality": (4, 10),
    "SystolicBP": (90, 180),
    "DiastolicBP": (60, 120),
    "CholesterolTotal": (150, 300),
    "CholesterolLDL": (50, 200),
    "CholesterolHDL": (20, 100),
    "CholesterolTriglycerides": (50, 400),
    "MMSE": (0, 30),
    "FunctionalAssessment": (0, 10),
    "ADL": (0, 10),
}


def create_directories() -> None:
    """Create required output directories."""

    directories = [
        SOURCE_DIR,
        BRONZE_DIR,
        SILVER_DIR,
        GOLD_DIR,
        QUALITY_REPORT_DIR,
        LOG_DIR,
    ]

    for directory in directories:
        directory.mkdir(parents=True, exist_ok=True)
# Silver output files
SILVER_PARQUET_FILE = (
    SILVER_DIR / "alzheimers_disease_data_silver.parquet"
)

SILVER_CSV_FILE = (
    SILVER_DIR / "alzheimers_disease_data_silver.csv"
)

SILVER_METADATA_FILE = (
    SILVER_DIR / "alzheimers_disease_data_silver_metadata.json"
)

# Analytical warehouse
WAREHOUSE_DIR = DATA_DIR / "warehouse"

DUCKDB_FILE = (
    WAREHOUSE_DIR / "alzheimers_analytics.duckdb"
)

DUCKDB_METADATA_FILE = (
    WAREHOUSE_DIR / "alzheimers_analytics_metadata.json"
)

# Power BI exports
POWERBI_EXPORT_DIR = GOLD_DIR / "powerbi"

POWERBI_EXPORT_METADATA_FILE = (
    POWERBI_EXPORT_DIR / "powerbi_export_metadata.json"
)
