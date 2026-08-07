$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$ModelRoot = Join-Path $ProjectRoot "dashboard\alzheimers_dashboard.SemanticModel\definition"
$TablesDir = Join-Path $ModelRoot "tables"
$CsvRoot = Join-Path $ProjectRoot "data\gold\powerbi"

New-Item -ItemType Directory -Force $TablesDir | Out-Null

function Quote-TmdlName {
    param([Parameter(Mandatory = $true)][string]$Name)

    if ($Name -match '^[A-Za-z_][A-Za-z0-9_]*$') {
        return $Name
    }

    return "'" + $Name.Replace("'", "''") + "'"
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines
    )

    $content = $Lines -join [Environment]::NewLine
    [System.IO.File]::WriteAllText(
        $Path,
        $content + [Environment]::NewLine,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function New-TmdlTable {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Definition
    )

    $tableName = [string]$Definition.Name
    $csvPath = Join-Path $CsvRoot ([string]$Definition.Csv)

    if (-not (Test-Path $csvPath)) {
        throw "Missing Power BI export: $csvPath. Run python -m src.export_powerbi first."
    }

    $resolvedCsv = (Resolve-Path $csvPath).Path.Replace('"', '""')
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("table $(Quote-TmdlName $tableName)")
    $lines.Add("`tlineageTag: $([guid]::NewGuid())")

    foreach ($measure in @($Definition.Measures)) {
        $lines.Add("")
        $lines.Add("`tmeasure $(Quote-TmdlName ([string]$measure.Name)) = $([string]$measure.Expression)")
        if ($measure.Format) {
            $lines.Add("`t`tformatString: $([string]$measure.Format)")
        }
    }

    foreach ($column in $Definition.Columns) {
        $lines.Add("")
        $lines.Add("`tcolumn $(Quote-TmdlName ([string]$column.Name))")
        $lines.Add("`t`tdataType: $([string]$column.Type)")
        if ($column.Key -eq $true) {
            $lines.Add("`t`tisKey")
        }
        if ($column.Format) {
            $lines.Add("`t`tformatString: $([string]$column.Format)")
        }
        $lines.Add("`t`tsummarizeBy: none")
        $lines.Add("`t`tsourceColumn: $([string]$column.Name)")
    }

    $lines.Add("")
    $lines.Add("`tpartition $(Quote-TmdlName $tableName) = m")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource =")
    $lines.Add("`t`t`tlet")
    $lines.Add("`t`t`t`tSource = Csv.Document(File.Contents(""$resolvedCsv""), [Delimiter="","", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),")
    $lines.Add("`t`t`t`t#""Promoted Headers"" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),")
    $lines.Add("`t`t`t`t#""Changed Type"" = Table.TransformColumnTypes(#""Promoted Headers"", {")

    for ($index = 0; $index -lt $Definition.Columns.Count; $index++) {
        $column = $Definition.Columns[$index]
        $suffix = if ($index -lt ($Definition.Columns.Count - 1)) { "," } else { "" }
        $lines.Add("`t`t`t`t`t{""$([string]$column.Name)"", $([string]$column.MType)}$suffix")
    }

    $lines.Add("`t`t`t`t}, ""en-GB"")")
    $lines.Add("`t`t`tin")
    $lines.Add("`t`t`t`t#""Changed Type""")

    $target = Join-Path $TablesDir "$tableName.tmdl"
    Write-Utf8File -Path $target -Lines $lines
    Write-Host "Created $target"
}

$tables = @(
    @{
        Name = "dim_patient"
        Csv = "dim_patient.csv"
        Columns = @(
            @{ Name = "patient_id"; Type = "int64"; MType = "Int64.Type"; Key = $true; Format = "0" }
            @{ Name = "age"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "age_group"; Type = "string"; MType = "type text" }
            @{ Name = "gender_code"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "gender_label"; Type = "string"; MType = "type text" }
            @{ Name = "ethnicity_code"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "ethnicity_label"; Type = "string"; MType = "type text" }
            @{ Name = "education_level_code"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "education_label"; Type = "string"; MType = "type text" }
        )
        Measures = @()
    }
    @{
        Name = "dim_diagnosis"
        Csv = "dim_diagnosis.csv"
        Columns = @(
            @{ Name = "diagnosis_code"; Type = "int64"; MType = "Int64.Type"; Key = $true; Format = "0" }
            @{ Name = "diagnosis_label"; Type = "string"; MType = "type text" }
        )
        Measures = @()
    }
    @{
        Name = "fct_patient_assessment"
        Csv = "fct_patient_assessment.csv"
        Columns = @(
            @{ Name = "patient_id"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "diagnosis_code"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "bmi"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "smoking"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "alcohol_consumption"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "physical_activity"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "diet_quality"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "sleep_quality"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "family_history_alzheimers"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "cardiovascular_disease"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "diabetes"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "depression"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "head_injury"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "hypertension"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "systolic_bp"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "diastolic_bp"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "cholesterol_total"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "cholesterol_ldl"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "cholesterol_hdl"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "cholesterol_triglycerides"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "mmse"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "mmse_band"; Type = "string"; MType = "type text" }
            @{ Name = "functional_assessment"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "functional_assessment_band"; Type = "string"; MType = "type text" }
            @{ Name = "adl"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "adl_band"; Type = "string"; MType = "type text" }
            @{ Name = "memory_complaints"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "behavioral_problems"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "confusion"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "disorientation"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "personality_changes"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "difficulty_completing_tasks"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "forgetfulness"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "medical_history_count"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "symptom_count"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "processing_timestamp_utc"; Type = "string"; MType = "type text" }
            @{ Name = "source_file_name"; Type = "string"; MType = "type text" }
        )
        Measures = @()
    }
    @{
        Name = "gold_kpi_overview"
        Csv = "gold_kpi_overview.csv"
        Columns = @(
            @{ Name = "overview_key"; Type = "int64"; MType = "Int64.Type"; Key = $true; Format = "0" }
            @{ Name = "total_patients"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "diagnosed_patients"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "not_diagnosed_patients"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "diagnosis_rate_pct"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "average_age"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "average_bmi"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "average_mmse"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "average_functional_assessment"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "average_adl"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "average_symptom_count"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "average_medical_history_count"; Type = "double"; MType = "type number"; Format = "0.00" }
        )
        Measures = @(
            @{ Name = "Total Patients"; Expression = "MAX('gold_kpi_overview'[total_patients])"; Format = "#,0" }
            @{ Name = "Diagnosed Patients"; Expression = "MAX('gold_kpi_overview'[diagnosed_patients])"; Format = "#,0" }
            @{ Name = "Not Diagnosed Patients"; Expression = "MAX('gold_kpi_overview'[not_diagnosed_patients])"; Format = "#,0" }
            @{ Name = "Diagnosis Rate"; Expression = "DIVIDE([Diagnosed Patients], [Total Patients])"; Format = "0.00%" }
            @{ Name = "Average Age"; Expression = "MAX('gold_kpi_overview'[average_age])"; Format = "0.00" }
            @{ Name = "Average BMI"; Expression = "MAX('gold_kpi_overview'[average_bmi])"; Format = "0.00" }
            @{ Name = "Average MMSE"; Expression = "MAX('gold_kpi_overview'[average_mmse])"; Format = "0.00" }
            @{ Name = "Average Functional Assessment"; Expression = "MAX('gold_kpi_overview'[average_functional_assessment])"; Format = "0.00" }
            @{ Name = "Average ADL"; Expression = "MAX('gold_kpi_overview'[average_adl])"; Format = "0.00" }
        )
    }
    @{
        Name = "gold_demographics"
        Csv = "gold_demographics.csv"
        Columns = @(
            @{ Name = "demographic_key"; Type = "string"; MType = "type text"; Key = $true }
            @{ Name = "group_type"; Type = "string"; MType = "type text" }
            @{ Name = "group_type_order"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "group_value"; Type = "string"; MType = "type text" }
            @{ Name = "category_order"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "total_patients"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "diagnosed_patients"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "not_diagnosed_patients"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "diagnosis_rate_pct"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "average_age"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "average_mmse"; Type = "double"; MType = "type number"; Format = "0.00" }
        )
        Measures = @()
    }
    @{
        Name = "gold_risk_factors"
        Csv = "gold_risk_factors.csv"
        Columns = @(
            @{ Name = "risk_factor_key"; Type = "string"; MType = "type text"; Key = $true }
            @{ Name = "risk_factor"; Type = "string"; MType = "type text" }
            @{ Name = "display_order"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "total_patients"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "patients_with_factor"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "patients_without_factor"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "diagnosed_with_factor"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "diagnosed_without_factor"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "factor_prevalence_pct"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "diagnosis_rate_with_factor_pct"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "diagnosis_rate_without_factor_pct"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "diagnosis_rate_difference_pct_points"; Type = "double"; MType = "type number"; Format = "0.00" }
        )
        Measures = @()
    }
    @{
        Name = "gold_symptoms"
        Csv = "gold_symptoms.csv"
        Columns = @(
            @{ Name = "symptom_key"; Type = "string"; MType = "type text"; Key = $true }
            @{ Name = "symptom"; Type = "string"; MType = "type text" }
            @{ Name = "display_order"; Type = "int64"; MType = "Int64.Type"; Format = "0" }
            @{ Name = "total_patients"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "patients_with_symptom"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "patients_without_symptom"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "diagnosed_with_symptom"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "diagnosed_without_symptom"; Type = "int64"; MType = "Int64.Type"; Format = "#,0" }
            @{ Name = "symptom_prevalence_pct"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "diagnosis_rate_with_symptom_pct"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "diagnosis_rate_without_symptom_pct"; Type = "double"; MType = "type number"; Format = "0.00" }
            @{ Name = "diagnosis_rate_difference_pct_points"; Type = "double"; MType = "type number"; Format = "0.00" }
        )
        Measures = @()
    }
)

foreach ($table in $tables) {
    New-TmdlTable -Definition $table
}

$modelLines = @(
    "model Model",
    "`tculture: en-GB",
    "`tdefaultPowerBIDataSourceVersion: powerBI_V3",
    "`tsourceQueryCulture: en-GB",
    "`tvalueFilterBehavior: independent",
    "`tdataAccessOptions",
    "`t`tlegacyRedirects",
    "`t`treturnErrorValuesAsNull",
    "",
    "annotation __PBI_TimeIntelligenceEnabled = 1",
    "",
    "annotation PBI_ProTooling = [""DevMode""]",
    "",
    "ref table dim_patient",
    "ref table dim_diagnosis",
    "ref table fct_patient_assessment",
    "ref table gold_kpi_overview",
    "ref table gold_demographics",
    "ref table gold_risk_factors",
    "ref table gold_symptoms",
    "",
    "ref cultureInfo en-GB"
)

Write-Utf8File -Path (Join-Path $ModelRoot "model.tmdl") -Lines $modelLines

$relationshipLines = @(
    "relationship $([guid]::NewGuid())",
    "`tfromColumn: fct_patient_assessment.patient_id",
    "`ttoColumn: dim_patient.patient_id",
    "",
    "relationship $([guid]::NewGuid())",
    "`tfromColumn: fct_patient_assessment.diagnosis_code",
    "`ttoColumn: dim_diagnosis.diagnosis_code"
)

Write-Utf8File -Path (Join-Path $ModelRoot "relationships.tmdl") -Lines $relationshipLines

Write-Host ""
Write-Host "Semantic model files created successfully."
Write-Host "Tables: $($tables.Count)"
Write-Host "Location: $ModelRoot"
