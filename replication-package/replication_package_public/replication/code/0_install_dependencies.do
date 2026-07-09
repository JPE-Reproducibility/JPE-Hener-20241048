*==============================================================================*
* 0_install_dependencies.do
*
*   Installs the user-written Stata commands required to run this replication
*   package. Run this ONCE before master.do (needs an internet connection).
*
*       . do "0_install_dependencies.do"
*
*   Safe to re-run: each package is (re)installed with , replace. Already-current
*   packages are simply refreshed. A summary is printed at the end.
*==============================================================================*

clear all
set more off
version 16

di as txt _n "{hline 78}"
di as txt "Installing dependencies for the Arrest/DV replication package..."
di as txt "{hline 78}"

* Install order matters: ftools/ranktest underpin reghdfe/ivreghdfe;
* moremata underpins mtefe missings.
local pkgs ftools reghdfe ranktest ivreghdfe estout moremata mtefe missings

foreach p of local pkgs {
    di as txt _n ">>> ssc install `p', replace"
    cap noisily ssc install `p', replace
    if _rc {
        di as error "    FAILED to install `p' (rc=" _rc ")."
        di as error "    Check your internet connection or install manually: ssc install `p'"
    }
}

*------------------------------------------------------------------------------*
* Verify the commands the package actually calls are now available.
*   - esttab / eststo are provided by the 'estout' package.
*------------------------------------------------------------------------------*
di as txt _n "{hline 78}"
di as txt "Verifying required commands are callable:"
di as txt "{hline 78}"

local cmds reghdfe ivreghdfe esttab eststo mtefe
local missing ""
foreach c of local cmds {
    cap which `c'
    if _rc {
        di as error "  [MISSING] `c'"
        local missing "`missing' `c'"
    }
    else {
        di as result "  [ ok    ] `c'"
    }
}

di as txt "{hline 78}"
if "`missing'" == "" {
    di as result "All dependencies installed. You can now run master.do."
}
else {
    di as error "Still missing:`missing'"
    di as error "Resolve the above before running master.do."
    exit 111
}


