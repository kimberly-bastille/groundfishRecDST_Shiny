# REFACTOR_04c — Validation Harness: Pair B (catch_at_length_calibration / _projection)

**Phase:** 4, step 3 of 3 (the Phase 3 equivalent for Pair B)
**Date:** 2026-09-09
**Branch:** `refactor_calib`
**Inputs:** `REFACTOR_04b §9`; user decision that a raw-byte CSV match is a PASS
criterion on its own.
**Nothing was executed.** Stata is not installed on this machine. The harness was
verified by static review and scripted structure checks only (§5).

---

## 1. What was produced

| File | Change | Lines |
|---|---|---|
| `Code/pre_sim/model_wrapper.do` | **modified**: 95 lines inserted, 9 changed (`git diff --numstat HEAD`) | 523 → 609 |
| `Code/refactor_validation/refval_tools.do` | **modified**: 61 inserted, 23 changed | 365 → 403 |
| `REFACTOR_04c_harness_pairB.md` | this report | |

SHA-256 at the end of this session:

```
a23e8b354a0da0913e3c6cdd47df0f11d2549d2fea99878922e3f8a6658aa95f  Code/pre_sim/model_wrapper.do
c3f40fbcb7aad701b9f8166f22aa6a044a36f15a17135b645a3b68bc93878a50  Code/refactor_validation/refval_tools.do
```

The four original target files and all four `_refactored` files plus the shared helper
are unchanged from their recorded checksums (`REFACTOR_00 §1`, `REFACTOR_02 §1`,
`REFACTOR_04b §1`). Git: `HEAD` (`5e9f866`) already contains the Phase 3 wrapper and
tools file, so `git diff HEAD` shows exactly this step's changes and
`git checkout HEAD -- <file>` reverts either one.

### 1.1 Where the Pair B harness sits in `model_wrapper.do`

| Block | Lines | What it does |
|---|---|---|
| `(config)` | `:208–237` | now also defines `validate_catch_at_length_cal` and `validate_catch_at_length_proj` (both 0), and loads `refval_tools.do` if any of the four `validate_*` toggles is on |
| `(catch_at_length_calibration)` | `:475–517` | immediately before step 9 (`if `generate_baseline'` is now at `:519`) |
| `(catch_at_length_projection)` | `:542–580` | immediately before step 10 (`if `catch_at_length_project'` is now at `:582`) |

The two Pair A blocks (`:330–368`, `:386–434`) are untouched. All five blocks are wrapped in
`* === BEGIN/END REFACTOR VALIDATION HARNESS (…) ===` markers; retirement is: delete the
five marked blocks and `Code/refactor_validation/`.

### 1.2 Changes to `refval_tools.do`

| Where | Change |
|---|---|
| `refval_load` | new `.csv` branch: `import delimited using "<file>", clear` (no options, as `catch_at_length_projection.do` itself reads these files) |
| `refval_compare` | two optional options `newlabel()` / `oldlabel()` for the report header; when omitted they default to the Pair A names, so the Pair A blocks behave as before |
| `refval_compare` | new per-file columns `is_csv` and `bytes_ok` (= present on both sides, same file length, same `checksum`); for `.csv` rows **status is set from `bytes_ok` alone**, PASS or FAIL. `.dta`/`.xlsx` rows keep the Phase 3 rule. Both columns are shown in the per-file table and saved in the results dataset |
| header comments | describe the CSV rule and the five blocks |
| three `display` strings | a `;` inside the quoted text replaced by a comma — see §5, item 3 |

---

## 2. Harness design

### 2.1 Run order inside each block

Identical to Pair A (`REFACTOR_03 §2.1`): stamp → save RNG state → `do` the
`_refactored` file → `refval_capture side(new)` → restore RNG state → `do` the original →
`refval_capture side(old)` → `refval_compare` → set the step's own toggle to 0.

The original runs last, so production paths hold original output. This matters more for
Pair B than the blocks' size suggests, because three later steps read cal's CSVs:
`rdb_catch_at_length.do` (toggle `prep_catch_at_length_for_dash`), the R gdrive push, and
step 10 itself. With both Pair B blocks on, **proj's refactored run reads the original
cal's output**, which isolates proj's refactor from cal's.

### 2.2 What is compared, and how

| Block | Files | Copied aside | PASS rule |
|---|---|---|---|
| cal | `baseline_catch_at_length_observed.csv`, `baseline_catch_at_length.csv` | both | raw bytes identical (length + checksum) |
| proj | `projected_catch_at_length.csv` | yes | raw bytes identical |

A CSV written by `export delimited` carries no metadata, so byte equality is the
strongest possible statement that old and new produced the same deliverable, and it is
what the R side reads. The imported-data checks (`N`, `k`, schema, row-indexed
`datasignature`) and `cf _all` on the copies still run and are printed, so on a FAIL the
report names the differing variable and counts mismatches; they do not affect the
verdict for `.csv` rows. If the bytes match, those diagnostics cannot disagree.

### 2.3 RNG and working directory

Both catch_at_length scripts `set seed $seed` first, so the save/restore of
`c(rngstate)` is redundant here. It is kept so all four Section E blocks read the same
way. Neither run is followed by `cd $here`: cal changes directory to `$misc_data_cd`
and never restores it (`REFACTOR_00 R6`); a harness-free run would be left there too,
and every harness path is absolute (`$refval_cd`, `$misc_data_cd`, `$input_code_cd`).

### 2.4 Prerequisite checks

cal block: `confirm file` on `simulated_catch_totals_for_catch_length.dta` (step 6 output).
proj block: `confirm file` on both baseline CSVs. Each stops with `file … not found` before
anything runs.

### 2.5 Decisions made in this session without asking

1. **CSV byte match is also *necessary*, not just sufficient.** You said a byte match is a
   PASS criterion on its own; I also made a byte *mismatch* a FAIL even if the imported
   data compare equal. Rationale: the CSV is the deliverable, and `export delimited` from
   the same Stata on the same data is deterministic, so a byte difference means the data
   differ in some digit. Reversible by one line in `refval_compare` if you prefer
   "either test passing is enough".
2. **`newlabel()`/`oldlabel()` default to the Pair A names** rather than editing the two
   committed Pair A blocks. Zero change to Pair A behaviour.
3. **No `cd $here` after the runs** (§2.3).
4. **Wrapper blocks remain carriage-return delimited**, matching Phase 3 decision 1.

---

## 3. What the user needs to run

### 3.1 Before running: git checkpoint

`HEAD` already holds Phases 0–3. Recommended now (I make no commits, constraint 6):

```
git add Code/pre_sim/catch_at_length_programs.do \
        Code/pre_sim/catch_at_length_calibration_refactored.do \
        Code/pre_sim/catch_at_length_projection_refactored.do \
        Code/pre_sim/model_wrapper.do Code/refactor_validation/refval_tools.do \
        REFACTOR_04*.md
git commit -m "Phase 4: Pair B refactor and validation harness (not yet validated)"
```

### 3.2 Prerequisites

As for a normal run of steps 9–10: `simulated_catch_totals_for_catch_length.dta` from step
6, the MRIP trip and size files, `MRIP_COD_ALL_SITE_LIST.csv`, the NEFSC trawl CSVs and
the four NAA `.dta` files. Working directory at the project root before
`do model_wrapper.do`. Disk: a second copy of three CSVs, negligible.

### 3.3 Round 1 — `$ndraws = 3`

| Local in Section D | Set to |
|---|---|
| `proto` | `1` (as committed → `$ndraws = 3`) |
| `validate_catch_at_length_cal` | `1` |
| `validate_catch_at_length_proj` | `1` |
| `compare_calibration_MRIP` (step 6) | `1` if `simulated_catch_totals_for_catch_length.dta` is not already on disk for this `$ndraws`; otherwise as committed |
| `generate_baseline`, `catch_at_length_project` | leave as they are; the harness overrides them |
| Pair A `validate_*` toggles | `0` unless you want to validate Pair A in the same run (they are independent) |

Then, from the project root in Stata:

```
do "Code/pre_sim/model_wrapper.do"
```

Sequence: … step 6 → cal new → cal old → compare → dashboard prep/push as toggled →
proj new (reads old cal output) → proj old → compare → step 11 as toggled.

### 3.4 Round 2 — `$ndraws = 101`

Same with `proto = 0`. This is the run whose exact match justifies retirement of Pair B
(`REFACTOR_00 O-3`). The gamma loop runs once per species × season × draw, so each script
runs roughly 34× longer than at 3 draws, twice.

### 3.5 Reading the result

Reports land in `Code/refactor_validation/` as `refval_report_cal_<ts>.log` and
`refval_report_proj_<ts>.log`; copies as `baseline_catch_at_length_observed_{old,new}.csv`,
`baseline_catch_at_length_{old,new}.csv`, `projected_catch_at_length_{old,new}.csv`.

**PASS looks like** (per-file table with `status = PASS`, `is_csv = 1`, `bytes_ok = 1` on
every row, then):

```
files compared : 2   with cf: 2   failed: 0
===== cal OVERALL: PASS (exact match on every file) =====
```

and for proj `files compared : 1   with cf: 1   failed: 0`.

**FAIL looks like** a row with `status = FAIL` and `bytes_ok = 0`, followed by

```
===== cal OVERALL: FAIL (1 file(s) differ, see rows above) =====
```

Then read the diagnostics above the table: `cf`'s per-variable mismatch lines say which
column differs and in how many rows; `N_old`/`N_new` differing means a row-count change;
`sig_ok = 0` with `N_ok = 1` and `cf` clean means the rows are permuted. For a
line-by-line look, the `_old`/`_new` copies are plain text and can be diffed with any tool.

**Report back:** the `OVERALL` lines for cal and proj and, on a FAIL, the report file(s).

---

## 4. What the harness does and does not guarantee (constraint 3)

**Detected exactly:** any byte-level difference in the three CSVs, hence any difference in
values, digits, row count, row order, column count, column order or header names.

**Not compared:** anything the scripts leave in memory or in the Stata session (the `cd`
side effect, defined programs, matrices). Nothing downstream reads those. The `.dta`
tempfiles are intermediate and not compared.

**Assumptions:** same Stata build and machine for old and new (they run in one session);
the `REFACTOR_04b §4.2` assumptions on the refactor itself.

---

## 5. Static verification performed

Scripted (Python, session scratchpad, not committed):

1. **Wrapper.** All five `BEGIN`/`END` marker pairs found with matching labels; brace
   depth returns to 0 in each block and across the file (38/38); no `;`-terminated lines
   in the cr-delimited blocks; the `do` targets are the two originals and the two
   `_refactored` files; `git diff --numstat HEAD` = 95 insertions, 9 deletions (the
   config block's comment and `if` line).
2. **`refval_tools.do`.** In the `#delimit ;` region after stripping comments: no
   `*`-comment lines, no `//`, every `{`/`}` followed by `;`, braces 28/28,
   `program define`/`end`/`capture program drop` 6/6/6.
3. **Semicolons inside quoted strings.** New check, added after `REFACTOR_04b` found the
   same problem in the refactored scripts. Under `#delimit ;` a `;` inside a string
   ends the command. `refval_tools.do` had **two such strings from Phase 3** (the report
   header's `old = … (ran last; …)` line and the `OVERALL: FAIL (… differ; see rows
   above)` line) plus one I had just added; all three now use a comma. **This was a
   latent bug in the committed Pair A harness**: `refval_compare` would have stopped with
   a syntax error at its header line on the very first run, before comparing anything.
   No output would have been lost (both runs and both captures complete before
   `refval_compare` is called), but the Pair A validation could not have produced a
   report until this fix. The two Pair A `_refactored` files were scanned as well and are
   clean. `REFACTOR_03 §3.5`'s "FAIL looks like" example still shows the old text with a
   semicolon; the actual line now reads `… differ, see rows above`.
4. **Baseline integrity.** All nine pre-existing tracked/new files re-checksummed.

---

## 6. Most likely first-run problems and where to look

1. **`refval_tools.do` parse error** on load (the config block `do`s it when any
   `validate_*` is 1). First `else if` in this file; standard Stata, but untested here.
   Nothing has run yet at that point.
2. **`syntax` in `refval_compare` rejecting `newlabel()`** — the value contains dots and
   underscores, which `string` accepts. Would surface after both runs and captures; the
   copies and fingerprints are already on disk, so `refval_compare` can be re-run by hand
   with the same `part()` and `ts()`.
3. **`import delimited` of a `_new`/`_old` copy** differing from the pipeline's own read —
   it should not; the file name does not affect `import delimited`.
4. A **`_refactored` script parse/`syntax` error** (`REFACTOR_04b §7`) — surfaces inside
   the new run, before any output is written; the original then never runs in that
   wrapper invocation because the error aborts the do-file. Fix and rerun.

---

## 7. Out-of-scope duplication observed

None new.

---

## 8. What's needed before the next phase

Phase 4 is complete for Pair B (analysis, implementation, harness). Next is **Phase 5**,
the consolidated handoff checklist for both pairs, which can be written now without
further input: it is §3 of `REFACTOR_03` and §3 of this report combined, with the
two-round `$ndraws` rule and the Phase 3 semicolon fix noted. After that, everything
waits on the user's production runs. Retirement (Phase 6) needs one decision not yet
taken: archive vs delete for the four original files.
