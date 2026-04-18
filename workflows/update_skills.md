# Workflow: Updating Typing Skills from pandas-stubs

This workflow describes how to iteratively update the typing skills knowledge base by fetching recent PRs and issues from `pandas-dev/pandas-stubs` and using an LLM agent to extract lessons.

## Prerequisites
- `gh` CLI authenticated (`gh auth login`)
- `jq` installed
- Access to an LLM agent with file-reading and editing capabilities.

## Step 1: Fetch Discussions
Run the provided shell script to download and format merged PRs and closed issues into markdown files.

```bash
cd workflows
chmod +x fetch_discussions.sh
./fetch_discussions.sh 2026-04-18 # Fetch everything merged/closed after this date
```

This will create a `tmp_learning/` directory populated with markdown files.

## Step 2: Batch Processing with LLM
Due to token limits, do not feed all files to the LLM at once. Process them in batches of 30-50 files.

Use the following prompt format for your LLM or sub-agent:

> **Prompt:**
> Process the first 50 files in `workflows/tmp_learning/` (e.g., using `ls workflows/tmp_learning | head -n 50` to identify them).
> Extract all new pandas typing lessons, rules, best practices, recurring debates, and advanced typing workarounds.
> Update the markdown files in `skills/` (e.g., `pandas_dataframe_typing.md`, `pandas_series_typing.md`, `pandas_stubs_pr_lessons.md`, etc.) accordingly.
> Provide a summary of the most important new findings.

Repeat this process for subsequent batches:
> **Prompt:**
> Process the next 50 files in `workflows/tmp_learning/` (files 51 to 100).
> ...

## Step 3: Consolidation and Cleanup
Once all batches are processed:
1. Review the updated files in `skills/` for consistency and deduplication.
2. Delete the temporary directory: `rm -rf workflows/tmp_learning/`
3. Commit and push the updated skills.
