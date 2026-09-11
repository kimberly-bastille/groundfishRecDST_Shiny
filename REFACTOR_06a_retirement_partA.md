# REFACTOR_06a — Retirement, Part A (both pairs)

**Phase:** 6, Part A
**Date:** 2026-09-10
**Branch:** `refactor_calib` (base: `main` at `fc318d1`; `main` has not moved since the branch point)
**Trigger:** you reported that Round 2 (`$ndraws = 101`) showed `OVERALL: PASS` on all four
harness blocks (part1, part2, cal, proj). That satisfies constraint 4 for both pairs, so
this Part A retires all four files at once.
**Nothing was executed** (constraint 2). Every check below is static.
**No git commit was made and no file was deleted** (constraint 6). The renames are staged
with `git mv`; the edits are unstaged. Part B waits for your go-ahead.

---

## 1. Decisions

### 1.1 Taken with you this session

| Question | Your answer |
|---|---|
| Round 2 result | all four blocks PASS at 101 draws |
| Layout of retired vs new files | rename in place: `X.do` → `X_old.do`, `X_refactored.do` → `X.do`, all in `Code/pre_sim/` |
| Rename mechanism | `git mv` (the resulting commit is identical to a plain rename; `git mv` only stages both halves of each swap together) |
| Committed defaults of the four `validate_*` toggles | all `1`: every wrapper run compares `_old` vs production until Part B strips the harness |
| Headers of the `_old` files | byte-identical: the Phase 0 SHA-256 values still verify them |

### 1.2 Taken without asking (each reversible in a few lines)

1. **Harness run order swapped: `_old` first, production last.** Through Phase 5 the
   refactored file ran first and the original last, so production paths held original
   output. After retirement the refactored file *is* production, and CLAUDE.md asks that
   the old logic path be removed from the wrapper. With the toggles at 1, leaving the
   original last would have meant the retired code still produced every downstream input
   on every run. The comparison itself is symmetric: `refval_compare` merges the two
   fingerprint files by file name and does not care which side ran first
   (`refval_tools.do:310–331`). The RNG save/restore is symmetric too: the state is saved
   at block entry and restored before the second run, so the production run starts from
   exactly the state a harness-free run would have had. I checked that neither
   `catch_at_length_calibration.do` nor `catch_at_length_projection.do` reads a relative
   path before its own `cd $misc_data_cd` (all `use`/`import`/`export` paths are
   `$misc_data_cd`-absolute or tempfiles), so the `cd` side effect of the first run does
   not change what the second run reads.
2. **Header comments of the five new files edited** (`Script:`, `Status:`, and the one
   line introducing the "what changed" list; plus the programs file's references to the
   `_refactored` names). No line outside the header comment block changed; §3.2 proves it.
3. **`refval_compare` is now always called with explicit `newlabel()`/`oldlabel()`**, and
   the defaults inside `refval_tools.do` were changed to the post-retirement names, so a
   report header can never show a `_refactored` name again.
4. **`model_wrapper.do` line endings normalised to CRLF.** The working copy was CRLF
   (git stores LF, `core.autocrlf = true`); my line-based edit inserted LF-only lines,
   leaving the file mixed. It was re-normalised to all-CRLF, its prior state. The other
   five edited files were LF in the working copy and stay LF. Git normalises all of them
   to LF on commit either way.

---

## 2. What was produced

### 2.1 Renames (staged via `git mv`)

| Was | Now | Content |
|---|---|---|
| `Code/pre_sim/calibration_catch_per_trip_part1.do` | `…_part1_old.do` | unchanged, `3f987851…` |
| `Code/pre_sim/calibration_catch_per_trip_part1_refactored.do` | `…_part1.do` | header comment edited |
| `Code/pre_sim/calibration_catch_per_trip_part2.do` | `…_part2_old.do` | unchanged, `02ccfdc8…` |
| `Code/pre_sim/calibration_catch_per_trip_part2_refactored.do` | `…_part2.do` | header comment edited |
| `Code/pre_sim/catch_at_length_calibration.do` | `…_calibration_old.do` | unchanged, `f135e37b…` |
| `Code/pre_sim/catch_at_length_calibration_refactored.do` | `…_calibration.do` | header comment edited |
| `Code/pre_sim/catch_at_length_projection.do` | `…_projection_old.do` | unchanged, `90c03aec…` |
| `Code/pre_sim/catch_at_length_projection_refactored.do` | `…_projection.do` | header comment edited |

### 2.2 Edits (unstaged; `git diff --numstat HEAD`)

| File | + | − | What |
|---|---|---|---|
| `Code/pre_sim/model_wrapper.do` | 67 | 58 | config comment; four harness blocks repointed and reordered (§2.3); nothing outside the five marker pairs |
| `Code/refactor_validation/refval_tools.do` | 15 | 11 | header `Retirement:` note; `side` doc; `newlabel`/`oldlabel` docs and defaults (`:291`, `:294`); two report-header `di` lines (`:306–307`) |
| `Code/pre_sim/catch_at_length_programs.do` | 8 | 5 | header comment only |
| the four new scripts | 10 each | 7 each | header comment only (§3.2) |

### 2.3 Where the harness now sits in `model_wrapper.do`

| Block | Lines | `do` targets, in order |
|---|---|---|
| `(config)` | `:208–242` | toggles at `:229–232`, all `1` |
| `(calibration_catch_per_trip part1)` | `:335–378` | `…_part1_old.do` → `…_part1.do`; step 5a at `:379` |
| `(calibration_catch_per_trip part2)` | `:396–449` | `…_part2_old.do` → `…_part2.do`; step 5c at `:450` |
| `(catch_at_length_calibration)` | `:490–538` | `…_calibration_old.do` → `…_calibration.do`; step 9 at `:540` |
| `(catch_at_length_projection)` | `:563–605` | `…_projection_old.do` → `…_projection.do`; step 10 at `:607` |

The normal step blocks (5a, 5c, 9, 10) were not edited. They call the plain names, which
now hold the refactored code, so **no path in the wrapper outside the harness reaches an
`_old` file**. With all four `validate_*` toggles at 0 the wrapper would run only the new
code.

### 2.4 SHA-256 at the end of this session

```
c5a4a84b5d47f0b2587761562dbeb8ddb720c5699d26d3afd83ec7e3952cf0a8  Code/pre_sim/model_wrapper.do
0047fde9f8729e2b3bc4d24d501b27e4d17b0b7fdc8d322e5d0dd6ab61a04f18  Code/pre_sim/calibration_catch_per_trip_part1.do
db4db55c30ede8fb0213f68a5d5bf8150a948db4833e65ce385c1b1adcb727d8  Code/pre_sim/calibration_catch_per_trip_part2.do
5f32b35f72232c2bf943c24da4ef1d606be1577625a2140fc1f3d8b20115a4e3  Code/pre_sim/catch_at_length_calibration.do
d663ede42b28fce934242e8cd1c9e3ac76eb4ee421e83b2cd8e6900f1261bbd8  Code/pre_sim/catch_at_length_projection.do
7fac63a482711f9c3ada4c733527dc827a9c15924884e1682f3c124210ab9793  Code/pre_sim/catch_at_length_programs.do
3f98785143de06c5a4c13abd6a811facfd68b5874d0ea2472541d8bf88c2e73a  Code/pre_sim/calibration_catch_per_trip_part1_old.do
02ccfdc8eb7542ce18af14aaacf307c9f0130096718e91d4a64e4af7bff2f7d1  Code/pre_sim/calibration_catch_per_trip_part2_old.do
f135e37b7cd1332803e5a8fef1c53a6b239171e34229f0c88e2c4bd6230f0e34  Code/pre_sim/catch_at_length_calibration_old.do
90c03aec399b158474288410b594ec611d82793ba6d40077791ccecc8d331577  Code/pre_sim/catch_at_length_projection_old.do
8fa98e5f442ce7ad85f460a408b0e2f98e375ad2b2b757b8233d2f26cadb0182  Code/refactor_validation/refval_tools.do
```

The four `_old` values are the Phase 0 values (`REFACTOR_00 §1`), unchanged.

---

## 3. Static verification performed

1. **Old files are the originals.** `git diff HEAD:Code/pre_sim/X.do Code/pre_sim/X_old.do`
   is empty for all four, and so is the same diff against `main:Code/pre_sim/X.do`.
   SHA-256 matches Phase 0.
2. **New files differ from the validated `_refactored` files only in the header.**
   `git diff -U0 HEAD:Code/pre_sim/X_refactored.do Code/pre_sim/X.do` shows, for each of
   the four, exactly 7 removed and 10 added lines, all between the opening
   `/****` and the closing `****/` of the file header: the `Script:` line, the six
   `Status:` lines, and the one-line introduction to the "what changed" list (now two
   lines naming the `_old` file). No executable line changed. The validated content is
   otherwise byte-for-byte what Round 2 ran.
3. **Wrapper structure.** Five `BEGIN`/`END` marker pairs with matching labels; braces
   38/38; the `do` targets inside the harness are exactly the four plain names and the
   four `_old` names; no `_refactored` string remains anywhere under `Code/`.
4. **`refval_tools.do`.** In the `#delimit ;` region after stripping comments: braces
   31/31, `program define`/`end`/`capture program drop` 6/6/6, no `*`-comment lines, no
   `;` inside a quoted string (the two edited `di` lines use commas).
5. **Line endings.** `model_wrapper.do` 634 CR / 634 LF; the other five edited files
   contain no CR, as before.
6. **No other reference needs updating.** A repo-wide search for the eight names found,
   outside the wrapper and the reports, only comment headers and `README.md:157–167`,
   which is a Part B item (Doc Drift Log).

---

## 4. What the reviewer will see

Git detects renames by content at diff time, so the diff the reviewer wants comes for
free: the path `X.do` exists on both sides, with original content on `main` and
refactored content on the branch.

In the retirement commit (and in the PR against `main`):

| Path | Shows as | Contains |
|---|---|---|
| `Code/pre_sim/X.do` (×4) | modified | the full original → refactored diff |
| `Code/pre_sim/X_old.do` (×4) | new file | the original, byte-identical to `main`'s `X.do` |
| `Code/pre_sim/X_refactored.do` | deleted in this commit; absent from the PR | |
| `Code/pre_sim/catch_at_length_programs.do` | new file | the shared Pair B programs |
| `Code/refactor_validation/refval_tools.do`, `.gitignore` | new files | the harness tooling |
| `Code/pre_sim/model_wrapper.do` | modified | five marked harness blocks; nothing else |

Also on this branch but **not from the refactor**: `copula_modeling_calibration.R` (1/1)
and `tidyup_mrip_data_fromR.do` (10/5), from the `patch_capwithresample` and
`patch_tidyup` merges. Mention this in the PR so they are not read as refactor changes.

Two commands for the reviewer:

```
# prove each _old file is the pre-refactor original (prints nothing when identical)
git diff main:Code/pre_sim/calibration_catch_per_trip_part1.do Code/pre_sim/calibration_catch_per_trip_part1_old.do

# side-by-side old vs new at any time, without git history
git diff --no-index Code/pre_sim/calibration_catch_per_trip_part1_old.do Code/pre_sim/calibration_catch_per_trip_part1.do
```

`git log --follow Code/pre_sim/X_old.do` stops at the retirement commit; the original's
history stays on the `X.do` path.

---

## 5. Running the validation on the tester branch

Same as `REFACTOR_05 §1`, with two differences: nothing needs to be set (all four toggles
are committed at 1), and the report header reads

```
new = calibration_catch_per_trip_part1.do (production script, ran last, so production paths hold new output)
old = calibration_catch_per_trip_part1_old.do (retired original, ran first)
```

Execution order per block is now `_old` → production → compare. Console line on success:
`REFVAL <part>: PASS -- report: Code/refactor_validation/refval_report_<part>_<ts>.log`.
PASS/FAIL criteria and expected `files compared` counts are unchanged (`REFACTOR_05 §3`).
Prerequisites (`copula_in_R`, `compare_calibration_MRIP`, inputs on disk) are unchanged.

Note that `proto = 1` at `model_wrapper.do:202` now sets `$ndraws = 5` (`:205`), while the
comment at `:201` and `REFACTOR_05` say 3. Either is a valid Round 1; for the run that
matters set `proto = 0`.

---

## 6. What's needed before Part B

**From you:**

1. Review the diff (`git diff HEAD` for the edits, `git status` for the staged renames).
2. Stage and commit; suggested:

```
git add -A Code/pre_sim Code/refactor_validation REFACTOR_0*.md
git commit -m "Phase 6 Part A: retire originals as _old, promote refactored scripts to production names

- calibration_catch_per_trip_part1/2.do and catch_at_length_calibration/projection.do
  now hold the refactored code (validated exact-match at ndraws=101, REFACTOR_05/06a)
- pre-refactor originals kept byte-identical as *_old.do for the validation harness
- model_wrapper.do harness blocks compare _old (first) vs production (last);
  normal step paths call only the production scripts
- refval_tools.do labels updated; catch_at_length_programs.do header updated
- REFACTOR_00..06a reports added

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Cpbv7VCBCNxrgcnUaAgmgh"
```

3. Hand the branch to the reviewer; optionally have them run the wrapper once (§5).
4. Say when to start Part B.

**Part B will do** (from CLAUDE.md and the running list in `REFACTOR_05 §6`):

- strip the five harness blocks from `model_wrapper.do` (the marker pairs in §2.3);
- delete the four `_old` files and `Code/refactor_validation/` (this is the one step that
  deletes files; it is yours to run, constraint 6, so Part B will list the commands);
- fix `README.md` and `DATAFLOW_GROUNDFISH.md` from the Doc Drift Log `REFACTOR_00 §4`,
  items D-1..D-14, plus the stale `$b2list`/`$sizelist` note at `model_wrapper.do:46–48`
  (the original carried the same note at `:36–38`; the refactored
  `catch_at_length_calibration.do` does not, so only the wrapper header remains);
- draft commit message and PR description (no git commands);
- assessment of the four refactored files with pointers to the earlier reports;
- output `REFACTOR_06_retirement.md`.

---

## 7. Out-of-scope items carried forward

- **F-6** (`REFACTOR_05 §7 V-2b`): the six per-row columns in
  `baseline_mrip_catch_processed.{xlsx,dta}` are not reproducible run to run in either
  version. Dead columns downstream. Fix candidate after Part B.
- **`proto` draw count drift** (`:201` comment says 3, `:205` sets 5). One-line fix, Part B
  or whenever the wrapper is next touched.
- Cross-pair and repo-wide duplication lists in `REFACTOR_01 §7`, `REFACTOR_04 §7`
  stand unchanged.
