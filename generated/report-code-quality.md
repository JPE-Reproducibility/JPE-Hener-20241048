## Code Quality

### Stata

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 90)
  → drop if osgr ==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 144)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 161)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 201)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 235)
  → drop if disparrleft_missing ==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 245)
  → drop if temp_dup>1 & max_temp>0 & disparrexists==0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 323)
  → keep if dvcallh==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 341)
  → drop if ward ==""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 424)
  → keep if inconsistent_flag==0 & true_cancel==0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 452)
  → keep if inconsistent_flag==0 & true_cancel==0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 543)
  → drop if flag_dropcase==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 553)
  → drop if flag_dropcase2==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 641)
  → keep if true_cancel==0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 652)
  → keep if true_cancel==0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 697)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 725)
  → keep if `DV_var'  == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 743)
  → keep if strict_action1==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 758)
  → keep if `altiv'==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 775)
  → keep if `altiv2'!=.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 804)
  → keep if `DV_var'  == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 805)
  → drop if osgr==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 811)
  → keep if strict_action1==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 821)
  → keep if report==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 831)
  → keep if advice==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 841)
  → keep if nonaction==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 851)
  → keep if crime_charge==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 861)
  → keep if incident_to_crime==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 1095)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 1394)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_build_sample.do, line 1586)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 140)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 142)
  → keep if n==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 158)
  → keep if lsaocal_cas>=400 & lsaocal!=. & ward!="" & dvcallh==1  & year>=2011 & year<=2016

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 241)
  → keep if esample_means==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 294)
  → keep if esample_means==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 898)
  → keep if esample_means==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 951)
  → keep if ward!=""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 970)
  → keep if dvcallh == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 1023)
  → keep if esample_means==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 1069)
  → keep if esample_means==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 1115)
  → keep if esample_means==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 1161)
  → keep if esample_means==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 1750)
  → keep if esample_means==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 1780)
  → keep if esample_means==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_analysis.do, line 1963)
  → keep if esample_means==1

