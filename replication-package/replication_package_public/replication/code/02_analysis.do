*==============================================================================*
* 02_analysis.do
*
*   Reproduces every figure and table in
*   "Deterrence or Backlash? Arrests and the Dynamics of Domestic Violence"
*   IN THE ORDER THEY APPEAR IN THE PAPER.
*
*   INPUT  : $path_est/Main_est.dta  (written by 01_build_sample.do)
*   OUTPUT : tables (.tex), figures (.png), and logs (.txt) in $path_results
*
*   Each section below is bannered with the exhibit and its output file(s).
*
*   Run via master.do. Bootstrap replications are controlled by $iterations500 
*   and $iterations100 (set just below); lower them for a fast trial run.
*
*   The do file has four parts
*		1. Preparations: loads dataset, sets macros, computes control complier 
*		   means for tables 
*		2. Main results: produces all Tables and Figures in the main text
*       3. Appendix: produces all Tables and Figures in the appendix
*       4. Auxilliary: produces all numbers mentioned in text that do not 
*          reference results from tables or figures
*==============================================================================*


*##############################################################################
**1. Preparations**
*##############################################################################

if "$path_est" == "" {
    di as error "Path globals not set. Run this file via master.do."
    exit 198
}

 
set scheme  s1mono
set scheme  s1mono  , permanently

* Number of bootstrap replications for Table A2
* (iterations100), and Figure 3 / A2 MTE bootstrap (iterations500).
* Defaults below reproduce the paper exactly but take longer to run; for a
* faster trial run, comment out the defaults and uncomment the smaller values.


global iterations100 "100"
*global iterations100 "10"

global iterations500 "500"
*global iterations500 "5"

use "$path_est/Main_est.dta", clear

**Control variable spcifications define
global x1 "year month ward call_grade dayofweek daytime bank_holiday"
global x2d "ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank "
global x2g "ward_year ward_month ward_dayofweek ward_daytime call_grade ward_bank "


*Sample identifier
cap drop esample_means
gen esample_means=1 if lsaocal_cas>=400 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016

********************************************************************************
** Control complier means for all tables are computed here and inserted in tables
** later
********************************************************************************

_pctile lsaocal if esample_means==1, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if esample_means==1, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal  if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

foreach var of varlist anyrepeat_*  repeatofficers_12callh nosevere_repeat severe_repeat vicrepeatofficers_12callh TRrepeatofficers_12callh   nrcases_trim99  incident_to_crime  crime_charge    {

qui xi: reghdfe `var' lsaocal action_arrest if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)

scalar define Pa0z1=_b[_cons]+_b[lsaocal]*z_h
scalar define Pa0z0=_b[_cons]+_b[lsaocal]*z_l

scalar define CCM_`var'=( Pa0z0+( Pa0z0- Pa0z1)*never/complier)
scalar list CCM_`var'

}
 
 //complier means with other instruments

foreach newinst in     Tstr_mostDV_dvcallh Tstr_equal_dvcallh {
	
_pctile `newinst' if lsaocal_cas>=400 & lsaocal_cas!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, p(99)
return list
scalar define z_h=r(r1)
_pctile `newinst' if lsaocal_cas>=400 & lsaocal_cas!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest `newinst' if lsaocal_cas>=400 & lsaocal_cas!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[`newinst']
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

qui xi: reghdfe   repeatofficers_12callh `newinst' action_arrest if lsaocal_cas>=400 & lsaocal_cas!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)

scalar define Pa0z1=_b[_cons]+_b[`newinst']*z_h
scalar define Pa0z0=_b[_cons]+_b[`newinst']*z_l

scalar define CCM`newinst'=( Pa0z0+( Pa0z0- Pa0z1)*never/complier)
scalar list CCM`newinst'

}
 

*##############################################################################
*2. Main results
*##############################################################################
 

*==============================================================================*
* FIGURE 1 — Police Handling of DV Emergency Calls
*   Figure 1 is a hand-drawn flowchart. The shares it reports are printed to
*   the log below so they can be checked. 
*   Output : Figure1_shares_log.txt
*==============================================================================*

preserve 
use "$path_raw/res_crimes_new2.dta", clear 
merge m:1 int_ref_number using "$path_raw/warks1019_new.dta", keepusing (final_classification qualifier)
drop if _merge==2
bysort int_ref_number: gen n=_n
keep if n==1
gen domestic_qualifier = strpos(qualifier, "DOMESTIC")  
gen dvfinal = strpos(final_classification, "DOMESTIC") 
gen dv = 0
replace dv = 1 if (dvfinal==1 | domestic_qualifier>0)

cap log close
log using "$path_results/Figure1_shares_log.txt", text replace
*DV share of all calls
sum dv 
restore
* Caller identity and priority level (over DV calls)
tab c_status               if esample_means==1     // victim vs third party
// priority level:
log close
preserve 
keep if lsaocal_cas>=400 & lsaocal!=. & ward!="" & dvcallh==1  & year>=2011 & year<=2016 
count if call_grade==1
local p1 = round(r(N)/_N, 0.01)*100
count if call_grade>2
local low = round(r(N)/_N, 0.01)*100
local p2=100-`p1'-`low'
log using "$path_results/Figure1_shares_log.txt", text append
display "Share Priority P1: " `p1' "%"
display "Share Priority P2: " `p2' "%"
display "Share Priority Lower: " `low' "%"
restore 


* First-response on-scene actions (shares)
tab action_arrest          if esample_means==1     // (a) Arrest 
sum report    		       if esample_means==1     // (b) Recommend investigation
sum advice                 if esample_means==1     // (c) Advice

sum incident_to_crime      if esample_means==1     // Further investigation opened 
sum crime_charge           if esample_means==1     // Charge 

cap log close


*==============================================================================*
* TABLE 1 — Testing Random Assignment of First Response Teams
*   Balancing of past DV history and case characteristics on (i) arrest x100
*   and (ii) team arrest propensity x100. 
*   Output : Table1.tex
*==============================================================================*

mat drop _all
eststo clear
estimates clear
 
// Column (1): Arrest x100 on the full set of balancing variables
eststo: xi:ivreghdfe action_arrest100mult pcasof parof d_previnc_off d_prevcrime_charge_off c_status callh_sex2 missing_callh_sex callh_experience2 missing_callh_experience if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
qui sum action_arrest100mult if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar pF= Ftail(e(df_m), e(df_r), e(F))

// Column (2): Team arrest propensity x100 on the full set of balancing variables
eststo: xi:ivreghdfe lsaocal100mult pcasof parof d_previnc_off d_prevcrime_charge_off c_status callh_sex2 missing_callh_sex callh_experience2 missing_callh_experience if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
qui sum lsaocal100mult if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar pF= Ftail(e(df_m), e(df_r), e(F))

# delimit ;
esttab using "$path_results/Table1.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(pcasof parof d_previnc_off d_prevcrime_charge_off c_status callh_sex2 callh_experience2)
	mlabel(none)
	stats(ward_grade ward_year ward_month ward_dayofweek ward_daytime ward_bank depmean F pF N,
			labels("Ward x call grade" "Ward x year" "Ward x month" "Ward x day of week" "Ward x day time" "Ward x holiday" "Mean of dep. var(\%)" "F" "Prob$>$F" "N") fmt(0 0 0 0 0 0 %12.3f %12.3f %12.3f %9.0gc))
	mgroups("Arrest x 100" "Team arrest propensity x 100" ,
			 pattern(1 1) prefix(\multicolumn{@span}{c}{) suffix(})
						span erepeat(\cmidrule(lr){@span}));
#delimit cr	





*==============================================================================*
* FIGURE 2 — First Stage Graph of Arrest on Team Arrest Propensity
*   Local linear regression of residualized
*   arrest on residualized team arrest propensity.
*   Output : Figure2.png
*==============================================================================*

preserve

keep if esample_means==1


cap drop r1_*
foreach y in action_arrest lsaocal {

	ivreghdfe `y' i.ward_year, absorb (ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank) resid(r1_`y')
	  su `y'
  scalar m_`y' = r(mean)
  replace r1_`y' = r1_`y' + m_`y'
}


*top and bottom 2% of officer stringency density
cap drop r1*_g r1*_v* r1*_se 
_pctile r1_lsaocal, n(100)
scalar p1_r1_lsaocal = r(r1)
scalar p99_r1_lsaocal = r(r99)

*local linear regression with degree=2,   kernel=triangular
lpoly r1_action_arrest r1_lsaocal, nogr ci gen(r1_lsaocalg r1_action_arrest_y0) se(r1_action_arrest_se) degree(2) kernel(tri)
cap g r1_action_arrest_y1 = r1_action_arrest_y0 - 1.96*r1_action_arrest_se 
cap g r1_action_arrest_y2 = r1_action_arrest_y0 + 1.96*r1_action_arrest_se 

 
twoway (hist r1_lsaocal if inrange(r1_lsaocal,p1_r1_lsaocal, p99_r1_lsaocal), /// 
        fcolor(none) lcolor(black) lwidth(vvthin) fintensity(50) yaxis(2) gap(5))              ///
	(line r1_action_arrest_y0 r1_lsaocalg if r1_lsaocalg >= p1_r1_lsaocal & r1_lsaocalg <= p99_r1_lsaocal, lcolor(black) lwidth(thick))                         ///
	(line r1_action_arrest_y1 r1_lsaocalg if r1_lsaocalg >= p1_r1_lsaocal & r1_lsaocalg <= p99_r1_lsaocal, lcolor(black) lpat("---") lwidth(thin))              /// 
	(line r1_action_arrest_y2 r1_lsaocalg if r1_lsaocalg >= p1_r1_lsaocal & r1_lsaocalg <= p99_r1_lsaocal, lcolor(black) lpat("---") lwidth(thin)             ///
	xtitle(Officer Stringency, size(medsmall)) ytitle("Pr(Arrest)", size(medsmall) axis(1)) ///
	ytitle("Density", size(medsmall) axis(2)) scheme(s1mono) legend(off) xlabel(0.01(0.01)0.06, format(%12.2fc))  ///
	ylabel(0.01(0.01)0.07, angle(0) axis(1) ticks format(%12.2fc) ) ylabel(#6, angle(0) axis(2) ticks ))
gr export "$path_results/Figure2.png", replace


restore

*==============================================================================*
* TABLE 2 — Testing the Monotonicity Assumption
*   Panel A: baseline instrument, first stage by subsample (prior DV call,
*   DV hotspot, time of day). Panel B: reverse-sample instrument requiring at
*   least 300 cases per team (per the table note).
*   Output : Table2a.tex (Panel A), Table2b.tex (Panel B)
*==============================================================================*

* ---- Panel A: baseline instrument ----

mat drop _all
eststo clear


preserve
keep if esample_means==1

eststo:xi:ivreghdfe action_arrest lsaocal if pcasof ==1, absorb ($x2d) cluster(clustvar)
cap drop esample_order
gen esample_order = e(sample)
sum action_arrest if esample_order==1 
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"

eststo:xi:ivreghdfe action_arrest lsaocal if pcasof ==0, absorb ($x2d) cluster(clustvar)
cap drop esample_order
gen esample_order = e(sample)
sum action_arrest if esample_order==1 
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"


eststo:xi:ivreghdfe action_arrest lsaocal if d_abovemedcalls==1, absorb ($x2d) cluster(clustvar)
cap drop esample2
gen esample2 = e(sample)
sum action_arrest if esample2==1 
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"

eststo:xi:ivreghdfe action_arrest lsaocal  if d_abovemedcalls==0, absorb ($x2d) cluster(clustvar)
cap drop esample2
gen esample2 = e(sample)
sum action_arrest if esample2==1
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"


eststo:xi:ivreghdfe action_arrest lsaocal if (hour < 18 & hour >= 6), absorb ($x2d) cluster(clustvar)
cap drop esample_hour
gen esample_hour = e(sample)
sum action_arrest if esample_hour==1
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"

eststo:xi:ivreghdfe action_arrest lsaocal if (hour >= 18 | hour < 6), absorb ($x2d) cluster(clustvar)
cap drop esample_hour
gen esample_hour = e(sample)
sum action_arrest if esample_hour==1
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"

# delimit ;
esttab using "$path_results/Table2a.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(lsaocal)
	stats(ward_grade ward_year ward_month ward_dayofweek ward_daytime ward_bank depmean N, 
			labels("Ward x Call Grade FE" "Ward x Year FE"  "Ward x Month FE" "Ward x Day FE" "Ward x Day time FE" "Ward x Holiday" "Mean of dep. var" "N") fmt(0 0 0 0 0 0 %12.3f %9.0gc))
	mgroups("Higher order victims" "First order victims" "DV hotspot" "No DV hotspot" "Day calls" "Night calls",
			 pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	

restore

* ---- Panel B: reverse-sample instrument ----

mat drop _all
eststo clear

preserve 


gen reverseIV=lsaocal_fvic1 if Teamcas_lsao_dvcfvc1>=300
eststo:xi:ivreghdfe action_arrest reverseIV if  pcasof ==1 & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb ($x2d) cluster(clustvar)
cap drop esample_order
gen esample_order = e(sample)
sum action_arrest if esample_order==1
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"

drop reverseIV
gen reverseIV=lsaocal_fvic0 if Teamcas_lsao_dvcfvc0>=300
eststo:xi:ivreghdfe action_arrest reverseIV if pcasof ==0 & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb ($x2d) cluster(clustvar)
cap drop esample_order
gen esample_order = e(sample)
sum action_arrest if esample_order==1
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"

drop reverseIV
gen  reverseIV=lsaocal_hot0 if Teamcas_lsao_dvchot0>=300
eststo:xi:ivreghdfe action_arrest reverseIV  if  d_abovemedcalls==1 & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb ($x2d) cluster(clustvar)
cap drop esample2
gen esample2 = e(sample)
sum action_arrest if esample2==1
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"

drop reverseIV
gen reverseIV=lsaocal_hot1 if Teamcas_lsao_dvchot1>=300
eststo:xi:ivreghdfe action_arrest  reverseIV if d_abovemedcalls==0 & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb ($x2d) cluster(clustvar)
cap drop esample2
gen esample2 = e(sample)
sum action_arrest if esample2==1
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"


drop reverseIV
gen reverseIV=lsaocal_day0 if Teamcas_lsao_dvcday0>=300
eststo:xi:ivreghdfe action_arrest reverseIV if  (hour < 18 & hour >= 6) & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb ($x2d) cluster(clustvar)
cap drop esample_hour
gen esample_hour = e(sample)
sum action_arrest if esample_hour==1
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"

drop reverseIV
gen reverseIV=lsaocal_day1 if Teamcas_lsao_dvcday1>=300
eststo:xi:ivreghdfe action_arrest reverseIV if  (hour >= 18 | hour < 6) & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb ($x2d) cluster(clustvar)
cap drop esample_hour
gen esample_hour = e(sample)
sum action_arrest if esample_hour==1
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"

# delimit ;
esttab using "$path_results/Table2b.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(reverseIV)
	stats(ward_grade ward_year ward_month ward_dayofweek ward_daytime ward_bank depmean N, 
			labels("Ward x Call Grade FE" "Ward x Year FE"  "Ward x Month FE" "Ward x Day FE" "Ward x Day time FE" "Ward x Holiday" "Mean of dep. var" "N") fmt(0 0 0 0 0 0 %12.3f %9.0gc))
	mgroups("Higher order victims" "First order victims" "DV hotspot" "No DV hotspot" "Day calls" "Night calls",
			 pattern(1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	

restore

*==============================================================================*
* TABLE 3 — Effect of Arrest on Repeat Emergency Calls for DV
*   Main result. Column 1 OLS; columns 2-4 IV adding ward x time and
*   ward x call-grade interactions.  
*   Output : Table3.tex 
*==============================================================================*
 
eststo clear
 

xi:ivreghdfe action_arrest lsaocal  if   esample_means==1, absorb ($x1) cluster(clustvar)
mat b1 = e(b)
mat semat = e(V)
scalar coef1 = `=b1[1,1]'
scalar se1 = sqrt(`=semat[1,1]')
scalar Fstat1 = e(F)

xi:ivreghdfe action_arrest lsaocal  if   esample_means==1, absorb ($x2g) cluster(clustvar)
mat b1 = e(b)
mat semat = e(V)
scalar coef2 = `=b1[1,1]'
scalar se2 = sqrt(`=semat[1,1]')
scalar Fstat2 = e(F)

xi:ivreghdfe action_arrest lsaocal  if   esample_means==1, absorb ($x2d) cluster(clustvar)
mat b1 = e(b)
mat semat = e(V)
scalar coef4 = `=b1[1,1]'
scalar se4= sqrt(`=semat[1,1]')
scalar Fstat4 = e(F)

xi:ivreghdfe repeatofficers_12callh lsaocal  if  esample_means==1 , absorb ($x1) cluster(clustvar)
mat b1 = e(b)
mat semat = e(V)
scalar coef1a = `=b1[1,1]'
scalar se1a = sqrt(`=semat[1,1]')

xi:ivreghdfe repeatofficers_12callh lsaocal  if  esample_means==1 , absorb ($x2g) cluster(clustvar)
mat b1 = e(b)
mat semat = e(V)
scalar coef2a = `=b1[1,1]'
scalar se2a = sqrt(`=semat[1,1]')

xi:ivreghdfe repeatofficers_12callh lsaocal  if  esample_means==1 , absorb ($x2d) cluster(clustvar)
mat b1 = e(b)
mat semat = e(V)
scalar coef4a = `=b1[1,1]'
scalar se4a= sqrt(`=semat[1,1]')

 

*OLS
eststo: xi:ivreghdfe repeatofficers_12callh action_arrest if  esample_means==1 , absorb ($x2d) cluster(clustvar)
estadd local all_fe "yes"
estadd local wardfe_time "yes"
estadd local wardfe_grade "yes"
estadd local wardfe_bank "yes"
qui sum repeatofficers_12callh if esample_means==1 
estadd scalar depmean = `r(mean)'

*IV  specs
eststo: xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if  esample_means==1 , absorb ($x1) cluster(clustvar)
estadd local all_fe "yes"
estadd local wardfe_time "no"
estadd local wardfe_grade "no"
estadd local wardfe_bank "no"
estadd scalar fs_coef = coef1
estadd scalar fs_se = se1
estadd scalar fstat = Fstat1
estadd scalar rf_coef = coef1a
estadd scalar rf_se = se1a
sum repeatofficers_12callh if esample_means==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 

eststo: xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if  esample_means==1 , absorb ($x2g) cluster(clustvar)
estadd local all_fe "yes"
estadd local wardfe_time "yes"
estadd local wardfe_grade "no"
estadd local wardfe_bank "no"
estadd scalar fs_coef = coef2
estadd scalar fs_se = se2
estadd scalar fstat = Fstat2
estadd scalar rf_coef = coef2a
estadd scalar rf_se = se2a
sum repeatofficers_12callh if esample_means==1
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 

eststo: xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if  esample_means==1 , absorb ($x2d) cluster(clustvar)
estadd local all_fe "yes"
estadd local wardfe_time "yes"
estadd local wardfe_grade "yes"
estadd local wardfe_bank "yes"
estadd scalar fs_coef = coef4
estadd scalar fs_se = se4
estadd scalar fstat = Fstat4
estadd scalar rf_coef = coef4a
estadd scalar rf_se = se4a
qui sum repeatofficers_12callh if esample_means==1
estadd scalar depmean = `r(mean)'

# delimit ;
esttab using "$path_results/Table3.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(action_arrest)
	stats(all_fe wardfe_time wardfe_grade depmean depmean_complier fs_coef fs_se rf_coef rf_se widstat  N, 
			labels("FE: Full set" "Ward x Time"  "Ward x Call grade"   "Mean of dep. var"  "Control complier mean" "First stage" " " "Reduced Form" " " "Kleibergen-Paap F" "N") fmt(0 0 0  %12.3f %12.3f %12.3f %12.3f %12.3f %12.3f %12.0f  %9.0gc))
	mgroups("Repeat OLS" "Repeat IV1" "Repeat IV2" "Repeat IV3" ,	
			 pattern(1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	


*==============================================================================*
* TABLE 4 — Reduction in Incidence vs Reporting
*   IV effect of arrest on repeat DV decomposed by severity (low/high) and by
*   who reports (victim / third party). 
*   Output : Table4.tex 
*==============================================================================*

eststo clear

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest= lsaocal ) if  esample_means==1, absorb ($x2d) cluster(clustvar)
cap drop esampletemp
gen esampletemp = e(sample)
sum repeatofficers_12callh if esampletemp==1 
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
estadd local ward_daytime "yes"
estadd scalar depmean_complier = CCM_repeatofficers_12callh 
drop esampletemp

eststo:xi:ivreghdfe nosevere_repeat (action_arrest= lsaocal ) if  esample_means==1, absorb ($x2d) cluster(clustvar)
gen esampletemp = e(sample)
sum nosevere_repeat if esampletemp==1 
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
estadd local ward_daytime "yes"
estadd scalar depmean_complier = CCM_nosevere_repeat
cap drop esampletemp

eststo:xi:ivreghdfe severe_repeat (action_arrest= lsaocal ) if  esample_means==1, absorb ($x2d) cluster(clustvar)
gen esampletemp = e(sample)
qui sum severe_repeat if esampletemp==1 
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
estadd local ward_daytime "yes"
estadd scalar depmean_complier = CCM_severe_repeat
cap drop esampletemp

eststo: xi:ivreghdfe vicrepeatofficers_12callh (action_arrest = lsaocal) if  esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
estadd local ward_daytime "yes"
gen esampletemp = e(sample)
qui sum vicrepeatofficers_12callh if esampletemp==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_vicrepeatofficers_12callh
cap drop esampletemp

eststo: xi:ivreghdfe TRrepeatofficers_12callh (action_arrest = lsaocal) if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
estadd local ward_daytime "yes"
gen esampletemp = e(sample)
qui sum TRrepeatofficers_12callh if esampletemp==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_TRrepeatofficers_12callh
cap drop esampletemp

# delimit ;
esttab using "$path_results/Table4.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(action_arrest)
	stats(ward_grade depmean depmean_complier widstat N, 
			labels("Full ward interactions"  "Mean of dep. var" "Control complier mean" "Kleibergen-Paap F" "N") fmt(0   %12.3f %12.3f %12.0f %9.0gc))
	mgroups("Repeat" "Repeat and less severe"  "Repeat and severe" "Repeat reported by victim" "Repeat reported by third party" ,
			 pattern(1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	




*==============================================================================*
* TABLE 5 — Mechanisms
*   Panel A: short-term re-victimization (within 4 days, hours 1-48, 49-96,
*   days 5-12, 5-8, 9-12). Panel B: longer-run persistence excluding initial
*   windows, plus criminal charges.
*   Output : Table5a.tex (Panel A), Table5b.tex (Panel B)
*==============================================================================*



*Panel A

eststo clear

foreach var in anyrepeat_96h anyrepeat_0to48h anyrepeat_49to96h anyrepeat_day4_to_12 anyrepeat_day4_to_8 anyrepeat_day8_to_12  {
eststo: xi:ivreghdfe `var' (action_arrest = lsaocal) if esample_means==1, absorb($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
qui sum `var' if esample_means==1
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_`var'
}

# delimit ;
esttab using "$path_results/Table5a.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(action_arrest)
	stats(ward_grade  depmean depmean_complier widstat N, 
			labels("Full ward interactions" "Mean of dep. var" "Control complier mean" "Kleibergen-Paap F" "N") fmt(0   %12.3f %12.3f %12.0f %9.0gc))
	mgroups( "within 4 days" "hours 1-48" "hours 49-96" "within days 5-12" "within days 5-8" "within days 9-12" ,	
			 pattern(1 1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	

*Panel B

eststo clear
 
foreach var in   anyrepeat_12m_96h anyrepeat_12m_1m anyrepeat_12m_1qrt anyrepeat_7_12months  crime_charge {
eststo: xi:ivreghdfe `var' (action_arrest = lsaocal) if esample_means==1, absorb($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
qui sum `var' if esample_means==1
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_`var'
}

# delimit ;
esttab using "$path_results/Table5b.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(action_arrest)
	stats(ward_grade  depmean depmean_complier widstat N, 
			labels("Full ward interactions" "Mean of dep. var" "Control complier mean" "Kleibergen-Paap F" "N") fmt(0   %12.3f %12.3f %12.0f %9.0gc))
	mgroups(  "w/o first 96" "w/o first month" "w/o first quarter" "w/o first half year" "Charges",	
			 pattern(1 1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	

*==============================================================================*
* TABLE 6 — Testing the Exclusion Restriction
*   Re-estimates the main effect while additionally instrumenting other
*   on-scene actions (recommend investigation, response time, advice).
*   Output : Table6.tex
*==============================================================================*
 
gen report_alt=report
replace report_alt=1 if action_arrest==1

gen advice_alt=advice
replace advice_alt=1 if action_arrest==1 | report==1

replace hh_resptime_minw95=hh_resptime_minw95/100
replace Slsaohh_resptime_minw95_dvcallh=Slsaohh_resptime_minw95_dvcallh/100

eststo clear

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal)  if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local Tstrreport_lsao_dvcallh "no"
estadd local Tstradvice_lsao_dvcallh "no"
estadd local Tarrival_min_loo_dvcallh "no"
estadd local r_share_females "no"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest incident_to_crime = lsaocal Tstrinvest_lsao_dvcallh) if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local Tstrreport_lsao_dvcallh "no"
estadd local Tstradvice_lsao_dvcallh "no"
estadd local Tarrival_min_loo_dvcallh "yes"
estadd local r_share_females "no"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest  hh_resptime_minw95  = lsaocal Slsaohh_resptime_minw95_dvcallh) missing_hh_resptime_min  if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local Tstrreport_lsao_dvcallh "yes"
estadd local Tstradvice_lsao_dvcallh "yes"
estadd local Tarrival_min_loo_dvcallh "no"
estadd local r_share_females "no"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest report_alt advice_alt = lsaocal Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh)  if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local Tstrreport_lsao_dvcallh "yes"
estadd local Tstradvice_lsao_dvcallh "yes"
estadd local Tarrival_min_loo_dvcallh "no"
estadd local r_share_females "no"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest incident_to_crime hh_resptime_minw95 report_alt advice_alt = lsaocal Tstrinvest_lsao_dvcallh Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh Slsaohh_resptime_minw95_dvcallh ) missing_hh_resptime_min if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local Tstrreport_lsao_dvcallh "yes"
estadd local Tstradvice_lsao_dvcallh "yes"
estadd local Tarrival_min_loo_dvcallh "no"
estadd local r_share_females "no"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) r_share_females r_mean_age if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local Tstrreport_lsao_dvcallh "yes"
estadd local Tstradvice_lsao_dvcallh "yes"
estadd local Tarrival_min_loo_dvcallh "no"
estadd local r_share_females "no"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 

# delimit ;
esttab using "$path_results/Table6.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(action_arrest incident_to_crime hh_resptime_minw95 report_alt advice_alt)
	stats(Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh Tarrival_min_loo_dvcallh wardinteractions depmean depmean_complier widstat N, 
			labels("Instrumented: Recommend CI propensity" "Instrumented: Advice propensity"  "Instrumented: Resp. Time in other DV" "Full ward interactions" "Mean of dep. var"  "Control complier mean" "Kleibergen-Paap F" "N") fmt(0 0 0 0  %12.3f %12.3f %12.0f %9.0gc))
	mgroups("Repeat DV call",
			 pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	



*==============================================================================*
* FIGURE 3 and A.2 — Marginal Treatment Effects
*   MTE, polynomial degree 2, trimmed 1% of the propensity tails,
*   500 bootstrap reps. The same run produces the common-support plot used as
*   Figure A2. The PRTE figure discussed in Section 8 is produced in the mtefe 
*   regression and reported in the exported table.
*   Output : Figure3.png, FigureA2.png, Text_section8_prte_boot.tex
*==============================================================================*

set seed 12345
eststo clear
preserve
probit action_arrest lsaocal   i.year i.month i.ward_num i.call_grade i.dayofweek i.daytime i.bank_holiday  if  esample_means==1
rename lsaocal tempdistcol
gen lsaocal=max(0.06,tempdistcol)
predict double p_prte
drop lsaocal
rename tempdistcol lsaocal
eststo: mtefe  repeatofficers_12callh  (action_arrest = lsaocal)   i.year i.month i.ward_num i.call_grade i.dayofweek i.daytime i.bank_holiday   if  esample_means==1  , trim(0.01)   poly(2)  prte(p_prte) bootreps($iterations500)
esttab using "$path_results/Text_section8_prte_boot.tex", label b(%12.3f) se(%12.3f) booktabs replace nocons keep(prte mprte1) se starlevels(* 0.10 ** 0.05 *** 0.01)
gr export "$path_results/FigureA2.png", replace name(CommonSupport)
mtefeplot
gr save "$path_results/Figure3.gph", replace
gr export "$path_results/Figure3.png", replace
restore

*##############################################################################
* 3. Appendix: ONLINE APPENDIX A — ADDITIONAL FIGURES AND TABLES
*##############################################################################
*==============================================================================*
* FIGURE A1 — Reduced Form Graph of Repeat DV on Team Arrest Propensity
*   Local linear regression of residualized repeat DV
*   on residualized team arrest propensity
*   Output : FigureA1.png
*==============================================================================*


preserve
keep if esample_means==1


cap drop r1_*
foreach y in repeatofficers_12callh lsaocal {

	ivreghdfe `y' i.ward_year, absorb (ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank) resid(r1_`y')
	  su `y'
  scalar m_`y' = r(mean)
 * clonevar _r1_`v' = r1_`v'
  replace r1_`y' = r1_`y' + m_`y'
}


cap drop r1*_g r1*_v* r1*_se 
_pctile r1_lsaocal, n(100)
scalar p1_r1_lsaocal = r(r1)
scalar p99_r1_lsaocal = r(r99)


lpoly r1_repeatofficers_12callh r1_lsaocal , nogr ci gen(r1_lsaocalg r1_repeatofficers_12callh_y0) se(r1_repeatofficers_12callh_se) degree(2) kernel(tri)
cap g r1_repeatofficers_12callh_y1 = r1_repeatofficers_12callh_y0 - 1.96*r1_repeatofficers_12callh_se 
cap g r1_repeatofficers_12callh_y2 = r1_repeatofficers_12callh_y0 + 1.96*r1_repeatofficers_12callh_se 

 
twoway (hist r1_lsaocal if inrange(r1_lsaocal,p1_r1_lsaocal, p99_r1_lsaocal), /// 
        fcolor(none) lcolor(black) lwidth(vvthin) fintensity(50) yaxis(2) gap(5))              ///
	(line r1_repeatofficers_12callh_y0 r1_lsaocalg if r1_lsaocalg >= p1_r1_lsaocal & r1_lsaocalg <= p99_r1_lsaocal, lcolor(black) lwidth(thick))                         ///
	(line r1_repeatofficers_12callh_y1 r1_lsaocalg if r1_lsaocalg >= p1_r1_lsaocal & r1_lsaocalg <= p99_r1_lsaocal, lcolor(black) lpat("---") lwidth(thin))              /// 
	(line r1_repeatofficers_12callh_y2 r1_lsaocalg if r1_lsaocalg >= p1_r1_lsaocal & r1_lsaocalg <= p99_r1_lsaocal, lcolor(black) lpat("---") lwidth(thin)             ///
	xtitle(Officer Stringency, size(medsmall)) ytitle("Repeat call", size(medsmall) axis(1)) ///
	ytitle("Density", size(medsmall) axis(2)) scheme(s1mono) legend(off) xlabel(0.01(0.01)0.06, format(%12.2fc))  ///
	ylabel(0.47(0.01)0.51, angle(0) axis(1) ticks format(%12.2fc) ) ylabel(#6, angle(0) axis(2) ticks ))
gr export "$path_results/FigureA1.png", replace


restore

*==============================================================================*
* FIGURE A2 — Marginal Treatment Effects: Common Support
*   Produced by the Figure 3 MTE run above (file FigureA2.png). No separate
*   code needed here.
*   Output : FigureA2.png
*==============================================================================*

*==============================================================================*
* TABLE A1 — Sample sizes
*   Reconstructs the case-level sample-restriction ladder. Conditions match
*   the estimation-sample definition (esample_means). 
*   Output : TableA1.txt
*==============================================================================*

preserve 
keep if ward!=""

cap log close
log using "$path_results/TableA1.txt", text replace


* DV cases classified by call handlers, 2011-2016                
count if dvcallh==1 & year>=2011 & year<=2016
* + non-missing dispatch info (valid ward and instrument)         
count if dvcallh==1 & year>=2011 & year<=2016  & lsaocal!=.
* + at least 400 DV cases in dispatched team                       
count if dvcallh==1 & year>=2011 & year<=2016  & lsaocal!=. & lsaocal_cas>=400
* + call grade 1 or 2  (= baseline estimation sample)            
count if esample_means==1

restore

preserve
use "$path_tempdata/DVsampleIV_dataprep.dta", clear
keep if dvcallh == 1
count
restore
cap log close

*==============================================================================*
* TABLE A2 — Characterization of Compliers
*   Population mean vs complier mean (with bootstrapped std. errors) for prior
*   case, prior arrest, prior investigation, and prior charge. Methodology in
*   Online Appendix B; reps controlled by $iterations100.
*   Output : TableA2.txt
*==============================================================================*

* Previous Case

cap program drop CM_pcasof
program define CM_pcasof, rclass

_pctile lsaocal if esample_means==1, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if esample_means==1, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal  if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

qui xi: reghdfe pcasof lsaocal action_arrest if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define Pa0z1_pcasof=_b[_cons]+_b[lsaocal]*z_h

qui xi: reghdfe pcasof lsaocal no_arrest if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define Pa1z0_pcasof=_b[_cons]+_b[lsaocal]*z_l

sum pcasof if esample_means==1
scalar pcasof_mean=r(mean)

scalar define Compliermean_pcasof=(pcasof_mean-never*Pa0z1_pcasof-always*Pa1z0_pcasof)/complier

return scalar pcasof_never=Pa0z1_pcasof
return scalar pcasof_always=Pa1z0_pcasof
return scalar pcasof_complier=Compliermean_pcasof

end

preserve
cap log close
log using "$path_results/TableA2.txt", text replace
keep if esample_means==1
sum pcasof
bootstrap r(pcasof_never) r(pcasof_always) r(pcasof_complier), reps($iterations100) seed(1234) saving("$path_results/TableA2_pcasof", replace): CM_pcasof
cap log close
restore

* Previous Arrest

cap program drop CM_parof
program define CM_parof, rclass

_pctile lsaocal if esample_means==1, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if esample_means==1, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal  if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

qui xi: reghdfe parof lsaocal action_arrest if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define Pa0z1_parof=_b[_cons]+_b[lsaocal]*z_h

qui xi: reghdfe parof lsaocal no_arrest if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define Pa1z0_parof=_b[_cons]+_b[lsaocal]*z_l

sum parof if esample_means==1
scalar parof_mean=r(mean)

scalar define Compliermean_parof=(parof_mean-never*Pa0z1_parof-always*Pa1z0_parof)/complier

return scalar parof_never=Pa0z1_parof
return scalar parof_always=Pa1z0_parof
return scalar parof_complier=Compliermean_parof

end

preserve
cap log close
log using "$path_results/TableA2.txt", text append
keep if esample_means==1
sum parof
bootstrap r(parof_never) r(parof_always) r(parof_complier), reps($iterations100) seed(1234) saving("$path_results/TableA2_parof", replace): CM_parof
cap log close
restore

* Previous Investigation

cap program drop CM_pinof
program define CM_pinof, rclass

_pctile lsaocal if esample_means==1, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if esample_means==1, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal  if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

qui xi: reghdfe d_previnc_off lsaocal action_arrest if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define Pa0z1_pinof=_b[_cons]+_b[lsaocal]*z_h

qui xi: reghdfe d_previnc_off lsaocal no_arrest if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define Pa1z0_pinof=_b[_cons]+_b[lsaocal]*z_l

sum d_previnc_off if esample_means==1
scalar pinof_mean=r(mean)

scalar define Compliermean_pinof=(pinof_mean-never*Pa0z1_pinof-always*Pa1z0_pinof)/complier

return scalar pinof_never=Pa0z1_pinof
return scalar pinof_always=Pa1z0_pinof
return scalar pinof_complier=Compliermean_pinof

end

preserve
cap log close
log using "$path_results/TableA2.txt", text append
keep if esample_means==1
sum d_previnc_off
bootstrap r(pinof_never) r(pinof_always) r(pinof_complier), reps($iterations100) seed(1234) saving("$path_results/TableA2_pinof", replace): CM_pinof
cap log close
restore

* Previous Charge

cap program drop CM_pchar
program define CM_pchar, rclass

_pctile lsaocal if esample_means==1, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if esample_means==1, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal  if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

qui xi: reghdfe d_prevcrime_charge_off lsaocal action_arrest if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define Pa0z1_pchar=_b[_cons]+_b[lsaocal]*z_h

qui xi: reghdfe d_prevcrime_charge_off lsaocal no_arrest if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define Pa1z0_pchar=_b[_cons]+_b[lsaocal]*z_l

sum d_prevcrime_charge_off if esample_means==1
scalar pchar_mean=r(mean)

scalar define Compliermean_pchar=(pchar_mean-never*Pa0z1_pchar-always*Pa1z0_pchar)/complier

return scalar pchar_never=Pa0z1_pchar
return scalar pchar_always=Pa1z0_pchar
return scalar pchar_complier=Compliermean_pchar

end

preserve
cap log close
log using "$path_results/TableA2.txt", text append
keep if esample_means==1
sum d_prevcrime_charge_off
bootstrap r(pchar_never) r(pchar_always) r(pchar_complier), reps($iterations100) seed(1234) saving("$path_results/TableA2_pchar", replace): CM_pchar
cap log close
restore

*==============================================================================*
* TABLE A3 — First Stages for the Extended IV Models
*   First stages underlying Table 6 (arrest, recommend, advice, response time).
*   Requires report_alt/advice_alt and rescaled response time from Table 6. See
*   Table 6 for F statistics.
*   Output : TableA3a.tex / TableA3b.tex
*==============================================================================*


*Panel A

eststo clear

eststo:xi:ivreghdfe action_arrest lsaocal Tstrinvest_lsao_dvcallh if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

eststo:xi:ivreghdfe incident_to_crime lsaocal Tstrinvest_lsao_dvcallh if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

eststo:xi:ivreghdfe action_arrest lsaocal lsaocal Slsaohh_resptime_minw95_dvcallh missing_hh_resptime_min if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

eststo:xi:ivreghdfe  hh_resptime_minw95 lsaocal lsaocal Slsaohh_resptime_minw95_dvcallh  missing_hh_resptime_min if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

eststo:xi:ivreghdfe action_arrest lsaocal Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

eststo:xi:ivreghdfe report_alt lsaocal Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

eststo:xi:ivreghdfe advice_alt lsaocal Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

# delimit ;
esttab using "$path_results/TableA3a.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(lsaocal Tstrinvest_lsao_dvcallh Slsaohh_resptime_minw95_dvcallh Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh )
	stats(wardinteractions   N, 
			labels( "Full ward interactions"   "N") fmt(0  %12.0f %9.0gc))
	mgroups("Arrest" "Report" "Advice" "Arrest" "Arrival time",
			 pattern(1 1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	

* Panel B

eststo clear

eststo:xi:ivreghdfe action_arrest lsaocal Tstrinvest_lsao_dvcallh Slsaohh_resptime_minw95_dvcallh Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh missing_hh_resptime_min if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

eststo:xi:ivreghdfe incident_to_crime lsaocal Tstrinvest_lsao_dvcallh Slsaohh_resptime_minw95_dvcallh Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh  missing_hh_resptime_min if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

eststo:xi:ivreghdfe hh_resptime_minw95 lsaocal Tstrinvest_lsao_dvcallh Slsaohh_resptime_minw95_dvcallh Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh  missing_hh_resptime_min if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

eststo:xi:ivreghdfe report_alt lsaocal Tstrinvest_lsao_dvcallh Slsaohh_resptime_minw95_dvcallh Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh  missing_hh_resptime_min if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

eststo:xi:ivreghdfe advice_alt lsaocal Tstrinvest_lsao_dvcallh Slsaohh_resptime_minw95_dvcallh Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh  missing_hh_resptime_min if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local wardinteractions "yes"

# delimit ;
esttab using "$path_results/TableA3b.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(lsaocal Tstrinvest_lsao_dvcallh Slsaohh_resptime_minw95_dvcallh Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh )
	stats(wardinteractions   N, 
			labels( "Full ward interactions"   "N") fmt(0  %12.0f %9.0gc))
	mgroups("Arrest" "Report" "Advice" "Arrest" "Arrival time",
			 pattern(1 1 1 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	

*==============================================================================*
* TABLE A4 — Controlling for Propensities of Actions other than Arrest
*   Main IV effect adding team propensities for formal investigation, time on
*   scene, recommend investigation, and advice as controls.
*   Output : TableA4.tex
*==============================================================================*


eststo clear

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local r_share_females "no"
estadd local Tstrreport_lsao_dvcallh "no"
estadd local Tstradvice_lsao_dvcallh "no"
estadd local Tarrival_min_loo_dvcallh "no"
estadd local wardinteractions "yes"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) Tstrinvest_lsao_dvcallh if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local r_share_females "yes"
estadd local Tstrreport_lsao_dvcallh "no"
estadd local Tstradvice_lsao_dvcallh "no"
estadd local Tarrival_min_loo_dvcallh "no"
estadd local wardinteractions "yes"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal)  Slsaohh_resptime_minw95_dvcallh  missing_hh_resptime_min  if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local r_share_females "no"
estadd local Tarrival_min_loo_dvcallh "no"
estadd local Tstrreport_lsao_dvcallh "yes"
estadd local Tstradvice_lsao_dvcallh "yes"
estadd local wardinteractions "yes"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh  

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh  if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local r_share_females "no"
estadd local Tarrival_min_loo_dvcallh "no"
estadd local Tstrreport_lsao_dvcallh "yes"
estadd local Tstradvice_lsao_dvcallh "yes"
estadd local wardinteractions "yes"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh 
 
eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) Tstrinvest_lsao_dvcallh Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh Slsaohh_resptime_minw95_dvcallh  missing_hh_resptime_min if esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local r_share_females "no"
estadd local Tarrival_min_loo_dvcallh "no"
estadd local Tstrreport_lsao_dvcallh "yes"
estadd local Tstradvice_lsao_dvcallh "yes"
estadd local wardinteractions "yes"
qui sum repeatofficers_12callh if e(sample)==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh  

# delimit ;
esttab using "$path_results/TableA4.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(action_arrest)
	stats(Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh Tarrival_min_loo_dvcallh wardinteractions depmean depmean_complier widstat N, 
			labels("Control: Recommend CI propensity" "Control: Advice propensity" "Control: Response time in other DV cases" "Full ward interactions" "Mean of dep. var" "Control complier mean" "Kleibergen-Paap F" "N") fmt(0 0 0 0  %12.3f  %12.3f %12.0f %9.0gc))
	mgroups("Repeat Victimization",
			 pattern(1 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	

*==============================================================================*
* TABLE A5 — Testing for Bias due to Misclassification Errors
*   Col 1: wards with >=80% detached/semi-detached housing. Col 2: excluding
*   the Birmingham city centre (3km around St Philips Cathedral).
*   Output : TableA5.tex
*==============================================================================*


gen cathedral_eastings = 407000
gen cathedral_northings = 287200

gen dist_cathedral = [(eastings-cathedral_eastings)^2 + (northings-cathedral_northings)^2]^(1/2)
			
 

_pctile lsaocal if Fraction_Flats <0.20 & esample_means==1, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if Fraction_Flats <0.20 & esample_means==1, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal if Fraction_Flats <0.20 & esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

foreach var of varlist repeatofficers_12callh   {

qui xi: reghdfe `var' lsaocal action_arrest if Fraction_Flats <0.20 & esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)

scalar define Pa0z1=_b[_cons]+_b[lsaocal]*z_h
scalar define Pa0z0=_b[_cons]+_b[lsaocal]*z_l

scalar define CCMr1_`var'=( Pa0z0+( Pa0z0- Pa0z1)*never/complier)
scalar list CCMr1_`var'

}
			
_pctile lsaocal if dist_cathedral>3000 & esample_means==1, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if dist_cathedral>3000 & esample_means==1, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal if dist_cathedral>3000 & esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

foreach var of varlist repeatofficers_12callh   {

qui xi: reghdfe `var' lsaocal action_arrest if dist_cathedral>3000 & esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)

scalar define Pa0z1=_b[_cons]+_b[lsaocal]*z_h
scalar define Pa0z0=_b[_cons]+_b[lsaocal]*z_l

scalar define CCMr2_`var'=( Pa0z0+( Pa0z0- Pa0z1)*never/complier)
scalar list CCMr2_`var'

}		
			
eststo clear

 
eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if Fraction_Flats <0.20 & esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
cap drop esample2
gen esample2=e(sample)
qui sum repeatofficers_12callh if esample2==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCMr1_repeatofficers_12callh 
 
eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if dist_cathedral>3000 & esample_means==1, absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
cap drop esample3
gen esample3=e(sample)
qui sum repeatofficers_12callh if esample3==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCMr2_repeatofficers_12callh 

# delimit ;
esttab using "$path_results/TableA5.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(action_arrest)
	stats(ward_grade ward_year ward_month ward_dayofweek ward_daytime ward_bank depmean depmean_complier widstat  N, 
			labels("Ward x Call Grade FE" "Ward x Year FE"  "Ward x Month FE" "Ward x Day FE" "Ward x Day time FE" "Ward x Holiday" "Mean of dep. var"  "Control complier mean" "Kleibergen-Paap F" "N") fmt(0 0 0 0 0 0 %12.3f %12.3f %12.0f  %9.0gc))
	mgroups("Only areas with min. 80p HH in detached houses" "Excluding city centre of Birmingham (3km radius)",
			 pattern(1 1) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	

*==============================================================================*
* TABLE A6 — Differential Accuracy of Geo-Coded Location as a Function of Arrest
*   Cross-tabulates the geo-coordinate repeat measure against the official
*   victim-ID repeat measure, and tests whether mismatch depends on arrest.
*   Output : TableA6.txt 
*==============================================================================*

 
cap log close
log using "$path_results/TableA6.txt", text replace

tab repeatofficers_12callh CRrepeatofficers_12callh if esample_means==1, row

tab repeatofficers_12callh CRrepeatofficers_12callh if action_arrest==1 & esample_means==1, row

tab repeatofficers_12callh CRrepeatofficers_12callh if action_arrest==0 & esample_means==1, row

cap drop missed_repeat
gen missed_repeat = 0 if repeatofficers_12callh==0 & CRrepeatofficers_12callh==0 & esample_means==1
replace missed_repeat = 1 if repeatofficers_12callh==0 & CRrepeatofficers_12callh==1  & esample_means==1
replace missed_repeat = . if (repeatofficers_12callh==. | CRrepeatofficers_12callh==.)  & esample_means==1

ttest missed_repeat, by(action_arrest) welch
cap log close

*==============================================================================*
* TABLE A7 — Testing Robustness to Alternative Specifications
*   Ten alternative specifications: intensive margin (incl. IV Poisson), call-
*   handler FE, team clustering, alternative officer weightings, call-grade-1/2
*   instrument, traditional leave-one-out, and >=300 / >=500 team-case cutoffs.
*   Output : TableA7.tex 
*==============================================================================*
 
*control complier means 300 cases
_pctile lsaocal if lsaocal_cas>=300 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if lsaocal_cas>=300 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal if lsaocal_cas>=300 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

 

qui xi: reghdfe  repeatofficers_12callh lsaocal action_arrest if lsaocal_cas>=300 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)

scalar define Pa0z1=_b[_cons]+_b[lsaocal]*z_h
scalar define Pa0z0=_b[_cons]+_b[lsaocal]*z_l

scalar define CCM300_repeat=( Pa0z0+( Pa0z0- Pa0z1)*never/complier)
scalar list CCM300_repeat

 
			
			
*control complier means 500 cases

_pctile lsaocal if lsaocal_cas>=500 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if lsaocal_cas>=500 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal if lsaocal_cas>=500 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

 

qui xi: reghdfe repeatofficers_12callh lsaocal action_arrest if lsaocal_cas>=500 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)

scalar define Pa0z1=_b[_cons]+_b[lsaocal]*z_h
scalar define Pa0z0=_b[_cons]+_b[lsaocal]*z_l

scalar define CCM500_repeat=( Pa0z0+( Pa0z0- Pa0z1)*never/complier)
scalar list CCM500_repeat


*Control complier means call grade 1 and 2 instrument 

_pctile lsaocal if Teamcas_lsao_dvc_12>=400 & Teamcas_lsao_dvc_12!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if Teamcas_lsao_dvc_12>=400 & Teamcas_lsao_dvc_12!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal if  Teamcas_lsao_dvc_12>=400 & Teamcas_lsao_dvc_12!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never


qui xi: reghdfe repeatofficers_12callh lsaocal action_arrest if Teamcas_lsao_dvc_12>=400 & Teamcas_lsao_dvc_12!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)

scalar define Pa0z1=_b[_cons]+_b[lsaocal]*z_h
scalar define Pa0z0=_b[_cons]+_b[lsaocal]*z_l

scalar define CCMdvc12_repeat=( Pa0z0+( Pa0z0- Pa0z1)*never/complier)
scalar list CCMdvc12_repeat



*control complier means leave-one-out instrument


_pctile Teamstr_loo_dvcallh if Teamcas_loo_dvcallh>=400 & Teamstr_loo_dvcallh!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, p(99)
return list
scalar define z_h=r(r1)
_pctile Teamstr_loo_dvcallh if Teamcas_loo_dvcallh>=400 & Teamstr_loo_dvcallh!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest Teamstr_loo_dvcallh if Teamcas_loo_dvcallh>=400 & Teamcas_loo_dvcallh!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[Teamstr_loo_dvcallh]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
scalar list complier always never

 

qui xi: reghdfe   repeatofficers_12callh Teamstr_loo_dvcallh action_arrest if Teamcas_loo_dvcallh>=400 & Teamstr_loo_dvcallh!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)

scalar define Pa0z1=_b[_cons]+_b[Teamstr_loo_dvcallh]*z_h
scalar define Pa0z0=_b[_cons]+_b[Teamstr_loo_dvcallh]*z_l

scalar define CCMloo_repeat=( Pa0z0+( Pa0z0- Pa0z1)*never/complier)
scalar list CCMloo_repeat


eststo clear

 
eststo: xi:ivreghdfe nrcases_trim99 (action_arrest = lsaocal)  if esample_means==1 , absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
qui sum nrcases_trim99 if e(sample)==1
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_nrcases_trim99 

 
eststo: ivpoisson gmm nrcases_trim99 (action_arrest=lsaocal) i.year i.month i.ward_num i.call_grade i.dayofweek i.daytime i.bank_holiday  if esample_means==1, vce(cluster clustvar) multi
margins, dydx(action_arrest)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
qui sum nrcases_trim99 if e(sample)==1
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_nrcases_trim99 

 
eststo: xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if  esample_means==1 , absorb ($x2d call_handlerid) cluster(clustvar)
estadd local ward_grade "yes"
estadd local callfe "yes"
estadd local teamclust "no"
qui sum repeatofficers_12callh if esample_means==1
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh

 
eststo: xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if  esample_means==1 , absorb ($x2d) cluster(team_id)
estadd local ward_grade "yes"
estadd local callfe "no"
estadd local teamclust "yes"
qui sum repeatofficers_12callh if esample_means==1
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_repeatofficers_12callh

 
eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = Tstr_mostDV_dvcallh) if lsaocal_cas>=400 & lsaocal_cas!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
cap drop esample2
gen esample2=e(sample)
qui sum repeatofficers_12callh if esample2==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCMTstr_mostDV_dvcallh

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = Tstr_equal_dvcallh) if lsaocal_cas>=400 & lsaocal_cas!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
cap drop esample2
gen esample2=e(sample)
qui sum repeatofficers_12callh if esample2==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCMTstr_equal_dvcallh

eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = Teamstr_lsao_dvc_12) if Teamcas_lsao_dvc_12>=400 & Teamcas_lsao_dvc_12!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
cap drop esample2
gen esample2=e(sample)
qui sum repeatofficers_12callh if esample2==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCMdvc12_repeat 
 
eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = Teamstr_loo_dvcallh) if Teamcas_loo_dvcallh>=400 & Teamcas_loo_dvcallh!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
cap drop esample2
gen esample2=e(sample)
qui sum repeatofficers_12callh if esample2==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCMloo_repeat 
 
eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if lsaocal_cas>=300 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
cap drop esample2
gen esample2=e(sample)
sum repeatofficers_12callh if esample2==1
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM300_repeat 
 
eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if lsaocal_cas>=500 & lsaocal!=. & ward!="" & dvcallh==1 & (call_grade==1 | call_grade==2) & year>=2011 & year<=2016, absorb($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
cap drop esample2
gen esample2=e(sample)
sum repeatofficers_12callh if esample2==1 
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM500_repeat 

# delimit ;
esttab using "$path_results/TableA7.tex",
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(action_arrest)
	stats(ward_grade depmean depmean_complier widstat  N, 
			labels("Full ward interactions" "Mean of dep. var" "Control complier mean" "Kleibergen-Paap F" "N") fmt(0   %12.3f %12.3f %12.0f  %9.0gc))
	mgroups("Intensive margin" "Intensive margin: Poisson" "Callhandler FE"  "Team clustering" "Most experience"   "Equal weight"  "IV: call grade 1 and 2" "IV: Traditional l-o-o" "Team DV cases: 300" "Team DV cases: 500" ,
			 pattern(1 1 1 1 1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	

*==============================================================================*
* TABLE A8 — Heterogeneous Effects of Arrest
*   IV interactions: prior DV investigation, above-P75 predicted arrest, above-
*   P75 predicted repeat, female on team, above-average team age.
*   Output : TableA8.tex 
*==============================================================================*
 

eststo clear
gen arrestXprevcase=action_arrest*d_previnc_off
gen lsaocalXprevcase=lsaocal*d_previnc_off

gen noprev=1-d_previnc_off
gen arrestXnoprevcase=action_arrest*noprev
gen lsaocalXnoprevcase=lsaocal*noprev

gen Yes=arrestXprevcase
gen No=arrestXnoprevcase

eststo:xi:ivreghdfe repeatofficers_12callh (Yes No= lsaocalXnoprevcase  lsaocalXprevcase) d_previnc_off if esample_means==1, absorb ($x2d) cluster(clustvar)
cap drop esample2
gen esample2 = e(sample)
sum repeatofficers_12callh if esample2==1  
estadd scalar depmean = `r(mean)'
estadd local wardinteractions "yes"
estadd scalar depmean_complier = CCM_repeatofficers_12callh
drop Yes No 

 

preserve
keep if esample_means==1
reghdfe action_arrest100mult pcasof parof d_previnc_off d_prevcrime_charge_off c_status callh_sex2 missing_callh_sex callh_experience2 missing_callh_experience if esample_means==1, absorb ($x2d) cluster(clustvar) resid
predict xbarrest_in, xb 

sum xbarrest_in, det
gen arrest_high=0
replace arrest_high=1 if xbarrest_in>=`r(p75)'

gen arrestXhigh=action_arrest*arrest_high
gen lsaocalXhigh=lsaocal*arrest_high

gen arrest_low=1-arrest_high
gen arrestXlow=action_arrest*arrest_low
gen lsaocalXlow=lsaocal*arrest_low

gen Yes=arrestXhigh
gen No=arrestXlow

eststo:xi:ivreghdfe repeatofficers_12callh (Yes No= lsaocalXhigh lsaocalXlow) arrest_high if esample_means==1, absorb ($x2d) cluster(clustvar)
cap drop esample2
gen esample2 = e(sample)
sum repeatofficers_12callh if esample2==1  
estadd scalar depmean = `r(mean)'
estadd local wardinteractions "yes"
estadd scalar depmean_complier = CCM_repeatofficers_12callh
drop Yes No 
restore 
 
 
preserve
keep if esample_means==1
reghdfe repeatofficers_12callh pcasof parof d_previnc_off d_prevcrime_charge_off c_status callh_sex2 missing_callh_sex callh_experience2 missing_callh_experience   if esample_means==1, absorb ($x2d) cluster(clustvar) resid
predict xbrepeat_in, xb 

sum xbrepeat_in, det
gen repeat_high=0
replace repeat_high=1 if xbrepeat_in>=`r(p75)'

gen repeatXhigh=action_arrest*repeat_high
gen lsaocalXhigh=lsaocal*repeat_high

gen repeat_low=1-repeat_high
gen repeatXlow=action_arrest*repeat_low
gen lsaocalXlow=lsaocal*repeat_low

gen Yes=repeatXhigh
gen No=repeatXlow

eststo:xi:ivreghdfe repeatofficers_12callh (Yes No= lsaocalXhigh lsaocalXlow) repeat_high if esample_means==1, absorb ($x2d) cluster(clustvar)
cap drop esample2
gen esample2 = e(sample)
sum repeatofficers_12callh if esample2==1  
estadd scalar depmean = `r(mean)'
estadd local wardinteractions "yes"
estadd scalar depmean_complier = CCM_repeatofficers_12callh
drop Yes No 
restore 

 

gen arrestXfem=action_arrest*r_atleastone_female
gen lsaocalXfem=lsaocal*r_atleastone_female

gen nofem=1-r_atleastone_female
gen arrestXnofem=action_arrest*nofem
gen lsaocalXnofem=lsaocal*nofem

gen Yes=arrestXfem
gen No=arrestXnofem

eststo:xi:ivreghdfe repeatofficers_12callh (Yes No= lsaocalXnofem lsaocalXfem) r_atleastone_female if esample_means==1, absorb ($x2d) cluster(clustvar)
cap drop esample2
gen esample2 = e(sample)
sum repeatofficers_12callh if esample2==1  
estadd scalar depmean = `r(mean)'
estadd local wardinteractions "yes"
estadd scalar depmean_complier = CCM_repeatofficers_12callh
drop Yes No 

 

sum r_mean_age if esample_means==1, de
gen d_age_above=0 if r_mean_age!=.
replace d_age_above=1 if r_mean_age>=`r(mean)' & r_mean_age!=.

gen arrestXage=action_arrest*d_age_above
gen lsaocalXage=lsaocal*d_age_above

gen d_age_below=1-d_age_above
gen arrestXnoage=action_arrest*d_age_below
gen lsaocalXnoage=lsaocal*d_age_below

gen Yes=arrestXage
gen No=arrestXnoage

eststo:xi:ivreghdfe repeatofficers_12callh (Yes No= lsaocalXnoage lsaocalXage) d_age_above if esample_means==1, absorb ($x2d) cluster(clustvar)
cap drop esample2
gen esample2 = e(sample)
sum repeatofficers_12callh if esample2==1  
estadd scalar depmean = `r(mean)'
estadd local wardinteractions "yes"
estadd scalar depmean_complier = CCM_repeatofficers_12callh


corr d_age_above r_atleastone_female if esample_means==1
xi:ivreghdfe repeatofficers_12callh (Yes No= lsaocalXnoage lsaocalXage) d_age_above r_atleastone_female if esample_means==1, absorb ($x2d) cluster(clustvar)

drop Yes No d_age_above d_age_below arrestXage lsaocalXage arrestXnoage lsaocalXnoage

# delimit ;
esttab using "$path_results/TableA8.tex", 
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep( Yes No)
	stats(wardinteractions depmean depmean_complier widstat  N, 
			labels("Full ward interactions" "Mean of dep. var"  "Control complier mean" "Kleibergen-Paap F" "N") fmt(0 %12.3f %12.3f %12.0f  %9.0gc))
	mgroups("Previous investigation" "Above P75 arrest prediction" "Above P75 repeat prediction" "Female in team" "Above avg. age" ,
			 pattern(1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	





*##############################################################################
* 4. AUXILLIARY: ALL TEXT EXHIBITS NOT SHOWN IN FIGURES OR TABLES
*##############################################################################



*==============================================================================*
* Section 2.3 — Reported numbers in text
*   Average number of officers in team. 
*   Output : Text_section23_log.txt
*==============================================================================*


cap log close
log using "$path_results/Text_section23_log.txt", text replace
su nr_officers if esample_means==1
cap log close



*==============================================================================*
* FOOTNOTE 17 — Number of cases 
*   Footnote 17 reports case numbers per team and per officer 
*   Output : Text_footnote17_log.txt
*==============================================================================*
cap log close
log using "$path_results/Text_footnote17_log.txt", text replace

su lsaocal_cas if esample_means==1, det
gen casesperofficer=lsaocal_cas/nr_officers
su casesperofficer if esample_means==1,det

cap log close



*==============================================================================*
* Section 3.1 and 3.2 — Reported numbers in text
*   Mean and regression of instrument on team age and gender (Section 3.1)
*   First stage with additional controls, reported in the text (Section 3.2).
*   Output : Text_section31_log.txt, Text_section32_log.txt
*==============================================================================*


cap log close
log using "$path_results/Text_section31_log.txt", text replace
sum lsaocal if esample_means==1
reghdfe lsaocal r_mean_age r_share_females if esample_means==1, absorb ($x2d) cluster(clustvar) residual
cap log close

cap log close
log using "$path_results/Text_section32_log.txt", text replace
xi: ivreghdfe action_arrest lsaocal pcasof parof d_previnc_off d_prevcrime_charge_off c_status callh_sex2 missing_callh_sex callh_experience2 missing_callh_experience if esample_means==1, absorb ($x2d) cluster(clustvar)
cap log close


*==============================================================================*
* Section 4 - complier shares
*   Output : Text_section4_compliershares_log.tex
*==============================================================================*

_pctile lsaocal if esample_means==1, p(99)
return list
scalar define z_h=r(r1)
_pctile lsaocal if esample_means==1, p(1)
return list
scalar define z_l=r(r1)

qui xi: reghdfe action_arrest lsaocal  if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma=_b[lsaocal]
scalar define alpha=_b[_cons]
scalar define complier=gamma*(z_h-z_l)
scalar define always=alpha+gamma*z_l
scalar define never=1-alpha-gamma*z_h
cap log close
log using "$path_results/Text_section4_compliershares_log.txt", text replace 
scalar list complier always never
cap log close

*==============================================================================*
* Section 4 - complier reweighted OLS
*   Output : Text_section4_complierols_log.tex
*==============================================================================*


preserve
keep if esample_means==1
_pctile lsaocal, nq(100)
return list r99 r1

gen p1 = r(r1) 
gen p99 = r(r99)
gen complier_weight=.
gen complgroup=.
replace complgroup=1 if pcasof==0 & parof==0 & d_previnc_off==0 & d_prevcrime_charge_off==0  
replace complgroup=4 if pcasof==1 & parof==1 & d_previnc_off==0 & d_prevcrime_charge_off==0
replace complgroup=2 if pcasof==1 & parof==0 & d_previnc_off==0 & d_prevcrime_charge_off==0
replace complgroup=3 if pcasof==1 & parof==0 & d_previnc_off==1 & d_prevcrime_charge_off==0
replace complgroup=4 if pcasof==1 & parof==1 & d_previnc_off==1 & d_prevcrime_charge_off==0
replace complgroup=5 if pcasof==1 & parof==0 & d_previnc_off==1 & d_prevcrime_charge_off==1
replace complgroup=6 if pcasof==1 & parof==1 & d_previnc_off==1 & d_prevcrime_charge_off==1
tab complgroup
forvalues n=1/6{
	qui reghdfe action_arrest lsaocal if complgroup==`n' , absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank) 

gen frac_complier_`n' = ((_b[lsaocal])*p99) - ((_b[lsaocal])*p1)  if complgroup==`n'

gen helpvar=(complgroup==`n')
egen frac_`n' = mean(helpvar)  
sum frac_`n'
replace complier_weight = frac_complier_`n'/frac_`n'  if complgroup==`n' & complier_weight==.
drop helpvar
}
cap log close
log using "$path_results/Text_section4_complierols_log.txt", text replace 
xi:ivreghdfe repeatofficers_12callh action_arrest [w=complier_weight], absorb ($x2d) cluster(clustvar)

cap log close
restore


*==============================================================================*
*   Footnote 24 — Severity test by reference call identity, results reported
*   in footnote 24.
*   Output : Text_footnote24.tex 
*==============================================================================*
 
eststo clear
 
preserve

gen vic_call= (c_status==1)
gen third_call=1-vic_call
gen vic_arrest=vic_call*action_arrest
gen third_arrest=third_call*action_arrest
gen vic_lsaocal=vic_call*lsaocal
gen third_lsaocal=third_call*lsaocal


 
_pctile lsaocal if esample_means==1 & c_status!=1, p(99)
return list
scalar define z_h_split_t=r(r1)
_pctile lsaocal if esample_means==1 & c_status!=1, p(1)
return list
scalar define z_l_split_t=r(r1)
_pctile lsaocal if esample_means==1 & c_status!=1, p(99)
return list
scalar define z_h_split_v=r(r1)
_pctile lsaocal if esample_means==1 & c_status!=1, p(1)
return list
scalar define z_l_split_v=r(r1)

qui xi: reghdfe vic_arrest  vic_lsaocal third_lsaocal third_call  if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma_split_v=_b[vic_lsaocal]
scalar define alpha_split_v=_b[_cons]
qui xi: reghdfe third_arrest vic_lsaocal third_lsaocal third_call  if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)
scalar define gamma_split_t=_b[third_lsaocal]
scalar define alpha_split_t=_b[_cons]

scalar define complier_split_v=gamma_split_v*(z_h_split_v-z_l_split_v)
scalar define always_split_v=alpha_split_v+gamma_split_v*z_l_split_v
scalar define never_split_v=1-alpha_split_v-gamma_split_v*z_h_split_v
scalar list complier_split_v always_split_v never_split_v
scalar define complier_split_t=gamma_split_t*(z_h_split_t-z_l_split_t)
scalar define always_split_t=alpha_split_t+gamma_split_t*z_l_split_t
scalar define never_split_t=1-alpha_split_t-gamma_split_t*z_h_split_t
scalar list complier_split_t always_split_t never_split_t
foreach var of varlist  severe_repeat    {

qui xi: reghdfe `var' vic_lsaocal third_lsaocal third_call  action_arrest if esample_means==1 , cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)

scalar define Pa0z1_split_v=_b[_cons]+_b[vic_lsaocal]*z_h_split_v
scalar define Pa0z0_split_v=_b[_cons]+_b[vic_lsaocal]*z_l_split_v
scalar define Pa0z1_split_t=_b[_cons]+_b[third_lsaocal]*z_h_split_t
scalar define Pa0z0_split_t=_b[_cons]+_b[third_lsaocal]*z_l_split_t

scalar define CCMs_v_`var'=( Pa0z0_split_v+( Pa0z0_split_v- Pa0z1_split_v)*never_split_v/complier_split_v)
scalar define CCMs_t_`var'=( Pa0z0_split_t+( Pa0z0_split_t- Pa0z1_split_t)*never_split_t/complier_split_t)
scalar list CCMs_v_`var' CCMs_t_`var'

} 


eststo:xi:ivreghdfe severe_repeat (vic_arrest third_arrest= vic_lsaocal third_lsaocal) third_call if  esample_means==1, absorb ($x2d) cluster(clustvar)
cap drop esampletemp
gen esampletemp = e(sample)
qui sum severe_repeat if esampletemp==1 
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
estadd local ward_daytime "yes"
estadd scalar depmean_complier_v = CCMs_v_severe_repeat
estadd scalar depmean_complier_t = CCMs_t_severe_repeat 
cap drop esampletemp


# delimit ;
esttab using "$path_results/Text_footnote24.tex", 
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(vic_arrest third_arrest)
	stats(ward_grade depmean depmean_complier_v depmean_complier_t widstat N, 
			labels("Full ward interactions"  "Mean of dep. var" "Control complier mean victim" "Control complier mean third" "Kleibergen-Paap F" "N") fmt(0   %12.3f %12.3f %12.3f  %12.0f %9.0gc))
	mgroups( "Repeat and severe",
			 pattern(1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	
restore

*==============================================================================*
* Section 5.2 and 5.3 — Reporting tests 
*   Additional reporting tests conditional on repeat call, reported in 
*   Section 5.2 in the main text and in section 5.3 in footnote 25.
*   Output : Text_section52_53_reporting.tex
*==============================================================================*
 
 
eststo clear
eststo:xi:ivreghdfe severe_repeat (action_arrest= lsaocal ) if  esample_means==1 & repeatofficers_12callh==1, absorb ($x2d) cluster(clustvar)
cap drop esampletemp
gen esampletemp = e(sample)
qui sum severe_repeat if esampletemp==1 
estadd scalar depmean = `r(mean)'
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
estadd local ward_daytime "yes" 
test _b[action_arrest]=0
local sign=sign(_b[action_arrest])
estadd scalar onesideless=ttail(r(df_r),`sign'*sqrt(r(F)))
estadd scalar onesidemore=1-ttail(r(df_r),`sign'*sqrt(r(F)))
cap drop esampletemp

eststo: xi:ivreghdfe TRrepeatofficers_12callh (action_arrest = lsaocal) if esample_means==1 &  repeatofficers_12callh==1 , absorb ($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
estadd local ward_daytime "yes"
cap drop esampletemp
gen esampletemp = e(sample)
qui sum TRrepeatofficers_12callh if esampletemp==1 
estadd scalar depmean = `r(mean)' 
test _b[action_arrest]=0
local sign=sign(_b[action_arrest])
estadd scalar onesideless=ttail(r(df_r),`sign'*sqrt(r(F)))
estadd scalar onesidemore=1-ttail(r(df_r),`sign'*sqrt(r(F)))
cap drop esampletemp

# delimit ;
esttab using "$path_results/Text_section52_53_reporting.tex", 
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(action_arrest)
	stats(ward_grade depmean   widstat N onesideless onesidemore, 
			labels("Full ward interaction" "Mean of dep. var"   "Kleibergen-Paap F" "N" "One-sided ttest<=0" "One-sided ttest>=0") fmt(0 %12.3f %12.3f %12.0f %9.0gc %12.4f %12.4f))
	mgroups(  "Repeat and severe cond repeat"   "Repeat reported by third party cond repeat",
			 pattern(1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	\sym{***} \(p<.01\)}\\" "");
#delimit cr	
 

*==============================================================================*
* Footnote 27 - short term effects
*   Output : Text_footnote27_short.tex
*==============================================================================*

eststo clear
forvalues day=1/2 {
eststo: xi:ivreghdfe anyrepeat_day`day' (action_arrest = lsaocal) if esample_means==1, absorb($x2d) cluster(clustvar)
estadd local ward_year "yes"
estadd local ward_month "yes"
estadd local ward_dayofweek "yes"
estadd local ward_daytime "yes"
estadd local ward_grade "yes"
estadd local ward_bank "yes"
qui sum anyrepeat_day`day' if esample_means==1
estadd scalar depmean = `r(mean)'
estadd scalar depmean_complier = CCM_anyrepeat_day`day'
}
 
 
# delimit ;
esttab using "$path_results/Text_footnote27_short.tex", 
	label b(%12.3f) se(%12.3f) booktabs replace nocons keep(action_arrest)
	stats(ward_grade  depmean depmean_complier widstat N, 
			labels("Full ward interactions" "Mean of dep. var" "Control complier mean" "Kleibergen-Paap F" "N") fmt(0   %12.3f %12.3f %12.0f %9.0gc))
	mgroups( "day 1" "day 2" ,	
			 pattern(1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) 
			span erepeat(\cmidrule(lr){@span}))
	mlabel(none) star(* .10 ** .05 *** .01) 
	substitute("\multicolumn{4}{l}{\footnotesize Standard errors in parentheses}\\" ""
				"\multicolumn{4}{l}{\footnotesize \sym{*} \(p<.10\), \sym{**} \(p<.05\), \sym{***} \(p<.01\)}\\" "");
#delimit cr	


*==============================================================================*
* Section 7.1 - Percentage of arrests followed by formal investigation
*   Output : Text_section71_investshare_log.tex
*==============================================================================*
cap log close
log using "$path_results/Text_section71_investshare_log.txt", text replace 

tab incident_to_crime if esample_means==1 & action_arrest

cap log close


*==============================================================================*
* Footnote 30 - Missing time on scene test
*   Output : Text_footnote30_log.txt
*==============================================================================*
cap log close
log using "$path_results/Text_footnote30_log.txt", text replace 

ta missing_hh_resptime_min  if esample_means==1
xi:ivreghdfe Slsaohh_resptime_minw95_dvcallh missing_hh_resptime_min  if esample_means==1, absorb ($x2d) cluster(clustvar)
su Slsaohh_resptime_minw95_dvcallh if esample_means==1

cap log close

*==============================================================================*
* Section 8 — Never taker repeats
*   The estimated never taker repeat probability.
*   Output : Text_section8_nevertaker_log.tex
*==============================================================================*

_pctile lsaocal if esample_means==1, p(99)
return list
scalar define z_h=r(r1) 

qui xi: reghdfe repeatofficers_12callh lsaocal action_arrest if esample_means==1, cluster(clustvar) absorb(ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank)

cap log close
log using "$path_results/Text_section8_nevertaker_log.txt", text replace 

display "NT prob: " _b[_cons]+_b[lsaocal]*z_h

cap log close


*==============================================================================*
* Section 2.1 — British crime survey 
*   The paper states two numbers based on the British Crime Survey in section
*   2.1. To replicate the numbers, download the replication package
*   (https://onlinelibrary.wiley.com/doi/abs/10.1111/ecoj.12246), obtain survey
*   access, run the code in „BCS2005_EJ.do" and „Dataset_Final_EJ.do", and place
*   "Analysis_Final_EJ.dta" in the Rawdata folder. Then run the below code.
*   Output : Text_section21_log.txt
*==============================================================================*
 
preserve 
use "$path_raw/Analysis_Final_EJ.dta", clear
cap log close
log using "$path_results/Text_section21_log.txt", text replace 
gen any=0
replace any=1 if physical12==1 | nonphysical12==1
tab any if bcsyear!=2011
tab any if bcsyear!=2011 & pfa==6
cap log close
restore
 


di as result "02_analysis.do complete."
