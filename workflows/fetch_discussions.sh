#!/bin/bash

# Reusable Fetch Script for pandas-stubs discussions
# Usage: ./fetch_discussions.sh <START_DATE> <OPTIONAL_LIMIT>
# Example: ./fetch_discussions.sh 2026-04-18 50

REPO="pandas-dev/pandas-stubs"
DIR="tmp_learning"
START_DATE=${1:-"2026-04-18"}
LIMIT=${2:-"1000"}

mkdir -p "$DIR"

echo "Fetching PRs merged since $START_DATE..."
PR_NUMS=$(gh pr list -R "$REPO" --state merged --search "merged:>=$START_DATE" --limit "$LIMIT" --json number -q '.[].number')

for PR in $PR_NUMS; do
    echo "Processing PR #$PR..."
    gh pr view "$PR" -R "$REPO" --comments --json number,title,body,comments,reviews > "$DIR/pr_$PR.json"
    
    MD_FILE="$DIR/pr_$PR.md"
    echo "# PR #$PR: $(jq -r '.title' "$DIR/pr_$PR.json")" > "$MD_FILE"
    echo "" >> "$MD_FILE"
    echo "## Description" >> "$MD_FILE"
    jq -r '.body' "$DIR/pr_$PR.json" >> "$MD_FILE"
    echo "" >> "$MD_FILE"
    echo "## Reviews & Comments" >> "$MD_FILE"
    
    # Extract reviews
    jq -r '.reviews[]? | "### Review by \(.author.login)\n\(.body)\n"' "$DIR/pr_$PR.json" >> "$MD_FILE"
    # Extract comments
    jq -r '.comments[]? | "### Comment by \(.author.login)\n\(.body)\n"' "$DIR/pr_$PR.json" >> "$MD_FILE"
    
    rm "$DIR/pr_$PR.json"
done

echo "Fetching closed issues since $START_DATE..."
ISSUE_NUMS=$(gh issue list -R "$REPO" --state closed --search "closed:>=$START_DATE" --limit "$LIMIT" --json number -q '.[].number')

for ISSUE in $ISSUE_NUMS; do
    echo "Processing Issue #$ISSUE..."
    gh issue view "$ISSUE" -R "$REPO" --comments --json number,title,body,comments > "$DIR/issue_$ISSUE.json"
    
    MD_FILE="$DIR/issue_$ISSUE.md"
    echo "# Issue #$ISSUE: $(jq -r '.title' "$DIR/issue_$ISSUE.json")" > "$MD_FILE"
    echo "" >> "$MD_FILE"
    echo "## Description" >> "$MD_FILE"
    jq -r '.body' "$DIR/issue_$ISSUE.json" >> "$MD_FILE"
    echo "" >> "$MD_FILE"
    echo "## Comments" >> "$MD_FILE"
    
    # Extract comments
    jq -r '.comments[]? | "### Comment by \(.author.login)\n\(.body)\n"' "$DIR/issue_$ISSUE.json" >> "$MD_FILE"
    
    rm "$DIR/issue_$ISSUE.json"
done

echo "Done! Data saved to $DIR"
