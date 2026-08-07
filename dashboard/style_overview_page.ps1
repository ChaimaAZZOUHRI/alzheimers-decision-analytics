$ErrorActionPreference = "Stop"

# Run this script from the repository root.
$ProjectRoot = (Resolve-Path ".").Path
$DashboardRoot = Join-Path $ProjectRoot "dashboard"
$ReportRoot = Join-Path $DashboardRoot "alzheimers_dashboard.Report"
$ReportDefinition = Join-Path $ReportRoot "definition"
$ReportJsonPath = Join-Path $ReportDefinition "report.json"
$PagesJsonPath = Join-Path $ReportDefinition "pages\pages.json"
$AssetPath = Join-Path $DashboardRoot "assets\neuro_header.svg"
$RegisteredResources = Join-Path $ReportRoot "StaticResources\RegisteredResources"

if (-not (Test-Path $ReportJsonPath)) {
    throw "Cannot find report.json: $ReportJsonPath"
}

if (-not (Test-Path $PagesJsonPath)) {
    throw "Cannot find pages.json: $PagesJsonPath"
}

if (-not (Test-Path $AssetPath)) {
    throw "Cannot find the header image: $AssetPath"
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

function New-SolidColor {
    param([Parameter(Mandatory = $true)][string]$HexColor)

    return [ordered]@{
        solid = [ordered]@{
            color = (New-Literal "'$HexColor'")
        }
    }
}

function Set-Property {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$Value
    )

    $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
}

function Set-VisualPosition {
    param(
        [Parameter(Mandatory = $true)][string]$VisualPath,
        [Parameter(Mandatory = $true)][int]$X,
        [Parameter(Mandatory = $true)][int]$Y,
        [Parameter(Mandatory = $true)][int]$Width,
        [Parameter(Mandatory = $true)][int]$Height,
        [Parameter(Mandatory = $true)][int]$Z,
        [Parameter(Mandatory = $true)][int]$TabOrder,
        [switch]$AddContainerStyle
    )

    if (-not (Test-Path $VisualPath)) {
        throw "Cannot find visual file: $VisualPath"
    }

    $visualFile = Get-Content $VisualPath -Raw | ConvertFrom-Json
    $visualFile.position.x = $X
    $visualFile.position.y = $Y
    $visualFile.position.width = $Width
    $visualFile.position.height = $Height
    $visualFile.position.z = $Z
    $visualFile.position.tabOrder = $TabOrder

    if ($AddContainerStyle) {
        $title = $null
        if (
            $null -ne $visualFile.visual.visualContainerObjects -and
            $null -ne $visualFile.visual.visualContainerObjects.title
        ) {
            $title = $visualFile.visual.visualContainerObjects.title
        }

        $containerObjects = [ordered]@{
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
                        top = (New-Literal "10D")
                        bottom = (New-Literal "10D")
                        left = (New-Literal "12D")
                        right = (New-Literal "12D")
                    }
                }
            )
            subTitle = @(
                [ordered]@{
                    properties = [ordered]@{
                        show = (New-Literal "false")
                    }
                }
            )
        }

        if ($null -ne $title) {
            $containerObjects = [ordered]@{
                title = $title
                subTitle = $containerObjects.subTitle
                background = $containerObjects.background
                border = $containerObjects.border
                padding = $containerObjects.padding
            }
        }

        Set-Property -Object $visualFile.visual -Name "visualContainerObjects" -Value $containerObjects
    }

    Write-JsonFile -Path $VisualPath -Object $visualFile
}

# Safety backup.
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupRoot = Join-Path $env:TEMP "alzheimers_style_backup_$timestamp"
New-Item -ItemType Directory -Force $backupRoot | Out-Null
Copy-Item $ReportRoot $backupRoot -Recurse
Write-Host "Backup created at: $backupRoot"

# Determine the active page.
$pagesMetadata = Get-Content $PagesJsonPath -Raw | ConvertFrom-Json
$pageName = [string]$pagesMetadata.activePageName
if ([string]::IsNullOrWhiteSpace($pageName)) {
    $pageName = [string]$pagesMetadata.pageOrder[0]
}

$pageRoot = Join-Path $ReportDefinition "pages\$pageName"
$pageJsonPath = Join-Path $pageRoot "page.json"
$visualsRoot = Join-Path $pageRoot "visuals"

if (-not (Test-Path $pageJsonPath)) {
    throw "Cannot find page.json: $pageJsonPath"
}

# Add a subtle page background.
$page = Get-Content $pageJsonPath -Raw | ConvertFrom-Json
$pageBackground = [ordered]@{
    background = @(
        [ordered]@{
            properties = [ordered]@{
                color = (New-SolidColor "#F4F8FA")
                transparency = (New-Literal "0D")
            }
        }
    )
}
Set-Property -Object $page -Name "objects" -Value $pageBackground
Write-JsonFile -Path $pageJsonPath -Object $page

# Register the SVG as a report resource.
New-Item -ItemType Directory -Force $RegisteredResources | Out-Null
$report = Get-Content $ReportJsonPath -Raw | ConvertFrom-Json

$registeredPackage = $null
if ($null -ne $report.resourcePackages) {
    $registeredPackage = @(
        $report.resourcePackages |
        Where-Object { $_.name -eq "RegisteredResources" }
    ) | Select-Object -First 1
}

$existingResource = $null
if ($null -ne $registeredPackage -and $null -ne $registeredPackage.items) {
    $existingResource = @(
        $registeredPackage.items |
        Where-Object { $_.name -like "neuro_header*.svg" }
    ) | Select-Object -First 1
}

if ($null -ne $existingResource) {
    $resourceName = [string]$existingResource.name
}
else {
    $resourceName = "neuro_header_$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()).svg"
    Copy-Item $AssetPath (Join-Path $RegisteredResources $resourceName) -Force

    $resourceItem = [pscustomobject][ordered]@{
        name = $resourceName
        path = $resourceName
        type = "Image"
    }

    if ($null -eq $registeredPackage) {
        $registeredPackage = [pscustomobject][ordered]@{
            name = "RegisteredResources"
            type = "RegisteredResources"
            items = @($resourceItem)
        }

        if ($null -eq $report.resourcePackages) {
            Set-Property -Object $report -Name "resourcePackages" -Value @($registeredPackage)
        }
        else {
            $report.resourcePackages = @($report.resourcePackages) + @($registeredPackage)
        }
    }
    else {
        $registeredPackage.items = @($registeredPackage.items) + @($resourceItem)
    }

    Write-JsonFile -Path $ReportJsonPath -Object $report
}

# Remove the old plain-text title because the SVG already contains the title.
$oldTitleDirectory = Join-Path $visualsRoot "10000000000000000001"
if (Test-Path $oldTitleDirectory) {
    Remove-Item $oldTitleDirectory -Recurse -Force
}

# Create or replace the header image visual.
$imageId = "10000000000000000007"
$imageDirectory = Join-Path $visualsRoot $imageId
New-Item -ItemType Directory -Force $imageDirectory | Out-Null

$existingVisualFiles = Get-ChildItem $visualsRoot -Recurse -Filter "visual.json"
if ($existingVisualFiles.Count -eq 0) {
    throw "No existing visual.json file found to copy the visual schema from."
}

$visualSchema = (Get-Content $existingVisualFiles[0].FullName -Raw | ConvertFrom-Json).'$schema'

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

Write-JsonFile -Path (Join-Path $imageDirectory "visual.json") -Object $imageVisual

# Reposition and style the existing Overview visuals.
Set-VisualPosition `
    -VisualPath (Join-Path $visualsRoot "10000000000000000002\visual.json") `
    -X 20 -Y 170 -Width 760 -Height 118 -Z 2000 -TabOrder 2000 `
    -AddContainerStyle

Set-VisualPosition `
    -VisualPath (Join-Path $visualsRoot "10000000000000000003\visual.json") `
    -X 800 -Y 170 -Width 210 -Height 84 -Z 3000 -TabOrder 3000 `
    -AddContainerStyle

Set-VisualPosition `
    -VisualPath (Join-Path $visualsRoot "10000000000000000004\visual.json") `
    -X 1030 -Y 170 -Width 230 -Height 84 -Z 4000 -TabOrder 4000 `
    -AddContainerStyle

Set-VisualPosition `
    -VisualPath (Join-Path $visualsRoot "10000000000000000005\visual.json") `
    -X 20 -Y 306 -Width 500 -Height 390 -Z 5000 -TabOrder 5000 `
    -AddContainerStyle

Set-VisualPosition `
    -VisualPath (Join-Path $visualsRoot "10000000000000000006\visual.json") `
    -X 540 -Y 306 -Width 720 -Height 390 -Z 6000 -TabOrder 6000 `
    -AddContainerStyle

Write-Host ""
Write-Host "Overview styling completed successfully."
Write-Host "Header resource: $resourceName"
Write-Host "Page: $pageName"
Write-Host ""
Write-Host "Validate with:"
Write-Host "powerbi-report-author validate `"$ReportRoot`" --pretty"
