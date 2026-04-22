---
name: docs-cherry-pick
description: Intelligently cherry-pick documentation changes to enterprise branches, excluding files that don't exist on each target release
argument-hint: <pr-url|--commit sha> --target <branch> [--dry-run]
allowed-tools: Read, Write, Glob, Grep, Edit, Bash, AskUserQuestion, Agent
disable-model-invocation: true
---

# Cherry-Pick Backport

Backport documentation changes from a PR or commit to enterprise branches. Automatically excludes files not present on target releases and resolves cherry-pick conflicts.

**Required:** source (PR URL or `--commit <sha>`) and `--target <branches>`. If either is missing, ask the user.

## Usage

```bash
# Run the cherry-pick script
bash ${CLAUDE_SKILL_DIR}/scripts/cherry_pick.sh \
  --pr <url> --target <branches> [--dry-run] [--deep] [--no-push] [--ticket <id>]

# Commit mode
bash ${CLAUDE_SKILL_DIR}/scripts/cherry_pick.sh \
  --commit <sha> --target <branches>
```

## Options

| Option | Description |
|--------|-------------|
| `--target <branches>` | Comma-separated target branches (required) |
| `--commit <sha>` | Use a commit SHA instead of PR URL |
| `--dry-run` | Audit only — show what would be included/excluded |
| `--deep` | Deep content comparison for patch applicability |
| `--no-push` | Create branch locally, don't push |
| `--ticket <id>` | JIRA ticket ID (auto-detected from PR title) |

## Workflow

The script handles automation; the agent only intervenes for conflicts (exit code 2).

| Exit code | Action |
|-----------|--------|
| **0** | Success — nothing to do |
| **1** | Fatal error — show stderr to user, stop |
| **2** | Conflicts — resolve using steps below |

For `--dry-run`, display results and stop.

## Conflict Resolution (exit code 2)

State files are in `/tmp/cherry-pick-state/` (`conflicted-files.txt`, `current-target.txt`, `ticket.txt`).

### Step 1: Resolve conflicted files

Read `conflicted-files.txt` and `current-target.txt`. Spawn one Agent per file for parallel resolution:

```
Agent(subagent_type="general-purpose", prompt="
  Resolve cherry-pick conflict in <filepath>. Target: <target-branch>.
  1. Read file, apply resolution rules, remove ALL conflict markers
  2. Verify valid AsciiDoc
  3. Return: FILE, CONFLICTS count, RESOLVED count, DETAILS
")
```

After all agents return, verify no unresolved markers or `// REVIEW:` flags remain before continuing.

### Resolution rules

The guiding principle: apply editorial improvements, but keep target-branch content and paths when they differ substantively.

| Conflict type | Resolution |
|---------------|------------|
| Editorial fix (abstract tag, callout, block delimiter) | Apply the fix to target content |
| Both branches have content, minor differences | Apply editorial fix, keep target wording and feature names |
| Content only on main (new feature, new `include::`) | Keep target version, drop new content |
| UI element names differ across releases | Keep target version (e.g., "Operators" not "Ecosystem Catalog") |
| Xref paths differ / new xref to missing module | Keep target paths; drop xrefs to modules not on target |
| Ambiguous (both sides changed same block substantively) | Keep target, flag with `// REVIEW: <reason>` |

### Step 2: Stage, commit, and push

```bash
grep -rn '<<<<<<\|======\|>>>>>>' <conflicted-files>  # verify clean
git add <resolved-files>
TICKET=$(cat /tmp/cherry-pick-state/ticket.txt)
TARGET=$(cat /tmp/cherry-pick-state/current-target.txt)
git commit -m "${TICKET}: Backport to ${TARGET}

Co-Authored-By: Claude <model> <noreply@anthropic.com>"

bash ${CLAUDE_SKILL_DIR}/scripts/cherry_pick.sh \
  --pr <url> --target <target> --phase push
```

### Step 3: Handle `// REVIEW:` flags

If any flags remain, present both versions to the user via AskUserQuestion and ask which to keep.

## Path differences

The script detects path changes across releases automatically. For modify/delete conflicts caused by path moves: `git rm <old-path>`, apply edits at the target path, keep target xref paths.

## Related

- `docs-tools:docs-branch-audit` — file existence and content comparison
- `docs-tools:git-pr-reader` — PR/MR file listing and diff extraction
