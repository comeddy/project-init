# project-init Plugin

## Role
Core plugin providing project structure initialization, documentation quality scoring, and auto-sync workflows. This is the primary plugin in the marketplace.

## Key Files
- `.claude-plugin/plugin.json` - Plugin manifest (name, version, description)
- `commands/init-project.md` - Main initialization command (10K+ lines)
- `commands/sync-docs.md` - Documentation synchronization
- `commands/add-adr.md` - ADR creation
- `commands/add-module.md` - Module scaffolding
- `commands/add-runbook.md` - Runbook creation
- `commands/health-check.md` - Project validation
- `agents/doc-sync-checker.md` - Documentation sync analysis agent
- `skills/project-scaffolder/SKILL.md` - Scaffolding skill definition
- `skills/project-scaffolder/references/` - 8 template files for code generation

## Rules
- All commands must have clear step-by-step instructions
- Reference templates contain code in fenced blocks for extraction
- The init-project command adapts based on detected project type
- Version in plugin.json must be updated for each release
- Bilingual support (Korean/English) in user-facing templates
