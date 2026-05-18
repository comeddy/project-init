# Implementation Reference Docs — Design Spec

- **Date**: 2026-05-18
- **Author**: WooHyung Choi
- **Status**: Approved (pre-implementation)
- **Target version**: project-init plugin 2.1.0
- **Related ADRs (to be authored as part of this spec)**: ADR-005, ADR-006

---

## 1. Problem Statement

The `project-init` plugin generates project structure (CLAUDE.md, docs/, hooks, skills), but it does **not** generate implementation-level reference documents that explain *how* each technical layer of a project is built. As projects grow, this gap forces every new reader (a teammate, a future-self, an LLM agent, a reader of *another* project that adopted this plugin) to reconstruct the same knowledge by reading code.

The intent of this feature is to make every project initialized with `project-init` carry a **layered, consistently structured set of implementation reference guides** that are easy to navigate, easy to keep current, and identifiable across projects.

## 2. Goals

1. Add up to 8 layer-specific reference documents per project: **Infrastructure, Data, API, IaC, Frontend, UI, Security, Agent · LLM**.
2. All reference documents share an identical 5-section structure so that knowing one document means knowing how to navigate any.
3. Only generate the layers that are actually relevant to the project — detected automatically, then confirmed by the user.
4. Keep the navigation index (`docs/reference/INDEX.md`) and the root `CLAUDE.md` cross-references in sync automatically.
5. Allow incremental addition of reference docs after `init` via a new dedicated command.
6. Detect drift via `/sync-docs` — at minimum, verify that code-path references inside reference docs still exist.

## 3. Non-Goals

- **Not** auto-writing prose body content. The plugin generates skeletons; humans fill in.
- **Not** scoring reference docs in `/sync-docs` quality assessment (kept gap-only, like README/CHANGELOG today).
- **Not** modifying community docs (CONTRIBUTING/SECURITY/CoC/ISSUE/PR templates) — explicitly deferred.
- **Not** generating reference docs for already-installed plugin consumers retroactively — only at next `init` or via `/add-reference-doc`.

## 4. Architecture Overview

```
┌──────────────────────┐    Step 4.5 (NEW)     ┌─────────────────────────┐
│   /init-project      │ ───────────────────▶ │ Layer Detection         │
│                      │                      │  + User Confirmation    │
└──────────┬───────────┘                      └────────────┬────────────┘
           │                                               │
           │                              selected layers ▼
           │                              ┌────────────────────────────┐
           │                              │ Generate skeletons         │
           │                              │  docs/reference/{layer}.md │
           │                              │  docs/reference/INDEX.md   │
           │                              │  root CLAUDE.md section    │
           │                              └────────────────────────────┘
           │
           ▼
    ┌─────────────────────────────┐   later   ┌──────────────────────┐
    │   /add-reference-doc <l>    │ ──────▶  │ Same generation path │
    │   (incremental add)         │           └──────────────────────┘
    └─────────────────────────────┘

    ┌─────────────────────────────┐
    │   /sync-docs                │  ───▶ gap-check + Code Pointer validation
    │   (drift detection)         │
    └─────────────────────────────┘
```

The three commands (`/init-project`, `/add-reference-doc`, `/sync-docs`) share a single underlying primitive: **manage `docs/reference/` and its INDEX consistently**. The `doc-sync-checker` agent absorbs the validation logic that `/sync-docs` needs.

## 5. Detailed Design

### 5.1 New step in `/init-project` — Step 4.5: Implementation Reference Detection

Inserted between Step 4 (directory creation) and Step 5 (file generation).

#### 5.1.1 Layer detection signal matrix

| Layer | Detected when ANY of these are present |
|---|---|
| Infrastructure | `Dockerfile`, `docker-compose.yml`, `compose.yaml`, `k8s/`, `helm/` |
| Data | `migrations/`, `prisma/`, `schema.sql`, `*.prisma`, `models/`, `entities/`, `db/` |
| API | `routes/`, `controllers/`, `api/`, `openapi.yaml`, `*.proto`, `swagger.json` |
| IaC | `*.tf`, `cdk.json`, `template.yaml` (SAM), `serverless.yml`, `terragrunt.hcl` |
| Frontend | `package.json` deps with react/vue/svelte/next/nuxt/angular, `index.html`, `vite.config.*` |
| UI | Frontend AND any of {`components/`, `styles/`, `tailwind.config.*`, `*.css`/`*.scss`} |
| Security | `.env.example`, `auth/`, `middleware/`, `permissions/`, `iam/`, `policies/` — **defaults to pre-checked** regardless of detection |
| Agent · LLM | `prompts/`, `package.json` deps with anthropic/openai/langchain/bedrock; same imports in `*.py` |

#### 5.1.2 User confirmation flow

After detection, output the results and ask the user to confirm/adjust:

```
Detected implementation layers:
  ✓ Infrastructure (Dockerfile)
  ✓ API (routes/)
  ✓ Security (.env.example) — auto-recommended
  ─ Data — not detected
  ─ IaC — not detected
  ─ Frontend — not detected
  ─ UI — not detected
  ─ Agent · LLM — not detected

Proceed with detected set, or adjust? (a)ccept / (e)dit
```

If `(e)dit`: present a multi-select prompt (one row per layer, current selection pre-checked). User toggles.

For empty projects (zero detections): present an empty list with Security pre-checked, plus a note: *"More layers can be added later with `/add-reference-doc <layer>`."*

#### 5.1.3 Skeleton generation

For each selected layer `L`:
1. Extract skeleton from `plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md` (section corresponding to `L`).
2. Replace variables:
   - `{{LAYER_TITLE_EN}}` / `{{LAYER_TITLE_KO}}` — fixed per layer
   - `{{COMPONENTS_TABLE}}` — auto-filled rows from detected files (path column populated, "Purpose" left as `<!-- TODO -->`)
   - `{{CODE_POINTERS_AUTO}}` — top 1-3 detected files per layer
3. Write to `docs/reference/{L}.md`. **Skip if file exists** (init-project conflict policy).

After all layer files are generated:
4. Regenerate `docs/reference/INDEX.md` from current directory listing.
5. Update root `CLAUDE.md` `## Implementation References` section between `<!-- AUTO-MANAGED:references -->` markers.

### 5.2 New command: `/add-reference-doc <layer> [<layer>...]`

Manifest fields:
- `description`: "Add an implementation reference doc skeleton for one or more layers"
- `argument-hint`: "Layer name(s): infrastructure, data, api, iac, frontend, ui, security, agent-llm"
- `allowed-tools`: Read, Write, Edit, Bash(`ls`, `find`, `git config`, `grep`), Glob

Behavior:
1. Validate layer name(s) against the 8-layer enum.
2. For each layer:
   - If file exists at `docs/reference/{layer}.md`: prompt the user (`overwrite/skip/abort`) — the `/generate-*` family conflict policy.
   - Otherwise: invoke the same skeleton extraction + variable substitution path as 5.1.3.
3. Regenerate INDEX.md and root CLAUDE.md AUTO-MANAGED region.

### 5.3 Common skeleton structure (all 8 docs)

```markdown
# {{Title}} / {{한글 제목}}

[![English](https://img.shields.io/badge/Language-English-blue)](#english)
[![한국어](https://img.shields.io/badge/Language-한국어-red)](#korean)

<a id="english"></a>
## English

### 1. Overview
<!-- 1-3 sentences on what this layer does and why it exists. -->

### 2. Components
| Component | Path | Purpose |
|---|---|---|
| <!-- auto-populated rows --> |

### 3. Key Decisions
<!-- TODO: list 3-5 decisions or link to docs/decisions/ADR-*.md -->

### 4. Code Pointers
<!-- TODO: 3-7 entries; paths must be valid (checked by /sync-docs) -->
- `path/to/key/file.ext` — short description

### 5. Cross-references
<!-- TODO -->
- Related modules:
- Related ADRs:
- Related runbooks:

<a id="korean"></a>
## 한국어
(동일 5개 섹션의 한국어판; 영문 섹션의 미러 구조)
```

Bilingual policy: **all 8 docs follow ADR-001** — Korean and English mirror sections, English first, identical structure, shields.io badge anchors per ADR-002.

### 5.4 INDEX.md (auto-managed)

```markdown
# Implementation Reference Index / 구현 참조 인덱스

[![English](...)](#english) [![한국어](...)](#korean)

<a id="english"></a>
## English

Layer-by-layer implementation guides. Each file follows the same 5-section structure
(Overview / Components / Key Decisions / Code Pointers / Cross-references).

<!-- AUTO-MANAGED:index -->
| Layer | File | Status |
|---|---|---|
| Infrastructure | [infrastructure.md](infrastructure.md) | present |
| Data | — | not applicable |
| API | [api.md](api.md) | present |
| IaC | — | not applicable |
| Frontend | — | not applicable |
| UI | — | not applicable |
| Security | [security.md](security.md) | present |
| Agent · LLM | — | not applicable |
<!-- /AUTO-MANAGED -->

Last updated: {{LAST_UPDATED}} (managed by /init-project, /add-reference-doc, /sync-docs)

<a id="korean"></a>
## 한국어
(mirror)
```

The table between `<!-- AUTO-MANAGED:index -->` markers is the only region the three commands write. Everything outside is user-owned.

### 5.5 Root `CLAUDE.md` integration

`/init-project` and `/add-reference-doc` upsert this block:

```markdown
## Implementation References
<!-- AUTO-MANAGED:references -->
Layer-by-layer implementation guides in `docs/reference/`. See [INDEX](docs/reference/INDEX.md).
- Infrastructure: [docs/reference/infrastructure.md](docs/reference/infrastructure.md)
- API: [docs/reference/api.md](docs/reference/api.md)
- Security: [docs/reference/security.md](docs/reference/security.md)
<!-- /AUTO-MANAGED -->
```

If the section does not exist, it is appended near the end of CLAUDE.md (after existing `## Conventions` / `## Key Commands` blocks). If it exists, only the marker region is rewritten.

### 5.6 `/sync-docs` extension

Phase 1 (Gap Analysis) gains a new block: **Implementation References**.

For each of the 8 layers, the gap-check runs the same detection signals (5.1.1) and reports:

```
## Implementation References
- ✓ infrastructure.md exists, 4 Code Pointers all valid
- ⚠ api.md exists, 2 Code Pointer(s) point to missing paths:
    - "src/routes/legacy.ts" (renamed or removed)
- ❌ security.md missing — Security layer detected; run /add-reference-doc security
- INDEX.md: out of sync with directory listing — auto-corrected
```

Validation rules:
- **Existence**: detected layer + missing file → ❌
- **Code Pointer validity**: parse each Markdown inline code that looks like a path (`/^[A-Za-z0-9_./-]+\.[A-Za-z0-9]+$/` with at least one `/`) under the `### 4. Code Pointers` section; check filesystem existence
- **TODO marker count**: report only (no grading)
- **INDEX consistency**: regenerate table inside `<!-- AUTO-MANAGED:index -->` from directory listing; report if it differed

No quality grade (A-F) is assigned. Reference docs are gap-tracked, not scored.

### 5.7 `doc-sync-checker` agent extension

The agent's checklist gains:
- Enumerate `docs/reference/*.md`
- For each, parse Code Pointers section and validate paths
- Report INDEX.md / directory list mismatches
- Return findings in the same structured format the agent already uses

### 5.8 Plugin reference template file

New file: `plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md`

Structure (single mega-file, consistent with existing `docs-templates.md` / `readme-template.md` patterns):

```markdown
# Reference Doc Template Library

## Layer: infrastructure
\`\`\`markdown
<full 5-section skeleton with {{variables}}>
\`\`\`

## Layer: data
\`\`\`markdown
<full 5-section skeleton>
\`\`\`

(... 6 more layers ...)
```

Commands extract the fenced block for the requested layer.

## 6. Data & Variables

| Variable | Source | Fallback when source missing |
|---|---|---|
| `{{LAYER_TITLE_EN}}` | constant per layer | — |
| `{{LAYER_TITLE_KO}}` | constant per layer (Korean) | — |
| `{{COMPONENTS_TABLE}}` | detected files per layer | empty table with one TODO row |
| `{{CODE_POINTERS_AUTO}}` | top 1-3 detected files | `<!-- TODO: add code pointers -->` |
| `{{LAST_UPDATED}}` (INDEX) | today's date | — |

## 7. Conflict & Idempotency Policy

| Trigger | If layer file `docs/reference/{layer}.md` exists | Action |
|---|---|---|
| `/init-project` | skip silently, log "(existing, kept)" | preserve user work |
| `/add-reference-doc` | prompt `(o)verwrite / (s)kip / (a)bort` | explicit user intent |
| `/sync-docs` | never writes layer files | gap report only |

INDEX.md and root `CLAUDE.md` AUTO-MANAGED regions are treated differently:
- All three commands (`/init-project`, `/add-reference-doc`, `/sync-docs`) freely rewrite the content **inside** `<!-- AUTO-MANAGED:* -->` markers. Text outside the markers is user-owned and never touched.
- `/sync-docs` does write to INDEX.md's AUTO-MANAGED block when it detects drift; this is the one exception to "sync-docs does not modify files." Layer files themselves are never modified by sync-docs.

## 8. New ADRs

Created as part of this spec's implementation PR:

### ADR-005: Implementation Reference Docs Structure
Records the decision to:
- Split implementation knowledge across 8 layer-specific docs in `docs/reference/`
- Enforce a shared 5-section skeleton
- Use AUTO-MANAGED markers for the INDEX and root CLAUDE.md integration

Alternatives considered: single monolithic doc; extension of `docs/architecture.md`; per-module CLAUDE.md absorption.

### ADR-006: Hybrid Detection + User Confirmation
Records the choice of detection-then-confirm flow over fully-automatic detection, fully-interactive selection, or fixed presets.

Alternatives considered: detection-only (silent miss risk), interactive-only (cognitive load), preset-only (mismatch risk on edge cases).

## 9. Testing

New tests in `tests/`, registered in `tests/run-all.sh`:

| Test | Verifies |
|---|---|
| `test_reference_detection.sh` | Signal matrix returns correct layer set against fixtures |
| `test_reference_skeleton.sh` | Generated `docs/reference/{layer}.md` has 5 sections + bilingual anchors + AUTO-MANAGED markers |
| `test_index_consistency.sh` | INDEX.md table matches `ls docs/reference/*.md` after generation |
| `test_code_pointer_check.sh` | sync-docs flags missing paths and accepts valid paths |
| `test_add_reference_doc.sh` | `/add-reference-doc <layer>` updates INDEX and root CLAUDE.md AUTO-MANAGED regions |

## 10. Affected Files Summary

| File | Status | Lines |
|---|---|---|
| `plugins/project-init/commands/init-project.md` | modified | ~+80 |
| `plugins/project-init/commands/add-reference-doc.md` | **new** | ~100 |
| `plugins/project-init/commands/sync-docs.md` | modified | ~+25 |
| `plugins/project-init/agents/doc-sync-checker.md` | modified | ~+30 |
| `plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md` | **new** | ~400 (8 layers × ~50) |
| `plugins/project-init/CLAUDE.md` | modified | ~+2 |
| `CLAUDE.md` (root) | modified | ~+5 (Auto-Sync Rules update) |
| `docs/decisions/ADR-005-implementation-reference-docs.md` | **new** | ~60 |
| `docs/decisions/ADR-006-hybrid-detection-confirmation.md` | **new** | ~60 |
| `tests/test_reference_detection.sh` | **new** | ~60 |
| `tests/test_reference_skeleton.sh` | **new** | ~60 |
| `tests/test_index_consistency.sh` | **new** | ~60 |
| `tests/test_code_pointer_check.sh` | **new** | ~60 |
| `tests/test_add_reference_doc.sh` | **new** | ~60 |
| `tests/run-all.sh` | modified | ~+5 |
| `plugins/project-init/.claude-plugin/plugin.json` | modified | version bump |
| `.claude-plugin/marketplace.json` | modified | version bump |
| `CHANGELOG.md` | modified | 2.1.0 entry |
| `README.md` | modified | new command documented |

Total: 9 new files, 10 modified files.

## 11. Build Sequence

1. `reference-doc-template.md` — write all 8 layer skeletons with variables.
2. `/add-reference-doc` command — smallest standalone unit; verifiable by running directly.
3. `/init-project` Step 4.5 — reuses `/add-reference-doc` logic for batched layer generation.
4. `/sync-docs` Phase 1 — extend with reference-block gap check and Code Pointer validation.
5. `doc-sync-checker` agent — absorb same validation logic so it can be invoked standalone.
6. ADR-005, ADR-006 — author both as part of the implementation PR.
7. Tests (5 new bash tests) and register in `run-all.sh`.
8. Version bump: 2.0.0 → 2.1.0 in `plugin.json` and `marketplace.json`.
9. `CHANGELOG.md` — 2.1.0 entry; `README.md` — document new command.

After each step: run `bash tests/run-all.sh` to confirm no regressions in the 114 existing tests.

## 12. Open Risks

| Risk | Mitigation |
|---|---|
| Detection false positives generate irrelevant reference docs | User confirmation step (5.1.2) catches before generation |
| AUTO-MANAGED marker corrupted by user edit inside the block | Document the markers in CLAUDE.md and in INDEX.md preamble; commands re-emit cleanly on next call |
| Code Pointer regex over- or under-matches | Tests cover boundary cases (paths with spaces, query fragments, anchor links) |
| 8-layer set proves too narrow over time (e.g., "Observability" missing) | Layer set is enumerated in one place (`reference-doc-template.md`); extension via a follow-up ADR |
| Bilingual Korean skeleton bodies degenerate into stale machine-translation stubs | Skeleton uses TODO markers only (no auto-translated prose); humans fill both languages |

## 13. Out of Scope (Deferred)

- The 5 community docs bundle (CONTRIBUTING / SECURITY / CODE_OF_CONDUCT / ISSUE / PR templates) — separate future spec.
- Auto-generation of prose body content for the 8 layers — possible follow-up if a Bedrock/Claude integration is added to the plugin.
- Quality scoring (A-F) for reference docs — currently gap-only; can revisit if drift becomes a measurable problem.

---

## Approval

- Design approved by user on 2026-05-18 (3 sections reviewed and confirmed).
- Next step: invoke writing-plans skill to produce an implementation plan.
