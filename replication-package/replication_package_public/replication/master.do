*==============================================================================*
* REPLICATION PACKAGE — MASTER DO-FILE
*
*   "Deterrence or Backlash? Arrests and the Dynamics of Domestic Violence"
*    Amaral, Dahl, Hener, Kaiser, and Rainer
*
*   This master file runs the full pipeline:
*       (1) code/01_build_sample.do  — builds the estimation dataset from the
*                                       raw West Midlands Police .dta files.
*       (2) code/02_analysis.do      — produces every figure and table in the
*                                       paper, IN THE ORDER THEY APPEAR.
*
*   Software : Stata 16+.
*   Required user-written commands (install once, see below):
*       reghdfe, ftools, ivreghdfe, ranktest, estout (esttab/eststo), mtefe
*
*   To install dependencies, run ONCE (needs internet):
*       do "code/0_install_dependencies.do"
*==============================================================================*

clear all
set more off

*------------------------------------------------------------------------------*
* 1. PATHS — edit ONLY the line below.
*    $root must point to the project folder that contains "Rawdata/".
*    All other folders are created automatically beneath it.
*------------------------------------------------------------------------------*
global root "/path/to/your/replication/folder"


global path_raw       "$root/Rawdata"      // read-only raw inputs 
global path_tempdata  "$root/Tempdata"     // intermediate files (created)
global path_est       "$root/Estdata"      // built estimation dataset (created)
global path_results   "$root/Results"      // tables, figures, logs (created)

* Folder holding this package's code (01_*.do, 02_*.do)
global path_code      "$root/replication/code"

cap mkdir "$path_tempdata"
cap mkdir "$path_est"
cap mkdir "$path_results"

set seed 12345

*------------------------------------------------------------------------------*
* 2. DEPENDENCY CHECK — stops early with a clear message if an ado is missing.
*------------------------------------------------------------------------------*
foreach pkg in reghdfe ivreghdfe esttab mtefe {
    cap which `pkg'
    if _rc {
        di as error "Required command '`pkg'' not found."
        di as error "Run once:  do \"$path_code/0_install_dependencies.do\""
        exit 111
    }
}

*------------------------------------------------------------------------------*
* 3. RUN
*    Once 01_build_sample.do has been run once, 02_analysis.do, can be run by 
*    itself.
*------------------------------------------------------------------------------*
do "$path_code/01_build_sample.do"
do "$path_code/02_analysis.do"

di as result "Replication complete. Output written to: $path_results"
