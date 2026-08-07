$ErrorActionPreference = "Stop"

# Run from the repository root.
$ProjectRoot = (Resolve-Path ".").Path
$DashboardRoot = Join-Path $ProjectRoot "dashboard"
$ReportRoot = Join-Path $DashboardRoot "alzheimers_dashboard.Report"
$ReportDefinition = Join-Path $ReportRoot "definition"
$ReportJsonPath = Join-Path $ReportDefinition "report.json"
$PagesRoot = Join-Path $ReportDefinition "pages"
$PagesJsonPath = Join-Path $PagesRoot "pages.json"

if (-not (Test-Path $PagesJsonPath)) {
    throw "Cannot find pages.json: $PagesJsonPath"
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

    return [ordered]@{
        expr = [ordered]@{
            Literal = [ordered]@{
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

function New-SolidColor {
    param([Parameter(Mandatory = $true)][string]$HexColor)

    return [ordered]@{
        solid = [ordered]@{
            color = (New-Literal "'$HexColor'")
        }
    }
}

function New-MeasureProjection {
    param(
        [Parameter(Mandatory = $true)][string]$Table,
        [Parameter(Mandatory = $true)][string]$Measure
    )

    return [ordered]@{
        field = [ordered]@{
            Measure = [ordered]@{
                Expression = [ordered]@{
                    SourceRef = [ordered]@{
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

    return [ordered]@{
        field = [ordered]@{
            Column = [ordered]@{
                Expression = [ordered]@{
                    SourceRef = [ordered]@{
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

    return [ordered]@{
        title = @(
            [ordered]@{
                properties = [ordered]@{
                    show = (New-Literal "true")
                    text = (New-Literal (New-TextLiteral $Text))
                }
            }
        )
        background = @(
            [ordered]@{
                properties = [ordered]@{
                    show = (New-Literal "true")
                    color = (New-SolidColor "#FFFFFF")
                    transparency = (New-Literal "0D")
                }
            }
        )
        border = @(
            [ordered]@{
                properties = [ordered]@{
                    show = (New-Literal "true")
                    color = (New-SolidColor "#DCE8EC")
                    radius = (New-Literal "14D")
                    width = (New-Literal "1D")
                }
            }
        )
        padding = @(
            [ordered]@{
                properties = [ordered]@{
                    top = (New-Literal "8D")
                    bottom = (New-Literal "8D")
                    left = (New-Literal "10D")
                    right = (New-Literal "10D")
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

# Safety backup.
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupRoot = Join-Path $env:TEMP "alzheimers_demographics_backup_$timestamp"
New-Item -ItemType Directory -Force $backupRoot | Out-Null
Copy-Item $ReportRoot $backupRoot -Recurse
Write-Host "Backup created at: $backupRoot"

# Get visual schema from an existing Overview visual.
$existingVisual = Get-ChildItem $PagesRoot -Recurse -Filter "visual.json" |
    Select-Object -First 1

if ($null -eq $existingVisual) {
    throw "No existing visual.json file found."
}

$visualSchema = (Get-Content $existingVisual.FullName -Raw | ConvertFrom-Json).'$schema'

# Reuse the registered neuroscience header resource.
$report = Get-Content $ReportJsonPath -Raw | ConvertFrom-Json
$registeredPackage = @(
    $report.resourcePackages |
    Where-Object { $_.name -eq "RegisteredResources" }
) | Select-Object -First 1

if ($null -eq $registeredPackage) {
    throw "RegisteredResources package not found. Run the Overview styling step first."
}

$headerResource = @(
    $registeredPackage.items |
    Where-Object { $_.name -like "neuro_header*.svg" }
) | Select-Object -First 1

if ($null -eq $headerResource) {
    throw "Neuroscience header resource not found."
}

$resourceName = [string]$headerResource.name

# Create/update the Demographics page.
$pageName = "20000000000000000001"
$pageDirectory = Join-Path $PagesRoot $pageName
$visualsRoot = Join-Path $pageDirectory "visuals"

New-Item -ItemType Directory -Force $visualsRoot | Out-Null

$page = [ordered]@{
    '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.1.0/schema.json"
    name = $pageName
    displayName = "Demographics"
    displayOption = "FitToPage"
    height = 720
    width = 1280
    objects = [ordered]@{
        background = @(
            [ordered]@{
                properties = [ordered]@{
                    color = (New-SolidColor "#F4F8FA")
                    transparency = (New-Literal "0D")
                }
            }
        )
    }
}

Write-JsonFile -Path (Join-Path $pageDirectory "page.json") -Object $page

# Register page in pages.json without duplicating it.
$pagesMetadata = Get-Content $PagesJsonPath -Raw | ConvertFrom-Json
$currentOrder = @($pagesMetadata.pageOrder)

if ($currentOrder -notcontains $pageName) {
    $pagesMetadata.pageOrder = @($currentOrder) + @($pageName)
}

$pagesMetadata.activePageName = $pageName
Write-JsonFile -Path $PagesJsonPath -Object $pagesMetadata

# Visual IDs.
$imageId = "20000000000000000002"
$titleId = "20000000000000000003"
$ageSlicerId = "20000000000000000004"
$genderSlicerId = "20000000000000000005"
$ageChartId = "20000000000000000006"
$genderChartId = "20000000000000000007"
$ethnicityChartId = "20000000000000000008"
$educationChartId = "20000000000000000009"

# Header image.
$imageVisual = [ordered]@{
    '$schema' = $visualSchema
    name = $imageId
    position = [ordered]@{
        x = 20
        y = 12
        z = 1000
        height = 142
        width = 1240
        tabOrder = 1000
    }
    visual = [ordered]@{
        visualType = "image"
        objects = [ordered]@{
            general = @(
                [ordered]@{
                    properties = [ordered]@{
                        imageUrl = [ordered]@{
                            expr = [ordered]@{
                                ResourcePackageItem = [ordered]@{
                                    PackageName = "RegisteredResources"
                                    PackageType = 1
                                    ItemName = $resourceName
                                }
                            }
                        }
                    }
                }
            )
        }
        drillFilterOtherVisuals = $true
    }
}

# Page-specific title.
$titleVisual = [ordered]@{
    '$schema' = $visualSchema
    name = $titleId
    position = [ordered]@{
        x = 28
        y = 160
        z = 2000
        height = 60
        width = 720
        tabOrder = 2000
    }
    visual = [ordered]@{
        visualType = "textbox"
        objects = [ordered]@{
            general = @(
                [ordered]@{
                    properties = [ordered]@{
                        paragraphs = @(
                            [ordered]@{
                                textRuns = @(
                                    [ordered]@{
                                        value = "Demographic Profile"
                                        textStyle = [ordered]@{
                                            fontFamily = "Segoe UI Semibold"
                                            fontSize = "22px"
                                            color = "#0F4C5C"
                                        }
                                    }
                                )
                                horizontalTextAlignment = "left"
                            },
                            [ordered]@{
                                textRuns = @(
                                    [ordered]@{
                                        value = "Diagnosis patterns across age, gender, ethnicity and education"
                                        textStyle = [ordered]@{
                                            fontFamily = "Segoe UI"
                                            fontSize = "11px"
                                            color = "#5B6770"
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
    }
}

# Slicers.
$ageSlicerVisual = [ordered]@{
    '$schema' = $visualSchema
    name = $ageSlicerId
    position = [ordered]@{
        x = 820
        y = 162
        z = 3000
        height = 80
        width = 205
        tabOrder = 3000
    }
    visual = [ordered]@{
        visualType = "slicer"
        query = [ordered]@{
            queryState = [ordered]@{
                Values = [ordered]@{
                    projections = @(
                        (New-ColumnProjection "dim_patient" "age_group")
                    )
                }
            }
        }
        objects = [ordered]@{
            data = @(
                [ordered]@{
                    properties = [ordered]@{
                        mode = (New-Literal (New-TextLiteral "Dropdown"))
                    }
                }
            )
            header = @(
                [ordered]@{
                    properties = [ordered]@{
                        show = (New-Literal "true")
                        text = (New-Literal (New-TextLiteral "Age group"))
                    }
                }
            )
        }
        visualContainerObjects = [ordered]@{
            padding = @(
                [ordered]@{
                    properties = [ordered]@{
                        top = (New-Literal "8D")
                        bottom = (New-Literal "8D")
                        left = (New-Literal "8D")
                        right = (New-Literal "8D")
                    }
                }
            )
        }
    }
}

$genderSlicerVisual = [ordered]@{
    '$schema' = $visualSchema
    name = $genderSlicerId
    position = [ordered]@{
        x = 1045
        y = 162
        z = 4000
        height = 80
        width = 205
        tabOrder = 4000
    }
    visual = [ordered]@{
        visualType = "slicer"
        query = [ordered]@{
            queryState = [ordered]@{
                Values = [ordered]@{
                    projections = @(
                        (New-ColumnProjection "dim_patient" "gender_label")
                    )
                }
            }
        }
        objects = [ordered]@{
            data = @(
                [ordered]@{
                    properties = [ordered]@{
                        mode = (New-Literal (New-TextLiteral "Dropdown"))
                    }
                }
            )
            header = @(
                [ordered]@{
                    properties = [ordered]@{
                        show = (New-Literal "true")
                        text = (New-Literal (New-TextLiteral "Gender"))
                    }
                }
            )
        }
        visualContainerObjects = [ordered]@{
            padding = @(
                [ordered]@{
                    properties = [ordered]@{
                        top = (New-Literal "8D")
                        bottom = (New-Literal "8D")
                        left = (New-Literal "8D")
                        right = (New-Literal "8D")
                    }
                }
            )
        }
    }
}

function New-DemographicChart {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Column,
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][int]$X,
        [Parameter(Mandatory = $true)][int]$Y,
        [Parameter(Mandatory = $true)][int]$Width,
        [Parameter(Mandatory = $true)][int]$Height,
        [Parameter(Mandatory = $true)][int]$Z,
        [Parameter(Mandatory = $true)][int]$TabOrder
    )

    return [ordered]@{
        '$schema' = $visualSchema
        name = $Id
        position = [ordered]@{
            x = $X
            y = $Y
            z = $Z
            height = $Height
            width = $Width
            tabOrder = $TabOrder
        }
        visual = [ordered]@{
            visualType = "clusteredColumnChart"
            query = [ordered]@{
                queryState = [ordered]@{
                    Category = [ordered]@{
                        projections = @(
                            (New-ColumnProjection "dim_patient" $Column)
                        )
                    }
                    Y = [ordered]@{
                        projections = @(
                            (New-MeasureProjection "fct_patient_assessment" "Diagnosis Rate")
                        )
                    }
                    Tooltips = [ordered]@{
                        projections = @(
                            (New-MeasureProjection "fct_patient_assessment" "Total Patients"),
                            (New-MeasureProjection "fct_patient_assessment" "Diagnosed Patients")
                        )
                    }
                }
            }
            visualContainerObjects = (New-TitleVco $Title)
        }
    }
}

$ageChart = New-DemographicChart `
    -Id $ageChartId `
    -Column "age_group" `
    -Title "Diagnosis rate by age group" `
    -X 20 -Y 250 -Width 610 -Height 210 -Z 5000 -TabOrder 5000

$genderChart = New-DemographicChart `
    -Id $genderChartId `
    -Column "gender_label" `
    -Title "Diagnosis rate by gender" `
    -X 650 -Y 250 -Width 610 -Height 210 -Z 6000 -TabOrder 6000

$ethnicityChart = New-DemographicChart `
    -Id $ethnicityChartId `
    -Column "ethnicity_label" `
    -Title "Diagnosis rate by ethnicity" `
    -X 20 -Y 480 -Width 610 -Height 220 -Z 7000 -TabOrder 7000

$educationChart = New-DemographicChart `
    -Id $educationChartId `
    -Column "education_label" `
    -Title "Diagnosis rate by education" `
    -X 650 -Y 480 -Width 610 -Height 220 -Z 8000 -TabOrder 8000

Write-Visual -VisualsRoot $visualsRoot -VisualObject $imageVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $titleVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $ageSlicerVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $genderSlicerVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $ageChart
Write-Visual -VisualsRoot $visualsRoot -VisualObject $genderChart
Write-Visual -VisualsRoot $visualsRoot -VisualObject $ethnicityChart
Write-Visual -VisualsRoot $visualsRoot -VisualObject $educationChart

Write-Host ""
Write-Host "Demographics page created successfully."
Write-Host "Page: Demographics"
Write-Host "Visuals created: 8"
Write-Host "Report path: $ReportRoot"
Write-Host ""
Write-Host "Next:"
Write-Host "powerbi-report-author validate `"$ReportRoot`" --pretty"
