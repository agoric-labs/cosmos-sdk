#!/bin/bash

# Script to compare git tags and their merges
# Usage: ./compare-tags.sh <current_tag> <upstream_tag> <agoric_branch>

set -euo pipefail

# Check if we have the right number of arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <current_tag> <upstream_tag> <agoric_branch>"
    echo "Example: $0 v0.34.30 v0.37.15 agoric-updates"
    exit 1
fi

CURRENT_TAG=$1
UPSTREAM_TAG=$2
AGORIC_BRANCH=$3
TEMP_BRANCH="temp-merge-comparison"
WORKSPACE="tag-comparison-workspace"

# Create a workspace directory
mkdir -p "$WORKSPACE"

# Function to check if a tag exists
check_tag() {
    if ! git rev-parse "$1" >/dev/null 2>&1; then
        echo "Error: Tag or branch '$1' does not exist"
        exit 1
    fi
}

# Function to cleanup
cleanup() {
    echo "Cleaning up..."
    git checkout - >/dev/null 2>&1 || true
    git branch -D "$TEMP_BRANCH" >/dev/null 2>&1 || true
}

# Set up error handling
trap cleanup EXIT

# Verify tags exist
echo "Verifying tags and branch..."
check_tag "$CURRENT_TAG"
check_tag "$UPSTREAM_TAG"
check_tag "$AGORIC_BRANCH"

echo "Starting comparison process..."

# Step 1: Check merge result
echo "Step 1: Checking merge result..."
git checkout -b "$TEMP_BRANCH" "$CURRENT_TAG"
git merge "$UPSTREAM_TAG" -m "Test merge of $UPSTREAM_TAG into $CURRENT_TAG"
git diff HEAD "$UPSTREAM_TAG" > "$WORKSPACE/merge_diff.patch"

if [ -s "$WORKSPACE/merge_diff.patch" ]; then
    echo "Warning: Merge result differs from upstream tag"
else
    echo "Merge result matches upstream tag"
fi

# Step 2: Create diff between current tag and Agoric branch
echo "Step 2: Creating diff between $CURRENT_TAG and $AGORIC_BRANCH..."
git diff "$CURRENT_TAG" "$AGORIC_BRANCH" > "$WORKSPACE/agoric_changes.patch"

# Step 3: Create diff between upstream tag and final merge
echo "Step 3: Creating diff between $UPSTREAM_TAG and merged Agoric..."
git diff "$UPSTREAM_TAG" HEAD > "$WORKSPACE/final_changes.patch"

# Step 4: Compare the diffs
echo "Step 4: Comparing diffs..."
diff "$WORKSPACE/agoric_changes.patch" "$WORKSPACE/final_changes.patch" > "$WORKSPACE/diff_comparison.txt" || true

# Generate summary
echo "
Summary:
--------
1. Merge diff size: $(wc -l < "$WORKSPACE/merge_diff.patch") lines
2. Agoric changes: $(wc -l < "$WORKSPACE/agoric_changes.patch") lines
3. Final changes: $(wc -l < "$WORKSPACE/final_changes.patch") lines
4. Diff comparison: $(wc -l < "$WORKSPACE/diff_comparison.txt") lines

All files have been saved in the '$WORKSPACE' directory:
- merge_diff.patch: Differences between merge result and upstream
- agoric_changes.patch: Original Agoric modifications
- final_changes.patch: Final state differences
- diff_comparison.txt: Comparison between the two sets of changes
"

if [ -s "$WORKSPACE/diff_comparison.txt" ]; then
    echo "Warning: Differences found between original Agoric changes and final state"
else
    echo "Success: No differences found between original Agoric changes and final state"
fi