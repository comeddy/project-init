---
description: Build and publish the plugin to the marketplace
allowed-tools: Read, Bash(git tag:*), Bash(git push:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(python3:*), Glob, Grep
---

# Deploy

Build and publish the project-init plugin.

## Step 1: Pre-Deploy Checks

1. Verify working tree is clean: `git status`
2. Verify current branch (warn if not main): `git branch --show-current`
3. Run `/test-all` to validate plugin structure
4. Check if a deployment runbook exists: `ls docs/runbooks/deploy-*.md`

## Step 2: Version Validation

Both version files MUST match. Read and compare:

```bash
python3 -c "
import json
m = json.load(open('.claude-plugin/marketplace.json'))
p = json.load(open('plugins/project-init/.claude-plugin/plugin.json'))
mv = m['metadata']['version']
pv = p['version']
print(f'marketplace.json: {mv}')
print(f'plugin.json: {pv}')
if mv != pv:
    print(f'ERROR: Version mismatch! Fix before deploying.')
    exit(1)
print('Versions match.')
"
```

If versions don't match, update both files to the same version before proceeding.

## Step 3: Changelog Verification

1. Read `CHANGELOG.md`
2. Verify the current version has an entry with today's date
3. If missing, ask the user to update CHANGELOG.md before deploying

## Step 4: Tag and Push

```bash
# Get current version
VERSION=$(python3 -c "import json; print(json.load(open('plugins/project-init/.claude-plugin/plugin.json'))['version'])")

# Check if tag already exists
git tag -l "v$VERSION"

# If tag doesn't exist, create it
git tag -a "v$VERSION" -m "Release v$VERSION"

# Push code and tags
git push origin main
git push origin "v$VERSION"
```

## Step 5: User Update Instructions

After pushing, display:

```
## Release v<VERSION> Published

### For existing users:
claude plugin marketplace update project-init
claude plugin install project-init@project-init
# Restart Claude Code session

### For new users:
git clone https://github.com/whchoi98/project-init.git
claude plugin marketplace add ./project-init
claude plugin install project-init
```

## Step 6: Summary

Display:
- Version deployed
- Git tag created
- Files changed since last tag: `git log $(git describe --tags --abbrev=0 HEAD^)..HEAD --oneline`
- Reminder: Update GitHub Releases page if needed
