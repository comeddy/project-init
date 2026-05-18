#!/bin/bash
# Tests for the 8-layer implementation reference docs feature.
# Validates plugin template, new command file, init-project Step 4.5,
# sync-docs reference block, and doc-sync-checker reference validation.

# --- Reference doc template exists and has all 8 layers ---

TEMPLATE="plugins/project-init/skills/project-scaffolder/references/reference-doc-template.md"

assert_file_exists "reference-doc-template.md exists" "$TEMPLATE"

if [ -f "$TEMPLATE" ]; then
    TEMPLATE_CONTENT=$(cat "$TEMPLATE")
    for layer in infrastructure data api iac frontend ui security agent-llm; do
        assert_contains "Template defines layer: $layer" "$TEMPLATE_CONTENT" "## Layer: $layer"
    done
fi
