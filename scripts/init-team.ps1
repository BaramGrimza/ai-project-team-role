param(
  [Parameter(Mandatory = $true)]
  [string]$TargetDir,
  [string]$ProjectName = "",
  [string]$TeamRepoDir = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
$resolvedTarget = (Resolve-Path $TargetDir).Path
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
  $ProjectName = Split-Path -Leaf $resolvedTarget
}

Copy-Item -Path (Join-Path $TeamRepoDir "CLAUDE.md") -Destination (Join-Path $resolvedTarget "CLAUDE.md") -Force
New-Item -ItemType Directory -Force -Path (Join-Path $resolvedTarget ".claude\agents") | Out-Null
Copy-Item -Path (Join-Path $TeamRepoDir ".claude\agents\*") -Destination (Join-Path $resolvedTarget ".claude\agents") -Recurse -Force

New-Item -ItemType Directory -Force -Path (Join-Path $resolvedTarget "docs\templates") | Out-Null
Copy-Item -Path (Join-Path $TeamRepoDir "docs\templates\*") -Destination (Join-Path $resolvedTarget "docs\templates") -Recurse -Force

@("docs\01-analysis", "docs\02-design", "docs\03-dev", "docs\04-test", "docs\05-qa", "docs\logs") | ForEach-Object {
  $p = Join-Path $resolvedTarget $_
  New-Item -ItemType Directory -Force -Path $p | Out-Null
  New-Item -ItemType File -Force -Path (Join-Path $p ".gitkeep") | Out-Null
}

$logTemplate = Join-Path $TeamRepoDir "docs\templates\07_활동로그_activity-log_템플릿.md"
$logDest = Join-Path $resolvedTarget "docs\logs\activity-log.md"
if (Test-Path $logTemplate) {
  Copy-Item -Path $logTemplate -Destination $logDest -Force
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
  Add-Content -Path $logDest -Value "`n| $ts | 초기화 | PowerShell(init-team.ps1) | 저장소 초기화 | [$ProjectName] 팀 규약·에이전트·템플릿 복사 및 폴더 구조 생성 완료 | 완료 |" -Encoding utf8
}

Write-Host "초기화 완료: $resolvedTarget"