# REFACTOR_05 — Handoff for Production Validation (Pairs A and B)

**Phase:** 5
**Date:** 2026-09-09
**Branch:** `refactor_calib`
**Purpose:** one checklist covering everything you need to run, and what to send back.
Nothing here has been executed by Claude Code (constraint 2). Details and rationale are
in `REFACTOR_03_harness_pairA.md` and `REFACTOR_04c_harness_pairB.md`; this file is the
short version.

---

## 0. Before you start

**0.1 Git checkpoint.** `HEAD` (`5e9f866`) holds Phases 0–3. Phase 4 is uncommitted:

```
git add Code/pre_sim/catch_at_length_programs.do \
        Code/pre_sim/catch_at_length_calibration_refactored.do \
        Code/pre_sim/catch_at_length_projection_refactored.do \
        Code/pre_sim/model_wrapper.do Code/refactor_validation/refval_tools.do \
        REFACTOR_04_duplication_pairB.md REFACTOR_04b_implementation_pairB.md \
        REFACTOR_04c_harness_pairB.md REFACTOR_05_handoff.md
git commit -m "Phase 4-5: Pair B refactor, harness, handoff (not yet validated)"
```

**0.2 Confirm nothing drifted.** From `Code/pre_sim/`:

```
sha256sum catch_at_length_calibration.do catch_at_length_projection.do \
          calibration_catch_per_trip_part1.do calibration_catch_per_trip_part2.do
```

Expected (`REFACTOR_00 §1`):

```
3f98785143de06c5a4c13abd6a811facfd68b5874d0ea2472541d8bf88c2e73a  calibration_catch_per_trip_part1.do
02ccfdc8eb7542ce18af14aaacf307c9f0130096718e91d4a64e4af7bff2f7d1  calibration_catch_per_trip_part2.do
f135e37b7cd1332803e5a8fef1c53a6b239171e34229f0c88e2c4bd6230f0e34  catch_at_length_calibration.do
90c03aec399b158474288410b594ec611d82793ba6d40077791ccecc8d331577  catch_at_length_projection.do
```

If any differs, stop: the originals are the ground truth and must not have changed.

**0.3 Environment.** Stata 14+; user commands `here`, `dsconcat`, `renvarlab`, `distinct`;
the usual input data on disk under `$gfdatadir`; working directory at the project root.
Disk: Pair A copies every `calib_catch_draws_<i>.dta` aside, so at 101 draws budget a
second copy of `calib_catch_draws/`. Pair B adds three small CSVs.

**0.4 Do not edit** the four original `.do` files, the four `_refactored` files, or
`catch_at_length_programs.do` during validation. If a run fails with a parse error in a
new file, report it (§4) rather than patching it in place, so the fix is recorded.

---

## 1. What to set

All toggles are in `Code/pre_sim/model_wrapper.do`, Section D. Line numbers as of this
commit.

### Round 1 — prototype, `$ndraws = 3`

| Line | Local | Set to | Why |
|---|---|---|---|
| 202 | `proto` | `1` (committed) | forces `$ndraws = 3` at line 205 |
| 224 | `validate_catch_per_trip1` | `1` | Pair A part1 |
| 225 | `validate_catch_per_trip2` | `1` | Pair A part2 |
| 226 | `validate_catch_at_length_cal` | `1` | Pair B calibration |
| 227 | `validate_catch_at_length_proj` | `1` | Pair B projection |
| 187 | `copula_in_R` | `1` (committed) | part2 needs `calib_catch_draws_raw_1..3.dta` at this `$ndraws` |
| 189 | `compare_calibration_MRIP` | `1` (committed) | cal needs `simulated_catch_totals_for_catch_length.dta` at this `$ndraws` |
| 186, 188, 193, 196 | `catch_per_trip1`, `catch_per_trip2`, `generate_baseline`, `catch_at_length_project` | leave as they are | each `validate_*` block runs the original itself and then switches the step toggle off |
| 228, 230 | `refval_copy_draws`, `refval_cf_verbose` | leave | defaults: copy every draw, terse `cf` |

Everything else as committed. Then, in Stata from the project root:

```
do "Code/pre_sim/model_wrapper.do"
```

Execution order you will see: part1 new → part1 old → compare → R copula (on old part1
output) → part2 new → part2 old → compare → step 6 → cal new → cal old → compare →
dashboard steps as toggled → proj new (on old cal output) → proj old → compare → step 11.

The four blocks are independent. To run one pair only, set only its two `validate_*`
toggles; for Pair B alone, `compare_calibration_MRIP` must still produce
`simulated_catch_totals_for_catch_length.dta` at the current `$ndraws` (or it must already
be on disk). For part2 alone, `calib_catch_draws_raw_1..$ndraws.dta` must already exist.
Each block checks its prerequisite with `confirm file` and stops with `file … not found`
before touching anything.

### Round 2 — production, `$ndraws = 101`

Same as Round 1 with **line 202 `proto = 0`**. Run only after Round 1 passes on every
block. Each of the four steps runs twice, so expect roughly double the normal time for
steps 5a, 5c, 9 and 10, plus a few minutes to fingerprint 202 part2 files.

**Round 2 is the run that justifies retirement.** A Round 1 PASS alone is not sufficient
(`REFACTOR_00 O-3`): loop-count-dependent behaviour and sparse-domain gamma fits may not
surface at 3 draws.

---

## 2. Where the results land

All under `Code/refactor_validation/` (git-ignored except the tooling and `.log` reports):

| File | Contents |
|---|---|
| `refval_report_<part>_<ts>.log` | **the report**, one per block; `<part>` is `part1`, `part2`, `cal`, `proj` |
| `refval_results_<part>_<ts>.dta` | one row per compared file with every check's result |
| `<stem>_old.<ext>`, `<stem>_new.<ext>` | copies of the outputs, for inspection after a FAIL; overwritten each run |
| `Code/pre_sim/logs/model_wrapper_log_<date>.smcl` | the wrapper's own log, includes both full runs of every step |

The console also prints one summary line per block:
`REFVAL <part>: PASS -- report: <path>` (green) or `REFVAL <part>: FAIL -- see <path>` (red).

---

## 3. What PASS and FAIL look like

**PASS**: every row in the per-file table has `status = PASS`, and the last lines are

```
files compared : 5   with cf: 5   failed: 0
===== part1 OVERALL: PASS (exact match on every file) =====
```

Expected `files compared` per block: part1 **5**; part2 **1 + $ndraws** (4 at Round 1,
102 at Round 2); cal **2**; proj **1**. For `cal` and `proj` every row should also show
`is_csv = 1` and `bytes_ok = 1`.

**FAIL**: at least one row has `status = FAIL`, and the last summary line is

```
===== <part> OVERALL: FAIL (<n> file(s) differ, see rows above) =====
```

Read upward from there:

- `bytes_ok = 0` on a CSV row (Pair B): the two CSVs differ somewhere. The `cf` lines
  above the table name the variable(s) and mismatch counts. The `_old`/`_new` copies are
  plain text and can be diffed with any tool.
- `schema_ok = 0`: a variable name, order, storage type, format or label differs; the
  report prints both schema strings under "schema mismatches".
- `N_ok = 0` or `k_ok = 0`: a different number of rows or columns.
- `sig_ok = 0` with everything else OK: rows are permuted (row order is part of the
  fingerprint).
- `cf_rc != 0`: value differences, listed per variable above the table.
- A row with `sig = MISSING` on one side: that run did not write the file.

**A stop before any report** is most likely a parse or `syntax` error in code that has
never run (see §4). It is harmless: nothing is written to a production path before the
first program in each `_refactored` file runs, and the original runs after the new one.

---

## 4. What to send back

For each round, for each block:

1. The `OVERALL` line (or the console `REFVAL <part>: …` line).
2. On any FAIL: the matching `refval_report_<part>_<ts>.log`.
3. On a Stata error: the wrapper log around the error (the `r(###)` line and the twenty
   lines above it), and which file it was executing.

Nothing else is needed for Phase 6. If Round 2 passes on all four blocks, also say
whether you want the four original files **archived** (moved to an `archive/` folder or
kept under a `_original` suffix) or **deleted**; that is the one open decision for
retirement.

---

## 5. Known things that are not bugs

So a first read of the logs does not raise false alarms:

- **Both runs print progress messages**, so every `di` line from each script appears twice.
  The refactored scripts' messages read `…, this may take a while` where the originals
  read `…; this may take a while` (the semicolon had to go under `#delimit ;`).
- **`catch_at_length_calibration` changes Stata's working directory** and neither the
  original nor the refactored file restores it (`REFACTOR_00 R6`). The wrapper's later
  `cd $here` lines handle it as before.
- **Part1 output feeds the R copula step.** With the original running last, R sees the
  original's output, exactly as without the harness.
- **Pair A's `part2` at Round 2** copies 101 draw files aside; `Code/refactor_validation/`
  will be large. `.gitignore` there excludes `*.dta` and `*.xlsx`.
- **Deviations argued output-identical** (Pair A D-a..D-d, Pair B D-B1..D-B6) are
  expected to produce byte-identical outputs. If any of them does not, that is exactly
  what the harness is for; the report will name the file and variable.

---

## 6. After validation

| Result | Next |
|---|---|
| Round 1 FAIL | send the report; the fix goes into the `_refactored` file or harness, re-run Round 1 |
| Round 1 PASS, Round 2 FAIL | same; do not retire on Round 1 alone |
| Round 2 PASS on all four blocks | Phase 6: remove the old call paths and the five harness blocks from `model_wrapper.do`, delete `Code/refactor_validation/`, optionally drop the `_refactored` suffixes, fix README drift items D-1..D-14 (`REFACTOR_00 §4`), delete the stale `$b2list`/`$sizelist` note from `model_wrapper.do:46–48` and `catch_at_length_calibration.do:36–38` |

Phase 6 will not start until you report a Round 2 PASS (constraint 4).

---

## 7. Validation log (fixes made after the first runs)

| # | Date | Where it stopped | Cause | Fix |
|---|---|---|---|---|
| V-1 | 2026-09-09 | `refval_capture`, first call (Pair A part1, side new) | `postfile` rejects `strL` columns: "strL variables not allowed". Phase 3 assumed `postfile` could write `strL`; it cannot, in any Stata version. The `schema` column needs `strL` because a wide file's schema can exceed the 2,045-character `str#` limit. | `refval_capture` no longer uses `postfile`. It builds the fingerprint rows in memory (`set obs` / `replace`, with `preserve`/`restore` around each file's fingerprinting) and saves the same `refval_fp_<part>_<side>_<ts>.dta` at the end. Same columns, same downstream. `REFACTOR_03 §3.2`'s "strL in postfile" prerequisite is withdrawn. |

The refactored run that hit V-1 had already completed and written its outputs to the
production paths before `refval_capture` was called, so nothing was lost; re-running the
wrapper with the fixed tools file repeats both runs from the start (the RNG save/restore
makes that safe).

| # | Date | Where | Observation | Action |
|---|---|---|---|---|
| V-2 | 2026-09-09 | Pair A part1, Round 1 (`refval_report_part1_20260909_195812.log`, Stata 19 IC) | The three Part B totals files PASS; `baseline_mrip_catch_processed.dta` and `.xlsx` FAIL. **Evidence from the report:** `N` 1280 = 1280, `k` 47 = 47, `schema_ok = 1`, `sig_ok = 0`; `cf` mismatches in exactly the 16 trip-level variables that come from `basefile` (`strat_id psu_id id_code wp_int cod_tot_cat … hadd_rel`), 69 to 1261 rows each, and **zero** mismatches in the 31 domain-level variables (`my_dom_id_string`, `mean*`, `se*`, `missing*`, the eight composition indicators, the two `_ind` flags). Domain-level values are constant within a domain, so a within-domain permutation of rows leaves them equal and scrambles only the trip-level columns. That is the exact signature of the `merge 1:m my_dom_id_string using basefile` breaking ties in a different order in the two runs. Static re-review of the refactored Part A (statement order, the three cod/hadd loops with a strict per-species diff, the range `keep`, the Excel round-trip, the `global impute` reset) found no transcription difference. The failing files are the only trip-level outputs, and Part A ends with `merge 1:m my_dom_id_string using basefile`, an unstable sort on a key with heavy ties. **Working hypothesis:** row order differs between the two runs because Stata's sort tie-breaking uses a separate sort RNG (`c(sortrngstate)`) that the harness did not control. | All four harness blocks now save `c(sortrngstate)` next to `c(rngstate)` and restore it with `set sortrngstate` before the original run. Harmless if the hypothesis is wrong. Diagnostic recipe to confirm or refute it is in §8. |

| V-2b | 2026-09-09 | Same run, after the §8 Step 2 sorted `cf` | The sorted `cf` was **not** clean: some observations are missing in one copy and non-missing in the other, in both directions. This is the second face of the same tie-order cause, one level up. Inside `prep_mrip_trip_catch` (original `part1:180–194`), the per-catch-row columns `cod_tot_cat cod_harvest cod_releases hadd_tot_cat hadd_harvest hadd_releases` are `gen … if common=="<species>"`, so on a trip that caught both cod and haddock the cod row has `cod_*` filled and `hadd_*` missing, and the haddock row the reverse. The trip is then collapsed to one row by `bysort year strat_id psu_id id_code (my_dom_id_string no_dup): gen count_obs1=_n` / `keep if count_obs1==1`. Cod and haddock rows of the same trip tie on that sort key (same domain string, both `no_dup=0`), so **which row survives is decided by the unstable sort**, and with it which of those six columns are missing. The per-trip sums `cod_cat cod_keep cod_rel hadd_cat hadd_keep hadd_rel` are `egen … by(trip)` and identical whichever row survives. **Downstream impact:** `copula_modeling_calibration.R` (`needed_cols`, line ~350) reads `wp_int`, the six per-trip sums, the SEs and the flags, never the six per-row columns; `compare_calibration_data_to_MRIP.do` does not read them either. They are dead columns whose content is arbitrary in the original itself. | No code change beyond V-2: pinning `c(sortrngstate)` makes both runs pick the same survivor row. **To confirm before re-running:** the sorted `cf` differences should be confined to those six per-row columns (`cf cod_cat cod_keep cod_rel hadd_cat hadd_keep hadd_rel wp_int using …` on the sorted copies should be clean). **Logged as probable defect F-6** for after retirement: the six per-row columns in `baseline_mrip_catch_processed.{xlsx,dta}` are not reproducible run to run and should be dropped or made deterministic (e.g. `no_dup` ordering that prefers a species, or `sort …, stable`). Not fixed now (constraint 1). |

## 8. Diagnosing a `cf` FAIL (worked for V-2)

Work on the `.dta` only; the `.xlsx` is its source and fails for the same reason. All
paths relative to the project root.

**Step 1 — read the per-file row in the report.** Which of `N_ok k_ok schema_ok sig_ok`
is 0, and what are `cf_rc` / `cf_ndiff`?

| Pattern | Meaning | Where to look |
|---|---|---|
| `N_ok = 0` | different row count | a `keep`/`drop`/`merge` difference; compare `N_old`/`N_new` |
| `schema_ok = 0` or `cf_rc = 111` | variable list, order or type differs | the report prints both schema strings; the first variable that differs names the block |
| `N_ok = k_ok = schema_ok = 1`, `sig_ok = 0`, `cf` mismatches on **many** variables with counts near `N` | rows are permuted, values may be identical | go to Step 2 |
| `cf` mismatches on a **few** variables | genuine value difference in those variables | Step 3 |

**Step 2 — row-order test.** Align both copies on the trip key and compare again:

```
use "Code/refactor_validation/baseline_mrip_catch_processed_old.dta", clear
sort year strat_id psu_id id_code my_dom_id_string
tempfile o
save `o'
use "Code/refactor_validation/baseline_mrip_catch_processed_new.dta", clear
sort year strat_id psu_id id_code my_dom_id_string
cf _all using `o', verbose
```

If this `cf` is clean, the two files hold the same rows in a different order: the V-2
hypothesis, fixed by the `sortrngstate` change. Re-run the harness. If you want to prove
the cause independently, run the **original** part1 twice in one session (with
`catch_per_trip1 = 1`, no harness), copying the `.dta` aside between runs, and `cf` the
two copies unsorted: a mismatch there shows the original itself is not row-order
reproducible without the sort state pinned.

**Step 3 — value differences.** The `cf … verbose` output lists each differing variable
with observation numbers. Map the variable to the block:

| Variables | Block in the refactored file |
|---|---|
| `mean*`, `se*` (not `missing*`) | `post_svy_by_domain` / `decode_svy_domains` (svy: mean and its decoding) |
| `se*` where `missing*==1` | the SE-imputation loop (verbatim) or its merges |
| `*_only_keep`, `*_only_rel`, `*_keep_and_rel`, `*_no_catch` | the first `foreach sp` loop, or the two `replace *_no_catch` lines |
| `*_keep_and_rel_ind` | the second and third `foreach sp` loops |
| `cod_tot_cat … hadd_rel`, `wp_int`, `id_code`, `year`, `common_dom` | `prep_mrip_trip_catch` (unlikely: the same program feeds the three passing Part B files) |

Then list a few differing observations side by side to see the direction of the
difference:

```
use "…_old.dta", clear
gen long row = _n
list row my_dom_id_string <var> in 1/20
```
