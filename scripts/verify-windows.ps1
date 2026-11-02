#requires -Version 5.1
<#
  Real-machine verification of one PR. Run by Codex on the dedicated verify machine/account.
  Covers what hosted CI cannot: real GPU, driver, DPI, performance.
  Usage:  .\verify-windows.ps1 -Pr 42 -Repo OWNER/REPO -PostStatus
  Needs:  git, gh (read-only for code; statuses:write + issues:write on the Codex token), cmake, Visual Studio 2022.
  ADJUST the three variables in the "project-specific" block.
  Timeout: this script does not limit its own runtime. Run it with a timeout
  (e.g. Start-Job { .\verify-windows.ps1 -Pr 42 -Repo OWNER/REPO } | Wait-Job -Timeout 5400)
  to avoid hangs.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][int]$Pr,
  [Parameter(Mandatory)][string]$Repo,
  [string]$WorkRoot = 'C:\verify',
  [switch]$PostStatus
)
$ErrorActionPreference = 'Stop'

# ---- project-specific -------------------------------------------------------
$Configs         = @('Debug', 'Release')
$RealMachineTests = 'golden|gpu|dpi|perf'   # ctest -L regex; tests that need the real machine
$StatusContext   = 'verify/windows-real'    # must match .github/rulesets/main-protection.json
# -----------------------------------------------------------------------------

# Guard: never build/run agent-produced code elevated.
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if ((New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  throw 'Refusing to run elevated. Use the dedicated low-privilege verify account.'
}

function Invoke-Checked {
  param([string]$Exe, [string[]]$ArgList)
  & $Exe @ArgList 2>&1 | Tee-Object -FilePath $script:Log -Append
  if ($LASTEXITCODE -ne 0) { throw "$Exe $($ArgList -join ' ') failed with exit code $LASTEXITCODE" }
}

$head = (gh pr view $Pr --repo $Repo --json headRefOid --jq .headRefOid).Trim()
$out  = Join-Path $WorkRoot "out\$head"
$src  = Join-Path $WorkRoot "src\$head"
New-Item -ItemType Directory -Force $out | Out-Null
$script:Log = Join-Path $out 'verify.log'
'' | Set-Content $script:Log

$rows  = New-Object System.Collections.Generic.List[string]
$state = 'success'
$desc  = 'build + tests + real-machine tests passed'

try {
  # Hardware snapshot (evidence for "what machine was this")
  $gpu = Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion
  $os  = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, BuildNumber
  ($gpu | ConvertTo-Json) | Add-Content $script:Log
  ($os  | ConvertTo-Json) | Add-Content $script:Log

  # Fresh checkout of the exact PR head commit
  if (Test-Path $src) { Remove-Item -Recurse -Force $src }
  Invoke-Checked gh @('repo', 'clone', $Repo, $src, '--', '--no-checkout')
  Invoke-Checked git @('-C', $src, 'fetch', 'origin', "pull/$Pr/head")
  Invoke-Checked git @('-C', $src, 'checkout', '--detach', $head)
  if ((git -C $src rev-parse HEAD).Trim() -ne $head) { throw 'Checked-out commit != PR head' }

  foreach ($cfg in $Configs) {
    $b = Join-Path $src "build-$cfg"
    Invoke-Checked cmake @('-S', $src, '-B', $b, '-G', 'Visual Studio 17 2022', '-A', 'x64')
    Invoke-Checked cmake @('--build', $b, '--config', $cfg, '--parallel')
    Invoke-Checked ctest @('--test-dir', $b, '-C', $cfg, '--output-on-failure', '--no-tests=error')
    # --no-tests=error: if the labels match nothing, fail loudly instead of "passing" an empty run
    Invoke-Checked ctest @('--test-dir', $b, '-C', $cfg, '--output-on-failure', '-L', $RealMachineTests, '--no-tests=error')
    $rows.Add("| $cfg | build, ctest, real-machine tests | PASS |")
  }
}
catch {
  $state = 'failure'
  $desc  = ($_.Exception.Message -replace '\s+', ' ')
  if ($desc.Length -gt 130) { $desc = $desc.Substring(0, 130) }
  $rows.Add("| (stopped) | $desc | FAIL |")
}

# Stale check: if the PR moved while we were running, this result must not count.
$headNow = (gh pr view $Pr --repo $Repo --json headRefOid --jq .headRefOid).Trim()
if ($headNow -ne $head) { $state = 'error'; $desc = 'PR head changed during verify; result is stale'; $rows.Add("| - | $desc | STALE |") }

$summary = @"
### Verify on real Windows: **$state**
Commit ``$head``
GPU: $(($gpu | ForEach-Object { "$($_.Name) ($($_.DriverVersion))" }) -join '; ')
OS: $($os.Caption) build $($os.BuildNumber)

| Config | Steps | Result |
|---|---|---|
$($rows -join "`n")

<details><summary>Last 60 log lines</summary>

``````
$((Get-Content $script:Log -Tail 60) -join "`n")
``````
</details>
"@
$summary | Set-Content (Join-Path $out 'summary.md') -Encoding UTF8

if ($PostStatus) {
  gh pr comment $Pr --repo $Repo --body-file (Join-Path $out 'summary.md')
  gh api -X POST "repos/$Repo/statuses/$head" -f state=$state -f context=$StatusContext -f description=$desc | Out-Null
}
if ($state -ne 'success') { exit 1 }
