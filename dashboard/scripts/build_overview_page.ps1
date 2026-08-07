$ErrorActionPreference = "Stop"

# This script must be run from the repository root.
$ProjectRoot = (Resolve-Path ".").Path
$DashboardRoot = Join-Path $ProjectRoot "dashboard"
$ReportRoot = Join-Path $DashboardRoot "alzheimers_dashboard.Report"
$ReportDefinition = Join-Path $ReportRoot "definition"
$PagesRoot = Join-Path $ReportDefinition "pages"
$PagesMetadataPath = Join-Path $PagesRoot "pages.json"
$FactTablePath = Join-Path $DashboardRoot "alzheimers_dashboard.SemanticModel\definition\tables\fct_patient_assessment.tmdl"

if (-not (Test-Path $PagesMetadataPath)) {
    throw "Cannot find pages.json: $PagesMetadataPath"
}

if (-not (Test-Path $FactTablePath)) {
    throw "Cannot find the fact-table TMDL file: $FactTablePath"
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )

    $json = $Object | ConvertTo-Json -Depth 100
    Write-Utf8NoBom -Path $Path -Content ($json + [Environment]::NewLine)
}

function New-Literal {
    param([Parameter(Mandatory = $true)][string]$Value)

    return @{
        expr = @{
            Literal = @{
                Value = $Value
            }
        }
    }
}

function New-TextLiteral {
    param([Parameter(Mandatory = $true)][string]$Text)

    $escaped = $Text.Replace("'", "''")
    return "'$escaped'"
}

function New-MeasureProjection {
    param(
        [Parameter(Mandatory = $true)][string]$Table,
        [Parameter(Mandatory = $true)][string]$Measure
    )

    return @{
        field = @{
            Measure = @{
                Expression = @{
                    SourceRef = @{
                        Entity = $Table
                    }
                }
                Property = $Measure
            }
        }
        queryRef = "$Table.$Measure"
        nativeQueryRef = $Measure
    }
}

function New-ColumnProjection {
    param(
        [Parameter(Mandatory = $true)][string]$Table,
        [Parameter(Mandatory = $true)][string]$Column
    )

    return @{
        field = @{
            Column = @{
                Expression = @{
                    SourceRef = @{
                        Entity = $Table
                    }
                }
                Property = $Column
            }
        }
        queryRef = "$Table.$Column"
        nativeQueryRef = $Column
    }
}

function New-TitleVco {
    param([Parameter(Mandatory = $true)][string]$Text)

    return @{
        title = @(
            @{
                properties = @{
                    show = (New-Literal "true")
                    text = (New-Literal (New-TextLiteral $Text))
                }
            }
        )
    }
}

function Write-Visual {
    param(
        [Parameter(Mandatory = $true)][string]$VisualsRoot,
        [Parameter(Mandatory = $true)]$VisualObject
    )

    $visualDirectory = Join-Path $VisualsRoot $VisualObject.name
    New-Item -ItemType Directory -Force $visualDirectory | Out-Null
    Write-JsonFile -Path (Join-Path $visualDirectory "visual.json") -Object $VisualObject
}

# Create a safety backup before modifying the report and model.
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupRoot = Join-Path $env:TEMP "alzheimers_overview_backup_$timestamp"
New-Item -ItemType Directory -Force $backupRoot | Out-Null
Copy-Item $ReportRoot $backupRoot -Recurse
Copy-Item $FactTablePath $backupRoot
Write-Host "Backup created at: $backupRoot"

# Add filter-responsive measures to the fact table.
$factText = Get-Content $FactTablePath -Raw

if ($factText -notmatch "measure 'Total Patients'") {
    $factLines = [System.Collections.Generic.List[string]]::new()
    Get-Content $FactTablePath | ForEach-Object { [void]$factLines.Add($_) }

    $insertIndex = -1
    for ($i = 0; $i -lt $factLines.Count; $i++) {
        if ($factLines[$i] -match '^\s*lineageTag:') {
            $insertIndex = $i + 1
            break
        }
    }

    if ($insertIndex -lt 0) {
        throw "Could not find lineageTag in $FactTablePath"
    }

    [string[]]$measureLines = @(
        "",
        "`tmeasure 'Total Patients' = DISTINCTCOUNT(fct_patient_assessment[patient_id])",
        "`t`tformatString: #,0",
        "",
        "`tmeasure 'Diagnosed Patients' = CALCULATE([Total Patients], fct_patient_assessment[diagnosis_code] = 1)",
        "`t`tformatString: #,0",
        "",
        "`tmeasure 'Not Diagnosed Patients' = CALCULATE([Total Patients], fct_patient_assessment[diagnosis_code] = 0)",
        "`t`tformatString: #,0",
        "",
        "`tmeasure 'Diagnosis Rate' = DIVIDE([Diagnosed Patients], [Total Patients])",
        "`t`tformatString: 0.00%",
        "",
        "`tmeasure 'Average Age' = AVERAGE(dim_patient[age])",
        "`t`tformatString: 0.00",
        "",
        "`tmeasure 'Average MMSE' = AVERAGE(fct_patient_assessment[mmse])",
        "`t`tformatString: 0.00"
    )

    $factLines.InsertRange($insertIndex, $measureLines)
    $updatedFact = ($factLines -join [Environment]::NewLine) + [Environment]::NewLine
    Write-Utf8NoBom -Path $FactTablePath -Content $updatedFact
    Write-Host "Dynamic measures added to fct_patient_assessment.tmdl"
}
else {
    Write-Host "Dynamic measures already exist; no TMDL change required."
}

# Read the current active page created by Power BI Desktop.
$pagesMetadata = Get-Content $PagesMetadataPath -Raw | ConvertFrom-Json
$pageName = [string]$pagesMetadata.activePageName

if ([string]::IsNullOrWhiteSpace($pageName)) {
    $pageName = [string]$pagesMetadata.pageOrder[0]
}

$pageDirectory = Join-Path $PagesRoot $pageName
$pageJsonPath = Join-Path $pageDirectory "page.json"
$visualsRoot = Join-Path $pageDirectory "visuals"

if (-not (Test-Path $pageJsonPath)) {
    throw "Cannot find the active page: $pageJsonPath"
}

New-Item -ItemType Directory -Force $visualsRoot | Out-Null

$page = Get-Content $pageJsonPath -Raw | ConvertFrom-Json
$page.displayName = "Overview"
$page.displayOption = "FitToPage"
$page.height = 720
$page.width = 1280
Write-JsonFile -Path $pageJsonPath -Object $page

$visualSchema = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.9.0/schema.json"

# Fixed 20-character hexadecimal IDs allow the script to be run again safely.
$titleId = "10000000000000000001"
$cardId = "10000000000000000002"
$ageSlicerId = "10000000000000000003"
$genderSlicerId = "10000000000000000004"
$donutId = "10000000000000000005"
$columnId = "10000000000000000006"

$titleVisual = @{
    '$schema' = $visualSchema
    name = $titleId
    position = @{
        x = 20
        y = 10
        z = 1000
        height = 52
        width = 760
        tabOrder = 1000
    }
    visual = @{
        visualType = "textbox"
        objects = @{
            general = @(
                @{
                    properties = @{
                        paragraphs = @(
                            @{
                                textRuns = @(
                                    @{
                                        value = "Alzheimer's Decision Analytics - Overview"
                                        textStyle = @{
                                            fontFamily = "Segoe UI Semibold"
                                            fontSize = "24px"
                                            color = "#1F2937"
                                        }
                                    }
                                )
                                horizontalTextAlignment = "left"
                            }
                        )
                    }
                }
            )
        }
        visualContainerObjects = @{
            background = @(
                @{
                    properties = @{
                        show = (New-Literal "false")
                    }
                }
            )
            border = @(
                @{
                    properties = @{
                        show = (New-Literal "false")
                    }
                }
            )
            padding = @(
                @{
                    properties = @{
                        top = (New-Literal "0D")
                        bottom = (New-Literal "0D")
                        left = (New-Literal "0D")
                        right = (New-Literal "0D")
                    }
                }
            )
        }
    }
}

$cardVisual = @{
    '$schema' = $visualSchema
    name = $cardId
    position = @{
        x = 20
        y = 86
        z = 2000
        height = 120
        width = 1240
        tabOrder = 2000
    }
    visual = @{
        visualType = "cardVisual"
        query = @{
            queryState = @{
                Data = @{
                    projections = @(
                        (New-MeasureProjection "fct_patient_assessment" "Total Patients"),
                        (New-MeasureProjection "fct_patient_assessment" "Diagnosed Patients"),
                        (New-MeasureProjection "fct_patient_assessment" "Diagnosis Rate"),
                        (New-MeasureProjection "fct_patient_assessment" "Average MMSE")
                    )
                }
            }
        }
        objects = @{
            outline = @(
                @{
                    properties = @{
                        show = (New-Literal "false")
                    }
                    selector = @{
                        id = "default"
                    }
                }
            )
        }
    }
}

$ageSlicerVisual = @{
    '$schema' = $visualSchema
    name = $ageSlicerId
    position = @{
        x = 820
        y = 8
        z = 3000
        height = 72
        width = 210
        tabOrder = 3000
    }
    visual = @{
        visualType = "slicer"
        query = @{
            queryState = @{
                Values = @{
                    projections = @(
                        (New-ColumnProjection "dim_patient" "age_group")
                    )
                }
            }
        }
        objects = @{
            data = @(
                @{
                    properties = @{
                        mode = (New-Literal (New-TextLiteral "Dropdown"))
                    }
                }
            )
            header = @(
                @{
                    properties = @{
                        show = (New-Literal "true")
                        text = (New-Literal (New-TextLiteral "Age group"))
                    }
                }
            )
        }
        visualContainerObjects = @{
            padding = @(
                @{
                    properties = @{
                        top = (New-Literal "4D")
                        bottom = (New-Literal "4D")
                        left = (New-Literal "8D")
                        right = (New-Literal "8D")
                    }
                }
            )
        }
    }
}

$genderSlicerVisual = @{
    '$schema' = $visualSchema
    name = $genderSlicerId
    position = @{
        x = 1050
        y = 8
        z = 4000
        height = 72
        width = 210
        tabOrder = 4000
    }
    visual = @{
        visualType = "slicer"
        query = @{
            queryState = @{
                Values = @{
                    projections = @(
                        (New-ColumnProjection "dim_patient" "gender_label")
                    )
                }
            }
        }
        objects = @{
            data = @(
                @{
                    properties = @{
                        mode = (New-Literal (New-TextLiteral "Dropdown"))
                    }
                }
            )
            header = @(
                @{
                    properties = @{
                        show = (New-Literal "true")
                        text = (New-Literal (New-TextLiteral "Gender"))
                    }
                }
            )
        }
        visualContainerObjects = @{
            padding = @(
                @{
                    properties = @{
                        top = (New-Literal "4D")
                        bottom = (New-Literal "4D")
                        left = (New-Literal "8D")
                        right = (New-Literal "8D")
                    }
                }
            )
        }
    }
}

$donutVisual = @{
    '$schema' = $visualSchema
    name = $donutId
    position = @{
        x = 20
        y = 224
        z = 5000
        height = 470
        width = 500
        tabOrder = 5000
    }
    visual = @{
        visualType = "donutChart"
        query = @{
            queryState = @{
                Category = @{
                    projections = @(
                        (New-ColumnProjection "dim_diagnosis" "diagnosis_label")
                    )
                }
                Y = @{
                    projections = @(
                        (New-MeasureProjection "fct_patient_assessment" "Total Patients")
                    )
                }
            }
        }
        visualContainerObjects = (New-TitleVco "Diagnosis distribution")
    }
}

$columnVisual = @{
    '$schema' = $visualSchema
    name = $columnId
    position = @{
        x = 540
        y = 224
        z = 6000
        height = 470
        width = 720
        tabOrder = 6000
    }
    visual = @{
        visualType = "clusteredColumnChart"
        query = @{
            queryState = @{
                Category = @{
                    projections = @(
                        (New-ColumnProjection "dim_patient" "age_group")
                    )
                }
                Y = @{
                    projections = @(
                        (New-MeasureProjection "fct_patient_assessment" "Diagnosis Rate")
                    )
                }
            }
        }
        visualContainerObjects = (New-TitleVco "Diagnosis rate by age group")
    }
}

Write-Visual -VisualsRoot $visualsRoot -VisualObject $titleVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $cardVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $ageSlicerVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $genderSlicerVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $donutVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $columnVisual

Write-Host ""
Write-Host "Overview page files created successfully."
Write-Host "Page: $pageName"
Write-Host "Visuals created: 6"
Write-Host "Report path: $ReportRoot"
Write-Host ""
Write-Host "Next command:"
Write-Host "powerbi-report-author validate `"$ReportRoot`" --pretty"
