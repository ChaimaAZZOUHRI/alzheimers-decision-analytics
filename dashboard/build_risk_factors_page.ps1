$ErrorActionPreference = "Stop"

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
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content
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

function New-ColumnProjection {
    param(
        [Parameter(Mandatory = $true)][string]$Table,
        [Parameter(Mandatory = $true)][string]$Column,
        [string]$DisplayName
    )

    $projection = [ordered]@{
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

    if ($DisplayName) {
        $projection.displayName = $DisplayName
    }

    return $projection
}

function New-MinAggregationProjection {
    param(
        [Parameter(Mandatory = $true)][string]$Table,
        [Parameter(Mandatory = $true)][string]$Column,
        [Parameter(Mandatory = $true)][string]$DisplayName
    )

    return [ordered]@{
        field = [ordered]@{
            Aggregation = [ordered]@{
                Expression = [ordered]@{
                    Column = [ordered]@{
                        Expression = [ordered]@{
                            SourceRef = [ordered]@{
                                Entity = $Table
                            }
                        }
                        Property = $Column
                    }
                }
                Function = 3
            }
        }
        queryRef = "Min($Table.$Column)"
        nativeQueryRef = "Minimum of $Column"
        displayName = $DisplayName
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

# Backup the current report before modifying it.
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupRoot = Join-Path $env:TEMP "alzheimers_risk_factors_backup_$timestamp"
New-Item -ItemType Directory -Force $backupRoot | Out-Null
Copy-Item $ReportRoot $backupRoot -Recurse
Write-Host "Backup created at: $backupRoot"

# Reuse the existing report visual schema.
$existingVisual = Get-ChildItem $PagesRoot -Recurse -Filter "visual.json" |
    Select-Object -First 1

if ($null -eq $existingVisual) {
    throw "No existing visual.json file found."
}

$visualSchema = (Get-Content $existingVisual.FullName -Raw | ConvertFrom-Json).'$schema'

# Reuse the registered neuroscience header image.
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

# Stable page and visual identifiers (20 hexadecimal characters each).
$pageName = "00000000000000000030"
$imageId = "00000000000000000031"
$titleId = "00000000000000000032"
$prevalenceChartId = "00000000000000000033"
$comparisonChartId = "00000000000000000034"
$differenceChartId = "00000000000000000035"
$tableId = "00000000000000000036"

$pageDirectory = Join-Path $PagesRoot $pageName
$visualsRoot = Join-Path $pageDirectory "visuals"
New-Item -ItemType Directory -Force $visualsRoot | Out-Null

$page = [ordered]@{
    '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.1.0/schema.json"
    name = $pageName
    displayName = "Risk Factors"
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

# Add the page to page order and make it active.
$pagesMetadata = Get-Content $PagesJsonPath -Raw | ConvertFrom-Json
$currentOrder = @($pagesMetadata.pageOrder)

if ($currentOrder -notcontains $pageName) {
    $pagesMetadata.pageOrder = @($currentOrder) + @($pageName)
}

$pagesMetadata.activePageName = $pageName
Write-JsonFile -Path $PagesJsonPath -Object $pagesMetadata

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

# Page-specific title and subtitle.
$titleVisual = [ordered]@{
    '$schema' = $visualSchema
    name = $titleId
    position = [ordered]@{
        x = 28
        y = 160
        z = 2000
        height = 58
        width = 1100
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
                                        value = "Risk Factor Analysis"
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
                                        value = "Compare prevalence and diagnosis rates across recorded risk factors"
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

function New-RiskChart {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][array]$YProjections,
        [Parameter(Mandatory = $true)][int]$X,
        [Parameter(Mandatory = $true)][int]$Y,
        [Parameter(Mandatory = $true)][int]$Width,
        [Parameter(Mandatory = $true)][int]$Height,
        [Parameter(Mandatory = $true)][int]$Z
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
            tabOrder = $Z
        }
        visual = [ordered]@{
            visualType = "clusteredColumnChart"
            query = [ordered]@{
                queryState = [ordered]@{
                    Category = [ordered]@{
                        projections = @(
                            (New-ColumnProjection "gold_risk_factors" "risk_factor" "Risk factor")
                        )
                    }
                    Y = [ordered]@{
                        projections = $YProjections
                    }
                }
            }
            visualContainerObjects = (New-TitleVco $Title)
        }
    }
}

$prevalenceChart = New-RiskChart `
    -Id $prevalenceChartId `
    -Title "Risk factor prevalence (%)" `
    -YProjections @(
        (New-MinAggregationProjection "gold_risk_factors" "factor_prevalence_pct" "Prevalence (%)")
    ) `
    -X 20 -Y 230 -Width 390 -Height 220 -Z 3000

$comparisonChart = New-RiskChart `
    -Id $comparisonChartId `
    -Title "Diagnosis rate: with vs without factor (%)" `
    -YProjections @(
        (New-MinAggregationProjection "gold_risk_factors" "diagnosis_rate_with_factor_pct" "With factor (%)"),
        (New-MinAggregationProjection "gold_risk_factors" "diagnosis_rate_without_factor_pct" "Without factor (%)")
    ) `
    -X 430 -Y 230 -Width 830 -Height 220 -Z 4000

$differenceChart = New-RiskChart `
    -Id $differenceChartId `
    -Title "Diagnosis-rate difference (percentage points)" `
    -YProjections @(
        (New-MinAggregationProjection "gold_risk_factors" "diagnosis_rate_difference_pct_points" "Difference (pp)")
    ) `
    -X 20 -Y 470 -Width 390 -Height 225 -Z 5000

# Detailed table for exact values.
$tableVisual = [ordered]@{
    '$schema' = $visualSchema
    name = $tableId
    position = [ordered]@{
        x = 430
        y = 470
        z = 6000
        height = 225
        width = 830
        tabOrder = 6000
    }
    visual = [ordered]@{
        visualType = "tableEx"
        query = [ordered]@{
            queryState = [ordered]@{
                Values = [ordered]@{
                    projections = @(
                        (New-ColumnProjection "gold_risk_factors" "risk_factor" "Risk factor"),
                        (New-ColumnProjection "gold_risk_factors" "factor_prevalence_pct" "Prevalence (%)"),
                        (New-ColumnProjection "gold_risk_factors" "diagnosis_rate_with_factor_pct" "Diagnosis with factor (%)"),
                        (New-ColumnProjection "gold_risk_factors" "diagnosis_rate_without_factor_pct" "Diagnosis without factor (%)"),
                        (New-ColumnProjection "gold_risk_factors" "diagnosis_rate_difference_pct_points" "Difference (pp)")
                    )
                }
            }
        }
        objects = [ordered]@{
            columnHeaders = @(
                [ordered]@{
                    properties = [ordered]@{
                        autoSizeColumnWidth = (New-Literal "true")
                        columnAdjustment = (New-Literal (New-TextLiteral "growToFit"))
                    }
                }
            )
        }
        visualContainerObjects = [ordered]@{
            title = @(
                [ordered]@{
                    properties = [ordered]@{
                        show = (New-Literal "true")
                        text = (New-Literal (New-TextLiteral "Risk-factor summary"))
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
}

Write-Visual -VisualsRoot $visualsRoot -VisualObject $imageVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $titleVisual
Write-Visual -VisualsRoot $visualsRoot -VisualObject $prevalenceChart
Write-Visual -VisualsRoot $visualsRoot -VisualObject $comparisonChart
Write-Visual -VisualsRoot $visualsRoot -VisualObject $differenceChart
Write-Visual -VisualsRoot $visualsRoot -VisualObject $tableVisual

Write-Host ""
Write-Host "Risk Factors page created successfully."
Write-Host "Page: Risk Factors"
Write-Host "Visuals created: 6"
Write-Host "Report path: $ReportRoot"
Write-Host ""
Write-Host "Next command:"
Write-Host "powerbi-report-author validate `"$ReportRoot`" --pretty"
