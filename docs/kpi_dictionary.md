# KPI Dictionary

## 1. Purpose

This document defines the principal Key Performance Indicators (KPIs) and analytical metrics used in the Alzheimer's Decision Analytics project.

The KPIs are produced through:

- dbt Gold models;
- Power BI semantic-model measures;
- demographic aggregations;
- risk-factor aggregations;
- symptom aggregations.

The objective is to ensure that every KPI displayed in the dashboard has a clear definition and reproducible calculation.

Because the dataset is synthetic, these indicators describe patterns within the dataset only and must not be interpreted as clinical or epidemiological estimates.

---

# 2. KPI Overview Model

The main overview KPIs are produced by:

`gold_kpi_overview`

This model contains one aggregated row describing the complete analytical population.

---

## 2.1 Total Patients

### Name

`total_patients`

### Power BI Measure

`Total Patients`

### Definition

Number of unique patient records available for analysis.

### dbt Calculation

    COUNT(*)

### Power BI Calculation

    DISTINCTCOUNT(fct_patient_assessment[patient_id])

### Interpretation

Represents the total analytical population currently available in the dataset.

---

## 2.2 Diagnosed Patients

### Name

`diagnosed_patients`

### Power BI Measure

`Diagnosed Patients`

### Definition

Number of records for which:

`Diagnosis = 1`

### Calculation

    Number of patients with diagnosis_code = 1

### Power BI DAX Logic

    CALCULATE(
        [Total Patients],
        fct_patient_assessment[diagnosis_code] = 1
    )

### Interpretation

Represents records labelled as diagnosed in the synthetic source dataset.

The project itself does not generate this diagnosis.

---

## 2.3 Not Diagnosed Patients

### Name

`not_diagnosed_patients`

### Power BI Measure

`Not Diagnosed Patients`

### Definition

Number of records for which:

`Diagnosis = 0`

### Calculation

    Number of patients with diagnosis_code = 0

### Interpretation

Represents records labelled as not diagnosed in the source dataset.

---

## 2.4 Diagnosis Rate

### dbt Name

`diagnosis_rate_pct`

### Power BI Measure

`Diagnosis Rate`

### Definition

Percentage of analytical records labelled as diagnosed.

### Formula

    Diagnosed Patients
    ------------------- x 100
      Total Patients

### dbt Calculation

    100 × diagnosed_patients / total_patients

### Power BI DAX Logic

    DIVIDE(
        [Diagnosed Patients],
        [Total Patients]
    )

### Unit

Percentage (%)

### Interpretation

Describes the proportion of diagnosed records in the synthetic analytical population.

It is not a population prevalence estimate.

---

# 3. Average Patient Indicators

## 3.1 Average Age

### dbt Name

`average_age`

### Power BI Measure

`Average Age`

### Formula

    SUM(Age) / Number of records

### Unit

Years

### Interpretation

Mean age of the records included in the current analytical context or dashboard filter.

---

## 3.2 Average BMI

### dbt Name

`average_bmi`

### Formula

    SUM(BMI) / Number of records

### Interpretation

Mean BMI across the selected analytical population.

---

## 3.3 Average MMSE

### dbt Name

`average_mmse`

### Power BI Measure

`Average MMSE`

### Formula

    SUM(MMSE) / Number of records

### Unit

Score points

### Interpretation

Average MMSE score represented in the selected dataset records.

This metric is descriptive only.

---

## 3.4 Average Functional Assessment

### dbt Name

`average_functional_assessment`

### Formula

    SUM(FunctionalAssessment)
    -------------------------
        Number of records

### Interpretation

Mean functional-assessment score within the selected analytical population.

---

## 3.5 Average ADL

### dbt Name

`average_adl`

### Formula

    SUM(ADL) / Number of records

### Interpretation

Mean Activities of Daily Living score represented in the dataset.

---

## 3.6 Average Symptom Count

### dbt Name

`average_symptom_count`

### Formula

    SUM(SymptomCount)
    -----------------
     Number of records

### Source

`SymptomCount`

is the sum of seven binary symptom indicators for each patient.

### Interpretation

Average number of indicated symptoms per record.

It must not be interpreted as a validated clinical severity score.

---

## 3.7 Average Medical History Count

### dbt Name

`average_medical_history_count`

### Formula

    SUM(MedicalHistoryCount)
    ------------------------
        Number of records

### Source

`MedicalHistoryCount`

is the sum of six binary medical-history indicators.

### Interpretation

Average number of indicated medical-history conditions per record.

It is an analytical count rather than a medical-risk score.

---

# 4. Demographic KPIs

The demographic Gold model is:

`gold_demographics`

It analyses four demographic dimensions:

1. Age group
2. Gender
3. Ethnicity
4. Education

---

## 4.1 Demographic Total Patients

### Name

`total_patients`

### Definition

Number of patient records belonging to a specific demographic category.

Example:

    Gender = Female

or:

    Age group = 70-79

---

## 4.2 Demographic Diagnosed Patients

### Name

`diagnosed_patients`

### Definition

Number of diagnosed records belonging to the demographic category.

### Formula

    COUNT(records where diagnosis_code = 1)

---

## 4.3 Demographic Not Diagnosed Patients

### Name

`not_diagnosed_patients`

### Definition

Number of non-diagnosed records belonging to the demographic category.

---

## 4.4 Demographic Diagnosis Rate

### Name

`diagnosis_rate_pct`

### Formula

    Diagnosed patients in category
    ------------------------------ x 100
       Total patients in category

### Unit

Percentage (%)

### Interpretation

Allows comparison of diagnosis proportions between categories such as:

- age groups;
- genders;
- ethnic categories;
- education categories.

Differences are descriptive and do not establish causality.

---

## 4.5 Demographic Average Age

### Name

`average_age`

### Definition

Mean age within each demographic category.

---

## 4.6 Demographic Average MMSE

### Name

`average_mmse`

### Definition

Mean MMSE score within each demographic category.

---

# 5. Risk Factor KPIs

The Gold model is:

`gold_risk_factors`

The following seven binary factors are analysed:

1. Smoking
2. Family history of Alzheimer's
3. Cardiovascular disease
4. Diabetes
5. Depression
6. Head injury
7. Hypertension

---

## 5.1 Patients With Factor

### Name

`patients_with_factor`

### Definition

Number of records for which the selected factor equals:

`1`

---

## 5.2 Patients Without Factor

### Name

`patients_without_factor`

### Definition

Number of records for which the selected factor equals:

`0`

---

## 5.3 Diagnosed With Factor

### Name

`diagnosed_with_factor`

### Definition

Number of records where:

    risk_present = 1

and:

    diagnosis_code = 1

---

## 5.4 Diagnosed Without Factor

### Name

`diagnosed_without_factor`

### Definition

Number of records where:

    risk_present = 0

and:

    diagnosis_code = 1

---

## 5.5 Factor Prevalence

### Name

`factor_prevalence_pct`

### Formula

    Patients with factor
    -------------------- x 100
       Total patients

### Unit

Percentage (%)

### Interpretation

Proportion of synthetic records containing the selected factor.

---

## 5.6 Diagnosis Rate With Factor

### Name

`diagnosis_rate_with_factor_pct`

### Formula

    Diagnosed patients with factor
    ------------------------------ x 100
        Patients with factor

### Unit

Percentage (%)

### Interpretation

Percentage of records with the selected factor that are labelled as diagnosed.

---

## 5.7 Diagnosis Rate Without Factor

### Name

`diagnosis_rate_without_factor_pct`

### Formula

    Diagnosed patients without factor
    --------------------------------- x 100
         Patients without factor

### Unit

Percentage (%)

---

## 5.8 Diagnosis Rate Difference

### Name

`diagnosis_rate_difference_pct_points`

### Formula

    Diagnosis Rate With Factor
              -
    Diagnosis Rate Without Factor

### Unit

Percentage points

### Example

If:

    With factor = 42%

and:

    Without factor = 35%

then:

    Difference = +7 percentage points

### Interpretation

A positive value indicates that the diagnosed proportion is higher among records containing the factor.

A negative value indicates that the diagnosed proportion is lower among records containing the factor.

This indicator measures a descriptive association only.

It does not demonstrate that the factor causes Alzheimer's disease.

---

# 6. Symptom KPIs

The Gold model is:

`gold_symptoms`

The following symptoms are analysed:

1. Memory complaints
2. Behavioral problems
3. Confusion
4. Disorientation
5. Personality changes
6. Difficulty completing tasks
7. Forgetfulness

---

## 6.1 Patients With Symptom

### Name

`patients_with_symptom`

### Definition

Number of records for which the selected symptom equals:

`1`

---

## 6.2 Patients Without Symptom

### Name

`patients_without_symptom`

### Definition

Number of records for which the selected symptom equals:

`0`

---

## 6.3 Diagnosed With Symptom

### Name

`diagnosed_with_symptom`

### Definition

Number of records where both conditions are satisfied:

    symptom_present = 1

and:

    diagnosis_code = 1

---

## 6.4 Diagnosed Without Symptom

### Name

`diagnosed_without_symptom`

### Definition

Number of records where:

    symptom_present = 0

and:

    diagnosis_code = 1

---

## 6.5 Symptom Prevalence

### Name

`symptom_prevalence_pct`

### Formula

    Patients with symptom
    --------------------- x 100
       Total patients

### Unit

Percentage (%)

### Interpretation

Proportion of records containing the selected symptom.

---

## 6.6 Diagnosis Rate With Symptom

### Name

`diagnosis_rate_with_symptom_pct`

### Formula

    Diagnosed patients with symptom
    ------------------------------- x 100
        Patients with symptom

### Unit

Percentage (%)

---

## 6.7 Diagnosis Rate Without Symptom

### Name

`diagnosis_rate_without_symptom_pct`

### Formula

    Diagnosed patients without symptom
    ---------------------------------- x 100
         Patients without symptom

### Unit

Percentage (%)

---

## 6.8 Symptom Diagnosis Rate Difference

### Name

`diagnosis_rate_difference_pct_points`

### Formula

    Diagnosis Rate With Symptom
               -
    Diagnosis Rate Without Symptom

### Unit

Percentage points

### Interpretation

Measures the descriptive difference in diagnosis proportions between records with and without each symptom.

This is not a causal-effect measure.

---

# 7. KPI Calculation Layers

The project calculates indicators at different layers.

| Layer | Purpose |
|---|---|
| Silver | Patient-level analytical variables |
| dbt staging | Standardised analytical source |
| Fact / dimensions | Dimensional analytical model |
| Gold | Pre-aggregated decision-support indicators |
| Power BI semantic model | Interactive DAX measures |
| Power BI report | KPI cards, charts and filtered analysis |

---

# 8. Power BI Measures

The semantic model currently defines the following principal DAX measures:

| Power BI Measure | Definition |
|---|---|
| `Total Patients` | Distinct patient count |
| `Diagnosed Patients` | Patients with diagnosis code 1 |
| `Not Diagnosed Patients` | Patients with diagnosis code 0 |
| `Diagnosis Rate` | Diagnosed Patients / Total Patients |
| `Average Age` | Mean patient age |
| `Average MMSE` | Mean MMSE score |

These measures respond dynamically to the filter context applied in Power BI.

---

# 9. KPI Filtering Behaviour

Power BI measures can change according to filters applied by the dashboard user.

Examples include filtering by:

- age group;
- gender;
- ethnicity;
- education;
- diagnosis group;
- MMSE band;
- functional-assessment band;
- ADL band.

Therefore, a KPI card may display a different result after a dashboard filter is applied.

---

# 10. KPI Interpretation Rules

The following rules should be respected when presenting the dashboard:

1. Counts represent synthetic dataset records.

2. Diagnosis Rate is not an epidemiological prevalence estimate.

3. Risk-factor comparisons represent associations within the synthetic dataset only.

4. Symptom comparisons do not establish diagnostic accuracy.

5. Percentage-point differences do not represent causal effects.

6. MMSE, Functional Assessment and ADL indicators are descriptive analytical measures.

7. `MedicalHistoryCount` is not a validated risk score.

8. `SymptomCount` is not a validated severity score.

9. No KPI should be used for clinical decision-making.

---

# 11. KPI Summary

The principal decision-support metrics can be summarised as:

    Population
        |
        |-- Total Patients
        |-- Diagnosed Patients
        |-- Not Diagnosed Patients
        `-- Diagnosis Rate

    Patient Characteristics
        |
        |-- Average Age
        |-- Average BMI
        |-- Average MMSE
        |-- Average Functional Assessment
        |-- Average ADL
        |-- Average Symptom Count
        `-- Average Medical History Count

    Demographics
        |
        |-- Patients by demographic category
        |-- Diagnosed patients
        |-- Diagnosis Rate
        |-- Average Age
        `-- Average MMSE

    Risk Factors
        |
        |-- Factor Prevalence
        |-- Diagnosis Rate With Factor
        |-- Diagnosis Rate Without Factor
        `-- Diagnosis Rate Difference

    Symptoms
        |
        |-- Symptom Prevalence
        |-- Diagnosis Rate With Symptom
        |-- Diagnosis Rate Without Symptom
        `-- Diagnosis Rate Difference

Together, these KPIs provide a consistent analytical layer connecting the dbt Gold models to the Power BI decision-support dashboard.
