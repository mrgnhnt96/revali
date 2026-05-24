# Windows CI test runner for Revali.
# All output is tee'd to numbered log files under logs/windows-ci/ for export.

$ErrorActionPreference = 'Continue'
$script:Root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$script:LogDir = Join-Path $script:Root 'logs/windows-ci'
$script:StepResults = @()

Set-Location $script:Root
New-Item -ItemType Directory -Force -Path $script:LogDir | Out-Null

function Write-StepHeader {
    param(
        [string]$Name,
        [string]$LogFile
    )

    $header = @"
================================================================================
STEP: $Name
Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')
Working directory: $(Get-Location)
================================================================================

"@
    $header | Out-File -FilePath $LogFile -Encoding utf8
}

function Invoke-LoggedStep {
    param(
        [string]$Name,
        [string]$LogFile,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "==> $Name" -ForegroundColor Cyan
    Write-StepHeader -Name $Name -LogFile $LogFile

    $script:StepExitCode = $null
    $exitCode = 0
    try {
        & $Action 2>&1 | Tee-Object -FilePath $LogFile -Append
        if ($null -ne $script:StepExitCode) {
            $exitCode = $script:StepExitCode
        }
        elseif ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            $exitCode = $LASTEXITCODE
        }
    }
    catch {
        $_ | Out-String | Tee-Object -FilePath $LogFile -Append
        $exitCode = 1
    }
    finally {
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

function Set-RevaliPubspecPathDependencies {
    param([bool]$CommentOut)

    $pubspecs = Get-ChildItem -Path $script:Root -Recurse -Filter pubspec.yaml |
        Where-Object { $_.FullName -notmatch '[\\/]\.revali[\\/]' }

    foreach ($pubspec in $pubspecs) {
        $lines = Get-Content -Path $pubspec.FullName
        $changed = $false

        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'path:\s*\.revali/') {
                if ($CommentOut) {
                    if ($i -gt 0 -and $lines[$i - 1] -notmatch '^\s*#') {
                        $lines[$i - 1] = "#$($lines[$i - 1])"
                        $changed = $true
                    }
                    if ($lines[$i] -notmatch '^\s*#') {
                        $lines[$i] = "#$($lines[$i])"
                        $changed = $true
                    }
                }
                else {
                    if ($i -gt 0 -and $lines[$i - 1] -match '^\s*#') {
                        $lines[$i - 1] = ($lines[$i - 1] -replace '^\s*#+\s?', '')
                        $changed = $true
                    }
                    if ($lines[$i] -match '^\s*#') {
                        $lines[$i] = ($lines[$i] -replace '^\s*#+\s?', '')
                        $changed = $true
                    }
                }
            }
        }

        if ($changed) {
            Set-Content -Path $pubspec.FullName -Value $lines -Encoding utf8
            "Updated $($pubspec.FullName)" | Write-Host
        }
    }
}

function Invoke-DartInDirectory {
    param(
        [string]$Directory,
        [string[]]$Arguments
    )

    Push-Location $Directory
    try {
        & dart @Arguments
        return $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
}

function Invoke-TestSuiteGeneration {
    $serverDirs = @(
        'methods', 'access_control', 'custom_return_types', 'primitive_return_types',
        'null_primitive_return_types', 'middleware', 'params', 'pipes', 'default_params',
        'custom_params', 'sse', 'sse_custom', 'meta_reflect'
    )
    $clientDirs = @(
        'can_compile_aot', 'cookies', 'primitive_return_types', 'null_primitive_return_types',
        'custom_return_types', 'default_params', 'default_custom_params', 'methods', 'params',
        'sse', 'sse_custom',
        'websockets/custom_return_types', 'websockets/primitive_return_types',
        'websockets/params', 'websockets/null_primitive_return_types', 'websockets/two_way'
    )

    $failures = @()

    foreach ($dir in $serverDirs) {
        $testDir = Join-Path $script:Root "test_suite/constructs/revali_server/$dir"
        Write-Host "Generating server test suite: $dir"
        $code = Invoke-DartInDirectory -Directory $testDir -Arguments @(
            'run', 'revali', 'dev', '--generate-only', '--recompile'
        )
        if ($code -ne 0) {
            $failures += "revali_server/$dir (exit $code)"
        }
    }

    foreach ($dir in $clientDirs) {
        $testDir = Join-Path $script:Root "test_suite/constructs/revali_client/$dir"
        Write-Host "Generating client test suite: $dir"
        $code = Invoke-DartInDirectory -Directory $testDir -Arguments @(
            'run', 'revali', 'dev', '--generate-only', '--recompile'
        )
        if ($code -ne 0) {
            $failures += "revali_client/$dir (exit $code)"
        }
    }

    if ($failures.Count -gt 0) {
        Write-Host "Generation failures:"
        $failures | ForEach-Object { Write-Host "  - $_" }
        return 1
    }

    return 0
}

function Invoke-RecursiveDartTests {
    $packages = Get-ChildItem -Path $script:Root -Recurse -Filter pubspec.yaml |
        Where-Object {
            $_.FullName -notmatch '[\\/]\.revali[\\/]' -and
            $_.FullName -notmatch '[\\/]examples[\\/]' -and
            (Test-Path (Join-Path $_.DirectoryName 'test'))
        } |
        Sort-Object FullName

    $failures = @()

    foreach ($pubspec in $packages) {
        $packageDir = $pubspec.DirectoryName
        $relativePath = $packageDir.Substring($script:Root.Length).TrimStart('\', '/')
        Write-Host ""
        Write-Host "--- dart test in $relativePath ---" -ForegroundColor Yellow

        Push-Location $packageDir
        try {
            & dart pub get -v
            if ($LASTEXITCODE -ne 0) {
                $failures += "$relativePath (pub get exit $LASTEXITCODE)"
                continue
            }

            & dart test --reporter expanded --chain-stack-traces --verbose-trace
            if ($LASTEXITCODE -ne 0) {
                $failures += "$relativePath (test exit $LASTEXITCODE)"
            }
        }
        finally {
            Pop-Location
        }
    }

    if ($failures.Count -gt 0) {
        Write-Host ""
        Write-Host "Test failures:" -ForegroundColor Red
        $failures | ForEach-Object { Write-Host "  - $_" }
        return 1
    }

    return 0
}

$overallExit = 0

Invoke-LoggedStep -Name 'Environment' -LogFile (Join-Path $script:LogDir '00-environment.log') -Action {
    Write-Host "Root: $script:Root"
    Write-Host "Log directory: $script:LogDir"
    Write-Host "Computer: $env:COMPUTERNAME"
    Write-Host "User: $env:USERNAME"
    Write-Host "OS: $([System.Environment]::OSVersion.VersionString)"
    cmd /c ver
    Write-Host "Shell: $($PSVersionTable.PSVersion)"
    Write-Host "PATH: $env:PATH"
    Get-Command dart -ErrorAction SilentlyContinue | Format-List *
    dart --version -v
    git --version
    where.exe dart
}

if ((Invoke-LoggedStep -Name 'Bootstrap tooling' -LogFile (Join-Path $script:LogDir '01-bootstrap.log') -Action {
        dart pub global activate sip_cli
        if ($LASTEXITCODE -ne 0) { return }

        Add-PubCacheBinToPath
        Write-Host "Pub cache bin: $(Join-Path $env:LOCALAPPDATA 'Pub/Cache/bin')"
        Get-Command sip -ErrorAction SilentlyContinue | Format-List *

        Push-Location (Join-Path $script:Root 'hooks')
        dart pub get -v
        if ($LASTEXITCODE -ne 0) { return }
        Pop-Location

        Push-Location (Join-Path $script:Root 'scripts')
        dart pub get -v
        if ($LASTEXITCODE -ne 0) { return }
        Pop-Location

        sip pub get --recursive --no-version-check
    }) -ne 0) {
    $overallExit = 1
}

if ((Invoke-LoggedStep -Name 'Build runner code generation' -LogFile (Join-Path $script:LogDir '02-build-runner.log') -Action {
        $packages = @(
            'packages/revali_construct',
            'revali_router/revali_router',
            'constructs/revali_server'
        )

        foreach ($relative in $packages) {
            Write-Host "build_runner in $relative"
            Push-Location (Join-Path $script:Root $relative)
            dart pub get -v
            if ($LASTEXITCODE -ne 0) { return }
            dart run build_runner build --delete-conflicting-outputs -v
            if ($LASTEXITCODE -ne 0) { return }
            Pop-Location
        }
    }) -ne 0) {
    $overallExit = 1
}

if ((Invoke-LoggedStep -Name 'Test suite generation' -LogFile (Join-Path $script:LogDir '03-test-suite-gen.log') -Action {
        Write-Host 'Commenting out .revali path dependencies...'
        Set-RevaliPubspecPathDependencies -CommentOut:$true

        Push-Location (Join-Path $script:Root 'test_suite')
        dart pub get -v
        if ($LASTEXITCODE -ne 0) { return }
        Pop-Location

        $script:StepExitCode = Invoke-TestSuiteGeneration
        if ($script:StepExitCode -ne 0) { return }

        Write-Host 'Restoring .revali path dependencies...'
        Set-RevaliPubspecPathDependencies -CommentOut:$false

        Push-Location (Join-Path $script:Root 'test_suite')
        dart pub get -v
    }) -ne 0) {
    $overallExit = 1
}

if ((Invoke-LoggedStep -Name 'Recursive dart tests' -LogFile (Join-Path $script:LogDir '04-recursive-tests.log') -Action {
        $script:StepExitCode = Invoke-RecursiveDartTests
    }) -ne 0) {
    $overallExit = 1
}

if ((Invoke-LoggedStep -Name 'Hello example smoke test' -LogFile (Join-Path $script:LogDir '05-hello-example.log') -Action {
        $helloDir = Join-Path $script:Root 'examples/hello'
        Push-Location $helloDir
        dart pub get -v
        if ($LASTEXITCODE -ne 0) { return }

        dart run revali dev --generate-only --recompile
        if ($LASTEXITCODE -ne 0) { return }

        dart run revali build
    }) -ne 0) {
    $overallExit = 1
}

$summaryPath = Join-Path $script:LogDir 'summary.log'
$summary = @(
    "Revali Windows CI summary",
    "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')",
    "Root: $script:Root",
    "Overall exit code: $overallExit",
    "",
    "Step results:"
)

foreach ($result in $script:StepResults) {
    $summary += "- [$($result.Status)] $($result.Step) (exit $($result.ExitCode)) -> $(Split-Path $result.LogFile -Leaf)"
}

$summary += ""
$summary += "Download the logs/windows-ci artifact from the GitHub Actions run to share these files."

$summary | Out-File -FilePath $summaryPath -Encoding utf8
Get-Content $summaryPath | Write-Host

exit $overallExit
