/*******************************************************************************
 Script:       model_wrapper.do
 Purpose:      Master Stata wrapper for the GroundfishRDM pre-simulation
               pipeline. Sets the year-specific global parameters (calibration
               and projection windows, federal holidays, number of draws, seed),
               configures project directories, then runs the pre-simulation
               steps in order via on/off execution-control toggles. Ends by
               launching the R simulation wrapper (R code wrapper.R).
 Inputs:       None read directly here; each sub-script reads its own inputs.
               Assumes the working directory is the project root on entry (see
               "Before running" below) and that the external data directory has
               been located by developer_setup_stata.do.
 Outputs:      None written directly; orchestrates sub-scripts that write to
               $misc_data_cd, $calib_catch_draws_cd and $figure_cd. Writes a
               timestamped SMCL log to $log_dir.
 Dependencies: User-written commands: here, xsvmat, gammafit, grc1leg, rscript
               (`ssc install` each once). Code/helpers/developer_setup_stata.do.
               Google Drive mounted to D: (for get_assessment_from_gdrive.do).
               MRIP source data mounted (see "Data availability" below).
			   Some R scripts that are called will copy files from Google Drive or write files to 
			   Google Drive.  If you have not already connected to google drive, 
			   run "Code/helpers/googledrivesetup.R".  If you do not the
			   the R scripts that use googledrive will fail ungracefully.
 Pipeline:     Step 0 / very top of the whole pipeline. Each toggle below runs
               one pre_sim script (execution order documented in
               DATAFLOW_GROUNDFISH.md); the final toggle hands off to
               Code/sim/R code wrapper.R for the simulation.

 Before running: this wrapper uses `here` to locate the project root, so you
   MUST change into the project directory first. A convenient pattern is to add
       global groundfishRDMdir "path to this project"
   to your profile do-file and run `cd "$groundfishRDMdir"` before this script.

 Data availability (projections are made for the next fishing year in Dec/Jan):
   - MRIP catch, effort and length data: most recent 6 waves.
   - Stock-assessment projection data: Jan 1 numbers-at-age (NAA) for the
     baseline year (historical rec. selectivity) and projection year
     (projected catch-at-length).
   - NEFSC trawl-survey data (recent years) used to build age-length keys.
   - MRIP source data live at
       smb://net/mrfss/products/mrip_estim/Public_data_cal2018
     (on Windows, mount \\net.nefsc.noaa.gov\mrfss to A:).

 THESE GLOBALS AND REGULATIONS MUST BE UPDATED EVERY YEAR (see Section A).

 Note:         Suspected mislabeling (flagged, code unchanged): in Section E the
               $b2list and $sizelist macros appear to point at swapped files
               ($b2list -> mrip_size.dta, $sizelist -> mrip_size_b2.dta).
*******************************************************************************/

set varabbrev on

/******************************************************************************/
/******************************************************************************/
/* Section A: Year-specific global parameters (UPDATE EVERY YEAR) */
/******************************************************************************/
/******************************************************************************/

/*Set calibration year-waves*/
global calibration_year "(year==2025 & inlist(wave, 1, 2, 3, 4, 5)) | (year==2024 & inlist(wave, 6))"  // last six waves of data  updated
global calibration_date_start td(01nov2024)
global calibration_date_end td(31oct2025)

global projection_date_start td(01may2026)
global projection_date_end td(30apr2027)

* add federal holidays, as these are considered "weekend" days by the MRIP and we need to account for this when estimating fishing effort at the month and kind-of-day level

* fed holidays in the calibration year
global fed_holidays "inlist(day, td(11nov2024), td(28nov2024), td(25dec2024), td(01jan2025), td(20jan2025), td(17feb2025), td(26may2025), td(19jun2025), td(04jul2025), td(01sep2025), td(13oct2025))"

* fed holidays in the projection year
global fed_holidays_y2 "inlist(day1, td(25may2026), td(19jun2026), td(03jul2026), td(07sep2026), td(12oct2026), td(11nov2026),  td(26nov2026),  td(25dec2026), td(01jan2027), td(18jan2027), td(15feb2027))"

* leap-year days here
global leap_yr_days "td(29feb2024)"

* set number of model iterations to create
global ndraws 101

* adjust 2022 survey trip costs to account for inflation (January 2022 - January 2025)
* source =https://www.bls.gov/data/inflation_calculator.htm
global inflation_expansion=1.13

/******************************************************************************/
/******************************************************************************/
/* Section B: Directories, log, and seed */
/******************************************************************************/
/******************************************************************************/
/* `here' finds the project root. This only works if you have already cd'd into
   the project directory (see the "Before running" note in the header). */
here, nogit

do "${here}/Code/helpers/developer_setup_stata.do"

* adjust project paths based on user
global input_code_cd "${here}/Code/pre_sim"
global misc_data_cd "${gfdatadir}/miscellaneous"
global calib_catch_draws_cd "${gfdatadir}/calib_catch_draws"
global figure_cd  "${gfdatadir}/figures"

global log_dir "${input_code_cd}/logs"

/* make directories if necessary */
capture mkdir $misc_data_cd
capture mkdir $calib_catch_draws_cd
capture mkdir $figure_cd
capture mkdir $log_dir

timer clear 1        // Resets timer #1
timer on 1           // Starts timing

/* start log */
cap log close
log using "${log_dir}\model_wrapper_log_$S_DATE.smcl", replace


* set a global seed
global seed 03211990


/******************************************************************************/
/******************************************************************************/
/* Section C: MRIP year/wave globals and assessment-year globals */
/******************************************************************************/
/******************************************************************************/

/* years/waves of MRIP data.*/
/* used by:
tidyup_mrip_data_fromR.do
MRIP_column_cases.do (dead code)
compare wave 5 data.do*/

global yr_wvs 20231 20232 20233 20234 20235 20236  ///
			  20241 20242 20243 20244 20245 20246  ///
			  20251 20252 20253 20254 20255 20256

/* First and last year of MRIP data.*/
/* used by:
tidyup_mrip_data_fromR.do*/

global first_mrip_year 2023
global last_mrip_year 2025
numlist "$first_mrip_year/$last_mrip_year"

/* Yearlist and wavelist.*/
/* used by:
MRIP_lists.do (dead code) */

global yearlist  `r(numlist)'
global wavelist 1 2 3 4 5 6

/* set the baseline year and projection year numbers-at-age globals
used by catch_at_length_projection.do*/

global cod_NAA_base_year 2025
global hadd_NAA_base_year 2025
global cod_NAA_proj_year 2026
global hadd_NAA_proj_year 2026

/* set the starting year for the NEFSC trawl survey data pull (in catch_at_length_projection.do)
	 we aggregate these data across multiple years and use them to create age-length keys
	 I usually check how many observations are available across different choices of the starting year; we want sufficient data
	 but do not want to use historical data too far in the past.
used by catch_at_length_projection.do*/

global trawl_survey_start_year 2022



/******************************************************************************/
/******************************************************************************/
/* Section D: Execution control (toggle each pipeline step on/off) */
/******************************************************************************/
/******************************************************************************/

// Control which modules to run (set to 0 to skip)
loc pull_assessment = 1		 		// Pull Assessment data
loc pull_MRIP = 1		 			// Pull MRIP data.

loc processMRIP = 0	 			// deal with casing MRIP data
loc assemblemriplists =0		 	// deal with casing MRIP data
loc estimate_dtrips = 1				// Estimate Directed Trips
loc costs_per_trip = 1  			// Create Distributions of costs per trip (run 1x)
loc draw_angler_preferences = 1		// Create draw of angler preference parameters (run 1x)
loc catch_per_trip1 = 1				// Part 1 of catch per trip
loc copula_in_R = 1					// Copula model in R
loc catch_per_trip2 = 1				// Part 2 of catch per trip
loc compare_calibration_MRIP = 1	// compare calibration output to MRIP
loc prep_cpt_for_dashboard= 1		// prep data for dashboard
loc Rpush_cpt_to_gdrive =0 			// Push to google drive in R
loc angler_demogs	=1				// add additional angler demographics
loc generate_baseline=1				// Generate baseline-year catch-at-length
loc prep_catch_at_length_for_dash= 0		// Prep catch at length data for dashboard
loc Rpush_catch_at_length_to_gdrive =0 			// Push catch at length data to  google drive in R
loc catch_at_length_project=0			// Generate projection-year catch-at-length
loc run_calibration=0						// Run calibration routine in R



// Prototyping: set proto=1 to override $ndraws down to 3 for a fast test run.
local proto = 1

if `proto' {
	global ndraws 5
}

* === BEGIN REFACTOR VALIDATION HARNESS (config) ===
/************************************
 Refactor validation harness (REFACTOR_03, Pair A; REFACTOR_04c, Pair B;
 retirement Part A in REFACTOR_06a).
 Since Phase 6 Part A the refactored scripts ARE the production scripts,
 under their plain names (calibration_catch_per_trip_part1.do / _part2.do,
 catch_at_length_calibration.do / _projection.do). The pre-refactor
 originals are kept byte-identical under an _old suffix for comparison.
 With a validate_* toggle set to 1, the matching harness block in Section E
 runs the retired _old version of that step FIRST, then the production
 version, copies both sets of outputs into $refval_cd, and compares them
 exactly (cf + datasignature for .dta/.xlsx; raw-byte match for .csv).
 The production version runs last, so production paths hold its output and
 the rest of the pipeline consumes exactly what a harness-free run would.
 A validate_* toggle supersedes the step's own toggle above: the harness
 has already run the production version, so it switches that toggle off
 and nothing runs a third time.
 What to run and where results land: REFACTOR_06a_retirement_partA.md.
 Phase 6 Part B removes this block, the four Section E blocks, the four
 _old files and Code/refactor_validation/.
**************************************/
local validate_catch_per_trip1 = 1		// 1 = compare part1 _old vs production (Pair A)
local validate_catch_per_trip2 = 1		// 1 = compare part2 _old vs production (Pair A)
local validate_catch_at_length_cal = 1	// 1 = compare catch_at_length_calibration _old vs production (Pair B, step 9)
local validate_catch_at_length_proj = 1	// 1 = compare catch_at_length_projection _old vs production (Pair B, step 10)
local refval_copy_draws = $ndraws		// part2: how many calib_catch_draws_<i>.dta to copy aside for cf.
										//   Every draw is fingerprinted regardless; lower this only if disk is tight.
local refval_cf_verbose = 0				// 1 = cf also lists every differing observation (large logs)

global refval_cd "${here}/Code/refactor_validation"
if `validate_catch_per_trip1' | `validate_catch_per_trip2' | `validate_catch_at_length_cal' | `validate_catch_at_length_proj' {
	capture mkdir "$refval_cd"
	do "${refval_cd}/refval_tools.do"
}
* === END REFACTOR VALIDATION HARNESS (config) ===

/******************************************************************************/
/******************************************************************************/
/* Section E: Run the pipeline (each step gated by its Section D toggle) */
/******************************************************************************/
/******************************************************************************/

// 0) Pull Assessment data from google.

/* This code requires you to mount your google drive to D on your computer */
if `pull_assessment' {
	di "Pulling Assessment data from google"

	do "$input_code_cd\get_assessment_from_gdrive.do"
}

// 0) Pull MRIP data from Oracle (takes a while).




/* Paths to the tidied MRIP extracts (written by tidyup_mrip_data_fromR.do). */
global catchlist "$misc_data_cd/mrip_catch.dta"
global triplist  "$misc_data_cd/mrip_trip.dta"
global b2list  "$misc_data_cd/mrip_size_b2.dta"
global sizelist  "$misc_data_cd/mrip_size.dta"



if `pull_MRIP' {
  	di "Pulling MRIP data from oracle"
		rscript using "$input_code_cd\get_mrip_oracle.R", args($first_mrip_year $last_mrip_year)
    di "Oracle Data Pull Finished"

  	di "Tidying up MRIP data"
  	do "$input_code_cd\tidyup_mrip_data_fromR.do"
  	di "Tidyup finished"

}




// 1) Process MRIP data


if `processMRIP' {
	di "Processing MRIP data"

	do "$input_code_cd\MRIP_column_cases.do"
	di "MRIP data processed"
}

if `assemblemriplists' {
	di "Assembling Lists of MRIP files"

	do "$input_code_cd\MRIP_lists.do"
	di "Lists of MRIP files assembled"

}


// 2) Estimate directed trips at the month, mode, kind-of day level

if `estimate_dtrips' {
	di "Estimating Directed trips"
	*This file calls "set_regulations.do". In it you must enter the SQ regulations in the calibration and projection year.
	*THIS NEEDS TO BE ADJUSTED EVERY YEAR.

	do "$input_code_cd\directed_trips_calibration.do"
	di "Directed trips Estimated"

}


// 3) Create distributions of costs per trip across strata - only needs to be run once
if `costs_per_trip' {
	di "Creating distributions of cost per trip"

	do "$input_code_cd\survey_trip_costs.do"
	di "distributions of cost per trip Done"

}
// 4) Create draw of angler preference parameters - only needs to be run once
if `draw_angler_preferences' {
	di "Creating draws of angler preference parameters"
	do "$input_code_cd\estimate_angler_preferences.do"
	di "Draws of angler preference parameters Done"

}
// 5) Estimate catch-per-trip at the month and mode level
		//a) compute mean catch-per-trip and standard error, imputing standard errors from historical data when they are missing.
* === BEGIN REFACTOR VALIDATION HARNESS (calibration_catch_per_trip part1) ===
if `validate_catch_per_trip1' {
	di "REFVAL part1: running _old (retired original), then production version, then comparing"
	refval_stamp
	local refval_ts "`r(ts)'"

	/* every file part1 writes; the xlsx is compared as imported, see refval_tools.do */
	local refval_p1_files `""$misc_data_cd\baseline_mrip_catch_processed.dta""'
	local refval_p1_files `"`refval_p1_files' "$misc_data_cd\baseline_mrip_catch_processed.xlsx""'
	local refval_p1_files `"`refval_p1_files' "$misc_data_cd\mrip_catch_by_mode.dta""'
	local refval_p1_files `"`refval_p1_files' "$misc_data_cd\mrip_catch_by_mode_month.dta""'
	local refval_p1_files `"`refval_p1_files' "$misc_data_cd\mrip_catch_by_mode_season.dta""'

	/************************************
	 RNG state is saved before the first (_old) run and restored before the
	 production run, so both runs start from the same state AND the production
	 run starts from exactly the state it would have had without the harness.
	 Part1 sets its own seed, so this only matters for part2 (REFACTOR_00 O-2);
	 the two blocks are kept identical on purpose.
	**************************************/
	local refval_rng0 `c(rngstate)'
	/* the sort RNG (tie order of unstable sorts and merges) is separate from
	   the main RNG and is saved/restored too, so both runs break ties identically */
	local refval_sort0 `c(sortrngstate)'

	do "$input_code_cd\calibration_catch_per_trip_part1_old.do"
	refval_capture , part(part1) side(old) ts(`refval_ts') files(`refval_p1_files') copyfiles(`refval_p1_files')

	set rngstate `refval_rng0'
	set sortrngstate `refval_sort0'
	do "$input_code_cd\calibration_catch_per_trip_part1.do"
	refval_capture , part(part1) side(new) ts(`refval_ts') files(`refval_p1_files') copyfiles(`refval_p1_files')

	refval_compare , part(part1) ts(`refval_ts') verbose(`refval_cf_verbose') ///
		newlabel(calibration_catch_per_trip_part1.do) oldlabel(calibration_catch_per_trip_part1_old.do)
	local refval_pass = r(pass)
	local refval_report "`r(report)'"
	if `refval_pass' di as result "REFVAL part1: PASS -- report: `refval_report'"
	else di as error "REFVAL part1: FAIL -- see `refval_report'"

	/* the production version already ran (last), so production paths hold its output: skip step 5a */
	local catch_per_trip1 = 0
}
* === END REFACTOR VALIDATION HARNESS (calibration_catch_per_trip part1) ===
if `catch_per_trip1' {
	di "Estimate catch-per-trip at the month and mode level"

	do "$input_code_cd\calibration_catch_per_trip_part1.do"
	di "catch-per-trip at the month and mode level Done"

}
		//b) use copula model (in R) to simulate harvest and discards per-trip
if `copula_in_R' {
	 /* this takes a while and will look like it's hung. it's not */
    	di "Estimating copula in R. This takes a while and will look like it's hung"

		rscript using "$input_code_cd\copula_modeling_calibration.R", args($ndraws)
    	di "Copula in R estimated"

}
		//c) generate estimates of simulated total harvest based on random draws of catch-per-trip and directed trips
* === BEGIN REFACTOR VALIDATION HARNESS (calibration_catch_per_trip part2) ===
if `validate_catch_per_trip2' {
	di "REFVAL part2: running _old (retired original), then production version, then comparing ($ndraws draws)"

	/* part2 needs the copula output for every draw; stop here if any is missing */
	forvalues i = 1/$ndraws {
		confirm file "$calib_catch_draws_cd\calib_catch_draws_raw_`i'.dta"
	}

	refval_stamp
	local refval_ts "`r(ts)'"

	/* every file part2 writes: the demographics pool, then one file per draw */
	local refval_p2_files `""$misc_data_cd\angler_dems.dta""'
	forvalues i = 1/$ndraws {
		local refval_p2_files `"`refval_p2_files' "$calib_catch_draws_cd\calib_catch_draws_`i'.dta""'
	}
	/* subset copied aside for cf; the rest are checked by fingerprint only */
	local refval_ncopy = min(`refval_copy_draws', $ndraws)
	local refval_p2_copy `""$misc_data_cd\angler_dems.dta""'
	forvalues i = 1/`refval_ncopy' {
		local refval_p2_copy `"`refval_p2_copy' "$calib_catch_draws_cd\calib_catch_draws_`i'.dta""'
	}

	/************************************
	 RNG state is saved before the first (_old) run and restored before the
	 production run. Part2 sets no seed (REFACTOR_00 O-2), so this is what
	 makes old and new start from the same state, and it leaves the production
	 run starting from exactly the state it would have had without the harness.
	**************************************/
	local refval_rng0 `c(rngstate)'
	/* the sort RNG (tie order of unstable sorts and merges) is separate from
	   the main RNG and is saved/restored too, so both runs break ties identically */
	local refval_sort0 `c(sortrngstate)'

	do "$input_code_cd\calibration_catch_per_trip_part2_old.do"
	refval_capture , part(part2) side(old) ts(`refval_ts') files(`refval_p2_files') copyfiles(`refval_p2_copy')

	set rngstate `refval_rng0'
	set sortrngstate `refval_sort0'
	do "$input_code_cd\calibration_catch_per_trip_part2.do"
	refval_capture , part(part2) side(new) ts(`refval_ts') files(`refval_p2_files') copyfiles(`refval_p2_copy')

	refval_compare , part(part2) ts(`refval_ts') verbose(`refval_cf_verbose') ///
		newlabel(calibration_catch_per_trip_part2.do) oldlabel(calibration_catch_per_trip_part2_old.do)
	local refval_pass = r(pass)
	local refval_report "`r(report)'"
	if `refval_pass' di as result "REFVAL part2: PASS -- report: `refval_report'"
	else di as error "REFVAL part2: FAIL -- see `refval_report'"

	/* the production version already ran (last), so production paths hold its output: skip step 5c */
	local catch_per_trip2 = 0
}
* === END REFACTOR VALIDATION HARNESS (calibration_catch_per_trip part2) ===
if `catch_per_trip2' {
    	di "Generating estimates of simulated total harvest based on random draws"

		do "$input_code_cd\calibration_catch_per_trip_part2.do"
    	di "Estimates of simulated total harvest Done"

	}
// 6) compare calibration output to MRIP, and retain total simulated harvest and discards to apply to the baseline catch-at-length distribution
if `compare_calibration_MRIP' {
    	di "Comparing calibration output to MRIP"
		cd $here

		do "$input_code_cd\compare_calibration_data_to_MRIP.do"
    	di "Comparison of calibration output to MRIP done"

	}
// 7) Process catch-per-trip and format it for the rec dashboard
if `prep_cpt_for_dashboard'{
    	di "Processing and formatting catch-per-trip for dashboard"

		do "$input_code_cd\rdb_processing_catch_per_trip.do"
    	di "Processing and formatting catch-per-trip for dashboard done"

		}
		//run this script in R to read in the catch per trip processed for the rec dashboard, save it as an Rds, and push it to Google Drive
if `Rpush_cpt_to_gdrive'{
    	di "Pushing rec dashboard data to gdrive using R" 

		rscript using "$input_code_cd\rdb_catch_per_trip_to_drive.R"
	    di "Rec dashboard data pushed to gdrive "

}
// 8) add additional angler demographics based on results of utility model
if `angler_demogs'{
    	di "Adding additional angler demographics"

		do "$input_code_cd\additional_angler_dems.do"
    	di "Additional angler demographics done"

		}
* === BEGIN REFACTOR VALIDATION HARNESS (catch_at_length_calibration) ===
if `validate_catch_at_length_cal' {
	di "REFVAL cal: running _old (retired original), then production version, then comparing ($ndraws draws)"

	/* step 9 needs the simulated totals written by step 6; stop here if missing */
	confirm file "$misc_data_cd\simulated_catch_totals_for_catch_length.dta"

	refval_stamp
	local refval_ts "`r(ts)'"

	/* every file catch_at_length_calibration writes; both are CSVs, compared byte-for-byte */
	local refval_cal_files `""$misc_data_cd\baseline_catch_at_length_observed.csv""'
	local refval_cal_files `"`refval_cal_files' "$misc_data_cd\baseline_catch_at_length.csv""'

	/************************************
	 RNG state is saved before the first (_old) run and restored before the
	 production run, so the production run starts from exactly the state it
	 would have had without the harness. Both catch_at_length scripts set
	 their own seed, so this is redundant here; kept so all harness blocks
	 read the same way.
	 Neither run is followed by cd $here: the script changes directory
	 (REFACTOR_00 R6) and a harness-free run would be left there too. All
	 harness paths are absolute, and neither script reads a relative path
	 before its own cd, so the run order does not matter for paths.
	**************************************/
	local refval_rng0 `c(rngstate)'
	/* the sort RNG (tie order of unstable sorts and merges) is separate from
	   the main RNG and is saved/restored too, so both runs break ties identically */
	local refval_sort0 `c(sortrngstate)'

	do "$input_code_cd\catch_at_length_calibration_old.do"
	refval_capture , part(cal) side(old) ts(`refval_ts') files(`refval_cal_files') copyfiles(`refval_cal_files')

	set rngstate `refval_rng0'
	set sortrngstate `refval_sort0'
	do "$input_code_cd\catch_at_length_calibration.do"
	refval_capture , part(cal) side(new) ts(`refval_ts') files(`refval_cal_files') copyfiles(`refval_cal_files')

	refval_compare , part(cal) ts(`refval_ts') verbose(`refval_cf_verbose') ///
		newlabel(catch_at_length_calibration.do) oldlabel(catch_at_length_calibration_old.do)
	local refval_pass = r(pass)
	local refval_report "`r(report)'"
	if `refval_pass' di as result "REFVAL cal: PASS -- report: `refval_report'"
	else di as error "REFVAL cal: FAIL -- see `refval_report'"

	/* the production version already ran (last), so production paths hold its output: skip step 9 */
	local generate_baseline = 0
}
* === END REFACTOR VALIDATION HARNESS (catch_at_length_calibration) ===
// 9) Generate baseline-year catch-at-length, using the simulated harvest/discard totals from step 5
if `generate_baseline'{
    	di "Generating baseline catch-at-length"

		do "$input_code_cd\catch_at_length_calibration.do"
    	di "Baseline catch-at-length generated "

		}
		//Process catch at length and format it for the rec dashboard
if `prep_catch_at_length_for_dash'{
    	di "Processing and formatting catch-at-length for dashboard"

		do "$input_code_cd\rdb_catch_at_length.do"
    	di "Processing and formatting catch-at-length for dashboard done"

		}
		//run this script in R to read in the catch at length processed for the rec dashboard, save it as an Rds, and push it to Google Drive
if `Rpush_catch_at_length_to_gdrive'{
    	di "Pushing rec dashboard catch at length data to gdrive using R"

		rscript using "$input_code_cd\rdb_catch_at_len_to_drive.R"
	    di "Rec dashboard catch at length data pushed to gdrive " 

}		
* === BEGIN REFACTOR VALIDATION HARNESS (catch_at_length_projection) ===
if `validate_catch_at_length_proj' {
	di "REFVAL proj: running _old (retired original), then production version, then comparing ($ndraws draws)"

	/* step 10 reads both calibration CSVs (step 9 output, the production
	   version's if the cal block above ran); stop here if either is missing */
	confirm file "$misc_data_cd\baseline_catch_at_length_observed.csv"
	confirm file "$misc_data_cd\baseline_catch_at_length.csv"

	refval_stamp
	local refval_ts "`r(ts)'"

	/* the one file catch_at_length_projection writes; a CSV, compared byte-for-byte */
	local refval_proj_files `""$misc_data_cd\projected_catch_at_length.csv""'

	/************************************
	 RNG state is saved before the first (_old) run and restored before the
	 production run; see the cal block above for why this is redundant but kept.
	**************************************/
	local refval_rng0 `c(rngstate)'
	/* the sort RNG (tie order of unstable sorts and merges) is separate from
	   the main RNG and is saved/restored too, so both runs break ties identically */
	local refval_sort0 `c(sortrngstate)'

	do "$input_code_cd\catch_at_length_projection_old.do"
	refval_capture , part(proj) side(old) ts(`refval_ts') files(`refval_proj_files') copyfiles(`refval_proj_files')

	set rngstate `refval_rng0'
	set sortrngstate `refval_sort0'
	do "$input_code_cd\catch_at_length_projection.do"
	refval_capture , part(proj) side(new) ts(`refval_ts') files(`refval_proj_files') copyfiles(`refval_proj_files')

	refval_compare , part(proj) ts(`refval_ts') verbose(`refval_cf_verbose') ///
		newlabel(catch_at_length_projection.do) oldlabel(catch_at_length_projection_old.do)
	local refval_pass = r(pass)
	local refval_report "`r(report)'"
	if `refval_pass' di as result "REFVAL proj: PASS -- report: `refval_report'"
	else di as error "REFVAL proj: FAIL -- see `refval_report'"

	/* the production version already ran (last), so production paths hold its output: skip step 10 */
	local catch_at_length_project = 0
}
* === END REFACTOR VALIDATION HARNESS (catch_at_length_projection) ===
// 10) Generate projection-year catch-at-length, incorporating the stock assessment data
if `catch_at_length_project'{
		di "Generating projection year catch-at-length"

		do "$input_code_cd\catch_at_length_projection.do"
    	di "Projection year catch-at-length generated "

		}
di "The calibration and projection routines can now be run in R "
// 11) Run the calibration routine in R, export files to Google Drive
if `run_calibration'{
		di "Running calibration routine in R"
	cd $here

		rscript using "$here\Code\sim\R code wrapper.R", args($ndraws)
    	di "Simulation model calibrated and files exported to Google Drive"

		}


log close
display "model_wrapper.do: Stata pre-simulation stage complete."

if (`proto'==1) {
	display "Prototyping option set on. ndraws global set to $ndraws"
}

timer off 1          // Stops timing
timer list 1         // Displays elapsed time in seconds
