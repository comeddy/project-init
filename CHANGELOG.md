# Changelog

[![English](https://img.shields.io/badge/lang-English-blue.svg)](#english) [![한국어](https://img.shields.io/badge/lang-한국어-red.svg)](#한국어)

---

# English

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Rewrite README.md as bilingual (English/Korean) format with shields.io badges and structured sections

## [2.0.0] - 2026-03-07

### Added

- `/init-project` command with adaptive language and framework detection for existing projects ([afd1311](https://github.com/whchoi98/project-init/commit/afd1311))
- `/sync-docs` command with CLAUDE.md quality scoring on a 0-100 scale (A-F grades)
- `/add-module` command with automatic architecture docs and root CLAUDE.md update
- `project-scaffolder` knowledge skill for project structure patterns and conventions
- `doc-sync-checker` subagent for parallel documentation gap analysis (model: opus)
- 4-layer auto-sync workflow: Plan mode rules, PostToolUse hook, `/sync-docs` command, and Git commit-msg hook
- Plan mode integration for context-aware project generation with pre-filled architecture docs and ADRs ([8b0476c](https://github.com/whchoi98/project-init/commit/8b0476c))
- Claude Code marketplace registration support ([0581c40](https://github.com/whchoi98/project-init/commit/0581c40))
- Existing project detection for Node.js, Python, Go, Rust, and Java/Kotlin
- Confidence-based code review skill with 75+ threshold filtering in generated projects
- 5 reference template files (CLAUDE.md, settings.json, skills, docs, hooks)

### Changed

- Restructure repository as marketplace with plugin in `plugins/project-init/` subdirectory ([7c6a6db](https://github.com/whchoi98/project-init/commit/7c6a6db))

[Unreleased]: https://github.com/whchoi98/project-init/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/whchoi98/project-init/releases/tag/v2.0.0

---

# 한국어

이 프로젝트의 모든 주요 변경 사항은 이 파일에 기록됩니다.
이 문서는 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)를 기반으로 하며,
[Semantic Versioning](https://semver.org/spec/v2.0.0.html)을 따릅니다.

## [Unreleased]

### Changed

- README.md를 이중 언어(영어/한국어) 형식으로 전면 재작성, shields.io 뱃지 및 구조화된 섹션 적용

## [2.0.0] - 2026-03-07

### Added

- 기존 프로젝트의 언어 및 프레임워크를 자동 감지하는 `/init-project` 커맨드 추가 ([afd1311](https://github.com/whchoi98/project-init/commit/afd1311))
- CLAUDE.md 품질을 0-100점(A-F 등급)으로 평가하는 `/sync-docs` 커맨드 추가
- 아키텍처 문서와 루트 CLAUDE.md를 자동 업데이트하는 `/add-module` 커맨드 추가
- 프로젝트 구조 패턴과 컨벤션 지식을 제공하는 `project-scaffolder` 스킬 추가
- 문서 갭 분석을 병렬 실행하는 `doc-sync-checker` 서브에이전트 추가 (model: opus)
- Plan 모드 규칙, PostToolUse 훅, `/sync-docs` 커맨드, Git commit-msg 훅으로 구성된 4단계 자동 동기화 워크플로우 추가
- Plan 모드 연동으로 아키텍처 문서와 ADR이 사전 작성되는 컨텍스트 기반 프로젝트 생성 지원 ([8b0476c](https://github.com/whchoi98/project-init/commit/8b0476c))
- Claude Code 마켓플레이스 등록 지원 ([0581c40](https://github.com/whchoi98/project-init/commit/0581c40))
- Node.js, Python, Go, Rust, Java/Kotlin 기존 프로젝트 감지 지원
- 생성 프로젝트에 75점 이상만 보고하는 confidence 기반 코드 리뷰 스킬 포함
- 5개 참조 템플릿 파일 제공 (CLAUDE.md, settings.json, skills, docs, hooks)

### Changed

- 리포지토리를 마켓플레이스 구조로 변경, 플러그인을 `plugins/project-init/` 하위 디렉토리로 이동 ([7c6a6db](https://github.com/whchoi98/project-init/commit/7c6a6db))

[Unreleased]: https://github.com/whchoi98/project-init/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/whchoi98/project-init/releases/tag/v2.0.0
