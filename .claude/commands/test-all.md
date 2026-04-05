---
description: Validate plugin structure and run project health checks
allowed-tools: Read, Bash(find:*), Bash(python3:*), Glob, Grep
---

# Test All

Validate the plugin structure and project health for this Claude Code plugin marketplace.

## Step 1: Validate Plugin Manifest

Check `plugins/project-init/.claude-plugin/plugin.json`:
- Valid JSON
- Required fields present (name, description, version)

Check `.claude-plugin/marketplace.json`:
- Valid JSON
- Plugin references resolve to valid paths

## Step 2: Validate Commands

For each `.md` file in `plugins/project-init/commands/`:
- Has valid frontmatter (if applicable)
- References to template files resolve correctly

## Step 3: Validate Skills

For each skill in `plugins/project-init/skills/`:
- `SKILL.md` exists
- Referenced files in `references/` exist

## Step 4: Validate Hooks

For each `.sh` file in `.claude/hooks/`:
- File is executable
- Bash syntax is valid: `bash -n <file>`

## Step 5: Report

Present:
- Total checks run, passed, failed
- Failed check details with file paths
- Suggest fixes for any failures
