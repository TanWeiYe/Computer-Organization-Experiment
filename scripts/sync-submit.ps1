# sync-submit.ps1
# Copies submission files from assignments/<n>/ to submit/<n>/
# Usage: .\scripts\sync-submit.ps1 [assignment-number]

param(
    [Parameter(Mandatory=$false)]
    [int]$AssignmentNumber = 1
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$srcDir  = Join-Path $repoRoot "assignments\$AssignmentNumber"
$destDir = Join-Path $repoRoot "submit\$AssignmentNumber"

if (-not (Test-Path $srcDir)) {
    Write-Host "ERROR: source not found: $srcDir" -ForegroundColor Red
    exit 1
}

Write-Host "Sync: assignments/$AssignmentNumber -> submit/$AssignmentNumber"
Write-Host "============================================================"

# Ensure dest directories exist
Get-ChildItem $srcDir -Directory -Filter "p*" | ForEach-Object {
    $p = $_.Name
    @("src\verilog", "tb", "docs") | ForEach-Object {
        $d = Join-Path $destDir "$p\$_"
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
}
$destDocsDir = Join-Path $destDir "docs"
if (-not (Test-Path $destDocsDir)) { New-Item -ItemType Directory -Path $destDocsDir -Force | Out-Null }

# Helper: copy files matching patterns from a dir to dest
function Copy-Files($sourceDir, $destDir, $patterns) {
    if (-not (Test-Path $sourceDir)) { return }
    foreach ($pat in $patterns) {
        Get-ChildItem $sourceDir -Filter $pat -ErrorAction SilentlyContinue | ForEach-Object {
            $dest = Join-Path $destDir $_.Name
            Copy-Item $_.FullName $dest -Force
            Write-Host "    [OK] $($_.Name)"
        }
    }
}

# Sync each pX
Get-ChildItem $srcDir -Directory -Filter "p*" | ForEach-Object {
    $pName = $_.Name
    Write-Host "  [$pName]"

    $pd = Join-Path $destDir $pName
    Copy-Files (Join-Path $_.FullName "src\verilog") (Join-Path $pd "src\verilog") @("*.v")
    Copy-Files (Join-Path $_.FullName "tb")         (Join-Path $pd "tb")         @("*.v")
    # Use single *.png filter to avoid duplicates; cleanup temp.png after
    Copy-Files (Join-Path $_.FullName "docs")       (Join-Path $pd "docs")       @("*.png", "*.svg")
}

# Remove temp.png if copied
$tempFiles = Get-ChildItem $destDir -Recurse -Filter "temp.png" -ErrorAction SilentlyContinue
$tempFiles | ForEach-Object { Remove-Item $_.FullName -Force }

# PDF reports
$reportSrc = Join-Path $srcDir "docs"
if (Test-Path $reportSrc) {
    Write-Host "  [reports]"
    Copy-Files $reportSrc $destDocsDir @("*.pdf")
}

# Ensure link file exists (use Out-File with Append to avoid encoding issues)
$linkFile = Join-Path $destDocsDir "2419040125-谭炜烨.txt"
if (-not (Test-Path $linkFile)) {
    try {
        $content = "https://github.com/TanWeiYe/Computer-Organization-Experiment"
        [System.IO.File]::WriteAllText($linkFile, $content, [System.Text.Encoding]::UTF8)
        Write-Host "    [OK] Link file created"
    } catch {
        Write-Host "    [WARN] Could not create link file: $_"
    }
}

Write-Host "============================================================"
Write-Host "Done. Next: zip submit/$AssignmentNumber/ for submission."
