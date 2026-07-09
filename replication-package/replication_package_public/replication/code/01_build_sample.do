*==============================================================================*
* 01_build_sample.do
*
*   Builds the case-level estimation dataset for
*   "Deterrence or Backlash? Arrests and the Dynamics of Domestic Violence".
*
*   INPUT  : raw .dta files in $path_raw (set by master.do)
*   OUTPUT : $path_est/Main_est.dta  (case-level DV sample with
*            the team-arrest-propensity instrument and repeat-victimization
*            measures), plus intermediate files in $path_tempdata.
*
*
*   Run via master.do (which sets $path_raw etc.). If run standalone, define
*   the path globals first.
*
*   OVERVIEW (top to bottom):
*     1. Build Officer-crime level dataset: construct time variables and DV 
*        classifications by call handlers and officers including all crimes
*     2. Build DV case dataset: merge caller status; officer characteristics
*        and, and investigation database with charge outcomes
*     3. Add geography info: ward assignment to geolocation 
*	  4. Call handler data: define call grade, time identifier,  call-handler 
*        attributes
*     5. Data cleaning: duplicate handling Dispatch/arrival/leave times 
*        construction, imputation
*     6. Instrument construction: team arrest propensity (leave-one-out and
*        leave-same-address-out), alternative weightings, clustering IDs.
*        The program "DV" (defined below) builds one instrument-prep file per
*        DV-definition/subsample; it is then called for each definition used, 
*        and then merged into main file
*     7. Repeat-victimization measures (geo-location based, plus official
*        victim ID for validation).
*     8. Final data preparations: Bank-holiday calendar merge; final sample 
*        restrictions; save Main_est.dta.
*==============================================================================*

if "$path_raw" == "" {
    di as error "Path globals not set. Run this file via master.do."
    exit 198
}

*Preamble
cap n clear all
cap n clear matrix
cap n set maxvar 32767
cap n set matsize 11000
cap n set max_memory .
cap n set more off, permanently
cap n set checksum off, permanently
cap n set type double, permanently

set scheme s1mono, permanently

************************************
*1 Build Officer-crime level dataset 
************************************

use "$path_raw/res_crimes_new2.dta", clear  

//define time variables
split incident_date, p(" ")
split incident_date1, p("/")

foreach var of varlist incident_date11 incident_date12 incident_date13 {
destring `var', replace
}

split incident_time, p(" ")
split incident_time1, p(":")

foreach var of varlist incident_time11 incident_time12 incident_time13 {
destring `var', replace
}

gen incident_date_time=mdyhms(incident_date12,incident_date11 ,incident_date13 , incident_time11, incident_time12, incident_time13)
format %tc incident_date_time

drop incident_date1 incident_date2 incident_date11 incident_date12 incident_date13 incident_time1 incident_time11 incident_time12 incident_time13 incident_time incident_date

gen inc_date=mdy(month(dofc(incident_date_time)), day(dofc(incident_date_time)), year(dofc(incident_date_time)))
format %td inc_date

gen year = year(dofc(incident_date_time))
replace year = 2015 if int_ref_number==25213311 | int_ref_number==25213508  

//Merge with warks file to obtain crime type and geo coordinates
merge m:1 int_ref_number using "$path_raw/warks1019_new.dta", keepusing (osgr initial_classification final_classification qualifier)
drop if _merge!=3  
drop _merge
drop if osgr ==.

format osgr %12.0f
tostring osgr, gen(osgr_) usedisplayformat force
gen eastings = real(substr(osgr_, 1, 6))
gen northings = real(substr(osgr_, -6, .))
ren osgr_ eastnorth

//Classify DV

//Classified by call handler
cap drop temp 
gen temp = strpos(initial_classification, "DOMESTIC") 
gen dvcallh = 0
replace dvcallh = 1 if temp>0
replace dvcallh = 0 if strpos(initial_classification, "DOMESTICATED")

//Classified by officers
cap drop domestic_qualifier
gen domestic_qualifier = strpos(qualifier, "DOMESTIC")  
gen dvfinal = strpos(final_classification, "DOMESTIC") 
cap drop dvofficers
gen dvofficers = 0
replace dvofficers = 1 if (dvfinal==1 | domestic_qualifier>0)

gen callhORoff = 0
replace callhORoff = 1 if dvofficers==1 | dvcallh==1

//Save intermediate officer-crime level data for later use 
save "$path_tempdata/allcrimes_officerlevel.dta", replace


************************
*2 Build DV case dataset
************************

//Continute with DV cases only
keep if callhORoff==1 


//Merge with caller file to obtain caller status
merge m:1 int_ref_number using "$path_raw/caller1017.dta", keepusing (caller_status)
drop if _merge==2 
drop _merge

//add officer characteristics 
merge m:1 officer_collar_anon using "$path_raw/police_char_dec18.dta", keepusing(age sex years_service)
drop if _merge==2 
cap drop _merge

//merge investigation data
rename crime_number crimenumber
merge m:1 crimenumber using "$path_raw/crimes_201019_new.dta", keepusing (vict_nominalrefurn1  vict_cuc_code)
rename crimenumber crime_number
drop if _merge==2
cap drop _merge


//Outcomes for charge and investigation
gen crime_charge = (vict_cuc_code== 17 | vict_cuc_code==50 | vict_cuc_code==72 | vict_cuc_code==51 | vict_cuc_code==72 | vict_cuc_code==76)

cap drop incident_to_crime
gen incident_to_crime=(crime_number!="")
label var incident_to_crime "=1 Investigation"

*********************
*3 Add geography info
*********************
//Merge ward identifier 
merge m:1 eastnorth using "$path_raw/wards_matched_IV.dta", keepusing(ward_name) 
ren ward_name ward
drop if _merge==2
cap drop _merge


//Ward population 
merge m:1 ward using "$path_raw/wards_population.dta", keepusing(ward_pop2011)
drop if _merge==2
cap drop _merge



//Ward housing composition (NOMIS, 2011) 
merge m:1 ward using "$path_raw/ward_housingtype.dta"
drop if _merge==2
drop _merge

encode ward, gen (ward_)

*********************
*4 Call handler data
*********************

//Call Grade
gen call_grade=. 
replace call_grade=1 if gradedresponse=="P1 IMMEDIATE" | gradedresponse=="IMMEDIATE" 
replace call_grade=2 if gradedresponse=="EARLY" | gradedresponse=="EARLY RESPONSE" | gradedresponse=="P2 PRIORITY RESP"
replace call_grade=3 if  gradedresponse=="P3 PRIORITY INV"
replace call_grade=4 if gradedresponse=="P4 SCHEDULED INV"
replace call_grade=5 if  gradedresponse=="P5 INITIAL INV" | gradedresponse=="P6 NEIGHBOURHOOD" | gradedresponse=="P7 SUPPORT" | gradedresponse=="P8 INTERNAL TASK" | gradedresponse=="P9 CONTACT RESOLUTION" | gradedresponse=="STATION RESOLUTION" | gradedresponse=="APPOINTMENT" 
replace call_grade=6 if gradedresponse=="ROUTINE" | gradedresponse=="DEFERRED" 

//Time identifiers
gen dayofweek = dow(inc_date)
gen month = month(inc_date)
gen hour=hh(incident_date)


//Call handler information
cap drop _merge
merge m:1 int_ref_number using "$path_raw/callh_vars.dta", keepusing(callh_years_service ch_gender call_handlerid)
drop if _merge==2
cap drop _merge

replace callh_years_service = callh_years_service-1 if year==2016
replace callh_years_service = callh_years_service-2 if year==2015
replace callh_years_service = callh_years_service-3 if year==2014
replace callh_years_service = callh_years_service-4 if year==2013
replace callh_years_service = callh_years_service-5 if year==2012
replace callh_years_service = callh_years_service-6 if year==2011
replace callh_years_service = callh_years_service-7 if year==2010

rename callh_years_service callh_experience
rename ch_gender callh_sex

*************************
*5 Data cleaning
*************************

//Preparing time stamps 

global times dispatched_date_time arrived_date_time left_date_time cancelled_date_time

foreach x of global times {    
gen `x'_ = clock(`x', "DMYhms")
drop `x'
rename `x'_ `x'
}

format %tc dispatched_date_time arrived_date_time left_date_time cancelled_date_time

//Check for duplicates
unique int_ref_number 
bysort int_ref_number officer_collar_anon : gen temp_dup= _N
gen disparrleft_missing = (dispatched_date_time==. & arrived_date_time==. & left_date_time ==.)
drop if disparrleft_missing ==1
unique int_ref_number 
*drop officer obs with less info (time stamps) where there is more than one per officer 
cap drop temp_dup
bysort int_ref_number officer_collar_anon : gen temp_dup= _N
gen disparrexists = (dispatched_date_time!=. & arrived_date_time!=.)
sort int_ref_number officer_collar_anon disparrexists dispatched_date_time arrived_date_time
order int_ref_number officer_collar_anon temp_dup disparrexists dispatched_date_time arrived_date_time
bysort int_ref_number officer_collar_anon temp_dup: egen max_temp = max(disparrexists)
order int_ref_number officer_collar_anon temp_dup max_temp disparrexists dispatched_date_time arrived_date_time
drop if temp_dup>1 & max_temp>0 & disparrexists==0 
unique int_ref_number 
*keep officer obs with earliest dispatch time
sort int_ref_number officer_collar_anon dispatched_date_time arrived_date_time left_date_time cancelled_date_time
bysort int_ref_number officer_collar_anon: keep if _n==1 
unique int_ref_number 
isid int_ref_number officer_collar_anon
drop disparrexists temp_dup 


//First response action
cap drop temp
gen temp = strpos(incident_result, "MATCHED WITH")  
replace incident_result= "MATCHED WITH..." if temp==1
drop temp

gen temp= strpos(incident_result, "WARNING INCOMPLETE")  
replace incident_result= "WARNING INCOMPLETE INCIDENT" if temp==1
drop temp

gen action_arrest=(incident_result=="ARREST")

//Number of calls from same location, Tag top 0.1% of victims by number of calls at the same location
preserve
bysort int_ref_number: keep if _n==1
bysort eastings northings: gen nr_calls_samegeo = _N 
bysort eastings northings: keep if _n==1
egen nrcalls_top01 = pctile(nr_calls_samegeo),p(99.9)
tempfile myfile
save `myfile'
restore
cap drop _merge
merge m:1 eastings northings using "`myfile.dta'", keepusing(nr_calls_samegeo  nrcalls_top01)

gen top01_nrcalls = (nr_calls_samegeo>=nrcalls_top01)
 
// Save intermediate case-officer level DV dataset 
save "$path_tempdata/DV_officerlevel_merged.dta", replace




*************************************
*6 Instrument construction 
*************************************

use "$path_tempdata/DV_officerlevel_merged.dta", clear 
 

//Duplicate for response time measures
gen arrived_date_time2 = arrived_date_time

// Dispatch duration
bysort int_ref_number: gen incidentcreation_dur= dispatched_date_time-incident_date
format incidentcreation_dur %tc

gen hour2=hh(incidentcreation_dur)
gen aa=hour2*60
gen minutes=mm(incidentcreation_dur)
gen seconds=ss(incidentcreation_dur)
gen bb=seconds/60

gen incidentcreation_dur_min= aa+ minutes +bb
label var incidentcreation_dur_min "Duration of incident to dispatch time-min"

drop hour2 aa minutes seconds bb 

//Variabless for reverse sample IV 
gen dvc_12=dvcallh if gradedresponse=="P1 IMMEDIATE" | gradedresponse=="IMMEDIATE"  | gradedresponse=="EARLY" | gradedresponse=="EARLY RESPONSE" | gradedresponse=="P2 PRIORITY RESP"

gen day_call = .
replace day_call= 1 if (hour <= 17 & hour >= 6)
gen dvcday1=dvcallh if day_call==1
gen dvcday0=dvcallh if day_call==.
drop day_call

egen victim_id= group(osgr)
preserve
keep if dvcallh==1
sort int_ref_number incident_date_time
bysort int_ref_number: keep if _n==1
sort victim_id incident_date_time
bysort victim_id: gen nr_incident = _n
tempfile myfile
save `myfile'
restore
cap drop _merge
merge m:1 int_ref_number using "`myfile.dta'", keepusing(nr_incident)
gen dvcfvc1=dvcallh if nr_incident==1
gen dvcfvc0=dvcallh if nr_incident!=1
drop nr_incident victim_id

//DV hotspots
bysort ward: gen sum_dvcallsbyward = _N
gen wardcalls_perpop = sum_dvcallsbyward/ward_pop
preserve
	drop if ward ==""
	bysort ward: keep if _n==1
	sum wardcalls_perpop, detail
	loc mymedian = `r(p75)'
restore
gen med_wardcalls_perpop = `mymedian'
gen d_abovemedcalls = 0
replace d_abovemedcalls = 1 if wardcalls_perpop>med_wardcalls_perpop
gen dvchot1=dvcallh if d_abovemedcalls==1
gen dvchot0=dvcallh if d_abovemedcalls==0
drop d_abovemedcalls sum_dvcallsbyward ward_pop


//Mark inconsistent time stamps
cap drop flag_incon_disparr1
gen flag_incon_disparr1 = 0
replace flag_incon_disparr1 = 1 if dispatched_date_time< incident_date_time & dispatched_date_time !=.

cap drop flag_incon_disparr2
gen flag_incon_disparr2 = 0
replace flag_incon_disparr2 = 1 if dispatched_date_time> arrived_date_time & (dispatched_date_time!=. & arrived_date_time!=.) 

cap drop flag_incon_disparr3
gen flag_incon_disparr3 = 0
replace flag_incon_disparr3 = 1 if arrived_date_time< incident_date_time & (arrived_date_time!=.  & incident_date_time!=.) 

cap drop inconsistent_flag
gen inconsistent_flag = 0
replace inconsistent_flag= 1 if flag_incon_disparr1==1 | flag_incon_disparr2 ==1 | flag_incon_disparr3 ==1 


// Construct / Impute arrival times

//dispatched with someone else
missings report arrived_date_time 

sort int_ref_number dispatched_date_time arrived_date_time left_date_time officer_collar_anon
bysort int_ref_number (dispatched_date_time arrived_date_time): replace arrived_date_time = arrived_date_time[_n-1] if mi(arrived_date_time) & !mi(dispatched_date_time[_n-1]) & !mi(arrived_date_time[_n-1]) & (dispatched_date_time==dispatched_date_time[_n-1]) 

missings report arrived_date_time 

//all dispatched at the same time 

//Dummy for at least one misses disp time
sort int_ref_number dispatched_date_time
cap drop temp
gen temp= 0
replace temp = 1 if dispatched_date_time==.
bys int_ref_number: egen atleastone_missdisp = max(temp)
order int_ref_number officer_collar_anon dispatched_date_time arrived_date_time atleastone_missdisp left_date_time 

//Dummy for all have the same dispatch time
sort int_ref_number dispatched_date_time officer_collar_anon
bysort int_ref_number: gen all_samedispatch = 1 if  (dispatched_date_time[1] ==dispatched_date_time[_N]) & atleastone_missdisp==0
order int_ref_number officer_collar_anon dispatched_date_time arrived_date_time atleastone_missdisp left_date_time all_samedispatch

//Construct arrival time
cap drop imputed_arrivaltime2
gen imputed_arrivaltime2 = dispatched_date_time +msofhours(1)
format imputed_arrivaltime2 %tc


replace arrived_date_time = imputed_arrivaltime2 if (arrived_date_time==. & all_samedispatch==1) 
missings report arrived_date_time 
drop imputed_arrivaltime2

//same left time
sort int_ref_number left_date_time arrived_date_time officer_collar_anon
cap drop temp
bysort int_ref_number (left_date_time arrived_date_time): gen temp=1 if mi(arrived_date_time) & !mi(left_date_time[_n-1]) & !mi(arrived_date_time[_n-1])& (left_date_time==left_date_time[_n-1])
order int_ref_number dispatched_date_time arrived_date_time left_date_time temp
bysort int_ref_number (left_date_time arrived_date_time): replace arrived_date_time = arrived_date_time[_n-1] if mi(arrived_date_time) & !mi(arrived_date_time[_n-1])& !mi(left_date_time[_n-1]) & (left_date_time==left_date_time[_n-1]) 
missings report arrived_date_time 


//Minimum arrival time among officers that didnt cancel and have consistent time stamps

*true cancels (dispatch, missing arrival, cancel time)---(cancel + arrival time means left early)
gen true_cancel= 0
replace true_cancel=1 if arrived_date_time==. & cancelled_date_time!=.

cap drop min_arrivaltime
preserve
	keep if inconsistent_flag==0 & true_cancel==0
	bysort int_ref_number: egen min_arrivaltime = min(arrived_date_time) 
	bysort int_ref_number: keep if _n==1
		tempfile myfile
	save `myfile'
restore
merge m:1 int_ref_number using "`myfile.dta'",  nogen keepusing(min_arrivaltime)

//Construct missing left times


//dispatched with someone else
missings report left_date_time 

sort int_ref_number dispatched_date_time arrived_date_time left_date_time officer_collar_anon
bysort int_ref_number (dispatched_date_time left_date_time): replace left_date_time = left_date_time[_n-1] if mi(left_date_time) & !mi(dispatched_date_time[_n-1]) & !mi(left_date_time[_n-1]) & (dispatched_date_time==dispatched_date_time[_n-1]) 

missings report left_date_time 

//arrived with someone else

sort int_ref_number dispatched_date_time arrived_date_time left_date_time officer_collar_anon
bysort int_ref_number (arrived_date_time left_date_time): replace left_date_time = left_date_time[_n-1] if mi(left_date_time) & !mi(arrived_date_time[_n-1]) & !mi(arrived_date_time[_n-1]) & (arrived_date_time==arrived_date_time[_n-1]) 

missings report left_date_time 

cap drop max_lefttime
preserve
	keep if inconsistent_flag==0 & true_cancel==0 
	bysort int_ref_number: egen max_lefttime = max(left_date_time), missing 
	bysort int_ref_number: keep if _n==1
		tempfile myfile
	save `myfile'
restore
merge m:1 int_ref_number using "`myfile.dta'",  nogen keepusing(max_lefttime)

//Define cases that we keep even though arrival times are partly missing


//Define latest dispatch among those with non-missing arrival times
//include true cancels (dispatched but cancel then without arriving) 
preserve
keep if (arrived_date_time!=. | true_cancel==1) & (dispatched_date_time< min_arrivaltime)
bysort int_ref_number: egen max_dispatch = max(dispatched_date_time) 
bysort int_ref_number: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 int_ref_number using "`myfile.dta'",  nogen keepusing(max_dispatch)

//Scenario 1: drop case (=set min. arrival time to missing) if any officer was dispatched before latest dispatch (among those with non-missing arrival times)
cap drop temp
gen dispatched_prior_lar =0
replace dispatched_prior_lar = 1 if arrived_date_time ==. & true_cancel==0 & (dispatched_date_time< max_dispatch)
bysort int_ref_number: egen temp = max(dispatched_prior_lar)
gen scenario1 = (temp>0)

format %tc min_arrivaltime
order int_ref_number min_arrivaltime dispatched_date_time max_dispatch arrived_date_time cancelled_date_time true_cancel temp scenario1

replace min_arrivaltime =. if scenario1==1 

unique int_ref_number 
unique int_ref_number if min_arrivaltime!=. 

//Scenario 2: dispatch > latest dispatch & dipatch < min.arrival
cap drop temp
gen dispatch_betw_ldminarr = 0
replace dispatch_betw_ldminarr = 1 if arrived_date_time == . & true_cancel==0 & (dispatched_date_time > max_dispatch) & (dispatched_date_time < min_arrivaltime)
bysort int_ref_number: egen temp = total(dispatch_betw_ldminarr)
tab temp 
drop temp

unique int_ref_number 
unique int_ref_number if min_arrivaltime!=. 

//Construct missing dispatch times 

missings report dispatched_date_time 

//Keep officers with minimum arrival time even though dispatched time is missing
format min_arrivaltime %tc
cap drop imputed1
gen imputed1 = 0 
replace imputed1 = 1 if (dispatched_date_time==. & arrived_date_time!=.) & (arrived_date_time == min_arrivaltime) 
replace imputed1 = . if min_arrivaltime==. 

order int_ref_number incident_date_time dispatched_date_time arrived_date_time min_arrivaltime imputed1 

cap drop imputed_dispatchedtime1
gen imputed_dispatchedtime1 = incident_date_time
replace dispatched_date_time = imputed_dispatchedtime1 if imputed1==1 
format imputed_dispatchedtime1 %tc
drop imputed_dispatchedtime1

missings report dispatched_date_time 

//Keep officers that arrived with someone else and have a missing dispatched time

sort int_ref_number arrived_date_time dispatched_date_time left_date_time officer_collar_anon
bysort int_ref_number (arrived_date_time dispatched_date_time): replace dispatched_date_time = dispatched_date_time[_n-1] if mi(dispatched_date_time) & !mi(arrived_date_time[_n-1]) & (arrived_date_time==arrived_date_time[_n-1]) 

missings report dispatched_date_time 


//Drop cases that cannot be used for stringency variable

unique int_ref_number 
unique int_ref_number if min_arrivaltime!=. 

// drop case if one of the officers still misses dispatched time 
cap drop 
gen flag_missingdisp_afterimp = 0
replace flag_missingdisp_afterimp = 1 if  dispatched_date_time==.   

bysort int_ref_number: egen max_missdisp = max(flag_missingdisp_afterimp)
gen flag_dropcase = 0
replace flag_dropcase = 1 if max_missdisp>0 

drop if flag_dropcase==1 

unique int_ref_number
unique int_ref_number if min_arrivaltime!=. 

//Drop cases where at least one of the officers has inconsistent time stamps
bysort int_ref_number: egen max_inconsistent = max(inconsistent_flag)
bysort int_ref_number:gen flag_dropcase2 = 0
bysort int_ref_number:replace flag_dropcase2 = 1 if max_inconsistent>0 

drop if flag_dropcase2==1 


// Drop cases where staff on duty called
drop if caller_status =="STAFF ON DUTY" 

unique int_ref_number 
unique int_ref_number if min_arrivaltime!=. 

//Keep officers that are dispatched before first arrival
cap drop temp
gen temp=0
replace temp = 1 if dispatched_date_time < min_arrivaltime
replace temp =. if min_arrivaltime==.
order int_ref_number officer_collar_anon dispatched_date_time arrived_date_time min_arrivaltime temp

bysort int_ref_number: keep if temp==1 

unique int_ref_number 
unique int_ref_number if min_arrivaltime!=. 

//Variables for stringency
gen strict_action1= 0
replace strict_action1 =1 if incident_result =="ARREST"
replace strict_action1=. if incident_result==""

gen rep_crime= 0
replace rep_crime =1 if incident_result =="REPORT - CRIME" 
replace rep_crime=. if incident_result=="" 
gen rep_submit= 0
replace rep_submit =1 if incident_result =="REPORT SUBMITTED" 
replace rep_submit=. if incident_result=="" 
gen report= 0
replace report =1 if incident_result =="REPORT SUBMITTED" 
replace report =1 if incident_result =="REPORT - CRIME" 
replace report =1 if incident_result =="REPORT FOR PROCESS" 
replace report=. if incident_result=="" 
gen advice= 0
replace advice =1 if incident_result =="ADVICE GIVEN" 
replace advice=. if incident_result=="" 

gen nonaction=1
replace nonaction=0 if strict_action1==1
replace nonaction=0 if report==1
replace nonaction=0 if advice==1 


//construct missing arrival times


//dispatched with someone else

sort int_ref_number dispatched_date_time arrived_date_time2 left_date_time officer_collar_anon
bysort int_ref_number (dispatched_date_time arrived_date_time): replace arrived_date_time2 = arrived_date_time2[_n-1] if mi(arrived_date_time2) & !mi(dispatched_date_time[_n-1]) & !mi(arrived_date_time2[_n-1]) & (dispatched_date_time==dispatched_date_time[_n-1]) 

missings report arrived_date_time2 

//Same left time
sort int_ref_number left_date_time arrived_date_time2 officer_collar_anon
cap drop temp
bysort int_ref_number (left_date_time arrived_date_time2): gen temp=1 if mi(arrived_date_time2) & !mi(left_date_time[_n-1]) & !mi(arrived_date_time2[_n-1])& (left_date_time==left_date_time[_n-1])
order int_ref_number dispatched_date_time arrived_date_time2 left_date_time temp
bysort int_ref_number (left_date_time arrived_date_time2): replace arrived_date_time2 = arrived_date_time2[_n-1] if mi(arrived_date_time2) & !mi(arrived_date_time2[_n-1])& !mi(left_date_time[_n-1]) & (left_date_time==left_date_time[_n-1]) 
missings report arrived_date_time2 

*Construct missing left times

//dispatched with someone else
missings report left_date_time 

sort int_ref_number dispatched_date_time arrived_date_time2 left_date_time officer_collar_anon
bysort int_ref_number (dispatched_date_time left_date_time): replace left_date_time = left_date_time[_n-1] if mi(left_date_time) & !mi(dispatched_date_time[_n-1]) & !mi(left_date_time[_n-1]) & (dispatched_date_time==dispatched_date_time[_n-1]) 
missings report left_date_time 

//arrived with someone else
sort int_ref_number dispatched_date_time arrived_date_time2 left_date_time officer_collar_anon
bysort int_ref_number (arrived_date_time2 left_date_time): replace left_date_time = left_date_time[_n-1] if mi(left_date_time) & !mi(arrived_date_time2[_n-1]) & !mi(arrived_date_time2[_n-1]) & (arrived_date_time2==arrived_date_time2[_n-1]) 

missings report left_date_time 

//response duration


//Version 1: first arrival until last left (ignore officers that cancelled)

//earliest arrival
cap drop first_arrived
preserve
	keep if true_cancel==0
	bysort int_ref_number: egen first_arrived = min(arrived_date_time2) 
	bysort int_ref_number: keep if _n==1
		tempfile myfile
	save `myfile'
restore
merge m:1 int_ref_number using "`myfile.dta'",  nogen keepusing(first_arrived)

//latest leave time
cap drop last_left
preserve
	keep if true_cancel==0
	bysort int_ref_number: egen last_left = max(left_date_time) 
	bysort int_ref_number: keep if _n==1
		tempfile myfile
	save `myfile'
restore
merge m:1 int_ref_number using "`myfile.dta'",  nogen keepusing(last_left)

gen hh_resp_time= last_left-first_arrived 
gen hour2=hh(hh_resp_time)
gen aa=hour2*60
gen minutes=mm(hh_resp_time)
gen seconds=ss(hh_resp_time)
gen bb=seconds/60
gen hh_resptime_min= aa+ minutes +bb
label var hh_resptime_min "Duration of time on scene, first arrived to last left"
drop hour2 aa minutes seconds bb hh_resp_time 

//Mean imputation

//save non-imputed variable

preserve
bysort int_ref_number: keep if _n ==1
egen mean_hh_resptime_min= mean(hh_resptime_min)
	tempfile myfile
	save `myfile'
restore
merge m:1 int_ref_number using "`myfile.dta'",  nogen keepusing(mean_hh_resptime_min)

gen missing_hh_resptime_min = 0
replace missing_hh_resptime_min = 1 if hh_resptime_min==.
replace hh_resptime_min = mean_hh_resptime_min if hh_resptime_min ==.

//Winsorize time vars
centile hh_resptime_min, c(99 98 95 90)
gen hh_resptime_minc95=r(c_3) 
 
gen hh_resptime_minw95 = hh_resptime_min
replace hh_resptime_minw95 = hh_resptime_minc95 if hh_resptime_minw95>hh_resptime_minc95
 
//Merge police officer characteristics

drop _merge
merge m:1 officer_collar_anon using "$path_raw/police_char_dec18.dta", keepusing(age sex years_service)
drop if _merge==2
drop _merge
drop temp

gen years_service_= round(years_service, 1)

egen victim_id= group(osgr)

//Drop victims that have top 0.1% number of calls

drop if top01_nrcalls==1 

//Dummies for ranks and dispatched officers

save "$path_tempdata/DVsampleIV_dataprep.dta", replace

// 
//Calculate Team Stringency
//

 

clear all
cap program drop DV 
program define DV 
args DV_var 

use "$path_tempdata/DVsampleIV_dataprep.dta", clear
keep if `DV_var'  == 1

/////////////////////////////////////
// CALCULATE STRINGENCY IN RESP TEAM
/////////////////////////////////////

//Count cases by officers



bysort officer_collar_anon: egen DVcases_off3 = count(int_ref_number)
replace DVcases_off3 = 0 if DVcases_off3==.
rename DVcases_off3 DVcases_officer3


// Count arrests

preserve 
	keep if strict_action1==1
	bysort officer_collar_anon: egen DVstrict1cases_off3 = count(int_ref_number)
	bysort officer_collar_anon: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon using "`myfile.dta'",  nogen keepusing(DVstrict1cases_off3)
replace DVstrict1cases_off3 = 0 if DVstrict1cases_off3 == .

rename DVstrict1cases_off3 DVstrict1cases_officer3

gen invest = incident_to_crime 

foreach altiv in nonaction   rep_crime rep_submit report advice invest crime_charge{ 
preserve 
	keep if `altiv'==1
	bysort officer_collar_anon: egen altiv`altiv'_off3 = count(int_ref_number)
	bysort officer_collar_anon: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon using "`myfile.dta'",  nogen keepusing(altiv`altiv'_off3)
replace altiv`altiv'_off3 = 0 if altiv`altiv'_off3 == .

rename altiv`altiv'_off3 altiv`altiv'_officer3
}
 
//For the case of continous variables.
 
foreach altiv2 of varlist hh_resptim*_minw* { 
	
preserve 
	keep if `altiv2'!=.
	bysort officer_collar_anon: egen altiv`altiv2'_off3 = sum(`altiv2')
	bysort officer_collar_anon: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon using "`myfile.dta'",  nogen keepusing(altiv`altiv2'_off3)

//Use number of DV cases where time is not missing
preserve
keep if `altiv2' !=.
bysort officer_collar_anon: egen DVcasesT_`altiv2' = count(int_ref_number)
replace DVcasesT_`altiv2'  = 0 if DVcasesT_`altiv2' ==.
	bysort officer_collar_anon: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon using "`myfile.dta'",  nogen keepusing(DVcasesT_`altiv2')

}

unique int_ref_number

bysort officer_collar_anon: keep if _n==1
save "$path_tempdata/temp.dta", replace

*Counts for officer-victim encounters
use "$path_tempdata/DVsampleIV_dataprep.dta", clear

keep if `DV_var'  == 1
drop if osgr==. 
 
bysort officer_collar_anon victim_id: gen offvic_combis= _N

cap drop offvic_arrests
preserve
keep if strict_action1==1
bysort officer_collar_anon victim_id : gen offvic_arrests= _N
bysort officer_collar_anon victim_id: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon victim_id using "`myfile.dta'",  nogen keepusing(offvic_arrests)
replace offvic_arrests = 0 if offvic_arrests==.

preserve
keep if report==1
bysort officer_collar_anon victim_id : gen offvic_report= _N
bysort officer_collar_anon victim_id: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon victim_id using "`myfile.dta'",  nogen keepusing(offvic_report)
replace offvic_report = 0 if offvic_report==.

preserve
keep if advice==1
bysort officer_collar_anon victim_id : gen offvic_advice= _N
bysort officer_collar_anon victim_id: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon victim_id using "`myfile.dta'",  nogen keepusing(offvic_advice)
replace offvic_advice = 0 if offvic_advice==.

preserve
keep if nonaction==1
bysort officer_collar_anon victim_id : gen offvic_nonaction= _N
bysort officer_collar_anon victim_id: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon victim_id using "`myfile.dta'",  nogen keepusing(offvic_nonaction)
replace offvic_nonaction= 0 if offvic_nonaction==.

preserve
keep if crime_charge==1
bysort officer_collar_anon victim_id : gen offvic_charge= _N
bysort officer_collar_anon victim_id: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon victim_id using "`myfile.dta'",  nogen keepusing(offvic_charge)
replace offvic_charge = 0 if offvic_charge==.

preserve
keep if incident_to_crime==1
bysort officer_collar_anon victim_id : gen offvic_invest= _N
bysort officer_collar_anon victim_id: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon victim_id using "`myfile.dta'",  nogen keepusing(offvic_invest)
replace offvic_invest = 0 if offvic_invest==.

//sum time for each officer spent with victim 
foreach altiv2 of varlist hh_resptim*_minw*   { 

preserve
bysort officer_collar_anon victim_id : egen `altiv2'_offvic = total(`altiv2')
bysort officer_collar_anon victim_id: keep if _n==1
	tempfile myfile
	save `myfile'
restore
merge m:1 officer_collar_anon victim_id using "`myfile.dta'",  nogen keepusing(`altiv2'_offvic)
replace `altiv2'_offvic = 0 if `altiv2'_offvic==.

}

bysort officer_collar_anon victim_id: keep if _n==1
save "$path_tempdata/temp2.dta", replace

//Merge all counts
use "$path_tempdata/DVsampleIV_dataprep.dta", clear
cap drop _merge
merge m:1 officer_collar_anon using "$path_tempdata/temp.dta", nogen
replace DVstrict1cases_officer3 = 0 if DVstrict1cases_officer3 ==.
replace DVcases_officer3 = 0 if DVcases_officer3 ==.
recode altiv* (.=0)

cap drop _merge
merge m:1 officer_collar_anon victim_id using "$path_tempdata/temp2.dta", nogen 

replace offvic_arrests=0 if offvic_arrests==.
replace offvic_combis=0 if offvic_combis==. 
replace offvic_report=0 if offvic_report==.  
replace offvic_advice=0 if offvic_advice==.  
replace offvic_charge=0 if offvic_charge==.  
replace offvic_invest=0 if offvic_invest==.  

//nr of officers
bysort int_ref_number: gen nr_officers = _N


cap drop Teamarrests Teamcas
bysort int_ref_number: egen help_Teamarrests = total(DVstrict1cases_officer3)
gen Teamarrests = help_Teamarrests
bysort int_ref_number: egen help_Teamcas = total(DVcases_officer3)
gen Teamcas= help_Teamcas 
drop help_Teamarrests help_Teamcas


//Instrument leave-one-out

gen Teamarrests_loo_`DV_var' = Teamarrests 
replace Teamarrests_loo_`DV_var'= Teamarrests - nr_officers if (`DV_var'==1 & strict_action1==1)

gen Teamcas_loo_`DV_var'= Teamcas 
replace Teamcas_loo_`DV_var'= Teamcas - nr_officers if (`DV_var'==1)

cap drop Teamstr_loo_`DV_var'
gen Teamstr_loo_`DV_var' = Teamarrests_loo_`DV_var'/Teamcas_loo_`DV_var'
drop Teamarrests_loo_`DV_var'

foreach altiv in nonaction   rep_crime rep_submit report advice {   
cap drop Team`altiv'
bysort int_ref_number: egen help_Team`altiv' = total(altiv`altiv'_officer3)
gen Team`altiv' = help_Team`altiv'
replace Team`altiv' = help_Team`altiv' - nr_officers if (`DV_var'==1 & `altiv'==1)
cap drop Team`altiv'_`DV_var'
bysort int_ref_number: gen Team`altiv'_loo_`DV_var' = Team`altiv'/Teamcas_loo_`DV_var'
}

foreach altiv2 in   hh_resptime_minw95     {   
cap drop Team`altiv2'
bysort int_ref_number: egen help_Team`altiv2'time = total(altiv`altiv2'_off3)
gen Team`altiv2'time = help_Team`altiv2'time 
replace Team`altiv2'time = help_Team`altiv2'time - (nr_officers*`altiv2') if `DV_var'==1 & `altiv2'!=.

bysort int_ref_number: egen helpT`altiv2'cases = total(DVcasesT_`altiv2')
gen Team`altiv2'cases = helpT`altiv2'cases
replace Team`altiv2'cases = helpT`altiv2'cases - nr_officers if `DV_var'==1 & `altiv2'!=.

bysort int_ref_number: gen Team`altiv2' = Team`altiv2'time/Team`altiv2'cases
gen T`altiv2'_loo_`DV_var' = Team`altiv2'
gen T`altiv2'cloo_`DV_var'=Team`altiv2'cases 
}

//Instrument leave-same-address-out

bysort int_ref_number: egen team_offvic_combis = total(offvic_combis)
bysort int_ref_number: egen team_offvic_arrests = total(offvic_arrests)
gen Teamarrests_lsao_`DV_var' = Teamarrests - team_offvic_arrests
gen Teamcas_lsao_`DV_var'= Teamcas - team_offvic_combis
cap drop Teamstr_lsao_`DV_var'
gen Teamstr_lsao_`DV_var' = Teamarrests_lsao_`DV_var'/Teamcas_lsao_`DV_var'
drop Teamarrests_lsao_`DV_var'

cap drop help_Teamreport
bysort int_ref_number: egen team_offvic_report = total(offvic_report)
bysort int_ref_number: egen help_Teamreport = total(altivreport_officer3)
gen Teamreport_lsao_`DV_var' = help_Teamreport - team_offvic_report
gen Tstrreport_lsao_`DV_var' = Teamreport_lsao_`DV_var'/Teamcas_lsao_`DV_var'
drop Teamreport_lsao_`DV_var' help_Teamreport 

cap drop help_Teamadvice
bysort int_ref_number: egen team_offvic_advice = total(offvic_advice)
bysort int_ref_number: egen help_Teamadvice = total(altivadvice_officer3)
gen Teamadvice_lsao_`DV_var' = help_Teamadvice - team_offvic_advice
gen Tstradvice_lsao_`DV_var' = Teamadvice_lsao_`DV_var'/Teamcas_lsao_`DV_var'
drop Teamadvice_lsao_`DV_var' help_Teamadvice

cap drop help_Teamnonaction
bysort int_ref_number: egen team_offvic_nonaction = total(offvic_nonaction)
bysort int_ref_number: egen help_Teamnonaction = total(altivnonaction_officer3)
gen Teamnonaction_lsao_`DV_var' = help_Teamnonaction - team_offvic_nonaction
gen Tstrnonaction_lsao_`DV_var' = Teamnonaction_lsao_`DV_var'/Teamcas_lsao_`DV_var'
drop Teamnonaction_lsao_`DV_var' help_Teamnonaction

	//Same for charge instead of arrest
	bysort int_ref_number: egen team_offvic_charge = total(offvic_charge)
	bysort int_ref_number: egen help_Teamcharge = total(altivcrime_charge_officer3)
	gen Teamcharge_lsao_`DV_var' = help_Teamcharge - team_offvic_charge
	gen Tstrcharge_lsao_`DV_var' = Teamcharge_lsao_`DV_var'/Teamcas_lsao_`DV_var'
	drop Teamcharge_lsao_`DV_var' help_Teamcharge

	//Same for formal investigation instead of arrest
	bysort int_ref_number: egen team_offvic_invest = total(offvic_invest)
	bysort int_ref_number: egen help_Teaminvest = total(altivinvest_officer3)
	gen Teaminvest_lsao_`DV_var' = help_Teaminvest - team_offvic_invest
	gen Tstrinvest_lsao_`DV_var' = Teaminvest_lsao_`DV_var'/Teamcas_lsao_`DV_var'
	drop Teaminvest_lsao_`DV_var' help_Teaminvest

	//Same for time variables  
	foreach altiv2 of varlist   hh_resptime_minw95      {   
	bysort int_ref_number: egen help_All`altiv2' = total(altiv`altiv2'_off3) 
	bysort int_ref_number: egen hA`altiv2'_ov = total(`altiv2'_offvic)
	gen Tlsao`altiv2'_`DV_var' = help_All`altiv2' - hA`altiv2'_ov
	gen Slsao`altiv2'_`DV_var' = Tlsao`altiv2'_`DV_var'/Teamcas_lsao_`DV_var'
	drop  Tlsao`altiv2'_`DV_var' help_All`altiv2' hA`altiv2'_ov
	}

*IVs with different weighting
gen offcases_lsao=DVcases_officer3-offvic_combis
gen offarrests_lsao=DVstrict1cases_officer3-offvic_arrests
bysort int_ref_number: gen help_offnumb_lsao = _N 
//equal weight all officers
gen equal_weight=1/help_offnumb_lsao
gen equal_string=equal_weight*(offarrests_lsao/offcases_lsao)
bysort int_ref_number: egen Tstr_equal_`DV_var' = total(equal_string)
drop equal_string equal_weight 
//officer with highest arrest propensity
gen offstring=offarrests_lsao/offcases_lsao
bysort int_ref_number: egen Tstr_maxProp_`DV_var'=max(offstring)
drop offstring
//officer with most dv cases
bysort int_ref_number: egen maxcases=max(offcases_lsao)
gen maxoffstring=offarrests_lsao/offcases_lsao if maxcases==offcases_lsao
bysort int_ref_number: egen Tstr_mostDV_`DV_var'=max(maxoffstring)
drop maxoffstring maxcases
 
//Alternative instruments

 
*according to most DV cases
 
bysort int_ref_number(years_service DVcases_officer3 officer_collar_anon): egen max_DV= max(DVcases_officer3)
bysort int_ref_number(years_service DVcases_officer3 officer_collar_anon): gen help_casesmaxDV = DVcases_officer3 if DVcases_officer3 == max_DV
bysort int_ref_number(years_service DVcases_officer3 officer_collar_anon): egen casesmaxDV = max(help_casesmaxDV)
bysort int_ref_number(years_service DVcases_officer3 officer_collar_anon): gen help_arrestmaxDV = DVstrict1cases_officer3 if DVcases_officer3 == max_DV
bysort int_ref_number(years_service DVcases_officer3 officer_collar_anon): egen arrestmaxDV = max(help_arrestmaxDV)

gen cmaxDV_loo_`DV_var' = casesmaxDV
replace cmaxDV_loo_`DV_var' = casesmaxDV - 1 if `DV_var'==1 
gen amaxDV_loo_`DV_var' =arrestmaxDV
replace amaxDV_loo_`DV_var' = amaxDV -1 if `DV_var'==1 & strict_action1==1
gen Str_mostDV_`DV_var' = amaxDV_loo_`DV_var'/cmaxDV_loo_`DV_var'


//Officer with most DV cases among those that are dispatched before first arrives
cap drop max_DVcases_inteam officer_mostDV
bysort int_ref_number: egen max_DVcases_inteam= max(DVcases_officer3)
gen officer_mostDV = officer_collar_anon if DVcases_officer3 == max_DVcases_inteam
sort int_ref_number officer_collar_anon
bysort int_ref_number: replace officer_mostDV = officer_mostDV[_n-1] if _n>1 & officer_mostDV[_n-1]!=""
bysort int_ref_number: replace officer_mostDV = officer_mostDV[_N] 
rename officer_mostDV offmostDV_`DV_var'

*Unique officer team IDs
* 1. Sort so officer‐IDs are in ascending order within each case
sort int_ref_number officer_collar_anon

* 2. Build a "team signature" string by concatenating the sorted officer_collar_anons
by int_ref_number (officer_collar_anon): gen str team_sig = officer_collar_anon         // first officer
by int_ref_number (officer_collar_anon): replace team_sig = team_sig[_n-1] + "," + officer_collar_anon if _n>1

* 3. Mark only the last obs in each case (where team_sig is the full list)
by int_ref_number: gen byte is_last = (_n == _N)

* 4. Generate a grouping code from the full‐team signatures
quietly egen teamcode = group(team_sig) if is_last

* 5. Propagate that code to all officers in the same case
by int_ref_number: egen team_id_`DV_var' = max(teamcode)

* 6. clean up intermediate vars
drop team_sig is_last teamcode

bysort int_ref_number: keep if _n==1
cap drop _merge
save "$path_tempdata/IV_DVsamplecleanedprep_`DV_var'.dta", replace

end

* Build the instrument-prep file for each DV definition / subsample in use:
*   dvcallh = baseline (call-handler DV); hot/fvc/day = hotspot, first-vs-higher-
*   order, and day/night subsamples for the monotonicity checks 
DV dvcallh
DV dvchot1
DV dvchot0
DV dvcfvc1
DV dvcfvc0
DV dvcday1
DV dvcday0
DV dvc_12

//Merge all Data sets

use "$path_tempdata/DVsampleIV_dataprep.dta", clear
merge m:1 officer_collar_anon using "$path_raw/police_char_dec18.dta", keepusing(age sex years_service)
drop if _merge==2
drop _merge
cap drop temp

bysort int_ref_number: egen temp = mean(years_service_)
cap drop temp
bysort int_ref_number: egen temp = max(years_service_)
cap drop temp
bysort int_ref_number: egen temp = min(years_service_)
drop years_service_ years_service temp

gen age_= round(age, 1)
replace age_ = age-1 if year ==2016
replace age_ = age-2 if year ==2015
replace age_ = age-3 if year ==2014
replace age_ = age-4 if year ==2013
replace age_ = age-5 if year ==2012
replace age_ = age-6 if year ==2011
replace age_ = age-7 if year ==2010
bysort int_ref_number: egen temp = mean(age_)
gen r_mean_age=temp 
cap drop temp
bysort int_ref_number: egen temp = max(age_)
cap drop temp
bysort int_ref_number: egen temp = min(age_)
drop age_ age temp

bysort int_ref_number: gen r_nr_officers_involved = _N
bysort int_ref_number: egen female_officers_involved = total(sex)
bysort int_ref_number: gen r_share_females = female_officers_involved/r_nr_officers_involved
bysort int_ref_number: gen r_atleastone_female = 0
bysort int_ref_number: replace r_atleastone_female = 1 if female_officers_involved>0
bysort int_ref_number: replace r_atleastone_female = . if female_officers_involved==.

keep int_ref_number r_*
collapse r_*, by(int_ref_number)
save  "$path_tempdata/DVsampleIVcorrectchars.dta", replace

use "$path_tempdata/IV_DVsamplecleanedprep_dvcallh.dta", clear
rename team_id_dvcallh team_id
merge 1:1 int_ref_number using "$path_tempdata/DVsampleIVcorrectchars.dta", nogen
merge 1:1 int_ref_number using "$path_tempdata/IV_DVsamplecleanedprep_dvchot1.dta", nogen
merge 1:1 int_ref_number using "$path_tempdata/IV_DVsamplecleanedprep_dvchot0.dta", nogen
merge 1:1 int_ref_number using "$path_tempdata/IV_DVsamplecleanedprep_dvcfvc1.dta", nogen
merge 1:1 int_ref_number using "$path_tempdata/IV_DVsamplecleanedprep_dvcfvc0.dta", nogen
merge 1:1 int_ref_number using "$path_tempdata/IV_DVsamplecleanedprep_dvcday1.dta", nogen
merge 1:1 int_ref_number using "$path_tempdata/IV_DVsamplecleanedprep_dvcday0.dta", nogen
merge 1:1 int_ref_number using "$path_tempdata/IV_DVsamplecleanedprep_dvc_12.dta", nogen

cap drop victim_id
save "$path_tempdata/allIVversions_DVsample.dta", replace

***********************
*7 Repeat-victimization
***********************

use "$path_tempdata/DV_officerlevel_merged.dta", clear 

//From officer-case level to case level 
bysort int_ref_number: keep if _n==1 
cap n drop dispatched_date_time arrived_date_time left_date_time cancelled_date_time loc_desc officer_collar_anon

//Keep years 2010-2017 for which we have all files
keep if year <2018 

//Victim ID

egen victim_id= group(osgr)
label var victim_id "id based on geo coordinates"

//Repeat variables

gen severe_case =0
replace severe_case = 1 if call_grade==1

cap drop c_status
gen c_status = 0
replace c_status = 1 if caller_status =="VICTIM"

cap drop repeatofficers_12callh
gen repeatofficers_12callh = 0

cap drop repeat_cstatus
gen repeat_cstatus = .

cap drop repeat_severity
gen repeat_severity = .

cap drop timepyear
gen timepyear = incident_date_time + msofhours(8760)
format %tc timepyear

sort victim_id incident_date_time int_ref_number
forvalues i=1/502{
	if mod(`i',30) == 0 di "Row #`i'"
	qui{
	*repeat
	replace repeatofficers_12callh =1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timepyear) & repeatofficers_12callh==0 & dvofficers[_n+`i']==1
	*caller status of repeat call
	replace repeat_cstatus = c_status[_n+`i'] if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timepyear) & 		repeat_cstatus==. & dvofficers[_n+`i']==1
	*severity of repeat
	replace repeat_severity = severe_case[_n+`i'] if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timepyear) & 		repeat_severity==. & dvofficers[_n+`i']==1
 	}
}

replace repeatofficers_12callh=. if year==2017
replace repeat_cstatus =. if year==2017
replace repeat_severity =. if year==2017
 
//Repeat variable based on official victim IDs

cap drop CRrepeatofficers_12callh
gen CRrepeatofficers_12callh = 0

sort vict_nominalrefurn1 incident_date_time int_ref_number
forvalues i=1/502{
	if mod(`i',30) == 0 di "Row #`i'"
	qui{
	*repeat
	replace CRrepeatofficers_12callh =1 if vict_nominalrefurn1== vict_nominalrefurn1[_n+`i'] & (incident_date_time[_n+`i'] <= timepyear) & CRrepeatofficers_12callh==0 & dvofficers[_n+`i']==1
	}
}

replace CRrepeatofficers_12callh =. if vict_nominalrefurn1=="" //only defined for investigation sample
replace CRrepeatofficers_12callh = . if dvcallh ==0 | year ==2017 //repeat variable only defined for call handler classified cases, not defined for year 2017 as no 12 months future period

//Order of victimization
cap drop count_officer 
cap drop prevcases12m_off  

cap drop timeprevyear
gen timeprevyear = incident_date_time - msofhours(8760)
format %tc timeprevyear

gen count_officer= 0
 
sort victim_id incident_date_time int_ref_number
forvalues i=1/502{
	if mod(`i',30) == 0 di "Row #`i'"
	qui{

replace count_officer = count_officer +1 if victim_id== victim_id[_n-`i'] & (incident_date_time[_n-`i'] >= timeprevyear) & dvofficers[_n-`i']==1

	}
}

replace count_officer = . if year ==2010 //previous 12 months not defined
rename count_officer prevcases12m_off

// case actions in previous 12 months
 
gen report= 0
replace report =1 if incident_result =="REPORT SUBMITTED" 
replace report =1 if incident_result =="REPORT - CRIME" 
replace report =1 if incident_result =="REPORT FOR PROCESS" 
replace report=. if incident_result=="" 
gen advice= 0
replace advice =1 if incident_result =="ADVICE GIVEN" 
replace advice=. if incident_result=="" 

sort victim_id incident_date_time int_ref_number
foreach var in action_arrest incident_to_crime    crime_charge  {
	gen prev`var'_off=0
 
forvalues i=1/502{
	if mod(`i',30) == 0 di "Row #`i'"
	qui{
	replace prev`var'_off= prev`var'_off+1 if victim_id== victim_id[_n-`i'] & `var'[_n-`i']==1 & (incident_date_time[_n-`i'] >= timeprevyear) &  dvofficers[_n-`i']==1
	
   }
}
replace prev`var'_off=. if year==2010 
}

save "$path_tempdata/Repeat_temp.dta", replace


//Number of cases within X time of initial case

*within 12 months
*cap drop count_rep_cases12
gen count_rep_cases12 = 0

*cap drop count_rep_cases96h
gen count_rep_cases96h = 0

*cap drop count_rep_cases0to48h
gen count_rep_cases0to48h = 0

*cap drop count_rep_cases49to96h
gen count_rep_cases49to96h = 0
 
*cap drop count_rep_cases6
gen count_rep_cases6 = 0
 
*cap drop count_rep_cases7to12
gen count_rep_cases7to12 = 0

gen count_rep_cases1to3=0
 
gen count_rep_casesmon1=0
 
forvalues day=4(4)12 {
	local prevday=`day'-4
	gen count_rep_casesday`prevday'_to_`day'=0
}

forvalues day=1/2 {
	gen count_rep_casesday`day'=0
}

cap drop timepyear
gen timepyear = incident_date_time + msofhours(8760)
format %tc timepyear

cap drop timep2d
gen timep2d = incident_date_time + msofhours(48)
format %tc timep2d

cap drop timep4d
gen timep4d = incident_date_time + msofhours(96)
format %tc timep4d

forvalues mon=0/12{
cap drop timep`mon'm
gen timep`mon'm = incident_date_time + msofhours(`mon'*730)
format %tc timep`mon'm
}

forvalues day=0/16{
cap drop timep`day'd
gen timep`day'd = incident_date_time + msofhours(`day'*24)
format %tc timep`day'd	
}

sort victim_id incident_date_time int_ref_number
forvalues i=1/502{
	if mod(`i',30) == 0 di "Row #`i'"
	qui{
	
	replace count_rep_cases12 = count_rep_cases12 +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timepyear) & dvofficers[_n+`i']==1
	 
	replace count_rep_cases96h = count_rep_cases96h +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timep4d) & dvofficers[_n+`i']==1

	replace count_rep_cases0to48h = count_rep_cases0to48h +1 if victim_id== victim_id[_n+`i']  & (incident_date_time[_n+`i'] <= timep2d) & dvofficers[_n+`i']==1
	
	replace count_rep_cases49to96h = count_rep_cases49to96h +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] > timep2d) & (incident_date_time[_n+`i'] <= timep4d) & dvofficers[_n+`i']==1
	 
	replace count_rep_cases6 = count_rep_cases6 +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timep6m) & dvofficers[_n+`i']==1

	replace count_rep_cases1to3 = count_rep_cases1to3 +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timep3m) & dvofficers[_n+`i']==1
	
	replace count_rep_cases7to12 = count_rep_cases7to12 +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timepyear) & (incident_date_time[_n+`i'] > timep6m) & dvofficers[_n+`i']==1

replace count_rep_casesmon1=count_rep_casesmon1 +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timep1m) & dvofficers[_n+`i']==1
 
replace count_rep_casesday0_to_4=count_rep_casesday0_to_4 +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timep4d) & dvofficers[_n+`i']==1
forvalues day=8(4)12 {
	local prevday=`day'-4
	replace count_rep_casesday`prevday'_to_`day'=count_rep_casesday`prevday'_to_`day' +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timep`day'd) & (incident_date_time[_n+`i'] > timep`prevday'd) & dvofficers[_n+`i']==1
}

replace count_rep_casesday1=count_rep_casesday1 +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timep1d) & (incident_date_time[_n+`i'] > incident_date_time)  & dvofficers[_n+`i']==1
forvalues day=2/2 {
	local prevday=`day'-1
	replace count_rep_casesday`day'=count_rep_casesday`day' +1 if victim_id== victim_id[_n+`i'] & (incident_date_time[_n+`i'] <= timep`day'd) & (incident_date_time[_n+`i'] > timep`prevday'd) & dvofficers[_n+`i']==1
}
	
	}
}

replace count_rep_cases12=. if year==2017  
replace count_rep_cases6 =. if year==2017 
replace count_rep_cases7to12 =. if year==2017

replace count_rep_cases1to3=. if year==2017
 
replace count_rep_cases96h =. if year==2017
replace count_rep_cases0to48h =. if year==2017
replace count_rep_cases49to96h =. if year==2017

	replace count_rep_casesmon1=. if year==2017
 
forvalues day=4(4)12 {
	local prevday=`day'-4
	replace count_rep_casesday`prevday'_to_`day'=. if year==2017
}

forvalues day=1/2 { 
	replace count_rep_casesday`day'=. if year==2017
}



//Merge stringency variables


cap drop _merge
merge 1:1 int_ref_number using "$path_tempdata/allIVversions_DVsample.dta" 
drop if _merge==2 

//Additional variables


//interacted FE
cap gen hour=hh(incident_date)
egen ward_year = group(ward year)
egen ward_month = group(ward month)
egen ward_dayofweek = group(ward dayofweek)

//Case characteristics
gen callh_sex2 = callh_sex
gen missing_callh_sex=(callh_sex2==.)
qui sum callh_sex2
replace callh_sex2= `r(mean)' if callh_sex2==.

gen callh_experience2 = callh_experience
replace callh_experience2=0 if callh_experience2<0
gen missing_callh_experience=(callh_experience2==.)
qui sum callh_experience2
replace callh_experience2= `r(mean)' if callh_experience2==.

//DV "hotspots" 
cap drop sum_dvcallsbyward
bysort ward: gen sum_dvcallsbyward = _N
cap drop wardcalls_perpop
gen wardcalls_perpop = sum_dvcallsbyward/ward_pop
sum wardcalls_perpop, detail
order ward sum_dvcallsbyward ward_pop

preserve
	bysort ward: keep if _n==1
	sum wardcalls_perpop, detail
	loc mymedian = `r(p75)'
restore

cap drop med_wardcalls_perpop
gen med_wardcalls_perpop = `mymedian'

cap drop d_abovemedcalls
gen d_abovemedcalls = 0
replace d_abovemedcalls = 1 if wardcalls_perpop>med_wardcalls_perpop
tab d_abovemedcalls

//Reporting variables (severity+ caller status of repeat call)

cap drop severe_repeat
gen severe_repeat = 0 
replace severe_repeat = 1 if repeatofficers_12callh==1 & repeat_severity ==1
replace severe_repeat=. if repeatofficers_12callh ==.

cap drop nosevere_repeat
gen nosevere_repeat = 0 
replace nosevere_repeat = 1 if repeatofficers_12callh==1 & repeat_severity ==0
replace nosevere_repeat=. if repeatofficers_12callh ==.

cap drop TRrepeatofficers_12callh
gen TRrepeatofficers_12callh = 0 
replace TRrepeatofficers_12callh = 1 if repeatofficers_12callh==1 & repeat_cstatus ==0
replace TRrepeatofficers_12callh=. if repeatofficers_12callh ==.

cap drop vicrepeatofficers_12callh
gen vicrepeatofficers_12callh = 0 
replace vicrepeatofficers_12callh = 1 if repeatofficers_12callh==1 & repeat_cstatus ==1
replace vicrepeatofficers_12callh=. if repeatofficers_12callh ==.

save "$path_tempdata/Temp_repeatfile.dta", replace


**************************
*8 Final data preparations
**************************


//Holidays

use "$path_raw/datefile.dta", clear

*find date indicators for the beginning and the end of the time frame 
display date("1/1/2010", "DMY") //18263
display date("31/12/2017", "DMY") //21184


*set number of observations 
set obs 2922 //total time frame + 1 day to include 31/12/2017

*generate date indicator
egen [str] int_date =seq(), from(18263) to(21184)
gen date = int_date 
format date %td

*generate dummy for bank holidays 
gen bank_holiday=0

*bank holidays england 2010
replace bank_holiday=1 if int_date==date("1/1/2010", "DMY")
replace bank_holiday=1 if int_date==date("2/4/2010", "DMY")
replace bank_holiday=1 if int_date==date("5/4/2010", "DMY")
replace bank_holiday=1 if int_date==date("3/5/2010", "DMY")
replace bank_holiday=1 if int_date==date("31/5/2010", "DMY")
replace bank_holiday=1 if int_date==date("30/8/2010", "DMY")
replace bank_holiday=1 if int_date==date("25/12/2010", "DMY")
replace bank_holiday=1 if int_date==date("26/12/2010", "DMY")
replace bank_holiday=1 if int_date==date("27/12/2010", "DMY")
replace bank_holiday=1 if int_date==date("28/12/2010", "DMY")

*bank holidays england 2011
replace bank_holiday=1 if int_date==date("3/1/2011", "DMY")
replace bank_holiday=1 if int_date==date("22/4/2011", "DMY")
replace bank_holiday=1 if int_date==date("25/4/2011", "DMY")
replace bank_holiday=1 if int_date==date("29/4/2011", "DMY")
replace bank_holiday=1 if int_date==date("2/5/2011", "DMY")
replace bank_holiday=1 if int_date==date("30/5/2011", "DMY")
replace bank_holiday=1 if int_date==date("29/8/2011", "DMY")
replace bank_holiday=1 if int_date==date("25/12/2011", "DMY")
replace bank_holiday=1 if int_date==date("26/12/2011", "DMY")
replace bank_holiday=1 if int_date==date("27/12/2011", "DMY")

*bank holidays england 2012
replace bank_holiday=1 if int_date==date("2/1/2012", "DMY")
replace bank_holiday=1 if int_date==date("6/4/2012", "DMY")
replace bank_holiday=1 if int_date==date("9/4/2012", "DMY")
replace bank_holiday=1 if int_date==date("7/5/2012", "DMY")
replace bank_holiday=1 if int_date==date("4/6/2012", "DMY")
replace bank_holiday=1 if int_date==date("5/6/2012", "DMY")
replace bank_holiday=1 if int_date==date("27/8/2012", "DMY")
replace bank_holiday=1 if int_date==date("25/12/2012", "DMY")
replace bank_holiday=1 if int_date==date("26/12/2012", "DMY")

*bank holidays england 2013
replace bank_holiday=1 if int_date==date("1/1/2013", "DMY")
replace bank_holiday=1 if int_date==date("29/3/2013", "DMY")
replace bank_holiday=1 if int_date==date("31/3/2013", "DMY")
replace bank_holiday=1 if int_date==date("5/5/2013", "DMY")
replace bank_holiday=1 if int_date==date("27/5/2013", "DMY")
replace bank_holiday=1 if int_date==date("26/8/2013", "DMY")
replace bank_holiday=1 if int_date==date("25/12/2013", "DMY")
replace bank_holiday=1 if int_date==date("26/12/2013", "DMY")

*bank holidays england 2014
replace bank_holiday=1 if int_date==date("1/1/2014", "DMY")
replace bank_holiday=1 if int_date==date("18/4/2014", "DMY")
replace bank_holiday=1 if int_date==date("21/4/2014", "DMY")
replace bank_holiday=1 if int_date==date("5/5/2014", "DMY")
replace bank_holiday=1 if int_date==date("26/5/2014", "DMY")
replace bank_holiday=1 if int_date==date("25/8/2014", "DMY")
replace bank_holiday=1 if int_date==date("25/12/2014", "DMY")
replace bank_holiday=1 if int_date==date("26/12/2014", "DMY")

*bank holidays england 2015
replace bank_holiday=1 if int_date==date("1/1/2015", "DMY")
replace bank_holiday=1 if int_date==date("3/4/2015", "DMY")
replace bank_holiday=1 if int_date==date("5/4/2015", "DMY")
replace bank_holiday=1 if int_date==date("4/5/2015", "DMY")
replace bank_holiday=1 if int_date==date("25/5/2015", "DMY")
replace bank_holiday=1 if int_date==date("31/8/2015", "DMY")
replace bank_holiday=1 if int_date==date("25/12/2015", "DMY")
replace bank_holiday=1 if int_date==date("26/12/2015", "DMY")
replace bank_holiday=1 if int_date==date("28/12/2015", "DMY")

*bank holidays england 2016 
replace bank_holiday=1 if int_date==date("1/1/2016", "DMY")
replace bank_holiday=1 if int_date==date("25/3/2016", "DMY")
replace bank_holiday=1 if int_date==date("28/3/2016", "DMY")
replace bank_holiday=1 if int_date==date("2/5/2016", "DMY")
replace bank_holiday=1 if int_date==date("30/5/2016", "DMY")
replace bank_holiday=1 if int_date==date("29/8/2016", "DMY")
replace bank_holiday=1 if int_date==date("25/12/2016", "DMY")
replace bank_holiday=1 if int_date==date("26/12/2016", "DMY")
replace bank_holiday=1 if int_date==date("27/12/2016", "DMY")

*bank holidays england 2017
replace bank_holiday=1 if int_date==date("2/1/2017", "DMY")
replace bank_holiday=1 if int_date==date("14/4/2017", "DMY")
replace bank_holiday=1 if int_date==date("17/4/2017", "DMY")
replace bank_holiday=1 if int_date==date("1/5/2017", "DMY")
replace bank_holiday=1 if int_date==date("29/5/2017", "DMY")
replace bank_holiday=1 if int_date==date("29/8/2017", "DMY")
replace bank_holiday=1 if int_date==date("25/12/2017", "DMY")
replace bank_holiday=1 if int_date==date("26/12/2017", "DMY")

drop inc_date
ren date inc_date
drop int_date
save "$path_tempdata/bankholidays.dta", replace



use "$path_tempdata/Temp_repeatfile.dta", clear
cap drop _merge
merge m:1 inc_date using "$path_tempdata/bankholidays.dta"
drop if _merge==2
cap drop _merge

//Drop victims with >= top 0.1% calls

drop if top01_nrcalls ==1


gen date=dofc(incident_date_time)
format date %td
gen week=week(date)
drop date week incident_date_time

//Time-of-day fixed effect and its ward interaction
gen daytime=1 if hour>=0 & hour<=5
replace daytime=2 if hour>=6 & hour<=11
replace daytime=3 if hour>=12 & hour<=17
replace daytime=4 if hour>=18 & hour<=23
egen ward_daytime=group(ward daytime)
egen ward_grade=group(ward call_grade)
egen ward_bank=group(ward bank_holiday)

//Team-stringency instrument and subsample variants used by Table 2 Panel B
gen lsaocal_fvic0 = Teamstr_lsao_dvcfvc0
gen lsaocal_fvic1 = Teamstr_lsao_dvcfvc1
gen lsaocal_hot0 = Teamstr_lsao_dvchot0
gen lsaocal_hot1 = Teamstr_lsao_dvchot1
gen lsaocal_day0 = Teamstr_lsao_dvcday0
gen lsaocal_day1 = Teamstr_lsao_dvcday1

label var lsaocal_fvic0 "Team stringency in higher order calls"
label var lsaocal_fvic1 "Team stringency in first time calls"
label var lsaocal_hot0 "Team stringency in no hotspot cases"
label var lsaocal_hot1 "Team stringency in hotspot cases"
label var lsaocal_day0 "Team stringency in night calls"
label var lsaocal_day1 "Team stringency in day calls"

//Clustering variable: dispatched officer on the team with the most DV cases
encode offmostDV_dvcallh, gen(clustvar)

gen lsaocal=Teamstr_lsao_dvcallh
label var lsaocal "Team Stringency"

gen lsaocal_cas=Teamcas_lsao_dvcallh
replace lsaocal_cas=. if lsaocal ==.

//Dummy previous cases
gen d_prevcases12m_off = (prevcases12m_off>0)
replace d_prevcases12m_off = . if prevcases12m_off==.
gen pcasof=d_prevcases12m_off

//Dummy previous arrests
gen d_prevaction_arrest_off = (prevaction_arrest_off>0)
replace d_prevaction_arrest_off = . if prevaction_arrest_off==.
gen parof= d_prevaction_arrest_off

//Dummy previous charge
gen d_prevcrime_charge_off = (prevcrime_charge_off>0)
replace d_prevcrime_charge_off = . if prevcrime_charge_off==.

//Dummy previous investigation
gen d_previnc_off = (previncident_to_crime_off>0)
replace d_previnc_off = . if previncident_to_crime_off==.

//Dummies timing of repeat
gen anyrepeat_96h = (count_rep_cases96h >0) if count_rep_cases96h!=.
gen anyrepeat_0to48h = (count_rep_cases0to48h >0) if count_rep_cases0to48h!=.
gen anyrepeat_49to96h = (count_rep_cases49to96h >0) if count_rep_cases49to96h!=.
gen anyrepeat_7_12months = (count_rep_cases7to12>0) if count_rep_cases7to12!=.
gen anyrepeat_12m_96h=(count_rep_cases12-count_rep_cases96h>0) if count_rep_cases12!=.
gen anyrepeat_12m_1m=(count_rep_cases12-count_rep_casesmon1>0) if count_rep_cases12!=.
gen anyrepeat_12m_1qrt=(count_rep_cases12-count_rep_cases1to3>0) if count_rep_cases12!=.

gen anyrepeat_day4_to_12=(count_rep_casesday4_to_8+count_rep_casesday8_to_12>0) if count_rep_casesday4_to_8!=.

forvalues day=8(4)12 {
	local prevday=`day'-4
	gen anyrepeat_day`prevday'_to_`day'=(count_rep_casesday`prevday'_to_`day'>0) if count_rep_casesday`prevday'_to_`day'!=.
}

forvalues day=1/2 {
gen anyrepeat_day`day' = (count_rep_casesday`day'>0) if count_rep_casesday`day'!=.
}

//Intensive margin: top-1%-trimmed repeat-call count, trimmed on the estimation sample
centile count_rep_cases12 if lsaocal_cas>=400 & ward!=""  & dvcallh==1 &(call_grade==1 | call_grade==2) & year>=2011 & year<=2016, c(99)
gen c99=r(c_1)
gen nrcases_trim99=count_rep_cases12
replace nrcases_trim99=. if count_rep_cases12>c99 &count_rep_cases12!=.
drop c99

label var action_arrest "Arrest"
label var callh_sex2 "Gender of call handler (=1 female)"
label var c_status "Caller identity (=1 victim)"
label var callh_experience2 "Call handler experience"
label var parof "Arrest in past 12m"
label var pcasof "Case in past 12m"
label var d_previnc_off "Investigation in past 12m"
label var d_prevcrime_charge_off "Charged in past 12m"
label var Tstradvice_lsao_dvcallh "Advice propensity"
label var Tstrreport_lsao_dvcallh "Rec. CI propensity"
label var report "Report"
label var advice "Advice"

gen lsaocal100mult= lsaocal*100
label var lsaocal100mult "Team arrest propensity x 100"
gen action_arrest100mult = action_arrest *100
label var action_arrest100mult "Arrest x 100"

encode ward, gen(ward_num)

gen no_arrest=1-action_arrest

sort int_ref_number 



keep ward ward_num ward_year ward_month ward_dayofweek ward_daytime ward_grade ward_bank year month dayofweek hour bank_holiday call_grade eastings northings daytime ///
	no_arrest action_arrest report advice incident_to_crime crime_charge dvcallh c_status ///
	team_id nr_officers r_mean_age r_share_females r_atleastone_female clustvar ///
	lsaocal lsaocal_cas lsaocal_fvic0 lsaocal_fvic1 lsaocal_hot0 lsaocal_hot1 lsaocal_day0 lsaocal_day1 ///
	Teamcas_lsao_dvcfvc0 Teamcas_lsao_dvcfvc1 Teamcas_lsao_dvchot0 Teamcas_lsao_dvchot1 Teamcas_lsao_dvcday0 Teamcas_lsao_dvcday1 Teamcas_lsao_dvc_12 Teamcas_loo_dvcallh ///
	Teamstr_lsao_dvc_12 Teamstr_loo_dvcallh ///
	Tstr_mostDV_dvcallh Tstr_equal_dvcallh ///
	Tstrinvest_lsao_dvcallh Tstrreport_lsao_dvcallh Tstradvice_lsao_dvcallh ///
	Slsaohh_resptime_minw95_dvcallh hh_resptime_minw95 missing_hh_resptime_min ///
	callh_sex2 callh_experience2 missing_callh_sex missing_callh_experience call_handlerid ///
	pcasof parof d_prevcases12m_off d_prevaction_arrest_off d_prevcrime_charge_off d_previnc_off ///
	repeatofficers_12callh nosevere_repeat severe_repeat vicrepeatofficers_12callh TRrepeatofficers_12callh CRrepeatofficers_12callh ///
	anyrepeat_96h anyrepeat_0to48h anyrepeat_49to96h anyrepeat_7_12months anyrepeat_12m_96h anyrepeat_12m_1m anyrepeat_12m_1qrt ///
	anyrepeat_day4_to_8 anyrepeat_day8_to_12 anyrepeat_day4_to_12 ///
	anyrepeat_day1 anyrepeat_day2 ///
	nrcases_trim99 lsaocal100mult action_arrest100mult ///
	d_abovemedcalls Fraction_Flats

save "$path_est/Main_est.dta", replace
