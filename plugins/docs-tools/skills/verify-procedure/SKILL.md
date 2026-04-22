---
name: verify-procedure
description: Execute, test, and verify AsciiDoc procedures on a live OpenShift or Kubernetes cluster. Runs every command and validates every YAML block against a real cluster. Use this skill whenever the user asks to verify a procedure, test documentation steps, run through a guided exercise, prove a procedure works, check if steps are correct on a live system, or do a dry run of a doc. Requires an active oc/kubectl connection. For static review without a live system, use docs-tools:technical-reviewer instead.
allowed-tools: Bash, Read, Edit, Glob, Grep
---

# Procedure Verification Skill

You execute documented OpenShift/Kubernetes procedures against a live cluster to prove they work end-to-end. **You** are the parser and judgment layer. The bash script `scripts/verify_proc.sh` is a thin executor — it only runs commands, validates YAML, and saves files.

**This is not a review tool.** For reviewing documentation quality without a live system, use `docs-tools:technical-reviewer`.

## Architecture: what you do vs. what the script does

| You (Claude) | Script (`verify_proc.sh`) |
|---|---|
| Read and parse the `.adoc` file | `init` — create workdir, detect oc/kubectl |
| Resolve `include::` directives by reading included files | `check-connection` — verify cluster login |
| Handle `ifdef::`/`ifndef::` conditionals intelligently | `execute <label> <command>` — run a command |
| Extract source blocks (understand nesting, listing blocks, callouts) | `validate-yaml <label> [file]` — YAML syntax + dry-run |
| Classify each block: execute, validate, save-to-file, skip (example output), skip (placeholders) | `validate-json <label>` — JSON syntax check |
| Strip prompt symbols from commands (`$`, `#`, `[root@host ~]#`) | `save-file <label> <path>` — write content to workdir |
| Detect backslash-continued lines and join them | `cleanup` — delete resources + workdir |
| Identify placeholders that need user substitution | `summary` — print pass/fail totals |
| Number steps hierarchically (1, 1.a, 1.b, 2.a.i) | |
| Flag suspicious patterns and undocumented assumptions | |
| Resolve AsciiDoc attributes (`{product-version}`, etc.) | |

## Profiles

Optional `.profile.md` files in `assets/` configure verification runs with attributes, substitutions, prerequisites, scope, assertions, and cleanup. See `references/profile-format.md` for the full format.

**Discovery order**: explicit `--profile <path>` → auto-discover by matching `procedure` frontmatter → no profile (default behavior). Report the profile in the output header if found; no profile is not an error.

**Loading**: Read the profile and parse its YAML frontmatter and sections (`## Attributes`, `## Substitutions`, `## Prerequisites`, `## Scope`, `## Assertions`, `## Cleanup`). Store parsed data for use in subsequent steps.

## Workflow

### Step 0: Init and connectivity

```bash
export VERIFY_TIMEOUT=300  # if profile defines timeout
bash scripts/verify_proc.sh init
bash scripts/verify_proc.sh check-connection
```

If connection fails: stop and suggest `oc login` (or `docs-tools:technical-reviewer` for offline review), unless profile `mode` is `yaml-only` — then continue without a cluster.

If the profile has prerequisite setup commands, execute them sequentially via `execute "prereq-N" "<command>"`. Stop if any fail.

### Step 1: Parse the AsciiDoc file

Read the `.adoc` file. Resolve `include::` directives (read included files, resolve relative paths). Resolve `ifdef::`/`ifndef::` using profile flags → document header → `_attributes.adoc` (warn if unresolvable). Do NOT silently skip content or mis-number steps.

#### Extract and classify source blocks

Identify `[source,TYPE]` blocks (`terminal`, `bash`, `shell`, `yaml`, `json`) within `----` delimiters. Strip callout annotations (`<1>`, `<2>`). Skip listing blocks without `[source]` (display-only).

| Classification | Criteria | Action |
|---|---|---|
| **execute** | `[source,terminal/bash/shell]` with actual commands | Strip prompts (`$`, `#`, `[root@host ~]#`), join `\`-continued lines, send to `execute` |
| **validate-yaml/json** | `[source,yaml]` or `[source,json]` | Pipe to `validate-yaml` or `validate-json` |
| **save-to-file** | Step says "save/create a file" + filename | Pipe to `save-file` or `validate-yaml` with filename arg |
| **skip-example** | Preceded by "Example/sample/expected output" | Skip, report `[SKIP]` |
| **skip-placeholder** | Contains `<placeholder>`, `${VAR}`, `CHANGEME` without profile substitutions | Skip, report with explanation |

Number steps hierarchically: `.` → 1,2,3 / `..` → 1.a,1.b / `...` → 1.a.i,1.a.ii.

#### Resolve attributes and apply profile overrides

Attribute priority: profile → document header → `_attributes.adoc` → cluster fallback (`oc version` for `{product-version}`).

After classification, apply profile substitutions to resolve placeholders (reclassify `skip-placeholder` → appropriate type if all placeholders are covered). Then apply scope controls (`steps`, `skip`, `mode`) to filter the block list.

### Step 2: Execute the procedure

Process blocks sequentially. Use heredocs for content piping:

```bash
bash scripts/verify_proc.sh execute "1.a" "oc get pods -n openshift-operators"
bash scripts/verify_proc.sh validate-yaml "1.a" ["filename.yaml"] <<'YAML'
...
YAML
bash scripts/verify_proc.sh validate-json "2" <<'JSON'
...
JSON
bash scripts/verify_proc.sh save-file "3.a" "config.conf" <<'CONTENT'
...
CONTENT
```

Skip blocks: just report `[SKIP]` in output.

#### Assertions

After each step, check profile assertions (`contains`, `not-contains`, `regex`, `exit-code`). All must pass — assertion failures override exit code 0. Report as `[ASSERT] <label> N/N passed` or `[FAIL] <label> reason`. Steps without assertions use exit code 0 = pass.

### Step 3: Observations

After all blocks are processed, run:
```bash
bash scripts/verify_proc.sh summary
```

Then add your own observations:
- Steps that reference resources not created by earlier steps
- Missing `wait` or polling between create and verify steps
- Prerequisites that aren't documented
- Namespace assumptions
- Commands that would fail without prior `oc login` or specific permissions

### Step 4: Cleanup

Profile `cleanup` value controls behavior: `auto` (run immediately), `manual` (default — wait for user), `skip` (no cleanup). Run `bash scripts/verify_proc.sh cleanup`. If the profile has a `## Cleanup` section, preserve listed resources and execute additional cleanup commands afterward.

## Assemblies and partial cluster state

For assemblies: verify end-to-end (resolve all `include::` first). For single modules: verify but warn about possible parent assembly dependencies.

When a step fails due to missing prerequisites: report clearly, continue with remaining steps, and list discovered prerequisites in observations.

## What to flag

Missing prerequisites, missing wait/polling between create and verify steps, undocumented permission requirements (`cluster-admin`), unresolvable placeholders, deprecated API versions, and `ifdef` assumptions.

## Output format

Present results as you go:

```
--- Procedure Verification: <filename> ---
Profile: <name> (or "none") | CLI: oc | Mode: execute | Cleanup: auto

[Step 1.a] YAML syntax: PASS | Saved to: /tmp/verify-proc-XXXXXX/file.yaml
[Step 1.b] Executing: oc create -f file.yaml → PASS [ASSERT 1/1]
[Step 2]   [SKIP] placeholder: <your-registry-url>

--- Observations ---
- <judgment calls>

--- Summary ---
Total: 7 | Passed: 7 | Failed: 0 | Assertions: 2/2 passed
```
