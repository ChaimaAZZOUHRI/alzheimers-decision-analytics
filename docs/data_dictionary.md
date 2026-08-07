# Data Dictionary

## 1. Purpose

This document describes the variables used throughout the Alzheimer's Decision Analytics project.

The original dataset contains 35 source variables.

During the Bronze-to-Silver transformation:

- `DoctorInCharge` is removed because it is constant;
- 12 analytical and lineage variables are added;
- the final Silver dataset contains 46 variables.

The dictionary distinguishes:

- source variables;
- categorical coding;
- validated numerical ranges;
- Silver derived variables;
- lineage variables.

The dataset used in this project is synthetic and must not be interpreted as representing real patients.

---

## 2. Dataset Summary

| Attribute | Value |
|---|---|
| Source records | 2,149 |
| Source variables | 35 |
| Removed during Silver transformation | 1 |
| Added during Silver transformation | 12 |
| Final Silver variables | 46 |
| Primary identifier | `PatientID` |
| Target analytical variable | `Diagnosis` |
| Source format | CSV |
| Silver formats | CSV and Parquet |

---

# 3. Source Variables

## 3.1 Identification

| Variable | Type | Valid values / range | Description |
|---|---|---|---|
| `PatientID` | Integer | Unique identifier | Unique identifier assigned to each patient record |
| `DoctorInCharge` | Text | Constant value in source | Administrative field identifying the doctor in charge; removed in the Silver layer because it provides no analytical variability |

`PatientID` must be:

- non-null;
- unique across the dataset.

---

## 3.2 Demographic Variables

| Variable | Type | Valid values / range | Description |
|---|---|---|---|
| `Age` | Integer | 60-90 | Patient age in years |
| `Gender` | Integer / categorical | 0, 1 | Encoded gender |
| `Ethnicity` | Integer / categorical | 0, 1, 2, 3 | Encoded ethnicity category |
| `EducationLevel` | Integer / categorical | 0, 1, 2, 3 | Encoded educational attainment |

### Gender Coding

| Code | Label |
|---:|---|
| 0 | Male |
| 1 | Female |

### Ethnicity Coding

| Code | Label |
|---:|---|
| 0 | Caucasian |
| 1 | African American |
| 2 | Asian |
| 3 | Other |

### Education Coding

| Code | Label |
|---:|---|
| 0 | None |
| 1 | High School |
| 2 | Bachelor's |
| 3 | Higher Education |

---

## 3.3 Lifestyle Variables

| Variable | Type | Valid values / range | Description |
|---|---|---|---|
| `BMI` | Numeric | 15-40 | Body mass index |
| `Smoking` | Binary | 0, 1 | Smoking-status indicator |
| `AlcoholConsumption` | Numeric | 0-20 | Alcohol-consumption measure supplied by the source dataset |
| `PhysicalActivity` | Numeric | 0-10 | Physical-activity measure supplied by the source dataset |
| `DietQuality` | Numeric | 0-10 | Diet-quality score |
| `SleepQuality` | Numeric | 4-10 | Sleep-quality score |

### Binary Coding

For `Smoking`:

| Code | Meaning |
|---:|---|
| 0 | No |
| 1 | Yes |

---

## 3.4 Medical History Variables

| Variable | Type | Valid values | Description |
|---|---|---|---|
| `FamilyHistoryAlzheimers` | Binary | 0, 1 | Presence of a family history of Alzheimer's disease |
| `CardiovascularDisease` | Binary | 0, 1 | Cardiovascular-disease history |
| `Diabetes` | Binary | 0, 1 | Diabetes history |
| `Depression` | Binary | 0, 1 | Depression history |
| `HeadInjury` | Binary | 0, 1 | History of head injury |
| `Hypertension` | Binary | 0, 1 | Hypertension history |

For all medical-history indicators:

| Code | Meaning |
|---:|---|
| 0 | No |
| 1 | Yes |

These six variables are also used to calculate the Silver variable:

`MedicalHistoryCount`

---

## 3.5 Blood Pressure Variables

| Variable | Type | Valid range | Description |
|---|---|---|---|
| `SystolicBP` | Numeric | 90-180 | Systolic blood-pressure measurement |
| `DiastolicBP` | Numeric | 60-120 | Diastolic blood-pressure measurement |

---

## 3.6 Cholesterol Variables

| Variable | Type | Valid range | Description |
|---|---|---|---|
| `CholesterolTotal` | Numeric | 150-300 | Total cholesterol measurement |
| `CholesterolLDL` | Numeric | 50-200 | LDL cholesterol measurement |
| `CholesterolHDL` | Numeric | 20-100 | HDL cholesterol measurement |
| `CholesterolTriglycerides` | Numeric | 50-400 | Triglyceride measurement |

---

## 3.7 Cognitive and Functional Assessment Variables

| Variable | Type | Valid range | Description |
|---|---|---|---|
| `MMSE` | Numeric | 0-30 | Mini-Mental State Examination score represented in the dataset |
| `FunctionalAssessment` | Numeric | 0-10 | Functional-assessment score |
| `ADL` | Numeric | 0-10 | Activities of Daily Living score |

The project creates analytical bands from these variables without assigning clinical interpretations to the bands.

---

## 3.8 Symptom Variables

| Variable | Type | Valid values | Description |
|---|---|---|---|
| `MemoryComplaints` | Binary | 0, 1 | Indicator of memory complaints |
| `BehavioralProblems` | Binary | 0, 1 | Indicator of behavioural problems |
| `Confusion` | Binary | 0, 1 | Indicator of confusion |
| `Disorientation` | Binary | 0, 1 | Indicator of disorientation |
| `PersonalityChanges` | Binary | 0, 1 | Indicator of personality changes |
| `DifficultyCompletingTasks` | Binary | 0, 1 | Indicator of difficulty completing tasks |
| `Forgetfulness` | Binary | 0, 1 | Indicator of forgetfulness |

For all symptom variables:

| Code | Meaning |
|---:|---|
| 0 | Symptom not indicated |
| 1 | Symptom indicated |

These seven variables are used to calculate:

`SymptomCount`

---

## 3.9 Diagnosis Variable

| Variable | Type | Valid values | Description |
|---|---|---|---|
| `Diagnosis` | Binary | 0, 1 | Diagnosis-status variable used for analytical comparison |

### Diagnosis Coding

| Code | Label |
|---:|---|
| 0 | Not Diagnosed |
| 1 | Diagnosed |

`Diagnosis` is used for descriptive and decision-oriented analysis throughout the Gold models and Power BI dashboard.

Because the dataset is synthetic, this variable must not be interpreted as a clinical diagnosis generated by this project.

---

# 4. Source Data Quality Rules

The project validates the following source-variable rules before Silver transformation.

## 4.1 Binary Variables

The following variables must contain only `0` or `1`:

- `Gender`;
- `Smoking`;
- `FamilyHistoryAlzheimers`;
- `CardiovascularDisease`;
- `Diabetes`;
- `Depression`;
- `HeadInjury`;
- `Hypertension`;
- `MemoryComplaints`;
- `BehavioralProblems`;
- `Confusion`;
- `Disorientation`;
- `PersonalityChanges`;
- `DifficultyCompletingTasks`;
- `Forgetfulness`;
- `Diagnosis`.

---

## 4.2 Categorical Variables

| Variable | Accepted codes |
|---|---|
| `Ethnicity` | 0, 1, 2, 3 |
| `EducationLevel` | 0, 1, 2, 3 |

---

## 4.3 Numerical Range Rules

| Variable | Minimum | Maximum |
|---|---:|---:|
| `Age` | 60 | 90 |
| `BMI` | 15 | 40 |
| `AlcoholConsumption` | 0 | 20 |
| `PhysicalActivity` | 0 | 10 |
| `DietQuality` | 0 | 10 |
| `SleepQuality` | 4 | 10 |
| `SystolicBP` | 90 | 180 |
| `DiastolicBP` | 60 | 120 |
| `CholesterolTotal` | 150 | 300 |
| `CholesterolLDL` | 50 | 200 |
| `CholesterolHDL` | 20 | 100 |
| `CholesterolTriglycerides` | 50 | 400 |
| `MMSE` | 0 | 30 |
| `FunctionalAssessment` | 0 | 10 |
| `ADL` | 0 | 10 |

These ranges are validation rules implemented by the project and correspond to the expected domains of the source dataset.

---

# 5. Silver Derived Variables

The Silver transformation enriches the source dataset with 12 additional variables.

| Derived variable | Type | Source variable(s) | Description |
|---|---|---|---|
| `GenderLabel` | Text | `Gender` | Human-readable gender label |
| `EthnicityLabel` | Text | `Ethnicity` | Human-readable ethnicity label |
| `EducationLabel` | Text | `EducationLevel` | Human-readable education label |
| `DiagnosisLabel` | Text | `Diagnosis` | Human-readable diagnosis label |
| `AgeGroup` | Category | `Age` | Analytical age group |
| `MedicalHistoryCount` | Integer | Six medical-history variables | Number of indicated medical-history conditions |
| `SymptomCount` | Integer | Seven symptom variables | Number of indicated symptoms |
| `MMSEBand` | Category | `MMSE` | Analytical MMSE score band |
| `FunctionalAssessmentBand` | Category | `FunctionalAssessment` | Analytical functional-assessment band |
| `ADLBand` | Category | `ADL` | Analytical ADL band |
| `ProcessingTimestampUTC` | Timestamp | Pipeline | UTC timestamp for Silver processing |
| `SourceFileName` | Text | Pipeline | Name of the Bronze source file used for transformation |

---

# 6. Derived Categorical Labels

## 6.1 GenderLabel

Derived from:

`Gender`

| Original code | `GenderLabel` |
|---:|---|
| 0 | Male |
| 1 | Female |

---

## 6.2 EthnicityLabel

Derived from:

`Ethnicity`

| Original code | `EthnicityLabel` |
|---:|---|
| 0 | Caucasian |
| 1 | African American |
| 2 | Asian |
| 3 | Other |

---

## 6.3 EducationLabel

Derived from:

`EducationLevel`

| Original code | `EducationLabel` |
|---:|---|
| 0 | None |
| 1 | High School |
| 2 | Bachelor's |
| 3 | Higher Education |

---

## 6.4 DiagnosisLabel

Derived from:

`Diagnosis`

| Original code | `DiagnosisLabel` |
|---:|---|
| 0 | Not Diagnosed |
| 1 | Diagnosed |

---

# 7. Age Groups

`AgeGroup` is derived from `Age`.

| Age range | `AgeGroup` |
|---|---|
| 60-69 | `60-69` |
| 70-79 | `70-79` |
| 80-90 | `80-90` |

These bands are used to support demographic segmentation in analytical models and Power BI.

---

# 8. MedicalHistoryCount

`MedicalHistoryCount` is calculated as the row-wise sum of six binary variables:

1. `FamilyHistoryAlzheimers`
2. `CardiovascularDisease`
3. `Diabetes`
4. `Depression`
5. `HeadInjury`
6. `Hypertension`

Possible range:

`0-6`

Example:

If a record has:

- family history = 1;
- cardiovascular disease = 0;
- diabetes = 1;
- depression = 0;
- head injury = 0;
- hypertension = 1;

then:

`MedicalHistoryCount = 3`

This variable represents a simple count and is not a clinical risk score.

---

# 9. SymptomCount

`SymptomCount` is calculated as the row-wise sum of seven binary symptom indicators:

1. `MemoryComplaints`
2. `BehavioralProblems`
3. `Confusion`
4. `Disorientation`
5. `PersonalityChanges`
6. `DifficultyCompletingTasks`
7. `Forgetfulness`

Possible range:

`0-7`

This variable provides a compact analytical summary of the number of symptoms indicated for each synthetic patient record.

It is not a clinical severity score.

---

# 10. MMSEBand

`MMSEBand` is derived from the numerical `MMSE` field.

| MMSE values | `MMSEBand` |
|---|---|
| 0 to <10 | `0-9` |
| 10 to <20 | `10-19` |
| 20 to <25 | `20-24` |
| 25 to 30 | `25-30` |

These bands are created strictly for descriptive analytical segmentation.

The project does not assign diagnostic or clinical meaning to these categories.

---

# 11. FunctionalAssessmentBand

`FunctionalAssessmentBand` is derived from `FunctionalAssessment`.

| Values | `FunctionalAssessmentBand` |
|---|---|
| 0 to <4 | `0-3.99` |
| 4 to <7 | `4-6.99` |
| 7 to 10 | `7-10` |

These categories are used for dashboard segmentation and descriptive comparison.

---

# 12. ADLBand

`ADLBand` is derived from `ADL`.

| Values | `ADLBand` |
|---|---|
| 0 to <4 | `0-3.99` |
| 4 to <7 | `4-6.99` |
| 7 to 10 | `7-10` |

The categories are analytical groupings rather than clinical classifications.

---

# 13. Lineage Variables

## 13.1 ProcessingTimestampUTC

| Property | Description |
|---|---|
| Variable | `ProcessingTimestampUTC` |
| Type | Timestamp |
| Generated by | Silver transformation |
| Purpose | Records when the Silver dataset was generated |
| Time standard | UTC |

This variable supports traceability and pipeline lineage.

---

## 13.2 SourceFileName

| Property | Description |
|---|---|
| Variable | `SourceFileName` |
| Type | Text |
| Generated by | Silver transformation |
| Value | `alzheimers_disease_data_bronze.csv` |
| Purpose | Identifies the Bronze source used to generate the Silver record |

---

# 14. Removed Variable

The following field exists in the source and Bronze dataset but is intentionally removed from Silver:

| Variable | Reason for removal |
|---|---|
| `DoctorInCharge` | Constant field with no analytical variability or decision-support value |

The field is retained in Bronze to preserve the original source structure but excluded from downstream analytical modelling.

---

# 15. Bronze-to-Silver Variable Count

The transformation can be summarised as:

    Bronze
    35 columns
        |
        | Remove DoctorInCharge
        v
    34 retained source columns
        |
        | Add 12 derived variables
        v
    Silver
    46 columns

No patient rows are intentionally added or removed during this transformation.

---

# 16. Variable Classification Summary

## Identification

- `PatientID`

## Demographics

- `Age`
- `Gender`
- `Ethnicity`
- `EducationLevel`

## Lifestyle

- `BMI`
- `Smoking`
- `AlcoholConsumption`
- `PhysicalActivity`
- `DietQuality`
- `SleepQuality`

## Medical History

- `FamilyHistoryAlzheimers`
- `CardiovascularDisease`
- `Diabetes`
- `Depression`
- `HeadInjury`
- `Hypertension`

## Clinical Measurements

- `SystolicBP`
- `DiastolicBP`
- `CholesterolTotal`
- `CholesterolLDL`
- `CholesterolHDL`
- `CholesterolTriglycerides`

## Cognitive and Functional Assessments

- `MMSE`
- `FunctionalAssessment`
- `ADL`

## Symptoms

- `MemoryComplaints`
- `BehavioralProblems`
- `Confusion`
- `Disorientation`
- `PersonalityChanges`
- `DifficultyCompletingTasks`
- `Forgetfulness`

## Analytical Outcome

- `Diagnosis`

## Silver Analytical Variables

- `GenderLabel`
- `EthnicityLabel`
- `EducationLabel`
- `DiagnosisLabel`
- `AgeGroup`
- `MedicalHistoryCount`
- `SymptomCount`
- `MMSEBand`
- `FunctionalAssessmentBand`
- `ADLBand`

## Data Lineage

- `ProcessingTimestampUTC`
- `SourceFileName`

---

# 17. Analytical Interpretation Rules

The following principles apply when using the variables in reports and dashboards:

1. `Diagnosis` is an existing variable in the synthetic source dataset; the project does not generate a medical diagnosis.

2. `MedicalHistoryCount` is a simple count of six binary indicators and must not be presented as a validated medical risk score.

3. `SymptomCount` is a count of seven available symptom indicators and must not be interpreted as clinical severity.

4. MMSE, Functional Assessment and ADL bands are analytical segmentation variables created by this project.

5. Dashboard comparisons describe patterns present in the synthetic dataset only.

6. Differences between groups do not establish causal relationships.

7. No output from this project should be used for patient-level clinical decision-making.

---

# 18. Final Dictionary Summary

The data model preserves the original coded source variables while adding readable labels and analytical groupings.

This design allows:

- traceability back to the original data;
- reproducible transformations;
- human-readable reporting;
- consistent segmentation;
- dimensional modelling with dbt;
- reusable Power BI metrics;
- automated validation.

The final Silver layer contains 46 variables representing cleaned source attributes, analytical derivations and data-lineage information.
