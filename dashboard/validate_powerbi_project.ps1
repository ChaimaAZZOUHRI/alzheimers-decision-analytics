$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path ".").Path
$DashboardRoot = Join-Path $ProjectRoot "dashboard"
$ReportRoot = Join-Path $DashboardRoot "alzheimers_dashboard.Report"
$SemanticRoot = Join-Path $DashboardRoot "alzheimers_dashboard.SemanticModel"
$PowerBIRoot = Join-Path $ProjectRoot "data\gold\powerbi"

Write-Host ""
Write-Host "============================================"
Write-Host " Alzheimer Power BI - Final Validation"
Write-Host "============================================"
Write-Host ""

$errors = [System.Collections.Generic.List[string]]::new()

# 1. PBIP project
$pbip = Join-Path $DashboardRoot "alzheimers_dashboard.pbip"
if (Test-Path $pbip) {
    Write-Host "[PASS] PBIP project found"
} else {
    $errors.Add("PBIP project missing: $pbip")
    Write-Host "[FAIL] PBIP project missing"
}

# 2. Expected report pages
$expectedPages = @(
    "Overview",
    "Demographics",
    "Risk Factors",
    "Symptoms & Cognitive Assessment"
)

$pagesRoot = Join-Path $ReportRoot "definition\pages"
$pageFiles = Get-ChildItem $pagesRoot -Recurse -Filter "page.json"

$foundPages = @()

foreach ($pageFile in $pageFiles) {
    try {
        $page = Get-Content $pageFile.FullName -Raw | ConvertFrom-Json
        if ($page.displayName) {
            $foundPages += [string]$page.displayName
        }
    }
    catch {
        $errors.Add("Invalid page JSON: $($pageFile.FullName)")
    }
}

foreach ($pageName in $expectedPages) {
    if ($foundPages -contains $pageName) {
        Write-Host "[PASS] Page: $pageName"
    } else {
        $errors.Add("Missing report page: $pageName")
        Write-Host "[FAIL] Page missing: $pageName"
    }
}

# 3. Expected semantic-model tables
$expectedTables = @(
    "dim_patient.tmdl",
    "dim_diagnosis.tmdl",
    "fct_patient_assessment.tmdl",
    "gold_kpi_overview.tmdl",
    "gold_demographics.tmdl",
    "gold_risk_factors.tmdl",
    "gold_symptoms.tmdl"
)

$tableRoot = Join-Path $SemanticRoot "definition\tables"

foreach ($tableFile in $expectedTables) {
    $path = Join-Path $tableRoot $tableFile
    if (Test-Path $path) {
        Write-Host "[PASS] Semantic table: $tableFile"
    } else {
        $errors.Add("Missing semantic-model table: $tableFile")
        Write-Host "[FAIL] Semantic table missing: $tableFile"
    }
}

# 4. Expected Power BI CSV exports
$expectedCsv = @(
    "dim_patient.csv",
    "dim_diagnosis.csv",
    "fct_patient_assessment.csv",
    "gold_kpi_overview.csv",
    "gold_demographics.csv",
    "gold_risk_factors.csv",
    "gold_symptoms.csv"
)

foreach ($csv in $expectedCsv) {
    $path = Join-Path $PowerBIRoot $csv
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        if ($size -gt 0) {
            Write-Host "[PASS] Export: $csv"
        } else {
            $errors.Add("Empty Power BI export: $csv")
            Write-Host "[FAIL] Empty export: $csv"
        }
    } else {
        $errors.Add("Missing Power BI export: $csv")
        Write-Host "[FAIL] Export missing: $csv"
    }
}

# 5. PBIR structural validation
Write-Host ""
Write-Host "Running PBIR validation..."

$validationText = & powerbi-report-author validate $ReportRoot --pretty 2>&1
$validationText | ForEach-Object { Write-Host $_ }

try {
    $validationJson = ($validationText -join "`n") | ConvertFrom-Json

    if (
        $validationJson.data.result -eq "succeeded" -and
        [int]$validationJson.data.errorCount -eq 0
    ) {
        Write-Host "[PASS] PBIR validation succeeded"
    } else {
        $errors.Add(
            "PBIR validation failed with $($validationJson.data.errorCount) errors."
        )
    }
}
catch {
    $errors.Add(
        "Could not parse Power BI validation output. Review the output above."
    )
}

# 6. Final result
Write-Host ""
Write-Host "============================================"

if ($errors.Count -eq 0) {
    Write-Host "FINAL RESULT: PASS"
    Write-Host "The Power BI project passed all automated checks."
    Write-Host "============================================"
    exit 0
}

Write-Host "FINAL RESULT: FAIL"
Write-Host "Problems detected:"
foreach ($errorMessage in $errors) {
    Write-Host " - $errorMessage"
}
Write-Host "============================================"
exit 1
