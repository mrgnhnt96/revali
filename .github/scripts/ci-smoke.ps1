# Minimal CI smoke test: bootstrap deps and run revali on small_test.

$ErrorActionPreference = 'Continue'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$LogDir = Join-Path $Root 'logs/ci-smoke'
$Workspace = 'small_test'
$App = Join-Path $Workspace 'app'
$StepResults = @()

Set-Location $Root
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Invoke-SmokeStep {
    param(
        [string]$Name,
        [string]$LogFile,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "==> $Name" -ForegroundColor Cyan

    @(
        "STEP: $Name",
        "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')",
        ''
    ) | Out-File -FilePath $LogFile -Encoding utf8

    $exitCode = 0
    try {
        & $Action 2>&1 | Tee-Object -FilePath $LogFile -Append
    }
    catch {
        $_ | Out-String | Tee-Object -FilePath $LogFile -Append
        $exitCode = 1
    }

    if ($null -ne $script:StepExitCode) {
        $exitCode = $script:StepExitCode
        $script:StepExitCode = $null
    }

    $status = if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' }
    "`nFinished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K') | Status: $status | Exit code: $exitCode" |
        Out-File -FilePath $LogFile -Append -Encoding utf8

    $script:StepResults += [pscustomobject]@{
        Step     = $Name
        LogFile  = $LogFile
        ExitCode = $exitCode
        Status   = $status
    }

    return $exitCode
}

function Add-PubCacheBinToPath {
    $pubCacheBin = Join-Path $env:LOCALAPPDATA 'Pub/Cache/bin'
    if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $pubCacheBin })) {
        $env:PATH = "$pubCacheBin;$env:PATH"
    }
}

$overallExit = 0

if ((Invoke-SmokeStep -Name 'Environment' -LogFile (Join-Path $LogDir '00-environment.log') -Action {
        Write-Host "Root: $Root"
        Write-Host "Workspace: $Workspace"
        Write-Host "App: $App"
        Write-Host "OS: $([System.Environment]::OSVersion.VersionString)"
        dart --version -v
        git --version
    }) -ne 0) {
    $overallExit = 1
}

if ((Invoke-SmokeStep -Name 'Bootstrap tooling' -LogFile (Join-Path $LogDir '01-bootstrap.log') -Action {
        dart pub global activate sip_cli
        if ($LASTEXITCODE -ne 0) { $script:StepExitCode = $LASTEXITCODE; return }

        Add-PubCacheBinToPath
        Get-Command sip -ErrorAction SilentlyContinue | Format-List *

        $script:StepExitCode = $LASTEXITCODE
    }) -ne 0) {
    $overallExit = 1
}

if ((Invoke-SmokeStep -Name 'small_test (revali generate-only)' -LogFile (Join-Path $LogDir '02-small-test.log') -Action {
        Push-Location (Join-Path $Root $Workspace)
        try {
            dart pub get
            if ($LASTEXITCODE -ne 0) { $script:StepExitCode = $LASTEXITCODE; return }

            Push-Location app
            try {
                dart run revali dev --generate-only --recompile
                $script:StepExitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }
        }
        finally {
            Pop-Location
        }
    }) -ne 0) {
    $overallExit = 1
}

$summaryPath = Join-Path $LogDir 'summary.log'
$summary = @(
    'Revali CI smoke summary',
    "Workspace: $Workspace",
    "App: $App",
    "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')",
    "Root: $Root",
    "Overall exit code: $overallExit",
    '',
    'Step results:'
)

foreach ($result in $StepResults) {
    $summary += "- [$($result.Status)] $($result.Step) (exit $($result.ExitCode)) -> $(Split-Path $result.LogFile -Leaf)"
}

$summary | Out-File -FilePath $summaryPath -Encoding utf8
Get-Content $summaryPath | Write-Host

exit $overallExit
