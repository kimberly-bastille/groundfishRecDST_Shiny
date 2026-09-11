# REFACTOR_06 — Retirement, Part B (final state, docs, commit and PR drafts)

**Phase:** 6, Part B
**Date:** 2026-09-10
**Branch:** `refactor_calib_final` (merge-base with `main` is `1d94896`; `main` is at `e6886fa`)
**Prior state:** Part A (`REFACTOR_06a_retirement_partA.md`) is committed as `b1880e7`.
**Nothing was executed** (constraint 2). **No commit was made and no file was deleted**
(constraint 6); the two deletions this phase calls for are listed in §3 for you to run.

---

## 1. Decisions

### 1.1 Taken with you this session

| Question | Your answer |
|---|---|
| README toggle "committed defaults" | drop the values; describe the toggles and say committed values are whatever the last run used |
| The four `_old` files | delete (git history holds the originals); commands in §3 |
| `DATAFLOW_GROUNDFISH.md` (outside the repo) | minimal touch: dated note plus the new programs file; line numbers left as they were |
| The `REFACTOR_*.md` reports and `DATAFLOW_GROUNDFISH.md` | not committed; the draft commit excludes them, and (follow-up request) no code comment or README line in the repo refers to either |

### 1.2 Taken without asking (each reversible)

1. **Script headers finalised.** The Part A headers described a harness and `_old` files
   that no longer exist. The `Status:` block of each of the four scripts now says the file
   was refactored in September 2026, validated exact-match at 101 draws, and that the
   original is `git show fc318d1:Code/pre_sim/<name>`. The "what changed" line-number
   references point at that same commit. `catch_at_length_programs.do` likewise. Part2's
   RNG note now says the harness "(since removed) set" the state. Comment lines only; §4.2
   proves it.
2. **`proto` comment made value-agnostic** (`model_wrapper.do:199`): it said "down to 3"
   while the code sets 5. Same family as drift item D-8.
3. **One README claim that Phase 0 left unverified is now fixed as drift**:
   `compile_input_data_for_dashboard.do` is not in the tree (checked with `find`), so it
   was removed from the "no confirmed caller" list. Logged as D-15 below.
4. **README's Documentation Index gained an "Outside this repository" table** for
   `DATAFLOW_GROUNDFISH.md`, so the wrapper's pointer to it (D-11) lands somewhere.
5. **No pointers to uncommitted files.** At your request every reference to the
   `REFACTOR_*` reports and to `DATAFLOW_GROUNDFISH.md` was removed from the comments
   of the six project files and from README (the "Outside this repository" row). On
   your second request the six pre-existing mentions of `DATAFLOW_GROUNDFISH.md` in
   files this project had not touched were rewritten too, each pointing at the README
   section that covers the same ground: `app.R:35`, `Run_Model.R:13`,
   `Code/sim/R code wrapper.R:30`, `Code/pre_sim/baseline_and_projected_NAL.do:18–19`,
   `Code/pre_sim/get_commercial_landings.R:16`, `Code/pre_sim/set_regulations.do:22`.
   One comment line each, header blocks only. No file in the repository now names
   `DATAFLOW_GROUNDFISH.md` or a `REFACTOR_*` report.

---

## 2. What changed in this phase

| File | Change | `git diff --numstat HEAD` |
|---|---|---|
| `Code/pre_sim/model_wrapper.do` | five harness blocks removed (was `:208–243`, `:335–378`, `:396–449`, `:490–538`, `:563–605`); D-11 pointer rewritten to name README only (`:24–27`); D-12 stale note deleted (was `:45–48`); `proto` comment (`:197`) | 634 → 404 lines |
| `README.md` | D-1..D-10, D-13, D-14, D-15; date; three Documentation Index rows | 49 / 40 |
| `Code/pre_sim/calibration_catch_per_trip_part1.do` | comments only | 14 / 15 |
| `Code/pre_sim/calibration_catch_per_trip_part2.do` | comments only | 15 / 16 |
| `Code/pre_sim/catch_at_length_calibration.do` | comments only | 9 / 10 |
| `Code/pre_sim/catch_at_length_projection.do` | comments only | 8 / 9 |
| `Code/pre_sim/catch_at_length_programs.do` | comments only | 6 / 8 |
| `app.R`, `Run_Model.R`, `Code/sim/R code wrapper.R`, `Code/pre_sim/baseline_and_projected_NAL.do`, `Code/pre_sim/get_commercial_landings.R`, `Code/pre_sim/set_regulations.do` | one header-comment line each: `DATAFLOW_GROUNDFISH.md` pointer replaced by the matching README section | 1 / 1 each (NAL: 2 / 2; landings: 1 / 2) |
| `../DATAFLOW_GROUNDFISH.md` (outside the repo) | dated note under the provenance line; two sub-bullets in the wrapper inventory (items 17 and 20) | not in git |

**Wrapper vs `main`** (`git diff main -- Code/pre_sim/model_wrapper.do`, 15/19 lines): my
three header edits, plus the toggle values and `$ndraws` prototype value you changed on
the branch in earlier commits. No harness trace remains: no `refval`, `HARNESS`,
`_old.do`, `_refactored` or `validate_` string in the file; braces 28/28.

SHA-256 at the end of this session:

```
d668eef6f5e90554c20924fe0b831c3c1df0a7237995dfbc7d66f4c49a695dc1  Code/pre_sim/model_wrapper.do
1d961fadf1c2df36673c142a59b722773c2a0eff5b4170acd9579d2a3c30b930  README.md
fcdce30764f5003caf02586b9bf12bffa5df6f47962e9d14eaedd9ba927fe6ca  Code/pre_sim/calibration_catch_per_trip_part1.do
331399a47be9f8c1a702def4c8fdd303036054f359801fd46c7cef0baf17600e  Code/pre_sim/calibration_catch_per_trip_part2.do
b9cc82a06b8c1170245e5e577e250688bc71e65b0b923d09315682383644de3e  Code/pre_sim/catch_at_length_calibration.do
457b197b13ed4e2f21cb0519426ad1b13b8c0c246c8fa9af61db1a086ad29b7a  Code/pre_sim/catch_at_length_projection.do
a170e533812d25d14405382737b2ec96f05bdd0c6525af054fc9de980bd5acab  Code/pre_sim/catch_at_length_programs.do
209017dcdf5f6bd370861f01c271234ba2be62f825d22c12f1b51d430789bd45  ../DATAFLOW_GROUNDFISH.md
```

---

## 3. What you need to run (the two deletions, then the commit)

I cannot delete files (constraint 6). Two things must go:

```
git rm Code/pre_sim/calibration_catch_per_trip_part1_old.do \
       Code/pre_sim/calibration_catch_per_trip_part2_old.do \
       Code/pre_sim/catch_at_length_calibration_old.do \
       Code/pre_sim/catch_at_length_projection_old.do
git rm -r Code/refactor_validation
rm -r Code/refactor_validation        # sweeps the git-ignored data copies and .log reports left by validation runs
```

The folder can be large: every Round 2 run left `_old`/`_new` copies of 202 draw files
there. Nothing in it is needed after this; the validation verdict is recorded in
`REFACTOR_05 §7` and `REFACTOR_06a §1.1`.

Before deleting, you can re-prove the `_old` files are the originals (prints nothing):

```
git diff main:Code/pre_sim/calibration_catch_per_trip_part1.do Code/pre_sim/calibration_catch_per_trip_part1_old.do
```

(and the same for the other three). Then stage the edits and commit; drafts in §6.

---

## 4. Static verification performed

1. **Harness removal.** Each block was deleted by line range with an assertion on its
   `BEGIN` marker, its `END` marker and the first line after it; the config block's
   trailing blank line went with it. Post-edit search for `refval`, `HARNESS`, `_old.do`,
   `_refactored`, `validate_`: no hits. Brace count 28/28 (it was 38/38 with the five
   blocks, which held 10). Line endings: the wrapper is a CRLF file; 404 CR / 404 LF after
   the edits.
2. **Script edits are comment-only.** For each of the five scripts, `git diff -U0 HEAD`
   was filtered to changed lines that begin neither with a space nor with `/*`; the
   filter returned nothing, so every changed line is comment text (header lines are
   indented one space; the inline notes open with `/*`). Re-run after the reference
   removals with the same result. The executable content is
   byte-for-byte what Round 2 validated, as it was after Part A (`REFACTOR_06a §3.2`).
3. **`_old` files unchanged** (not edited this phase; their checksums are in
   `REFACTOR_06a §2.4`).
4. **README** edits were applied as exact-string replacements with a uniqueness assertion
   on each; the file is CRLF and was written back CRLF (373 CR).
5. **`DATAFLOW_GROUNDFISH.md`** likewise (LF file, written LF).
6. **Every README statement I wrote was checked against the tree:** `docs/` contents,
   `GLOSSARY_GROUNDFISH.md` at the root, Section D banner text, the `proto` block, the
   end-of-log "Prototyping option set on" message (`model_wrapper.do:401–403`), the two
   `do "$input_code_cd/catch_at_length_programs.do"` lines, and the absence of
   `compile_input_data_for_dashboard.do`.

---

## 5. Doc Drift Log — closed out (`REFACTOR_00 §4`)

| ID | Phase 0 finding | Now | How |
|---|---|---|---|
| D-1..D-6 | six toggles documented as `1`, code had `0` | closed | README no longer states a value for any toggle; it says committed values reflect the last run and must be checked in Section D. (The code values had changed again since Phase 0, which is the point.) |
| D-7 | "seventeen ON, two OFF" | closed | sentence removed; only `processMRIP` / `assemblemriplists` are called out, as "expected to stay 0" |
| D-8 | `proto` "default 0/OFF", "101 to 3" | closed | README describes `proto` without a value; wrapper comment no longer names a number |
| D-9 | "`EXECUTION CONTROL` banner, lines 168–187" | closed | now "Section D (\"Execution control\")", no line numbers |
| D-10 | "`proto` (line 192)" | closed | no line number |
| D-11 | wrapper points at `DATAFLOW_GROUNDFISH.md`, which is not in the repo | closed | wrapper header points at README's "Running the Pipeline" instead; per your follow-ups, nothing in the repo names `DATAFLOW_GROUNDFISH.md` any more (six pre-existing comments rewritten, §1.2 item 5) |
| D-12 | stale "swapped files" note in wrapper header and `catch_at_length_calibration.do` Note 2 | closed | deleted from the wrapper; the refactored calibration script never carried it (`REFACTOR_04b §5`, F-B13) |
| D-13 | `docs/` row lists only `Run_Summary` | closed | row lists `USER_GUIDE_GROUNDFISH.md`, the PDF and `figures/` |
| D-14 | index omits `GLOSSARY_GROUNDFISH.md`, user guide, PDF | closed | three rows added |
| D-15 (new) | `compile_input_data_for_dashboard.do` listed as a script with no caller; Phase 0 said "not confirmed" | closed | verified absent with `find`; removed from the list. `DATAFLOW_GROUNDFISH.md` Flag 6 still lists it; the dated note there says so |

Still unverified, unchanged from `REFACTOR_00 §4` "Claims I could not verify": the subACL
figures (README:20), the R dependency section, and the "no confirmed caller" role
inferences. Not drift findings; not touched.

---

## 6. Draft commit message and pull request (no git commands were run)

### 6.1 Commit (this phase)

```
Phase 6 Part B: strip validation harness, close out README drift

- model_wrapper.do: remove the five refactor-validation harness blocks; the
  normal step blocks now run the refactored scripts under their original names
- delete the four *_old.do copies and Code/refactor_validation/ (originals are
  in git history: git show fc318d1:Code/pre_sim/<name>)
- README.md: toggle table no longer claims committed defaults (they change
  with every run); proto described without a value; docs/ and Documentation
  Index rows completed; missing-script reference removed
- wrapper header: point at README for execution order instead of the
  out-of-repo DATAFLOW_GROUNDFISH.md; delete the stale $b2list/$sizelist
  "swapped files" note (the macros are name-consistent)
- script comments: final wording, no references to out-of-repo notes; six
  other header comments that pointed at DATAFLOW_GROUNDFISH.md now point at
  the README section instead

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Cpbv7VCBCNxrgcnUaAgmgh
```

### 6.2 Pull request `refactor_calib_final` → `main`

**Title:** Refactor the four calibration / catch-at-length Stata scripts (validated exact-match)

**Body:**

```
## What

Removes copy-paste duplication from four pre_sim scripts without changing any output:

| Script | Before | After | What was consolidated |
|---|---|---|---|
| calibration_catch_per_trip_part1.do | 1181 lines | ~700 | one ~158-line MRIP trip prep block repeated 4x, a svy/postfile loop 4x, a results decoder 4x, an export block 3x -> five programs defined once |
| calibration_catch_per_trip_part2.do | 436 | ~448 | a 4-line resample idiom 3x and 20 `distinct ... if key==k` blocks -> one program and three loops; sort-order-sensitive blocks kept verbatim on purpose |
| catch_at_length_calibration.do | 717 | ~540 | a ~115-line MRIP length prep block and a svy:tab-to-long block, each 2x -> two programs |
| catch_at_length_projection.do | 834 | ~671 | age-length key, NAA-to-NAL conversion (x2, cod/haddock) -> three programs |
| catch_at_length_programs.do (new) | | 180 | the gamma fit and truncate/renormalize loops that both catch_at_length scripts carried -> shared, loaded by both |

All four are now `#delimit ;` with `program define` blocks and documented parameters.
Known oddities of the originals are preserved and marked PRESERVED in the code, because
the goal was exact equivalence, not fixes.

## How it was validated

Each script was run twice in one Stata session from the same RNG and sort-RNG state,
original then refactored, and every output file compared exactly: `cf _all` plus a
row-indexed `datasignature` for .dta/.xlsx, raw-byte match for .csv. Result at
`$ndraws = 101`: PASS on every file of every script (5 files, 102 files, 2 files, 1 file).
The harness lived in model_wrapper.do behind marked blocks and has been removed in the
final commit; the reviewer can see it in the branch history (commits 5e9f866..b1880e7).

## How to review

- `git diff main -- Code/pre_sim/<script>.do` shows the original -> refactored diff
  directly, since the file names did not change.
- The originals are retrievable at `git show fc318d1:Code/pre_sim/<script>.do`.
- Also on this branch, unrelated to the refactor: `tidyup_mrip_data_fromR.do` (date
  handling, from the patch_tidyup merge). The patch_capwithresample changes are already
  on main via #159.

## Docs

README's "Running the Pipeline" section no longer states committed toggle defaults
(they change with every committed run and had drifted twice); it now says to check
Section D. Stale header notes in model_wrapper.do were removed.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01Cpbv7VCBCNxrgcnUaAgmgh
```

(Line counts above are the pre- and post-refactor working-copy line counts; the "After"
values include the headers and will move by a few lines with the final header edits.)

---

## 7. Assessment

### 7.1 The four refactored scripts, as they now stand

| Script | Outcome | Residual risk and where it is documented |
|---|---|---|
| `calibration_catch_per_trip_part1.do` | Largest win: four copies of a ~158-line prep block and their estimation, decode and export siblings are five programs. Readable end to end. | Preserved defects F-1..F-4 (`REFACTOR_02 §6`); F-2 (`hadd_no_catch` set from cod means) looks like a real bug and should be raised with the authors. Trip-level rows in `baseline_mrip_catch_processed.*` are not row-order reproducible (F-6, `REFACTOR_05 §7 V-2b`); harmless downstream today. |
| `calibration_catch_per_trip_part2.do` | Modest: one program, three loops. Deliberately conservative because sort order decides which resampled row lands on which trip (`REFACTOR_01 P2-2, P2-4`). | Seedless by design (`REFACTOR_00 O-2`); any future edit that changes the number or order of `sample` calls changes results. F-3 (MA-only demographics pool) is a modelling question, not a code one. |
| `catch_at_length_calibration.do` | Two programs replace the discard/harvest copy pair; gamma fit and truncation moved to the shared file. | F-B1, F-B3 (`cd` never restored), F-B9, F-B11 (`REFACTOR_04b §5`). The `l_cm` abbreviation was resolved to `l_cm_bin` on your confirmation (D-B4). |
| `catch_at_length_projection.do` | Cod/haddock duplication of the ALK, NAA-to-NAL and projection steps is three programs. | F-B5..F-B8, F-B12 (`REFACTOR_04b §5`); F-B8 (cod's trawl CSV column is `countage`, haddock's `count`) is an input-file inconsistency worth fixing upstream. |

Full detail: analysis in `REFACTOR_01` (Pair A) and `REFACTOR_04` (Pair B);
implementation and equivalence arguments in `REFACTOR_02 §5` and `REFACTOR_04b §4`;
harness and validation record in `REFACTOR_03`, `REFACTOR_04c`, `REFACTOR_05 §7`.

### 7.2 Recommended next candidates (out-of-scope duplication, logged during Phases 0–4)

In priority order. Each is a separate task with the same shape as this one (analysis,
refactor, exact-match harness, retirement).

1. **The MRIP calibration-year trip-prep idiom, repo-wide.** The state-code block, the
   site-list import/merge and the `area_s`/`mode1` classification recur in
   `directed_trips_calibration.do` (×4–5), `RP_data_analysis.do` (×3–4), and now once
   each inside `prep_mrip_trip_catch` (part1) and `prep_mrip_lengths` (cal). Roughly 14
   copies of the state block existed across five files at Phase 0; two named copies
   remain inside the refactored files and seven outside. A single "prepare trips through
   `area_s`" program would retire all of them. This is also the natural first entry for
   the planned `dstoolkit` package, since `flukeRDM` carries the same block. Described in
   `REFACTOR_00 §5`, `REFACTOR_01 §7`, `REFACTOR_04 §7`.
2. **`directed_trips_calibration.do` Part C.** Its own header says it is three
   near-identical ~160-line blocks differing only in the domain string; it also has a
   second, different idiom for decoding `r(table)` column names. Same pattern as
   part1's P1-1, same fix. `REFACTOR_01 §7`.
3. **`RP_data_analysis.do`.** Three copies of the trip prep, reading the site list from
   `$input_data_cd` rather than `$misc_data_cd`, and the F-1 `prim2_common` assignment.
   README lists it as having no confirmed caller, so the first question is whether it is
   live; if it is dead, retire it instead. `REFACTOR_01 §7`.
4. **`baseline_and_projected_NAL.do`.** Carries its own copies of the ALK build and the
   NAA-to-NAL conversion that `catch_at_length_programs.do` now provides. Header says
   "standalone / unwrapped, no confirmed caller". Either make it the third consumer of the
   shared programs or retire it with the README's no-caller list. `REFACTOR_04 §7`.

Not recommended: X-1 (part2's 9-state block vs part1's), P2-2/P2-4 (sort-sensitive),
X-B4 (`REFACTOR_01 §6`, `REFACTOR_04 §6`): low confidence they are the same operation,
or high risk for little gain.

### 7.3 Defects found along the way, for the authors

Not fixed (constraint 1 held throughout; the refactor reproduces them exactly):

- **F-2** `part1`: `hadd_no_catch` is set from the cod means. `REFACTOR_01 §4`.
- **F-6** `part1`: six per-row columns in `baseline_mrip_catch_processed.{xlsx,dta}` depend
  on unstable sort tie order; not reproducible run to run; unread downstream.
  `REFACTOR_05 §7 V-2b`.
- **F-B8** `proj`: trawl CSV count column differs by species. `REFACTOR_04b §5`.
- **F-3** `part2`: demographics pool is MA-only (state block lacks ME/NH). `REFACTOR_02 §6`.
- **F-B3** `cal`: `cd $misc_data_cd` is never restored; the wrapper compensates.

---

## 8. Open items, none blocking

- The `REFACTOR_*.md` reports and `DATAFLOW_GROUNDFISH.md` stay out of git (your choice).
  Nothing in the repository refers to either any more.
- `DATAFLOW_GROUNDFISH.md` still carries pre-refactor wrapper line numbers everywhere; its
  new dated note says so. A full refresh is a session of its own.
- Whether §7.2 becomes a new task, and whether it goes in this `CLAUDE.md` or a new one,
  was listed as an open item in `CLAUDE.md` and is still yours to decide.
