---
description: Build and publish the plugin to the marketplace
allowed-tools: Read, Bash(git tag:*), Bash(git push:*), Bash(claude plugin:*), Glob
---

# Deploy

Build and publish the project-init plugin.

## Step 1: Pre-Deploy Checks

1. Verify working tree is clean: `git status`
2. Verify current branch (warn if not main)
3. Run `/test-all` to validate plugin structure
4. Check if a deployment runbook exists: `ls docs/runbooks/deploy-*.md`

## Step 2: Follow Runbook

If a deployment runbook exists in `docs/runbooks/`, follow its steps.

If no runbook exists:
1. Verify version in `plugins/project-init/.claude-plugin/plugin.json`
2. Verify version in `.claude-plugin/marketplace.json`
3. Ensure CHANGELOG.md is updated
4. Create git tag if not already tagged

## Step 3: Publish

- Push changes: `git push origin main`
- Push tags: `git push --tags`
- Instruct user to run: `claude plugin marketplace update project-init`

## Step 4: Summary

Display:
- What was published and version
- Git tag created
- Next steps for users to update
