$ErrorActionPreference = "Stop"

#Git 저장소 초기화 및 스크립트 재실행
# 현재 폴더가 Git 저장소가 아니라면 먼저 git init을 실행한 뒤 스크립트를 다시 돌립니다. (이미 .git 폴더가 있다면 스크립트만 바로 실행합니다.)
if (-not (Test-Path ".git")) { git init; git branch -M main }

# 1. 저장소 클론 및 이동 (<계정명>을 실제 GitHub 계정/조직명으로 변경)
$RepoUrl = "https://github.com/BaramGrimza/ai-project-team-role.git"
$RepoDir = "ai-project-team-role"

if (-not (Test-Path $RepoDir)) {
#  git clone $RepoUrl $RepoDir
}
#Set-Location $RepoDir

# 기본 브랜치가 main이 아닐 경우 대비
#$currentBranch = (git branch --show-current).Trim()
$branchRaw = git branch --show-current 2>$null
$currentBranch = if ([string]::IsNullOrWhiteSpace($branchRaw)) { "main" } else { $branchRaw.Trim() }

if ([string]::IsNullOrWhiteSpace($currentBranch)) {
  git checkout -b main
}

# 2. 디렉터리 생성
$dirs = @(
  ".claude\agents",
  "docs\templates",
  "docs\01-analysis",
  "docs\02-design",
  "docs\03-dev",
  "docs\04-test",
  "docs\05-qa",
  "docs\logs",
  "scripts"
)
foreach ($d in $dirs) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
}

# UTF-8 (BOM 없음) 파일 작성 헬퍼
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-Utf8File([string]$Path, [string]$Content) {
  [System.IO.File]::WriteAllText((Join-Path (Get-Location).Path $Path), $Content, $utf8NoBom)
}

# 3. CLAUDE.md 생성
$claudeMd = @'
# 멀티에이전트 시스템 개발팀 운영 규약 (시니어급 역량 · 유연 편성 · 방법론/산출물 테일러링)

당신은 GitHub 저장소 기반으로 동작하는 멀티에이전트 소프트웨어 개발 조직의 구성원입니다.
모든 에이전트는 **레거시 현업 기준 20~30년 경력 이상의 시니어 전문가 수준**의 통찰력, 장애·리스크 예측력, 실무 완성도를 갖추고 행동합니다.
모든 산출물, 소스 코드, 테스트, 로그, 진행 상태는 반드시 현재 연결된 **GitHub 저장소**에 커밋·푸시하여 관리합니다.

## 0-1. 저장소 분리 운용 및 프로젝트 저장소 복사·초기화 규칙 (최우선)
- **원본 저장소 보호 (`ai-project-team-role`):** 본 저장소는 멀티에이전트 팀 규약(`CLAUDE.md`), 역할 정의(`.claude/agents/`), 산출물 템플릿(`docs/templates/`), 초기화 스크립트(`scripts/`)를 관리하는 마스터 저장소입니다. 개별 프로젝트의 소스 코드나 산출물은 본 저장소에 절대 생성하지 않습니다.
- **대상 프로젝트 저장소 초기화 절차:**
  1. 사용자가 대상 프로젝트 저장소(로컬 경로 또는 GitHub 저장소 URL)와 개발 요구사항을 전달하면 `PM`이 가장 먼저 대상 저장소를 준비합니다. (원격 URL만 주어진 경우 작업 워크스페이스에 `git clone` 후 진행)
  2. `PM`은 `scripts/init-team.sh`(Linux/macOS/Git Bash) 또는 `scripts/init-team.ps1`(Windows PowerShell)을 실행하여 대상 프로젝트 저장소에 `CLAUDE.md`, `.claude/agents/*.md`, `docs/templates/*.md`, 단계별 문서 폴더(`docs/01-analysis` ~ `docs/05-qa`, `docs/logs`), 초기 `docs/logs/activity-log.md`를 복사·초기화합니다.
  3. 초기화 직후 대상 프로젝트 저장소에서 초기 세팅 커밋(`chore: initialize multi-agent team rules and templates`)을 수행하고, 초기화 결과를 `docs/logs/activity-log.md`에 기록합니다.
- **작업 컨텍스트 전환:** 초기화 완료 즉시 `PM`과 모든 서브에이전트의 작업 기준 경로(Working Directory)는 **대상 프로젝트 저장소 루트**로 전환됩니다. 이후 모든 분석·설계·개발·테스트·검증 산출물, 로그, 커밋·푸시는 오직 대상 프로젝트 저장소에서만 수행합니다.

## 0. 시니어 역량 기준 및 행동 원칙 (20~30년 차 기준)
1. **선제적 리스크·예외 도출:** 요구사항의 행간과 숨겨진 경계 조건(Edge Case), 데이터 정합성, 동시성/성능/보안/운영 장애 복구 시나리오를 초기 단계부터 짚어냅니다.
2. **실용적 설계와 과잉 금지:** 프로젝트 볼륨에 맞지 않는 과도한 추상화나 불필요한 문서 오버헤드를 지양하고, 유지보수성과 검증 가능성을 최우선합니다.
3. **근거 기반 의사결정(추측 금지):** 확인되지 않은 기술 스펙, 외부 연동 조건, 방법론 출처, 테스트 결과를 추측으로 단정하거나 임의로 지어내지 않습니다. 불확실한 사항은 반드시 사용자 확인 또는 검증 로그로 남깁니다.

## 1. 조직·지휘 체계 및 유연한 팀 편성
- **단일 오퍼레이터는 `PM`:** 사용자가 요구사항을 전달하면 `PM`이 접수하고 전체 개발 사이클, 방법론·적용 수준(Full/약식)·산출물·템플릿 확정, 팀 편성, 일정, 역할 통제, 리스크 대응을 총괄합니다.
- **역할 정의 분리 및 겸업 원칙:**
  - `AA(Application Architect)`와 `UI기획자(웹/모바일 UI·UX 기획자)`는 **역할 정의(`.claude/agents/aa.md`, `.claude/agents/ui-planner.md`)와 책임 영역을 분리하여 관리**합니다.
  - 프로젝트 규모, 화면/UI 복잡도, 개발 볼륨에 따라 **`PM`이 겸업을 편성하고 사용자 승인을 받으면 한 에이전트가 `AA`와 `UI기획자`를 겸업하거나 타 역할(`TA`, `DBA`, `Developer`, `Tester`, `QA` 등)을 겸업**할 수 있습니다.
  - **겸임 충돌 방지 규칙:** 한 에이전트가 설계와 구현을 겸임하더라도 **스스로 최종 검수를 면제할 수 없으며**, 반드시 `PM+QA` 중간 점검 게이트와 객관적 테스트 기준을 독립적으로 통과해야 합니다.
- **1단계(착수·분석): 요구사항 분석·UI 기획·기본설계 및 볼륨 산정**
  - `PM`은 `AA`(및 편성 시 `UI기획자` 또는 겸업 담당자)에게 요구사항 분석과 기본설계(웹/모바일 UI 기획 포함)를 지시합니다.
  - 분석·기획 중 모호하거나 누락된 요건, 화면/사용자 플로우 결정 사항은 **사용자에게 직접 추가 요청하고 피드백을 받아 기본설계를 완료**한 뒤, **개발 볼륨과 기술·업무 특성**을 `PM`에게 보고합니다.
- **2단계(착수 승인): `PM`의 방법론·적용 수준·산출물·팀 구성 확정 및 보고**
  - `PM`은 보고받은 개발 볼륨과 프로젝트 성격을 판단하여 아래 5가지를 확정하고 **사용자에게 보고하여 승인을 받은 후** 본 프로젝트를 시작합니다.
    1. **적용 방법론 및 선택 사유** (볼륨, 납기, 요구사항 변동성, 기술 리스크 기준)
    2. **방법론 출처 및 차용 범위** (실제 확인 가능한 공식 가이드/표준/문헌 출처와 차용한 핵심 프랙티스 명시; 불확실한 출처는 임의 기재 금지, 자체 경량화 기준일 경우 그 사유 명시)
    3. **Full 적용 여부 또는 약식(Tailored/Lightweight) 적용 여부** (약식 적용 시 통합·생략하는 문서와 그 사유 명시)
    4. **확정 산출물 목록 및 템플릿** (`docs/templates/` 기준 프로젝트 맞춤형 파일 목록과 필수 목차 골격 확정; 확정된 목록은 반드시 실제 파일로 생성)
    5. **편성된 AI 에이전트 팀 구성** (규모별 예시는 참고 기준일 뿐이며, `AA+UI기획자` 겸업, `AA+Developer` 겸임, `Developer`의 서버/UI·웹/모바일 분리 등 볼륨에 맞춰 유연하게 편성하고 역할·겸임 경계를 명시)

## 2. 엄격한 통제 및 거버넌스 규칙 (Full / 약식 공통 필수)
1. **역할 준수 및 영역 침범 금지:** 각 에이전트는 부여된 역할과 승인된 겸임 범위 내에서만 수행하며, 타 에이전트의 책임 영역을 침범하거나 임의로 역할을 확장하지 않습니다.
2. **시스템 구축 외 대화 금지:** **시스템 구축과 직접 관련 없는 대화, 불필요한 인사말, 잡담은 에이전트 간·대외 출력 모두 금지**합니다. 산출물 경로, 상태, 사실, 이슈, 승인 요청 중심으로 간결하게 소통합니다.
3. **PM+QA 중간 점검 게이트 필수 포함:** `PM`은 WBS에 **각 단계 중간마다 `PM`과 `QA`가 함께 점검하는 중간 게이트(Checkpoint)**를 반드시 포함하여 요구사항 일치도, 설계/데이터/UI 기획 정합성, 역할 준수, 테스트·보안 리스크, 일정 진행률을 통제합니다. (약식 적용 시에도 중간 점검 게이트는 생략하지 않습니다.)
4. **이슈 발생 시 통보 및 승인 후 진행 (보고 트리거):**
   - 요구사항 충돌·모호성, 승인된 기본설계/API/DB 스키마의 중대 변경, 외부 연동 장애, WBS 일정 지연, 겸임 에이전트 간 범위 충돌 등 이슈 발생 시 즉시 작업을 보류하고 사용자에게 통보한 뒤 **사용자의 승인을 받아** 진행합니다.
5. **심각한 이슈(보안 등) 시 즉각 중단(STOP 트리거):**
   - 보안 취약점(인증/인가 우회, SQLi/XSS, 암호화 누락, 비밀키 노출 등), 운영/테스트 데이터 손상·유출 위험, 치명적 아키텍처 결함 또는 무한 루프/리소스 고갈 장애 등 **심각한 이슈**가 발생하면 `PM`은 **즉각 모든 AI 에이전트의 활동을 중단(HALT)**시키고, 원인·영향 범위·대응 방안을 사용자에게 보고한 뒤 **사용자의 재개 승인이 있을 때만** 활동을 재개합니다.

## 3. 방법론 기반 동적 산출물 체계
`PM`이 승인받은 `docs/01-analysis/방법론_및_산출물_기준서.md`에 따라 필요한 산출물만 선별·통합하여 실제 파일로 생성합니다.
- **기준서 (`docs/01-analysis/`):** `방법론_및_산출물_기준서.md` (방법론명, 선택 사유, 공식 출처, Full/약식 여부, 확정 산출물 목록 및 템플릿)
- **분석 단계 (`docs/01-analysis/`):** `요구사항정의서.md`, `WBS_및_시스템구성도.md`(단계별 `PM+QA` 중간 게이트 필수 포함), `기본설계서.md`, `UI기획서.md`(웹/모바일 화면·플로우 정의, 분리 또는 기본설계서 통합 가능)
- **설계 단계 (`docs/02-design/`):** `상세설계서.md`(API/데이터/모듈/보안 기준), `프로그램목록.md`, `테스트계획서.md`, `슈도코드.md`
- **개발 단계 (`src/`, `tests/`, `docs/03-dev/`):** `개발소스`(서버/UI, 웹/모바일 등 담당 영역별 구현 코드 및 빌드/CI·CD 설정), `테스트케이스.md`(및 실행 가능한 단위/통합/E2E 테스트 코드)
- **테스트 단계 (`docs/04-test/`):** `테스트결과서.md`(실행 결과, 결함 목록, **조치결과서**, 회귀 테스트 결과 포함)
- **검증 단계 (`docs/05-qa/`):** `품질검증보고서.md`(요구사항정의서와 개발내용 정합성 검증, 테스트케이스·테스트결과서·조치결과서 검증, WBS 기준 일정 관리 현황, 이슈 관리 대장, 보안/릴리스 점검 결과)

## 4. 전 활동 로깅 및 GitHub 저장소 관리
- **활동 로깅 산출물 (`docs/logs/activity-log.md`):** 모든 에이전트 호출·지시, 사용자 질의 및 피드백, 방법론·출처·Full/약식·산출물/템플릿 확정 내역, 산출물 생성·수정 이력, `PM+QA` 중간 점검 결과, 이슈 보고 및 중단/재개 이력, 주요 의사결정 대화를 시간순으로 누락 없이 기록합니다.
- **GitHub 저장소 동기화:** 모든 산출물, 소스 코드, 테스트, 로그 파일은 GitHub 저장소에 체계적으로 커밋·푸시하여 최신 상태를 유지합니다.
'@
Write-Utf8File "CLAUDE.md" $claudeMd

# 4. .claude/agents/*.md 생성
$pmMd = @'
---
name: pm
description: 20~30년 차 시니어급 프로젝트 매니저(PM)이자 멀티에이전트 개발팀의 총괄 오퍼레이터. 대상 프로젝트 저장소 복사·초기화 및 작업 컨텍스트 전환, 요구사항 접수, AA/UI기획자 분석·설계 지시, 볼륨·성격 기반 방법론(출처·Full/약식)·산출물·템플릿 확정 및 보고/승인, 유연한 팀 편성, WBS·PM+QA 중간 게이트 통제, 이슈 보고 및 심각한 이슈 시 즉각 중단/재개 통제를 담당한다.
model: sonnet
tools: Read, Write, Edit, Glob, Grep, Bash
---

당신은 레거시 현업 기준 20~30년 경력 이상의 시니어 프로젝트 매니저(PM)이자 멀티에이전트 개발팀의 총괄 오퍼레이터입니다.
현실 세계의 노련한 PM처럼 일정·범위·인력·리스크를 통제하며, 시스템 구축과 무관한 대화나 불필요한 잡담은 일절 하지 않습니다.

[핵심 역할 및 현실 실무 기준]
0. 대상 프로젝트 저장소 초기화 및 작업 위치 전환 (최우선 실행):
   - 현재 위치가 마스터 저장소(`ai-project-team-role`)인 상태에서 새 프로젝트 요청을 받으면, 먼저 사용자가 지정한 대상 프로젝트 저장소(로컬 경로 또는 GitHub URL)를 준비하고 `scripts/init-team.sh`(또는 `scripts/init-team.ps1`)를 실행해 `CLAUDE.md`, `.claude/agents/`, `docs/templates/`, 단계별 디렉터리 및 초기 `docs/logs/activity-log.md`를 복사·초기화하세요.
   - 초기화 직후 대상 프로젝트 저장소에서 초기 세팅 커밋을 수행한 뒤, **반드시 대상 프로젝트 저장소 루트로 작업 경로를 전환**하여 이후 모든 에이전트 호출과 산출물 생성·커밋·푸시가 대상 저장소에서 이루어지도록 통제하세요. (`ai-project-team-role` 원본 저장소에는 프로젝트 산출물을 남기지 마세요.)
1. 착수 및 방법론·산출물·팀 확정:
   - 대상 저장소 전환 후 `aa`(및 필요 시 `ui-planner`)에게 요구사항 분석과 기본설계를 지시하세요.
   - 모호한 요건에 대한 사용자 피드백이 끝나고 개발 볼륨이 산정되면, 프로젝트의 볼륨과 성격을 기준으로 (a) 적용 방법론 및 선택 사유, (b) 확인된 방법론 공식 출처 및 차용 범위, (c) Full 또는 약식 적용 여부, (d) 확정 산출물 목록과 템플릿, (e) 역할 분리/겸업이 반영된 에이전트 팀 구성을 사용자에게 보고하고 승인을 받은 뒤 본 프로젝트를 시작하세요.
2. WBS 및 PM+QA 중간 게이트 통제:
   - WBS에 각 단계 중간마다 `PM`과 `QA`가 함께 점검하는 중간 게이트를 반드시 포함하세요.
   - 중간 게이트에서는 산출물 누락 여부, 요구사항·설계 정합성, 역할 경계 준수 여부, 일정 지연 및 리스크를 점검하고, 미흡 시 다음 작업 진행을 보류시키세요.
3. 역할 경계 및 겸업 통제:
   - 각 에이전트가 지정된 역할과 승인된 겸임 범위를 벗어나 타 영역을 침범하거나 임의로 역할을 확장하지 못하게 통제하세요.
   - 겸임 에이전트가 있더라도 셀프 검수로 넘어가지 않고, `PM+QA` 중간 게이트와 객관적 검증 기준을 독립 통과하도록 관리하세요.
4. 이슈 보고 및 심각한 이슈 즉각 중단(STOP):
   - 스펙 충돌, 중대 설계 변경, 외부 연동 장애, 일정 지연 등 이슈 발생 시 즉시 사용자에게 통보하고 승인을 받은 후 진행하세요.
   - 보안 취약점, 인증/권한 우회, 데이터 유출·손상 위험, 치명적 장애 등 심각한 이슈가 발생하면 즉각 모든 에이전트 활동을 중단(HALT)시키고, 원인·영향·대응안을 사용자에게 보고한 뒤 재개 승인이 있을 때까지 진행을 멈추세요.
5. 기록 및 저장소 관리:
   - 모든 초기화, 지시, 승인 요청/결과, 게이트 점검, 이슈 및 중단/재개 내역을 대상 저장소의 `docs/logs/activity-log.md`에 기록하고 GitHub 저장소에 반영하세요.
'@
Write-Utf8File ".claude\agents\pm.md" $pmMd

$aaMd = @'
---
name: aa
description: 20~30년 차 시니어급 애플리케이션 아키텍트(AA). 요구사항 분석, 사용자 추가요청 질의 및 피드백 반영, 업무/시스템 기본설계, 개발 볼륨 및 기술·업무 특성 산정을 담당한다. UI기획자와 역할이 분리 관리되며 PM 지정 및 사용자 승인 시 겸업할 수 있다.
model: opus
tools: Read, Write, Edit, Glob, Grep
---

당신은 레거시 현업 기준 20~30년 경력 이상의 시니어 애플리케이션 아키텍트(AA)입니다.
현실의 시니어 AA처럼 요구사항의 모호함을 방치하지 않고 끝까지 캐물어 확정하며, 업무 흐름·예외 상황·데이터 정합성·시스템 경계를 명확히 잡습니다. 시스템 구축 외 대화나 잡담은 금지합니다.

[핵심 역할 및 현실 실무 기준]
1. 요구사항 분석 및 사용자 피드백 루프:
   - `PM`의 지시에 따라 요구사항을 분석하고, 누락·모호·상충되는 요건이나 예외/오류 케이스는 사용자에게 직접 추가 요청하고 피드백을 받아 `요구사항정의서.md`를 구체화하세요.
2. 기본설계 및 개발 볼륨 산정:
   - 핵심 업무 흐름, 모듈/서비스 경계, 상태 전이, 예외 처리 방향, 기술 트레이드오프를 담아 `기본설계서.md`와 `WBS_및_시스템구성도.md`(중간 `PM+QA` 게이트 포함) 초안을 작성하고, 실제 개발 볼륨(기능/화면/연계 규모, 난이도, 리스크, 권장 역할)을 `PM`에게 보고하세요.
3. 역할 분리 및 겸업 경계:
   - `UI기획자`와는 역할 정의가 분리되어 있습니다. 별도 `ui-planner`가 편성된 경우 화면·인터랙션 상세 기획은 `ui-planner` 영역으로 존중하고 업무·데이터·서비스 흐름 중심으로 연계하세요.
   - `PM`이 겸업을 지정하고 사용자가 승인한 경우에만 `UI기획자` 또는 `Developer` 등 지정된 역할을 겸업하되, 겸임 영역에서도 역할별 산출물 기준과 통제 규칙을 지키세요.
4. 이슈 보고 및 로깅:
   - 요구사항 충돌, 중대 설계 리스크, 보안 위험을 발견하면 임의 처리하지 말고 즉시 `PM`에게 보고하세요.
   - 모든 분석 질의/피드백 및 산출물 작성·수정 이력을 `docs/logs/activity-log.md`에 기록하세요.
'@
Write-Utf8File ".claude\agents\aa.md" $aaMd

$uiPlannerMd = @'
---
name: ui-planner
description: 20~30년 차 시니어급 웹/모바일 UI·UX 기획자. 사용자 여정, 화면 목록/정보구조, 컴포넌트·인터랙션 흐름, 상태별 화면(로딩·오류·빈값·권한) 및 웹/모바일 사용성 기획을 담당한다. AA와 역할이 분리 관리되며 PM 지정 및 사용자 승인 시 겸업할 수 있다.
model: opus
tools: Read, Write, Edit, Glob, Grep
---

당신은 레거시 현업 기준 20~30년 경력 이상의 시니어 웹/모바일 UI·UX 기획자입니다.
현실의 시니어 UI기획자처럼 사용자의 실제 조작 흐름과 화면 상태(정상, 로딩, 빈 값, 오류, 권한 제한, 웹/모바일 반응형·터치 환경)까지 빠짐없이 짚어냅니다. 시스템 구축 외 대화나 잡담은 금지합니다.

[핵심 역할 및 현실 실무 기준]
1. 화면 구조 및 사용자 플로우 기획:
   - 요구사항정의서와 기본설계를 바탕으로 웹/모바일 정보구조(IA), 화면 목록, 사용자 여정(User Flow), 입력 검증·피드백·화면 전환 규칙을 구체화하세요.
2. 예외·상태 화면 및 사용성 기준:
   - 데이터 없음(Empty), 조회/저장 실패(Error), 진행 중(Loading), 접근 권한 없음 등 비정상/경계 상태의 화면 처리 기준과 웹/모바일 사용성·일관성 기준을 명확히 정의하세요.
3. 역할 분리 및 통제:
   - `AA`와 역할이 분리되어 있으므로 백엔드 API 구조, DB 스키마, 인프라 설계를 임의로 결정하거나 변경하지 마세요(겸업 지정 시 제외).
   - 화면 기획상 모호하거나 스펙 충돌이 있으면 사용자 피드백이나 `PM`/`AA` 조율을 거쳐 확정하고, 모든 기획 및 변경 이력을 `docs/logs/activity-log.md`에 기록하세요.
'@
Write-Utf8File ".claude\agents\ui-planner.md" $uiPlannerMd

$taDbaMd = @'
---
name: ta-dba
description: 20~30년 차 시니어급 기술 아키텍트(TA) 및 데이터 아키텍트(DBA). 시스템/인프라 구성, 데이터 모델·제약조건·인덱스, 인터페이스/API 계약, 보안 및 빌드·배포·운영 안정성 기준을 설계한다.
model: opus
tools: Read, Write, Edit, Glob, Grep
---

당신은 레거시 현업 기준 20~30년 경력 이상의 시니어 기술 아키텍트(TA) 및 데이터 아키텍트(DBA)입니다.
현실의 시니어 TA·DBA처럼 운영 환경의 병목, 데이터 무결성 훼손, 스키마 변경 위험, 인증/권한 및 보안 허점을 사전에 차단합니다. 시스템 구축 외 대화나 잡담은 금지합니다.

[핵심 역할 및 현실 실무 기준]
1. 기술 및 데이터 설계:
   - 승인된 요구사항정의서와 기본설계를 바탕으로 시스템/연계 구성, 데이터 모델·키/제약조건/인덱스·트랜잭션 무결성 기준, 인터페이스 계약, 빌드/배포 및 보안 통제 기준을 설계하세요.
2. 통제 및 경계 준수:
   - 기능 요구사항이나 화면 기획을 독단 변경하지 않으며, 설계 단계에서 스펙 모순, 성능 병목, 데이터 손상 위험, 보안 취약점을 발견하면 즉시 `PM`에게 보고하세요.
   - 모든 설계 결정과 변경 내역을 `docs/logs/activity-log.md`에 기록하세요.
'@
Write-Utf8File ".claude\agents\ta-dba.md" $taDbaMd

$developerMd = @'
---
name: developer
description: 20~30년 차 시니어급 개발자(서버/UI, 웹/모바일 등 배정 영역 담당). 승인된 설계를 바탕으로 상세설계서, 프로그램 목록, 테스트 계획서, 슈도코드를 작성하고 담당 영역의 개발소스와 테스트케이스를 구현한다.
model: sonnet
tools: Read, Write, Edit, Glob, Grep, Bash
---

당신은 레거시 현업 기준 20~30년 경력 이상의 시니어 개발자(서버/UI, 웹/모바일 등 지정 영역 담당)입니다.
현실의 시니어 개발자처럼 꼼꼼한 예외 처리, 명확한 책임 분리, 재현 가능한 코드와 테스트를 작성하며, 편법이나 임의 스펙 변경을 하지 않습니다. 시스템 구축 외 대화나 잡담은 금지합니다.

[핵심 역할 및 현실 실무 기준]
1. 설계 산출물 및 구현:
   - 승인된 분석·설계 문서를 바탕으로 `상세설계서.md`, `프로그램목록.md`, `테스트계획서.md`, `슈도코드.md`를 작성하고, 개발 단계에서 배정된 영역(서버/UI, 웹/모바일 등)의 `개발소스`와 `테스트케이스`(문서 및 테스트 코드)를 구현하세요.
2. 영역 준수 및 통제:
   - 배정된 개발 영역 밖의 파일이나 타 역할의 산출물을 임의로 수정하지 마세요.
   - 구현 중 요구사항 불일치, 외부 연동 오류, 회귀 위험, 보안 취약점 등 이슈가 발생하면 스스로 얼버무리지 말고 즉시 `PM`에게 보고하고 승인(또는 중단 해제) 후 진행하세요.
   - 모든 구현·테스트 실행 및 이슈 보고 내역을 `docs/logs/activity-log.md`에 기록하세요.
'@
Write-Utf8File ".claude\agents\developer.md" $developerMd

$testerMd = @'
---
name: tester
description: 20~30년 차 시니어급 테스터. 테스트계획서와 테스트케이스에 따라 정상·경계·예외·회귀 테스트를 수행하고 테스트결과서 및 결함 조치결과서를 객관적 증빙 중심으로 작성한다.
model: haiku
tools: Read, Write, Edit, Glob, Grep, Bash
---

당신은 레거시 현업 기준 20~30년 경력 이상의 시니어 테스터입니다.
현실의 시니어 테스터처럼 단순 정상 동작 확인에 그치지 않고 경계값·예외·오류·회귀 시나리오를 꼼꼼히 검증하며, 사실과 증빙에 기반해 결과를 남깁니다. 시스템 구축 외 대화나 잡담은 금지합니다.

[핵심 역할 및 현실 실무 기준]
1. 테스트 실행 및 결과·조치 기록:
   - 테스트계획서와 테스트케이스에 따라 테스트를 수행하고, `테스트결과서.md`(실행 조건, 기대 결과, 실제 결과, Pass/Fail, 결함 및 **조치결과서**, 회귀 테스트 결과 포함)를 작성하세요.
2. 통제 및 경계 준수:
   - 테스트 편의나 임시 우회를 위해 본체 소스 코드를 임의로 수정하거나 요구사항을 재해석하지 마세요.
   - 결함, 회귀 실패, 보안 의심 사항 발견 시 즉시 `PM`에게 보고하고, 조치 완료 후 재검증 결과를 기록한 뒤 `docs/logs/activity-log.md`에 남기세요.
'@
Write-Utf8File ".claude\agents\tester.md" $testerMd

$qaMd = @'
---
name: qa
description: 20~30년 차 시니어급 품질보증(QA) 전문가. WBS의 각 단계 중간 PM과 공동 점검 게이트를 수행하고, 검증 단계에서 요구사항정의서-개발내용 검증, 테스트케이스/결과서/조치결과서 검증, WBS 일정 관리 및 이슈 관리를 총괄 검증한다.
model: opus
tools: Read, Write, Edit, Glob, Grep
---

당신은 레거시 현업 기준 20~30년 경력 이상의 시니어 품질보증(QA) 전문가입니다.
현실의 시니어 QA처럼 산출물 간 누락·불일치와 미해결 리스크를 놓치지 않고 걸러내며, 형식적인 통과 도장을 찍지 않습니다. 시스템 구축 외 대화나 잡담은 금지합니다.

[핵심 역할 및 현실 실무 기준]
1. PM 공동 중간 점검 게이트:
   - WBS에 정의된 각 단계 중간 점검 게이트에서 `PM`과 함께 산출물 완성도, 역할 경계 준수, 요구사항·설계·구현 정합성, 테스트·보안 리스크, 일정 진행률을 점검하세요.
2. 최종 품질 검증 (`품질검증보고서.md`):
   - 검증 단계에서 `요구사항정의서`와 실제 `개발내용`의 일치 여부, `테스트케이스`·`테스트결과서`·`조치결과서`의 완결성과 타당성, `WBS` 기준 일정 관리 현황, `이슈 관리` 상태를 검증하여 `품질검증보고서.md`를 작성하세요.
3. 통제 및 에스컬레이션:
   - 요구사항 누락, 미조치 결함, 보안 취약점 등 중대 리스크를 발견하면 즉시 `PM`에게 보고하여 진행 보류 또는 전체 중단(STOP) 및 사용자 승인 절차를 밟도록 하세요.
   - 모든 게이트 점검 및 품질 검증 이력을 `docs/logs/activity-log.md`에 기록하세요.
'@
Write-Utf8File ".claude\agents\qa.md" $qaMd

# 5. docs/templates/*.md 8종 생성
$tpl00 = @'
# 방법론 및 산출물 기준서

- **프로젝트명:**
- **작성자(PM):** | **승인자(사용자):** | **승인일:**
- **개발 볼륨 요약:** (기능 수, 화면/API 수, 외부 연동 수, 예상 공수/반복 횟수)

## 1. 적용 방법론 및 출처
- **선정 방법론:** (예: 애자일 스크럼 기반 점진적 개발 / 스펙 주도 개발 등)
- **적용 수준:** [ ] Full 적용  /  [ ] 약식(Tailored) 적용
- **방법론 선택 사유:** (볼륨, 요구사항 명확도, 납기, 기술 리스크 관점 서술)
- **방법론 공식 출처 및 차용 범위:**
  - 출처명/발행처: (예: *The Scrum Guide*, Scrum.org / *ISO/IEC/IEEE 29110* 등 확인된 공식 출처만 기재; 불확실한 출처 임의 기재 금지)
  - 차용 핵심 프랙티스:
  - 생략·경량화 항목 및 사유(약식 적용 시):

## 2. 확정 AI 에이전트 팀 구성 및 역할·겸업 매트릭스
| 역할 구분 | 담당 에이전트 | 수행 형태(단독/겸업) | 책임 범위 및 생성 산출물 |
| :--- | :--- | :--- | :--- |
| 총괄 오퍼레이터 | PM | 단독 | 방법론/일정/게이트/이슈/중단 통제 |
| 요구사항·기본설계 | AA | 단독 / 겸업(__) | 요구사항정의서, 기본설계서, 볼륨 산정 |
| 웹/모바일 UI기획 | UI기획자 | 단독 / 겸업(__) | UI/UX 기획서, 화면 흐름 |
| 기술·데이터 설계 | TA / DBA | 단독 / 겸업(__) | 시스템/DB 상세설계 기준 |
| 개발(서버/UI 등) | Developer | 분리(__) / 겸업(__) | 상세설계, 슈도코드, 개발소스, 테스트케이스 |
| 테스트 | Tester | 단독 / 겸업(__) | 테스트 수행, 테스트결과서·조치결과서 |
| 품질 검증 | QA | 단독 / 겸업(__) | 단계별 중간 게이트(PM 공동), 품질검증보고서 |

## 3. 확정 산출물 목록 및 적용 템플릿
| 단계 | 산출물명 | 저장 경로 | 적용 템플릿 | 필수/통합 여부 |
| :--- | :--- | :--- | :--- | :--- |
| 분석 | 요구사항정의서 | `docs/01-analysis/요구사항정의서.md` | `01_요구사항정의서_템플릿.md` | 필수 |
| 분석 | WBS 및 시스템구성도 | `docs/01-analysis/WBS_및_시스템구성도.md` | `02_WBS_및_시스템구성도_템플릿.md` | 필수 |
| 분석 | 기본설계서(UI기획 포함) | `docs/01-analysis/기본설계서.md` | `03_기본설계서_및_UI기획서_템플릿.md` | 필수 |
| 설계 | 상세설계·프로그램목록·슈도코드 | `docs/02-design/...` | `04_상세설계_프로그램목록_슈도코드_템플릿.md` | 필수/통합 |
| 개발/테스트 | 테스트계획·케이스·결과서 | `docs/02-design/`, `docs/04-test/` | `05_테스트계획_케이스_결과서_템플릿.md` | 필수 |
| 검증 | 품질검증보고서 | `docs/05-qa/품질검증보고서.md` | `06_품질검증보고서_템플릿.md` | 필수 |
| 상시 | 활동 로그 | `docs/logs/activity-log.md` | `07_활동로그_activity-log_템플릿.md` | 필수 |
'@
Write-Utf8File "docs\templates\00_방법론_및_산출물_기준서_템플릿.md" $tpl00

$tpl01 = @'
# 요구사항정의서

## 1. 프로젝트 개요 및 목적
- **배경 및 목표:**
- **대상 사용자 및 운영 환경(웹/모바일/서버):**
- **범위 내(In-Scope) / 범위 외(Out-of-Scope):**

## 2. 사용자 질의 및 피드백 반영 이력
| 질의 ID | 질의 내용(AA/UI기획자) | 사용자 답변·피드백 | 반영 요구사항 ID |
| :--- | :--- | :--- | :--- |
| Q-001 | | | |

## 3. 기능 요구사항 목록
| REQ-ID | 분류 | 요구사항명 | 상세 설명 및 예외 조건 | 수용 기준(Acceptance Criteria) | 우선순위 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| REQ-001 | | | | | 상/중/하 |

## 4. 비기능 요구사항 (성능 · 보안 · 데이터 · 운영)
| NFR-ID | 영역 | 요구 기준 | 검증 방법 |
| :--- | :--- | :--- | :--- |
| NFR-001 | 보안/권한 | | |
'@
Write-Utf8File "docs\templates\01_요구사항정의서_템플릿.md" $tpl01

$tpl02 = @'
# WBS 및 시스템 구성도

## 1. 전체 시스템 및 연계 구성도
- (텍스트 다이어그램 / Mermaid / 컴포넌트 및 데이터 흐름 요약)

## 2. 단계별 WBS (PM+QA 중간 점검 게이트 필수 포함)
| WBS ID | 단계 | 작업명 | 담당 역할 | 선행 작업 | 산출물 | 게이트/승인 여부 | 상태 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1.1 | 분석 | 요구사항 분석 및 사용자 피드백 | AA | - | 요구사항정의서 | 사용자 확인 | |
| 1.2 | 분석 | **[중간 게이트 1] 분석 단계 중간 점검** | **PM + QA** | 1.1 | 점검 로그 | **필수 게이트** | |
| 1.3 | 분석 | 기본설계·UI기획 및 볼륨/방법론 확정 | AA/UI기획자/PM | 1.2 | 기본설계서, 기준서 | **사용자 착수 승인** | |
| 2.1 | 설계 | 상세설계·프로그램목록·슈도코드 작성 | TA/DBA/Developer | 1.3 | 상세설계서 등 | | |
| 2.2 | 설계 | **[중간 게이트 2] 설계 단계 중간 점검** | **PM + QA** | 2.1 | 점검 로그 | **필수 게이트** | |
| 3.1 | 개발 | 개발소스 및 테스트케이스 구현 | Developer | 2.2 | 소스코드, TC | | |
| 3.2 | 개발 | **[중간 게이트 3] 개발 단계 중간 점검** | **PM + QA** | 3.1 | 점검 로그 | **필수 게이트** | |
| 4.1 | 테스트 | 테스트 수행 및 결함 조치 | Tester / Developer | 3.2 | 테스트결과서 | | |
| 4.2 | 테스트 | **[중간 게이트 4] 테스트 단계 중간 점검** | **PM + QA** | 4.1 | 점검 로그 | **필수 게이트** | |
| 5.1 | 검증 | 최종 품질 검증 및 릴리스 준비 확인 | QA / PM | 4.2 | 품질검증보고서 | **최종 완료 보고** | |
'@
Write-Utf8File "docs\templates\02_WBS_및_시스템구성도_템플릿.md" $tpl02

$tpl03 = @'
# 기본설계서 (및 웹/모바일 UI·UX 기획서)

## 1. 아키텍처 및 핵심 도메인 흐름 (AA)
- **기술 스택 및 선정 근거(ADR):**
- **주요 업무/데이터 처리 흐름:**
- **권한·보안 기본 설계 및 장애/예외 처리 방침:**
- **개발 볼륨 산정 결과:** (화면 수, API 수, 테이블 수, 핵심 난이도)

## 2. 웹/모바일 UI·UX 기획 (UI기획자 — 분리 또는 겸업 작성)
- **정보 구조(IA) 및 사용자 여정(User Flow):**
- **화면 목록 및 상태 정의(정상 / 로딩 / 빈 화면 / 오류 / 권한 없음):**
| 화면 ID | 화면명 | 플랫폼(웹/모바일) | 주요 기능 및 인터랙션 | 연결 API/REQ-ID |
| :--- | :--- | :--- | :--- | :--- |
| SCR-001 | | | | |
'@
Write-Utf8File "docs\templates\03_기본설계서_및_UI기획서_템플릿.md" $tpl03

$tpl04 = @'
# 상세설계서 · 프로그램 목록 · 슈도코드

## 1. 데이터 모델 및 스키마 상세 (DBA/TA)
- **테이블/컬렉션 명세, 키/인덱스, 무결성 제약조건:**

## 2. API 및 모듈 상세 명세 (TA/Developer)
| API/모듈 ID | 메서드/경로 | 입력 파라미터 | 출력/오류 코드 | 보안/권한 검증 | 관련 REQ-ID |
| :--- | :--- | :--- | :--- | :--- | :--- |
| API-001 | | | | | |

## 3. 프로그램 목록
| PGM-ID | 구분(서버/UI/배치 등) | 파일 경로 | 기능 요약 | 담당자 | 상태 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| PGM-001 | | | | | |

## 4. 핵심 로직 슈도코드 (Pseudocode)
- (트랜잭션 경계, 상태 전이, 예외 분기 중심 의사코드 작성)
'@
Write-Utf8File "docs\templates\04_상세설계_프로그램목록_슈도코드_템플릿.md" $tpl04

$tpl05 = @'
# 테스트 계획서 · 테스트케이스 · 테스트결과서(조치결과 포함)

## 1. 테스트 계획 (테스트 전략 및 합격 기준)
- **테스트 범위(단위 / 통합 / E2E / 회귀 / 보안):**
- **테스트 환경 및 데이터 준비 기준:**
- **단계 종료 합격 기준(Exit Criteria):**

## 2. 테스트케이스 및 실행 결과
| TC-ID | 관련 REQ-ID | 테스트 시나리오(정상/경계/예외) | 사전 조건 | 기대 결과 | 실제 결과 | 판정(Pass/Fail) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| TC-001 | | | | | | |

## 3. 결함 및 조치결과서
| DEF-ID | 관련 TC-ID | 심각도(치명/상/중/하) | 결함 내용 | 조치 내용 및 수정 파일 | 재테스트 결과 | 상태 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| DEF-001 | | | | | | |
'@
Write-Utf8File "docs\templates\05_테스트계획_케이스_결과서_템플릿.md" $tpl05

$tpl06 = @'
# 품질검증보고서 (QA)

## 1. 요구사항 정의서 대비 개발 내용 검증 (추적성 매트릭스)
| REQ-ID | 요구사항명 | 구현 모듈/화면 | 검증 TC-ID | 구현 일치 여부 | 비고 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| REQ-001 | | | | 일치/미흡 | |

## 2. 테스트케이스 · 테스트결과서 · 조치결과서 검증
- **전체 TC 수 / 실행 수 / 통과율:**
- **미해결 결함 및 보안 이슈 잔존 여부:** (잔존 시 릴리스 불가 및 PM 즉시 보고)

## 3. WBS 일정 관리 및 중간 게이트 이행 검증
- **단계별 PM+QA 중간 점검 게이트 이행 결과 요약:**
- **일정 준수 현황 및 지연/변경 승인 내역:**

## 4. 이슈 관리 대장 요약 및 최종 품질 판정
| ISSUE-ID | 유형(일반/보안·심각) | 발생 단계 | 중단(STOP) 여부 | 사용자 승인 일시 | 처리 상태 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| ISS-001 | | | | | |

- **최종 QA 판정:** [ ] 승인(완료 가능)  /  [ ] 조건부 보완  /  [ ] 반려(재작업)
'@
Write-Utf8File "docs\templates\06_품질검증보고서_템플릿.md" $tpl06

$tpl07 = @'
# 멀티에이전트 개발팀 활동 로그 (Activity Log)

> 시스템 구축과 관련된 모든 에이전트 호출, 사용자 질의/피드백, 방법론·산출물 확정, PM+QA 중간 게이트 점검, 이슈 통보/승인, 심각한 이슈 중단(STOP) 및 재개 내역을 시간순으로 기록합니다.

| 시각(Timestamp) | 단계 | 주체(에이전트/사용자) | 활동 유형(지시/질의/산출물/게이트/이슈/중단·재개) | 요약 내용 및 근거 산출물 경로 | 승인/상태 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| YYYY-MM-DD HH:MM | 착수 | 사용자 → PM | 요구사항 접수 | 초기 요구사항 전달 | 접수 완료 |
'@
Write-Utf8File "docs\templates\07_활동로그_activity-log_템플릿.md" $tpl07

# 6. scripts/init-team.sh 및 scripts/init-team.ps1 생성
$initSh = @'
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "사용법: $0 <대상_프로젝트_저장소_경로> [프로젝트명]"
  exit 1
fi

TEAM_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$(cd "$1" && pwd)"
PROJECT_NAME="${2:-$(basename "$TARGET_DIR")}"
NOW_TS="$(date '+%Y-%m-%d %H:%M')"

cp "$TEAM_REPO_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
mkdir -p "$TARGET_DIR/.claude/agents"
cp -R "$TEAM_REPO_DIR/.claude/agents/." "$TARGET_DIR/.claude/agents/"

mkdir -p "$TARGET_DIR/docs/templates"
cp -R "$TEAM_REPO_DIR/docs/templates/." "$TARGET_DIR/docs/templates/"

for dir in \
  "docs/01-analysis" \
  "docs/02-design" \
  "docs/03-dev" \
  "docs/04-test" \
  "docs/05-qa" \
  "docs/logs"
do
  mkdir -p "$TARGET_DIR/$dir"
  touch "$TARGET_DIR/$dir/.gitkeep"
done

ACTIVITY_LOG="$TARGET_DIR/docs/logs/activity-log.md"
if [ -f "$TEAM_REPO_DIR/docs/templates/07_활동로그_activity-log_템플릿.md" ]; then
  cp "$TEAM_REPO_DIR/docs/templates/07_활동로그_activity-log_템플릿.md" "$ACTIVITY_LOG"
  printf "\n| %s | 초기화 | 시스템(init-team.sh) | 저장소 초기화 | [%s] 팀 규약·에이전트·템플릿 복사 및 폴더 구조 생성 완료 | 완료 |\n" \
    "$NOW_TS" "$PROJECT_NAME" >> "$ACTIVITY_LOG"
fi

echo "초기화 완료: $TARGET_DIR"
'@
Write-Utf8File "scripts\init-team.sh" $initSh

$initPs1 = @'
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
'@
Write-Utf8File "scripts\init-team.ps1" $initPs1

# 7. 단계별 폴더 .gitkeep 및 초기 docs/logs/activity-log.md 생성
@("docs\01-analysis", "docs\02-design", "docs\03-dev", "docs\04-test", "docs\05-qa", "docs\logs") | ForEach-Object {
  Write-Utf8File "$_\.gitkeep" ""
}

$nowStr = Get-Date -Format "yyyy-MM-dd HH:mm"
$initLog = $tpl07 + "`n| $nowStr | 초기화 | 시스템(PowerShell) | 저장소 초기화 | ai-project-team-role 마스터 규약·에이전트·템플릿 구조 생성 | 완료 |"
Write-Utf8File "docs\logs\activity-log.md" $initLog

# 8. Git 커밋 및 첫 푸시
git add .
git commit -m "chore: initialize ai-project-team-role master rules, agents, templates, and scripts"
git push -u origin main

