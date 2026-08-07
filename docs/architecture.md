# Project Architecture

## 1. Overview

This project implements an end-to-end decision analytics solution based on an Alzheimer's disease dataset.

The objective is to transform a raw CSV dataset into validated, structured and analytics-ready information that can support exploratory and decision-oriented analysis through a Power BI dashboard.

The solution covers the complete analytical data lifecycle:

Source data -> ingestion -> data quality -> transformation -> analytical warehouse -> dbt modelling -> Gold analytical datasets -> Power BI -> orchestration.

---

## 2. General Architecture

The project follows a layered data architecture.

    Kaggle CSV Dataset
            |
            v
        SOURCE
    Original CSV file
            |
            v
        BRONZE
    Immutable raw copy
            |
            v
    DATA QUALITY CHECKS
    Schema
    Missing values
    Duplicates
    Domains
    Numeric ranges
    Patient identifiers
            |
            v
        SILVER
    Cleaned and enriched data
            |
            v
        DUCKDB
    Analytical warehouse
            |
            v
          dbt
    Staging models
            |
            v
    Dimensions + Fact
            |
            v
        GOLD
    Analytical models
            |
            v
    Power BI exports
            |
            v
    POWER BI DASHBOARD

Apache Airflow orchestrates the complete pipeline.

---

## 3. Source Layer

The original dataset is:

`alzheimers_disease_data.csv`

It contains:

- 2,149 patient records;
- 35 source variables;
- demographic information;
- lifestyle variables;
- medical history;
- clinical measurements;
- cognitive and functional assessments;
- symptoms;
- Alzheimer's diagnosis status.

The source dataset is stored locally under:

`data/source/`

The original CSV file is not committed to GitHub.

This keeps the repository focused on source code, configuration, analytical models and documentation.

---

## 4. Bronze Layer

The Bronze layer represents the raw ingestion layer.

The ingestion process:

- reads the original source file;
- creates a byte-for-byte Bronze copy;
- preserves the raw data without analytical transformation;
- calculates a SHA-256 checksum;
- records ingestion information;
- provides a reproducible input for subsequent processing.

The Bronze file is generated under:

`data/bronze/`

The main Python module is:

`src/ingest.py`

The Bronze layer ensures that transformations are never applied directly to the original source file.

---

## 5. Data Quality Layer

Before transformation, automated quality controls are applied to the Bronze dataset.

The quality process verifies:

- expected schema;
- expected number of columns;
- missing columns;
- unexpected columns;
- missing values;
- duplicate records;
- duplicated `PatientID`;
- null `PatientID`;
- binary-variable domains;
- categorical-variable domains;
- numeric ranges;
- constant columns.

The main module is:

`src/quality_checks.py`

The quality checks generate a quality report under:

`reports/quality/`

A constant `DoctorInCharge` field is detected during quality assessment and is subsequently removed from the analytical Silver dataset.

---

## 6. Silver Layer

The Silver layer contains the cleaned and enriched analytical dataset.

The main transformation module is:

`src/transform.py`

The transformation process includes:

- removal of the constant `DoctorInCharge` variable;
- creation of readable categorical labels;
- creation of diagnosis labels;
- age grouping;
- medical-history aggregation;
- symptom aggregation;
- MMSE categorisation;
- Functional Assessment categorisation;
- ADL categorisation;
- addition of data-lineage information.

Examples of derived variables include:

- `GenderLabel`;
- `EthnicityLabel`;
- `EducationLabel`;
- `DiagnosisLabel`;
- `AgeGroup`;
- `MedicalHistoryCount`;
- `SymptomCount`;
- `MMSEBand`;
- `FunctionalAssessmentBand`;
- `ADLBand`;
- `ProcessingTimestampUTC`;
- `SourceFileName`.

The Silver dataset is stored under:

`data/silver/`

---

## 7. Analytical Warehouse

The Silver dataset is loaded into a DuckDB analytical database.

DuckDB was selected because it provides:

- a lightweight analytical database;
- SQL support;
- local execution;
- simple integration with Python;
- direct integration with dbt;
- no requirement for a separate database server.

The main loading module is:

`src/load_duckdb.py`

The principal Silver warehouse table is:

`silver_alzheimer_patients`

The generated database is stored under:

`data/warehouse/`

DuckDB database files are generated locally and are not committed to GitHub.

---

## 8. dbt Analytical Modelling

dbt is used to structure the analytical layer of the project.

The dbt project is located under:

`dbt_project/`

### 8.1 Staging Layer

The staging layer standardises the Silver warehouse data before analytical modelling.

Main model:

`stg_alzheimer_patients`

### 8.2 Dimensional Models

The analytical model contains dimensions and a fact table.

Main models include:

- `dim_patient`;
- `dim_diagnosis`;
- `fct_patient_assessment`.

These models provide a structured analytical representation of patient characteristics, diagnosis information and assessments.

### 8.3 Gold Layer

The Gold layer provides aggregated datasets designed for decision analysis and Power BI.

Main Gold models:

- `gold_kpi_overview`;
- `gold_demographics`;
- `gold_risk_factors`;
- `gold_symptoms`.

These datasets are specifically designed to support dashboard KPIs and visual analysis.

---

## 9. dbt Data Testing

Automated dbt tests are implemented to verify analytical consistency.

Tests include:

- uniqueness checks;
- not-null checks;
- accepted-value checks;
- source validation;
- dimension-key validation;
- Gold aggregation consistency;
- demographic total consistency;
- risk-factor count consistency;
- symptom count consistency.

The validated dbt project currently contains:

- 8 analytical models;
- 46 dbt data tests;
- 1 source;
- 54 successful dbt build operations.

A successful validation produces:

`PASS=54 WARN=0 ERROR=0`

---

## 10. Power BI Export Layer

The analytical datasets required by Power BI are exported from DuckDB/dbt.

The export process is implemented in:

`src/export_powerbi.py`

Seven analytical CSV exports are generated:

- `dim_patient.csv`;
- `dim_diagnosis.csv`;
- `fct_patient_assessment.csv`;
- `gold_kpi_overview.csv`;
- `gold_demographics.csv`;
- `gold_risk_factors.csv`;
- `gold_symptoms.csv`.

Generated analytical exports are stored under:

`data/gold/`

---

## 11. Power BI Dashboard

The Power BI project is stored under:

`dashboard/`

The dashboard is implemented using the Power BI Project format (PBIP).

It contains four analytical pages:

### Overview

Provides the principal indicators and a global view of the dataset.

### Demographics

Analyses the population according to demographic characteristics such as age, gender, ethnicity and education.

### Risk Factors

Explores lifestyle and medical-history variables associated with the diagnosis groups within the synthetic dataset.

### Symptoms & Cognitive Assessment

Analyses symptoms together with cognitive, functional and daily-living assessment information.

The semantic model includes seven analytical tables corresponding to the dbt/Power BI export layer.

---

## 12. Power BI Validation

Automated Power BI project validation is provided through:

`dashboard/scripts/validate_powerbi_project.ps1`

The validation checks:

- presence of the PBIP project;
- expected report pages;
- expected semantic-model tables;
- expected Power BI exports;
- PBIR structural consistency.

The Power BI validation currently completes with zero structural errors.

Local Power BI cache files and machine-specific configuration files are excluded from Git.

---

## 13. Airflow Orchestration

Apache Airflow orchestrates the complete data pipeline.

The DAG is defined in:

`dags/alzheimers_pipeline_dag.py`

The workflow contains seven sequential tasks:

    check_source_file
            |
            v
    ingest_bronze
            |
            v
    validate_bronze_quality
            |
            v
    transform_silver
            |
            v
    load_duckdb
            |
            v
    run_dbt_models
            |
            v
    export_powerbi

This orchestration guarantees that every processing stage is executed in the correct order.

---

## 14. Docker Environment

Apache Airflow runs inside Docker containers.

The project uses:

- Docker;
- Docker Compose;
- Apache Airflow;
- PostgreSQL;
- Redis;
- Celery.

The main container-related files are:

- `Dockerfile`;
- `docker-compose.yaml`;
- `.dockerignore`.

The Docker image installs the Python dependencies and includes the dbt project required by the Airflow workflow.

---

## 15. Automated Python Testing

Unit tests are implemented with pytest.

Test files:

- `tests/test_quality_checks.py`;
- `tests/test_transform.py`.

The tests validate important behaviour such as:

- valid schemas;
- missing-value detection;
- duplicated identifiers;
- binary domains;
- categorical domains;
- numeric ranges;
- Silver row preservation;
- derived labels;
- age groups;
- cognitive and functional bands;
- symptom counts;
- medical-history counts;
- lineage variables;
- transformation errors.

The current Python test suite contains:

`17 passed`

---

## 16. Repository Structure

The main repository structure is:

    alzheimers-decision-analytics/
    |
    |-- dags/
    |   `-- alzheimers_pipeline_dag.py
    |
    |-- dashboard/
    |   |-- alzheimers_dashboard.pbip
    |   |-- alzheimers_dashboard.Report/
    |   |-- alzheimers_dashboard.SemanticModel/
    |   |-- scripts/
    |   `-- themes/
    |
    |-- data/
    |   |-- source/
    |   |-- bronze/
    |   |-- silver/
    |   |-- gold/
    |   `-- warehouse/
    |
    |-- dbt_project/
    |   |-- models/
    |   |-- tests/
    |   |-- dbt_project.yml
    |   `-- profiles.yml
    |
    |-- docs/
    |
    |-- reports/
    |   `-- quality/
    |
    |-- src/
    |   |-- config.py
    |   |-- ingest.py
    |   |-- quality_checks.py
    |   |-- transform.py
    |   |-- load_duckdb.py
    |   `-- export_powerbi.py
    |
    |-- tests/
    |
    |-- Dockerfile
    |-- docker-compose.yaml
    |-- pytest.ini
    |-- requirements.txt
    `-- README.md

---

## 17. Technology Stack

The project uses:

- Python 3.12;
- pandas;
- PyArrow;
- DuckDB;
- dbt;
- dbt-duckdb;
- Apache Airflow;
- PostgreSQL;
- Redis;
- Celery;
- Docker;
- Docker Compose;
- Power BI;
- PowerShell;
- pytest;
- Git;
- GitHub.

---

## 18. Version-Control Strategy

The Git repository contains only files required to understand, reproduce and maintain the project.

Versioned elements include:

- Python source code;
- Airflow DAG;
- dbt models;
- dbt tests;
- Power BI PBIP definitions;
- Power BI helper scripts;
- configuration files;
- automated tests;
- documentation.

Generated or machine-specific files are excluded.

Examples include:

- source CSV data;
- Bronze files;
- Silver files;
- Gold exports;
- DuckDB database files;
- Airflow runtime logs;
- dbt `target` artifacts;
- dbt logs;
- Power BI local cache;
- Power BI local settings;
- backup files;
- environment secrets.

These exclusions are controlled by:

`.gitignore`

and:

`.dockerignore`

---

## 19. Reproducibility

The project has been designed so that the analytical pipeline can be regenerated from the original source dataset.

The general reproducibility workflow is:

1. Download the source dataset.
2. Place the CSV file under `data/source/`.
3. Install the required dependencies.
4. Run the pipeline locally or through Airflow.
5. Generate Bronze and Silver datasets.
6. Load the DuckDB warehouse.
7. Execute the dbt models and tests.
8. Generate Power BI exports.
9. Open the PBIP dashboard in Power BI Desktop.

Generated datasets and warehouse files therefore do not need to be stored in GitHub.

---

## 20. Data and Analytical Limitations

The Alzheimer's disease dataset used in this project is synthetic.

Therefore:

- the records do not represent real patients;
- observed patterns must not be interpreted as epidemiological findings;
- associations visible in the dashboard do not demonstrate causality;
- the dashboard must not be used for clinical diagnosis;
- the project is intended for data analytics and decision-support training.

The main purpose is to demonstrate an end-to-end data analytics architecture rather than to develop a clinical predictive system.

---

## 21. Final Architecture Summary

The project implements the following complete decision-analytics chain:

    Synthetic Alzheimer's Dataset
                |
              Python
                |
        Bronze Ingestion
                |
        Data Quality Controls
                |
        Silver Transformation
                |
             DuckDB
                |
              dbt
                |
       Dimensional Models
                |
          Gold Models
                |
        Power BI Exports
                |
        Power BI Dashboard

                 +
                 |
          Apache Airflow
        Pipeline Orchestration

                 +
                 |
        pytest + dbt tests
       Automated Validation

This architecture separates raw data ingestion, data quality, transformation, analytical modelling, visualisation and orchestration while maintaining reproducibility and clear data lineage.
