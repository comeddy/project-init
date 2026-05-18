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

# --- Each layer skeleton contains 5 required sections + bilingual anchors ---

if [ -f "$TEMPLATE" ]; then
    REQUIRED_SECTIONS=("### 1. Overview" "### 2. Components" "### 3. Key Decisions" "### 4. Code Pointers" "### 5. Cross-references")
    KOREAN_SECTIONS=("### 1. 개요" "### 2. 구성요소" "### 3. 주요 결정" "### 4. 코드 포인터" "### 5. 상호 참조")
    for section in "${REQUIRED_SECTIONS[@]}"; do
        COUNT=$(grep -c "^$section\$" "$TEMPLATE" || echo 0)
        if [ "$COUNT" -ge 8 ]; then
            pass "Template: section '$section' appears in all 8 layers"
        else
            fail "Template: section '$section'" "found $COUNT occurrences, expected ≥8"
        fi
    done
    for section in "${KOREAN_SECTIONS[@]}"; do
        COUNT=$(grep -c "^$section\$" "$TEMPLATE" || echo 0)
        if [ "$COUNT" -ge 8 ]; then
            pass "Template: Korean section '$section' appears in all 8 layers"
        else
            fail "Template: Korean section '$section'" "found $COUNT occurrences, expected ≥8"
        fi
    done

    # Bilingual anchors per layer
    ANCHOR_EN=$(grep -c '<a id="english"></a>' "$TEMPLATE" || echo 0)
    ANCHOR_KO=$(grep -c '<a id="korean"></a>' "$TEMPLATE" || echo 0)
    if [ "$ANCHOR_EN" -ge 8 ]; then pass "Template: 8 English anchors"; else fail "Template: English anchors" "got $ANCHOR_EN, expected ≥8"; fi
    if [ "$ANCHOR_KO" -ge 8 ]; then pass "Template: 8 Korean anchors"; else fail "Template: Korean anchors" "got $ANCHOR_KO, expected ≥8"; fi

    # Variables present somewhere in the file
    for var in '{{COMPONENTS_TABLE}}' '{{CODE_POINTERS_AUTO}}'; do
        if grep -qF "$var" "$TEMPLATE"; then
            pass "Template: variable $var present"
        else
            fail "Template: variable $var" "not found"
        fi
    done
fi
