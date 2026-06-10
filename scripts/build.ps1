# build.ps1 - Creates dist/ with release, PTR, and classic zips ready for CurseForge
# Usage:
#   ./build.ps1                 # build only
#   ./build.ps1 -Bump patch    # 1.0.0 -> 1.0.1, then build
#   ./build.ps1 -Bump minor    # 1.0.0 -> 1.1.0, then build
#   ./build.ps1 -Bump major    # 1.0.0 -> 2.0.0, then build

param(
    [ValidateSet("major", "minor", "patch")]
    [string]$Bump
)

$ErrorActionPreference = "Stop"

$root = Split-Path $PSScriptRoot -Parent
$tocFile = Join-Path $root "Disenqueue.toc"
$coreFile = Join-Path (Join-Path $root "core") "Core.lua"

# Interface versions
$INTERFACE_LIVE = "120005"
$INTERFACE_PTR  = "120007"
$INTERFACE_CLASSIC_MOP = "50500"
# Placeholder values for disabled future flavors.
$INTERFACE_CLASSIC_CATA = "40400"
$INTERFACE_CLASSIC_ERA  = "11507"

$VARIANTS = @(
    [pscustomobject]@{
        Name = "release"
        InterfaceVersion = $INTERFACE_LIVE
        Adapter = "retail.lua"
        Enabled = $true
        UploadLabel = "The War Within (live)"
    },
    [pscustomobject]@{
        Name = "ptr"
        InterfaceVersion = $INTERFACE_PTR
        Adapter = "retail.lua"
        Enabled = $true
        UploadLabel = "PTR/Beta"
    },
    [pscustomobject]@{
        Name = "classic-mop"
        InterfaceVersion = $INTERFACE_CLASSIC_MOP
        Adapter = "mop.lua"
        Enabled = $true
        UploadLabel = "Mists of Pandaria Classic"
    },
    [pscustomobject]@{
        Name = "classic-cata"
        InterfaceVersion = $INTERFACE_CLASSIC_CATA
        Adapter = "mop.lua"
        Enabled = $false
        UploadLabel = "Future Classic Cata"
    },
    [pscustomobject]@{
        Name = "classic-era"
        InterfaceVersion = $INTERFACE_CLASSIC_ERA
        Adapter = "mop.lua"
        Enabled = $false
        UploadLabel = "Future Classic Era"
    }
)

# --- Version bump ---
if ($Bump) {
    # Read current version from .toc
    $tocContent = Get-Content $tocFile -Raw
    if ($tocContent -match '## Version:\s*(\d+)\.(\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patch = [int]$Matches[3]
    } else {
        throw "Could not parse version from Disenqueue.toc"
    }

    $old = "$major.$minor.$patch"

    switch ($Bump) {
        "major" { $major++; $minor = 0; $patch = 0 }
        "minor" { $minor++; $patch = 0 }
        "patch" { $patch++ }
    }

    $new = "$major.$minor.$patch"

    # Update .toc
    $tocContent = $tocContent -replace "## Version:\s*$([regex]::Escape($old))", "## Version: $new"
    Set-Content $tocFile $tocContent -NoNewline

    # Update Core.lua version
    $luaContent = Get-Content $coreFile -Raw
    $luaContent = $luaContent -replace "ns\.ADDON_VERSION\s*=\s*`"$([regex]::Escape($old))`"", "ns.ADDON_VERSION = `"$new`""
    Set-Content $coreFile $luaContent -NoNewline

    Write-Host "Version bumped: $old -> $new" -ForegroundColor Cyan
}

# --- Build ---
$distDir = Join-Path $root "dist"

# Clean previous build
if (Test-Path $distDir) {
    Remove-Item $distDir -Recurse -Force
}

# Read version for zip naming
$tocContent = Get-Content $tocFile -Raw
if ($tocContent -match '## Version:\s*(\d+\.\d+\.\d+)') {
    $version = $Matches[1]
} else {
    $version = "unknown"
}

# Build function: creates addon folder, patches interface version, zips it
function Build-Variant {
    param([pscustomobject]$Variant)

    if (-not $Variant.Enabled) {
        Write-Host "  Skipping $($Variant.Name) (disabled)" -ForegroundColor DarkGray
        return
    }

    if (-not $Variant.InterfaceVersion) {
        throw "Variant '$($Variant.Name)' is missing InterfaceVersion"
    }
    if (-not $Variant.Adapter) {
        throw "Variant '$($Variant.Name)' is missing Adapter"
    }

    $variantDir = Join-Path $distDir $Variant.Name
    $addonDir = Join-Path $variantDir "Disenqueue"

    New-Item -ItemType Directory -Path $addonDir -Force | Out-Null

    # Copy addon root files
    Copy-Item (Join-Path $root "Disenqueue.toc") -Destination $addonDir
    Copy-Item (Join-Path $root "Bindings.xml") -Destination $addonDir

    # Copy core module files
    Copy-Item (Join-Path (Join-Path $root "core") "Compat.lua") -Destination $addonDir
    Copy-Item (Join-Path (Join-Path $root "core") "Core.lua") -Destination $addonDir

    # Copy lib module files
    New-Item -ItemType Directory -Path (Join-Path $addonDir "lib") -Force | Out-Null
    Copy-Item (Join-Path (Join-Path $root "lib") "Theme.lua") -Destination (Join-Path $addonDir "lib")
    Copy-Item (Join-Path (Join-Path $root "lib") "APIAdapter.lua") -Destination (Join-Path $addonDir "lib")
    Copy-Item (Join-Path (Join-Path $root "lib") "SlotMap.lua") -Destination (Join-Path $addonDir "lib")
    Copy-Item (Join-Path (Join-Path $root "lib") "Settings.lua") -Destination (Join-Path $addonDir "lib")

    # Copy ui module files
    New-Item -ItemType Directory -Path (Join-Path $addonDir "ui") -Force | Out-Null
    Copy-Item (Join-Path (Join-Path $root "ui") "Main.lua") -Destination (Join-Path $addonDir "ui")
    Copy-Item (Join-Path (Join-Path $root "ui") "Locked.lua") -Destination (Join-Path $addonDir "ui")
    Copy-Item (Join-Path (Join-Path $root "ui") "Export.lua") -Destination (Join-Path $addonDir "ui")
    Copy-Item (Join-Path (Join-Path $root "ui") "Minimap.lua") -Destination (Join-Path $addonDir "ui")

    # Copy version-specific adapter
    New-Item -ItemType Directory -Path (Join-Path $addonDir "adapters") -Force | Out-Null
    Copy-Item (Join-Path (Join-Path $root "adapters") $Variant.Adapter) -Destination (Join-Path $addonDir "adapters")

    # Copy asset directories
    Copy-Item (Join-Path $root "icons") -Destination $addonDir -Recurse
    Copy-Item (Join-Path $root "logos") -Destination $addonDir -Recurse
    $fontsDir = Join-Path $root "Fonts"
    if (Test-Path $fontsDir) {
        Copy-Item $fontsDir -Destination $addonDir -Recurse
    }

    # Remove source art files that aren't needed in the addon
    $exclude = @("*.png", "*.svg", "*.psd")
    Get-ChildItem (Join-Path $addonDir "icons") -Include $exclude -Recurse | Remove-Item -Force
    Get-ChildItem (Join-Path $addonDir "logos") -Include $exclude -Recurse | Remove-Item -Force

    # Patch Interface version in the .toc copy
    $tocPath = Join-Path $addonDir "Disenqueue.toc"
    $content = Get-Content $tocPath -Raw
    $content = $content -replace '## Interface:\s*\d+', "## Interface: $($Variant.InterfaceVersion)"

    # Keep TOC adapter loading aligned with the adapter file packaged for this variant.
    $content = $content -replace '(?m)^adapters/retail\.lua\s*\r?\n', ''
    $content = $content -replace '(?m)^adapters/mop\.lua\s*\r?\n', ''
    $content = $content -replace '(?m)^lib/APIAdapter\.lua\s*\r?\n', "lib/APIAdapter.lua`r`nadapters/$($Variant.Adapter)`r`n"

    Set-Content $tocPath $content -NoNewline

    # Create zip
    $zipName = "Disenqueue-$version-$($Variant.Name).zip"
    $zipPath = Join-Path $distDir $zipName
    Compress-Archive -Path $addonDir -DestinationPath $zipPath -Force

    Write-Host "  $zipName (Interface: $($Variant.InterfaceVersion))" -ForegroundColor White
}

Write-Host ""
Write-Host "Building Disenqueue v$version..." -ForegroundColor Cyan
Write-Host ""

# Build all variants
Write-Host "Zips:" -ForegroundColor Green
foreach ($variant in $VARIANTS) {
    Build-Variant -Variant $variant
}

# Show contents of the release build
$releaseAddonDir = Join-Path $distDir "release\Disenqueue"
Write-Host ""
Write-Host "Contents:" -ForegroundColor Green
Get-ChildItem $releaseAddonDir -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring($releaseAddonDir.Length + 1)
    if ($_.PSIsContainer) { Write-Host "  $rel/" } else { Write-Host "  $rel" }
}
Write-Host ""
Write-Host "Ready to upload to CurseForge:" -ForegroundColor Green
foreach ($variant in $VARIANTS | Where-Object { $_.Enabled }) {
    Write-Host "  dist/Disenqueue-$version-$($variant.Name).zip -> $($variant.UploadLabel)" -ForegroundColor White
}
