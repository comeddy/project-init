# project-init

Claude Code plugin for initializing and maintaining project structures with adaptive project detection, CLAUDE.md quality scoring, and auto-sync documentation workflows.

## What is project-init?

`project-init`은 Claude Code 프로젝트의 **구조 생성**과 **문서 유지보수**를 자동화하는 플러그인입니다.

### 해결하는 문제

Claude Code는 `CLAUDE.md` 파일을 통해 프로젝트 컨텍스트를 이해합니다. 하지만 실제 개발에서는:

1. **프로젝트 시작 시** - 어떤 구조로 CLAUDE.md, docs, hooks, skills를 구성해야 할지 알기 어렵습니다
2. **코드가 변경될 때** - CLAUDE.md와 아키텍처 문서가 코드와 점점 괴리됩니다
3. **새 모듈을 추가할 때** - 모듈 CLAUDE.md를 빠뜨리거나 architecture.md 업데이트를 잊습니다
4. **문서 품질 관리** - CLAUDE.md가 얼마나 유용한지 객관적으로 평가할 기준이 없습니다

이 플러그인은 4가지 문제를 각각 `/init-project`, `/sync-docs`, `/add-module`, 품질 점수 시스템으로 해결합니다.

### 핵심 특징

**기존 프로젝트 적응** - `/init-project`는 빈 프로젝트에만 쓰는 것이 아닙니다. `package.json`, `pyproject.toml`, `go.mod` 등을 감지하여 이미 존재하는 프로젝트의 구조를 유지하면서 Claude Code 설정만 추가합니다. Next.js 앱이라면 `app/routes/CLAUDE.md`를, Go 프로젝트라면 `cmd/CLAUDE.md`를 생성합니다.

**CLAUDE.md 품질 점수** - 6가지 기준(명령어, 아키텍처 명확성, 비자명한 패턴, 간결성, 최신성, 실행 가능성)으로 0-100점 척도 평가. `/sync-docs` 실행 시 Before/After 점수를 비교하여 문서 품질 개선을 정량화합니다.

**4단계 자동 동기화** - 생성된 프로젝트에는 Plan 모드 연동 규칙, PostToolUse Hook, /sync-docs 스킬, Git commit-msg 훅이 설치되어 코드 변경 시 문서가 자동으로 따라갑니다.

**confidence 기반 코드 리뷰** - 생성되는 code-review 스킬은 0-100 점수로 이슈를 평가하고, 75점 이상만 리포트하여 거짓 양성을 필터링합니다.

### 동작 방식 요약

```
[프로젝트 시작]
     |
     v
/init-project ./my-app
     |
     ├─ 기존 프로젝트? ──> 언어/프레임워크 감지 -> 기존 구조 유지하며 Claude Code 설정 추가
     |
     └─ 새 프로젝트? ───> 사용자에게 질문 -> 전체 구조 + 내용 채워서 생성
     |
     v
[개발 진행]
     |
     ├─ 파일 수정 (Write/Edit) -> Hook이 CLAUDE.md 누락 감지 -> Claude에 피드백
     ├─ Plan 모드 종료 -> Auto-Sync Rules가 docs 자동 업데이트 지시
     ├─ 새 모듈 필요 -> /add-module src/auth -> 디렉토리 + CLAUDE.md + architecture.md 업데이트
     └─ 주기적으로 -> /sync-docs -> 전체 문서 감사 + 품질 점수 + ADR 제안
     |
     v
[Git 커밋]
     |
     v
commit-msg 훅 -> Co-Authored-By 자동 제거
```

### 플러그인 구성 요소

이 플러그인은 Claude Code의 4가지 확장 메커니즘을 모두 활용합니다:

| 유형 | 이름 | 호출 방식 | 역할 |
|------|------|----------|------|
| **Command** | `/init-project` | 사용자가 슬래시 명령으로 호출 | 프로젝트 구조 생성 (기존 프로젝트 적응) |
| **Command** | `/sync-docs` | 사용자가 슬래시 명령으로 호출 | 전체 문서 동기화 + 품질 점수 |
| **Command** | `/add-module` | 사용자가 슬래시 명령으로 호출 | 모듈 추가 + 관련 문서 일괄 업데이트 |
| **Skill** | `project-scaffolder` | Claude가 대화 중 자동 참조 | 프로젝트 구조 패턴/컨벤션 지식 |
| **Agent** | `doc-sync-checker` | Claude가 서브에이전트로 병렬 실행 | 문서 갭 분석 + 품질 평가 (model: opus) |
| **References** | 5개 템플릿 파일 | Command 실행 시 Read 도구로 참조 | CLAUDE.md, settings.json, skills, docs, hooks 템플릿 |

### 실행 환경

- Claude Code CLI 세션 내에서 슬래시 명령으로 실행
- 터미널에서 단독 실행 불가 (Claude가 AI로 파일을 생성하는 방식)
- 설치 후 Claude Code 재시작 필요

---

## Features

### Commands (User-Invocable)

| Command | Description |
|---------|-------------|
| `/init-project` | Initialize a Claude Code project structure. Detects existing projects and adapts. |
| `/sync-docs` | Synchronize all documentation with current code state. Includes quality scoring. |
| `/add-module` | Add a new module directory with CLAUDE.md and update architecture docs. |

### Skills (Model-Invocable)

| Skill | Description |
|-------|-------------|
| `project-scaffolder` | Knowledge skill for Claude Code project structure patterns, quality criteria, and existing project adaptation |

### Agents

| Agent | Description |
|-------|-------------|
| `doc-sync-checker` | Check documentation sync status, find gaps, and score CLAUDE.md quality (model: opus) |

## Created Project Structure

Running `/init-project` on a **new project** creates:

```
project/
├── CLAUDE.md                          # Project memory + Auto-Sync Rules
├── README.md
├── .gitignore
├── docs/
│   ├── architecture.md                # Architecture document
│   ├── decisions/.template.md         # ADR template
│   └── runbooks/.template.md          # Runbook template
├── .claude/
│   ├── settings.json                  # Claude settings + Hook config
│   ├── hooks/
│   │   └── check-doc-sync.sh         # Documentation sync detection hook
│   └── skills/
│       ├── code-review/SKILL.md       # Confidence-based code review
│       ├── refactor/SKILL.md          # Safe refactoring with verification
│       ├── release/SKILL.md           # Semver release automation
│       └── sync-docs/SKILL.md         # Documentation sync with quality scoring
├── tools/
│   ├── scripts/
│   └── prompts/
└── src/
    ├── api/CLAUDE.md                  # API module context
    └── persistence/CLAUDE.md          # Persistence module context
```

Running `/init-project` on an **existing project** adapts to the detected structure:

```
existing-nextjs-app/              # Detected: Next.js 14 / App Router
├── CLAUDE.md                     # Auto-filled Tech Stack, Commands from package.json
├── .claude/
│   ├── settings.json
│   ├── hooks/
│   │   └── check-doc-sync.sh    # Adapted to watch app/ instead of src/
│   └── skills/...
├── docs/...
├── tools/...
├── app/                          # Existing directories preserved
│   ├── routes/CLAUDE.md          # Module CLAUDE.md for each existing dir
│   ├── services/CLAUDE.md
│   └── models/CLAUDE.md
├── tests/CLAUDE.md
└── package.json                  # Existing files NOT overwritten
```

### Existing Project Detection

| File Found | Project Type | Source Dirs | Auto-filled Commands |
|-----------|-------------|-------------|---------------------|
| `package.json` | Node.js | src/, app/, lib/, components/ | npm/yarn/pnpm scripts |
| `pyproject.toml` | Python | src/, app/, lib/ | pip, pytest, ruff |
| `go.mod` | Go | cmd/, pkg/, internal/ | go build, go test |
| `Cargo.toml` | Rust | src/ | cargo build, cargo test |
| `pom.xml` / `build.gradle` | Java/Kotlin | src/main/, src/test/ | mvn, gradle |
| None | New project | src/api/, src/persistence/ | (ask user) |

## Auto-Sync Mechanisms

| Mechanism | Trigger | Action |
|-----------|---------|--------|
| CLAUDE.md Auto-Sync Rules | After Plan mode exit | Claude auto-updates architecture.md, ADRs, module CLAUDE.md |
| Hook (check-doc-sync.sh) | After Write/Edit | Detects missing CLAUDE.md in source modules, alerts on missing ADRs |
| Skill (/sync-docs) | User invocation | Full documentation sync with quality scoring |
| Git Hook (commit-msg) | On git commit | Auto-removes Co-Authored-By lines |

## CLAUDE.md Quality Scoring

`/sync-docs` and `doc-sync-checker` evaluate each CLAUDE.md file on a 100-point scale:

| Criterion | Max Score | What to check |
|-----------|-----------|---------------|
| Commands/workflows | 20 | Build/test/deploy commands present and copy-paste ready? |
| Architecture clarity | 20 | Codebase structure understandable from this file alone? |
| Non-obvious patterns | 15 | Gotchas, quirks, and conventions documented? |
| Conciseness | 15 | No verbose explanations or obvious info? |
| Currency | 15 | Reflects current codebase state? |
| Actionability | 15 | Instructions are executable, not vague? |

**Grades:** A (90-100), B (70-89), C (50-69), D (30-49), F (0-29)

Example output:

```
### Quality Scores (Before -> After)

| File | Before | After | Change |
|------|--------|-------|--------|
| ./CLAUDE.md | B (82) | B (87) | +5 |
| ./src/api/CLAUDE.md | C (62) | C (69) | +7 |
| ./src/auth/CLAUDE.md | F (28) | C (58) | +30 |
| Average | 56 | 72 | +16 |
```

## Plugin Structure

```
project-init/
├── .claude-plugin/plugin.json          # Manifest (v2.0.0)
├── commands/
│   ├── init-project.md                 # /init-project (adaptive project init)
│   ├── sync-docs.md                    # /sync-docs (quality scoring + sync)
│   └── add-module.md                   # /add-module (module + docs creation)
├── skills/
│   └── project-scaffolder/
│       ├── SKILL.md                    # Auto-referenced knowledge skill
│       └── references/                 # 5 template reference files
└── agents/
    └── doc-sync-checker.md             # Doc gap analysis subagent (model: opus)
```

---

## Detailed Operation

### `/init-project [path]`

Generates a Claude Code project structure in 11 steps. Adapts to existing projects.

**Allowed tools**: `Read, Write, Edit, Bash(mkdir, chmod, git init, git add, git commit, ls, find, cat), Glob, Grep`

```
/init-project ./my-app
     |
     v
Step 1:  Determine target directory
         - Use argument path, or current directory if empty
         - Warn and confirm before overwriting existing files
     |
     v
Step 2:  Detect existing project
         - Scan for package.json, pyproject.toml, go.mod, etc.
         - Identify actual source directories (src/, app/, lib/, cmd/)
         - Detect framework (Next.js, FastAPI, Gin, etc.)
         - If new project: ask user for name, description, tech stack
     |
     v
Step 3:  Create directory structure
         - Always: docs/, .claude/, tools/
         - New project only: src/api/, src/persistence/
         - Existing project: preserve current layout
     |
     v
Step 4:  Generate CLAUDE.md
         - Existing: auto-fill from dependency files and build system
         - New: fill from user responses
         - Always include Auto-Sync Rules
     |
     v
Step 5:  Generate .claude/settings.json + Hook
         - Adapt hook path to actual source directory
     |
     v
Step 6:  Generate Skills (4 SKILL.md files)
         - code-review (confidence scoring, 75+ filter)
         - refactor (test verification, risk assessment)
         - release (semver, changelog automation)
         - sync-docs (quality scoring, A-F grades)
     |
     v
Step 7:  Generate Docs templates
         - architecture.md (pre-fill for existing projects)
         - ADR template, Runbook template
     |
     v
Step 8:  Generate module CLAUDE.md files
         - Existing: create for each detected source directory
         - New: src/api/CLAUDE.md, src/persistence/CLAUDE.md
     |
     v
Step 9:  Generate supporting files (skip existing)
         - README.md, .gitignore (language-appropriate), .gitkeep
     |
     v
Step 10: Initialize Git (optional, skip if .git/ exists)
         - git init -> commit-msg hook -> initial commit
     |
     v
Step 11: Summary output
         - Created structure tree
         - What was adapted vs created fresh
         - 4 auto-sync mechanisms explained
```

---

### `/sync-docs`

Synchronizes all documentation with quality scoring in 7 phases.

**Allowed tools**: `Read, Write, Edit, Glob, Grep, Bash(find, git log, ls, tree), Agent`

```
/sync-docs
     |
     v
Phase 0: Gap analysis (doc-sync-checker subagent)
         - Parallel subagent scans for missing/stale docs
         - Returns quality scores for each CLAUDE.md
         - Identifies undocumented architectural decisions
     |
     v
Phase 1: CLAUDE.md quality assessment
         - Score each file (0-100) across 6 criteria
         - Output quality report with grades (A-F)
     |
     v
Phase 2: Root CLAUDE.md sync
         - Update Overview, Tech Stack, Project Structure,
           Conventions, Key Commands to match actual state
         - Verify commands are copy-paste ready
     |
     v
Phase 3: Architecture doc sync
         - Update docs/architecture.md
         - Reflect Components, Data Flow, Infrastructure changes
     |
     v
Phase 4: Module CLAUDE.md audit
         - Auto-detect source directory (src/, app/, lib/, etc.)
         - Missing CLAUDE.md -> create new
         - Existing CLAUDE.md -> compare with code and update
         - Score each module CLAUDE.md
     |
     v
Phase 5: ADR audit
         - Detect architecture changes in recent commits
         - Auto-create ADRs for confirmed decisions
         - Suggest ADRs for potential decisions
     |
     v
Phase 6: README.md sync
         - Match project structure section to actual directories
     |
     v
Phase 7: Report
         - Before/after quality scores for each file
         - Files created, files updated
         - ADRs created and suggested
         - Remaining gaps
```

---

### `/add-module <path>`

Creates a new module with documentation in 7 steps.

**Allowed tools**: `Read, Write, Edit, Bash(mkdir, ls, find), Glob, Grep`

```
/add-module src/auth
     |
     v
Step 1: Validate module path
     |
     v
Step 2: Ask module responsibility and dependencies
     |
     v
Step 3: Create directory + CLAUDE.md
     |
     v
Step 4: Update docs/architecture.md (add component)
     |
     v
Step 5: Update root CLAUDE.md (project structure)
     |
     v
Step 6: Verify hook coverage for new path
     |
     v
Step 7: Summary + suggest ADR if significant
```

---

### `project-scaffolder` (Skill)

```yaml
user-invocable: false   # Cannot be called with /
tools: Read, Glob       # Read-only
```

Background knowledge that Claude **automatically references** during conversations. Not directly callable by users.

**Auto-triggers when user**:
- Asks about project structure or organization
- Wants to add new modules
- Needs guidance on file placement

**Provides knowledge about**:
- Standard project structure pattern
- CLAUDE.md hierarchy (root vs module)
- CLAUDE.md quality criteria (6 dimensions, 100-point scale)
- Existing project adaptation rules
- 4 auto-sync mechanisms
- When to create module CLAUDE.md and ADRs
- Paths to 5 reference template files

---

### `doc-sync-checker` (Agent)

```yaml
model: opus
color: cyan
tools: Read, Glob, Grep, Bash(find, git log, ls, cat)
```

A **parallel subagent** that Claude spawns to analyze documentation gaps. Runs in a separate context window so it doesn't consume the main session's context.

**6 checks performed**:

| Check | Method | Example output |
|-------|--------|----------------|
| Detect source directories | `ls -d src/ app/ lib/ cmd/` | Adapts to actual project layout |
| Missing module CLAUDE.md | `find <source_dir> -type d` then check | `src/newmodule/ - no CLAUDE.md found` |
| Stale architecture.md | Compare component list vs actual dirs | `mentions "oldservice" which no longer exists` |
| Missing ADRs | `git log -20` detect architecture changes | `Commit abc1234 added Redis - no ADR found` |
| Stale CLAUDE.md | Tech Stack vs actual dependency files | `lists "express" but package.json shows "fastify"` |
| Quality scoring | Score each CLAUDE.md (0-100, 6 criteria) | `./src/api/CLAUDE.md: 45/100 (D)` |

**Output format**:

```
## Documentation Sync Report

### Quality Scores
| File | Score | Grade | Key Issues |
|------|-------|-------|------------|
| ./CLAUDE.md | 72/100 | B | Commands outdated |
| ./src/api/CLAUDE.md | 45/100 | D | Missing endpoints list |
| ./src/auth/CLAUDE.md | -- | F | FILE MISSING |

### Missing Module CLAUDE.md
### Stale Documents
### Suggested ADRs
### Summary (X missing, Y stale, Z undocumented, avg score: XX/100)
```

---

### Reference Files

Located in `skills/project-scaffolder/references/`. Claude reads these via the `Read` tool when generating files.

| File | Content | Used by |
|------|---------|---------|
| `claude-md-template.md` | Root CLAUDE.md + module CLAUDE.md + Auto-Sync Rules | `/init-project` Step 4, 8 |
| `settings-json-template.md` | .claude/settings.json + PostToolUse Hook config | `/init-project` Step 5 |
| `skills-templates.md` | code-review, refactor, release, sync-docs SKILL.md (enhanced) | `/init-project` Step 6 |
| `docs-templates.md` | architecture.md, ADR template, Runbook template | `/init-project` Step 7 |
| `hook-scripts.md` | check-doc-sync.sh + git commit-msg hook scripts | `/init-project` Step 5, 10 |

---

## Auto-Sync Workflow in Generated Projects

After `/init-project`, the generated project has 4 interconnected sync mechanisms:

```
/plan for planning
     |
     v
Plan exit
     |
     v
+----------------------------------+
| (1) CLAUDE.md Auto-Sync Rules   |  <- Rules embedded in
|     (in root CLAUDE.md)          |     root CLAUDE.md
|                                  |     instruct Claude
| - Update architecture.md        |     automatically
| - Create ADRs                   |
| - Create module CLAUDE.md       |
+----------------------------------+
     |
     v
Code writing (Write/Edit)
     |
     v
+----------------------------------+
| (2) PostToolUse Hook             |  <- Registered in
|     (check-doc-sync.sh)          |     settings.json
|                                  |
| - Missing CLAUDE.md in source?   |
| - No ADRs at all?               |
| -> Feedback to Claude            |
+----------------------------------+
     |
     v
+----------------------------------+
| (3) /sync-docs (manual)         |  <- User invokes
|                                  |     when needed
| - Quality scoring (A-F grades)   |
| - Full doc audit & update        |
| - Auto-create & suggest ADRs     |
| - Before/after score report      |
+----------------------------------+
     |
     v
git commit
     |
     v
+----------------------------------+
| (4) Git commit-msg Hook         |  <- Installed in
|                                  |     .git/hooks/
| - Auto-remove Co-Authored-By    |
+----------------------------------+
```

| Mechanism | Trigger | Auto/Manual | Location |
|-----------|---------|-------------|----------|
| Auto-Sync Rules | Plan mode exit | Auto (Claude reads rules) | `CLAUDE.md` |
| PostToolUse Hook | After Write/Edit | Auto (shell script) | `.claude/settings.json` -> `.claude/hooks/` |
| /sync-docs | User invocation | Manual | Plugin command or project skill |
| commit-msg Hook | git commit | Auto (Git hook) | `.git/hooks/commit-msg` |

---

## v2.0.0 Test Results

### Test 1: `/init-project` - New Project

| Item | Result |
|------|--------|
| Directory structure (11 dirs) | PASS |
| CLAUDE.md content (Tech Stack, Commands, Code Style) | PASS |
| Enhanced Skills 4 (confidence scoring, test verification) | PASS |
| Hook + settings.json | PASS |
| Git init + commit-msg hook | PASS |

### Test 2: `/init-project` - Existing Project Detection

| Item | Result |
|------|--------|
| Next.js / package.json detection | PASS |
| `src/api`, `src/persistence` NOT created | PASS |
| Module CLAUDE.md for `app/routes`, `app/services`, `app/models` | PASS |
| Hook adapted to `app/` path | PASS |
| Existing files NOT overwritten | PASS |

### Test 3: `/add-module` - Module Addition

| Item | Result |
|------|--------|
| `src/auth/` directory created | PASS |
| `src/auth/CLAUDE.md` (role, dependencies) | PASS |
| `docs/architecture.md` updated with auth component | PASS |

### Test 4: `/sync-docs` - Documentation Sync + Quality Scoring

| Item | Result |
|------|--------|
| doc-sync-checker subagent execution | PASS |
| Quality scores (Before -> After): avg 56 -> 72 | PASS |
| 5 files updated, 2 ADRs auto-created | PASS |
| 3 additional ADR suggestions | PASS |
| Remaining gaps report | PASS |

---

## Installation

```bash
# Run the setup script (registers marketplace + installs plugin)
bash claude_code_setup/06-setup-custom-plugin.sh
```

Or manually:

```bash
# 1. Register local marketplace
claude plugin marketplace add /path/to/custom-claude-plugins

# 2. Install plugin
claude plugin install project-init@custom-claude-plugins
```

## Usage

```bash
# Initialize a new project
/init-project ./my-new-project

# Initialize Claude Code structure in an existing project
/init-project ./existing-app

# Sync docs with quality scoring
/sync-docs

# Add a new module
/add-module src/auth
```
