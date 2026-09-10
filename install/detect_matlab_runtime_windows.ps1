param(
    [int]$MinYear = 2023,
    [string]$CustomRuntimePath = ""
)

function Add-Candidate {
    param(
        [string]$Version,
        [string]$Path
    )
    if ([string]::IsNullOrWhiteSpace($Version) -or [string]::IsNullOrWhiteSpace($Path)) { return }
    if ($Version -match '^R(\d{4})([ab])$') {
        $year = [int]$matches[1]
        $half = $matches[2]
        if ($year -ge $MinYear) {
            $score = ($year * 10) + ($(if ($half -eq 'b') { 1 } else { 0 }))
            $script:candidates += [pscustomobject]@{
                Version = $Version
                Path    = $Path
                Score   = $score
            }
        }
    }
}

$candidates = @()

if (-not [string]::IsNullOrWhiteSpace($CustomRuntimePath)) {
    $dllGlob = Join-Path $CustomRuntimePath 'runtime\win64\mclmcrrt*.dll'
    if (Test-Path $dllGlob) {
        if ($CustomRuntimePath -match '(R\d{4}[ab])') {
            Add-Candidate -Version $matches[1] -Path $CustomRuntimePath
        } else {
            # Accept explicit custom path if it contains runtime DLLs
            $script:candidates += [pscustomobject]@{
                Version = "CustomPath"
                Path    = $CustomRuntimePath
                Score   = 999999
            }
        }
    }
}

$regRoots = @(
    'HKLM:\SOFTWARE\MathWorks\MATLAB Runtime',
    'HKLM:\SOFTWARE\WOW6432Node\MathWorks\MATLAB Runtime',
    'HKCU:\SOFTWARE\MathWorks\MATLAB Runtime'
)

foreach ($root in $regRoots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem -Path $root -ErrorAction SilentlyContinue | ForEach-Object {
        $ver = $_.PSChildName
        if ($ver -match '^R\d{4}[ab]$') {
            Add-Candidate -Version $ver -Path "$root\$ver"
        }
    }
}

$dirRoots = @(
    "$env:ProgramFiles\MATLAB\MATLAB Runtime",
    "$env:ProgramFiles(x86)\MATLAB\MATLAB Runtime",
    "$env:LOCALAPPDATA\MathWorks\MATLAB Runtime"
)

foreach ($root in $dirRoots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $ver = $_.Name
        $dllGlob = Join-Path $_.FullName 'runtime\win64\mclmcrrt*.dll'
        if (($ver -match '^R\d{4}[ab]$') -and (Test-Path $dllGlob)) {
            Add-Candidate -Version $ver -Path $_.FullName
        }
    }
}

if ($candidates.Count -gt 0) {
    $best = $candidates | Sort-Object -Property Score -Descending | Select-Object -First 1
    Write-Output ("FOUND|{0}|{1}" -f $best.Version, $best.Path)
} else {
    Write-Output "NOTFOUND||"
}
