## Appendix: Detailed PII Detection Results

*Generated on 2026-08-22 15:21:33*

This appendix lists all detected instances of potential personally identifiable information (PII) in the project files. Each entry shows the matched PII terms and, for data files, sample values to help verify whether the flagged content is indeed sensitive.

### Code Files

**/replication-package/replication_package_public/replication/code/01_build_sample.do**

- Line 13: lon
  ```
  *   Run via master.do (which sets $path_raw etc.). If run standalone, define
  ```
- Line 21: loc, location
  ```
  *     3. Add geography info: ward assignment to geolocation
  ```
- Line 27: address
  ```
  *        leave-same-address-out), alternative weightings, clustering IDs.
  ```
- Line 31: loc, location
  ```
  *     7. Repeat-victimization measures (geo-location based, plus official
  ```
- Line 118: lat
  ```
  //Save intermediate officer-crime level data for later use
  ```
- Line 141: name
  ```
  rename crime_number crimenumber
  ```
- Line 143: name
  ```
  rename crimenumber crime_number
  ```
- Line 160: name
  ```
  ren ward_name ward
  ```
- Line 165: lat
  ```
  //Ward population
  ```
- Line 212: name
  ```
  rename callh_years_service callh_experience
  ```
- Line 213: gender, name, sex
  ```
  rename ch_gender callh_sex
  ```
- Line 224: loc
  ```
  gen `x'_ = clock(`x', "DMYhms")
  ```
- Line 226: name
  ```
  rename `x'_ `x'
  ```
- Line 303: minute
  ```
  gen minutes=mm(incidentcreation_dur)
  ```
- Line 304: second
  ```
  gen seconds=ss(incidentcreation_dur)
  ```
- Line 305: second
  ```
  gen bb=seconds/60
  ```
- Line 307: minute
  ```
  gen incidentcreation_dur_min= aa+ minutes +bb
  ```
- Line 310: minute, second
  ```
  drop hour2 aa minutes seconds bb
  ```
- Line 344: loc
  ```
  loc mymedian = `r(p75)'
  ```
- Line 463: lat
  ```
  //Define latest dispatch among those with non-missing arrival times
  ```
- Line 474: lat
  ```
  //Scenario 1: drop case (=set min. arrival time to missing) if any officer was dispatched before lat
  ```
- Line 489: lat
  ```
  //Scenario 2: dispatch > latest dispatch & dipatch < min.arrival
  ```
- Line 649: lat
  ```
  //latest leave time
  ```
- Line 663: minute
  ```
  gen minutes=mm(hh_resp_time)
  ```
- Line 664: second
  ```
  gen seconds=ss(hh_resp_time)
  ```
- Line 665: second
  ```
  gen bb=seconds/60
  ```
- Line 666: minute
  ```
  gen hh_resptime_min= aa+ minutes +bb
  ```
- Line 668: minute, second
  ```
  drop hour2 aa minutes seconds bb hh_resp_time
  ```
- Line 714: lat
  ```
  //Calculate Team Stringency
  ```
- Line 728: lat
  ```
  // CALCULATE STRINGENCY IN RESP TEAM
  ```
- Line 737: name
  ```
  rename DVcases_off3 DVcases_officer3
  ```
- Line 752: name
  ```
  rename DVstrict1cases_off3 DVstrict1cases_officer3
  ```
- Line 767: name
  ```
  rename altiv`altiv'_off3 altiv`altiv'_officer3
  ```
- Line 953: address
  ```
  //Instrument leave-same-address-out
  ```
- Line 1051: name
  ```
  rename officer_mostDV offmostDV_`DV_var'
  ```
- Line 1081: city
  ```
  *   order, and day/night subsamples for the monotonicity checks
  ```
- Line 1123: sex
  ```
  bysort int_ref_number: egen female_officers_involved = total(sex)
  ```
- Line 1134: name
  ```
  rename team_id_dvcallh team_id
  ```
- Line 1155: loc
  ```
  cap n drop dispatched_date_time arrived_date_time left_date_time cancelled_date_time loc_desc office
  ```
- Line 1163: coord
  ```
  label var victim_id "id based on geo coordinates"
  ```
- Line 1242: name
  ```
  rename count_officer prevcases12m_off
  ```
- Line 1298: loc
  ```
  local prevday=`day'-4
  ```
- Line 1353: loc
  ```
  local prevday=`day'-4
  ```
- Line 1359: loc
  ```
  local prevday=`day'-1
  ```
- Line 1379: loc
  ```
  local prevday=`day'-4
  ```
- Line 1406: sex
  ```
  gen callh_sex2 = callh_sex
  ```
- Line 1407: sex
  ```
  gen missing_callh_sex=(callh_sex2==.)
  ```
- Line 1408: sex
  ```
  qui sum callh_sex2
  ```
- Line 1409: sex
  ```
  replace callh_sex2= `r(mean)' if callh_sex2==.
  ```
- Line 1428: loc
  ```
  loc mymedian = `r(p75)'
  ```
- Line 1662: loc
  ```
  local prevday=`day'-4
  ```
- Line 1678: gender, sex
  ```
  label var callh_sex2 "Gender of call handler (=1 female)"
  ```
- Line 1712: sex
  ```
  callh_sex2 callh_experience2 missing_callh_sex missing_callh_experience call_handlerid ///
  ```
- Line 1719: lat
  ```
  d_abovemedcalls Fraction_Flats
  ```

**/replication-package/replication_package_public/replication/code/02_analysis.do**

- Line 41: lon
  ```
  * Defaults below reproduce the paper exactly but take longer to run; for a
  ```
- Line 65: lat
  ```
  ** later
  ```
- Line 160: loc
  ```
  local p1 = round(r(N)/_N, 0.01)*100
  ```
- Line 162: loc
  ```
  local low = round(r(N)/_N, 0.01)*100
  ```
- Line 163: loc
  ```
  local p2=100-`p1'-`low'
  ```
- Line 194: sex
  ```
  eststo: xi:ivreghdfe action_arrest100mult pcasof parof d_previnc_off d_prevcrime_charge_off c_status
  ```
- Line 195: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 196: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 197: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 198: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 199: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 200: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 206: sex
  ```
  eststo: xi:ivreghdfe lsaocal100mult pcasof parof d_previnc_off d_prevcrime_charge_off c_status callh
  ```
- Line 207: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 208: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 209: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 210: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 211: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 212: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 219: sex
  ```
  label b(%12.3f) se(%12.3f) booktabs replace nocons keep(pcasof parof d_previnc_off d_prevcrime_charg
  ```
- Line 234: loc
  ```
  *   Local linear regression of residualized
  ```
- Line 260: degree, loc
  ```
  *local linear regression with degree=2,   kernel=triangular
  ```
- Line 261: degree
  ```
  lpoly r1_action_arrest r1_lsaocal, nogr ci gen(r1_lsaocalg r1_action_arrest_y0) se(r1_action_arrest_
  ```
- Line 280: city
  ```
  * TABLE 2 — Testing the Monotonicity Assumpti
  ```
- Line 301: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 302: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 303: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 304: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 305: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 306: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 313: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 314: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 315: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 316: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 317: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 318: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 326: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 327: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 328: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 329: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 330: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 331: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 338: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 339: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 340: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 341: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 342: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 343: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 351: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 352: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 353: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 354: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 355: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 356: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 363: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 364: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 365: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 366: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 367: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 368: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 400: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 401: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 402: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 403: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 404: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 405: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 414: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 415: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 416: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 417: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 418: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 419: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 428: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 429: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 430: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 431: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 432: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 433: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 442: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 443: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 444: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 445: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 446: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 447: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 457: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 458: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 459: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 460: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 461: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 462: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 471: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 472: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 473: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 474: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 475: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 476: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 547: loc
  ```
  estadd local all_fe "yes"
  ```
- Line 548: loc
  ```
  estadd local wardfe_time "yes"
  ```
- Line 549: loc
  ```
  estadd local wardfe_grade "yes"
  ```
- Line 550: loc
  ```
  estadd local wardfe_bank "yes"
  ```
- Line 556: loc
  ```
  estadd local all_fe "yes"
  ```
- Line 557: loc
  ```
  estadd local wardfe_time "no"
  ```
- Line 558: loc
  ```
  estadd local wardfe_grade "no"
  ```
- Line 559: loc
  ```
  estadd local wardfe_bank "no"
  ```
- Line 570: loc
  ```
  estadd local all_fe "yes"
  ```
- Line 571: loc
  ```
  estadd local wardfe_time "yes"
  ```
- Line 572: loc
  ```
  estadd local wardfe_grade "no"
  ```
- Line 573: loc
  ```
  estadd local wardfe_bank "no"
  ```
- Line 584: loc
  ```
  estadd local all_fe "yes"
  ```
- Line 585: loc
  ```
  estadd local wardfe_time "yes"
  ```
- Line 586: loc
  ```
  estadd local wardfe_grade "yes"
  ```
- Line 587: loc
  ```
  estadd local wardfe_bank "yes"
  ```
- Line 624: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 625: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 626: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 627: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 628: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 629: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 637: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 638: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 639: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 640: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 641: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 642: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 650: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 651: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 652: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 653: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 654: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 655: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 660: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 661: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 662: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 663: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 664: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 665: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 673: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 674: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 675: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 676: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 677: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 678: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 705: lon
  ```
  *   days 5-12, 5-8, 9-12). Panel B: longer-run persistence excluding initial
  ```
- Line 718: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 719: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 720: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 721: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 722: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 723: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 748: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 749: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 750: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 751: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 752: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 753: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 791: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "no"
  ```
- Line 792: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "no"
  ```
- Line 793: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "no"
  ```
- Line 794: loc
  ```
  estadd local r_share_females "no"
  ```
- Line 800: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "no"
  ```
- Line 801: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "no"
  ```
- Line 802: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "yes"
  ```
- Line 803: loc
  ```
  estadd local r_share_females "no"
  ```
- Line 809: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "yes"
  ```
- Line 810: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "yes"
  ```
- Line 811: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "no"
  ```
- Line 812: loc
  ```
  estadd local r_share_females "no"
  ```
- Line 818: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "yes"
  ```
- Line 819: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "yes"
  ```
- Line 820: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "no"
  ```
- Line 821: loc
  ```
  estadd local r_share_females "no"
  ```
- Line 827: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "yes"
  ```
- Line 828: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "yes"
  ```
- Line 829: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "no"
  ```
- Line 830: loc
  ```
  estadd local r_share_females "no"
  ```
- Line 836: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "yes"
  ```
- Line 837: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "yes"
  ```
- Line 838: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "no"
  ```
- Line 839: loc
  ```
  estadd local r_share_females "no"
  ```
- Line 862: degree
  ```
  *   MTE, polynomial degree 2, trimmed 1% of the propensity tails,
  ```
- Line 873: name
  ```
  rename lsaocal tempdistcol
  ```
- Line 877: name
  ```
  rename tempdistcol lsaocal
  ```
- Line 880: name
  ```
  gr export "$path_results/FigureA2.png", replace name(CommonSupport)
  ```
- Line 891: loc
  ```
  *   Local linear regression of residualized repeat DV
  ```
- Line 907: lon
  ```
  * clonevar _r1_`v' = r1_`v'
  ```
- Line 918: degree
  ```
  lpoly r1_repeatofficers_12callh r1_lsaocal , nogr ci gen(r1_lsaocalg r1_repeatofficers_12callh_y0) s
  ```
- Line 977: lat
  ```
  *   Population mean vs complier mean (with bootstrapped std. errors) for prior
  ```
- Line 1181: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1184: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1187: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1190: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1193: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1196: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1199: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1220: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1223: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1226: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1229: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1232: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1259: loc
  ```
  estadd local r_share_females "no"
  ```
- Line 1260: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "no"
  ```
- Line 1261: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "no"
  ```
- Line 1262: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "no"
  ```
- Line 1263: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1269: loc
  ```
  estadd local r_share_females "yes"
  ```
- Line 1270: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "no"
  ```
- Line 1271: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "no"
  ```
- Line 1272: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "no"
  ```
- Line 1273: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1279: loc
  ```
  estadd local r_share_females "no"
  ```
- Line 1280: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "no"
  ```
- Line 1281: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "yes"
  ```
- Line 1282: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "yes"
  ```
- Line 1283: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1289: loc
  ```
  estadd local r_share_females "no"
  ```
- Line 1290: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "no"
  ```
- Line 1291: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "yes"
  ```
- Line 1292: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "yes"
  ```
- Line 1293: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1299: loc
  ```
  estadd local r_share_females "no"
  ```
- Line 1300: loc
  ```
  estadd local Tarrival_min_loo_dvcallh "no"
  ```
- Line 1301: loc
  ```
  estadd local Tstrreport_lsao_dvcallh "yes"
  ```
- Line 1302: loc
  ```
  estadd local Tstradvice_lsao_dvcallh "yes"
  ```
- Line 1303: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1325: city
  ```
  *   the Birmingham city centre (3km around St Philips Cathedral).
  ```
- Line 1337: lat
  ```
  _pctile lsaocal if Fraction_Flats <0.20 & esample_means==1, p(99)
  ```
- Line 1340: lat
  ```
  _pctile lsaocal if Fraction_Flats <0.20 & esample_means==1, p(1)
  ```
- Line 1344: lat
  ```
  qui xi: reghdfe action_arrest lsaocal if Fraction_Flats <0.20 & esample_means==1, cluster(clustvar) 
  ```
- Line 1354: lat
  ```
  qui xi: reghdfe `var' lsaocal action_arrest if Fraction_Flats <0.20 & esample_means==1, cluster(clus
  ```
- Line 1394: lat
  ```
  eststo:xi:ivreghdfe repeatofficers_12callh (action_arrest = lsaocal) if Fraction_Flats <0.20 & esamp
  ```
- Line 1395: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 1396: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 1397: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 1398: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 1399: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1400: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 1408: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 1409: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 1410: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 1411: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 1412: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1413: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 1425: city, house
  ```
  mgroups("Only areas with min. 80p HH in detached houses" "Excluding city centre of Birmingham (3km r
  ```
- Line 1435: loc, location
  ```
  * TABLE A6 — Differential Accuracy of Geo-Coded Location as a Function of Arre
  ```
- Line 1436: coord, lat
  ```
  *   Cross-tabulates the geo-coordinate repeat measure against the official
  ```
- Line 1461: son
  ```
  *   Ten alternative specifications: intensive margin (incl. IV Poisson), call-
  ```
- Line 1585: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 1586: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 1587: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 1588: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 1589: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1590: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 1596: son
  ```
  eststo: ivpoisson gmm nrcases_trim99 (action_arrest=lsaocal) i.year i.month i.ward_num i.call_grade 
  ```
- Line 1598: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 1599: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 1600: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 1601: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 1602: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1603: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 1610: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1611: loc
  ```
  estadd local callfe "yes"
  ```
- Line 1612: loc
  ```
  estadd local teamclust "no"
  ```
- Line 1619: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1620: loc
  ```
  estadd local callfe "no"
  ```
- Line 1621: loc
  ```
  estadd local teamclust "yes"
  ```
- Line 1628: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 1629: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 1630: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 1631: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 1632: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1633: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 1641: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 1642: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 1643: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 1644: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 1645: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1646: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 1654: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 1655: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 1656: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 1657: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 1658: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1659: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 1667: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 1668: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 1669: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 1670: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 1671: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1672: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 1680: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 1681: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 1682: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 1683: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 1684: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1685: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 1693: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 1694: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 1695: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 1696: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 1697: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 1698: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 1710: son
  ```
  mgroups("Intensive margin" "Intensive margin: Poisson" "Callhandler FE"  "Team clustering" "Most exp
  ```
- Line 1743: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1751: sex
  ```
  reghdfe action_arrest100mult pcasof parof d_previnc_off d_prevcrime_charge_off c_status callh_sex2 m
  ```
- Line 1773: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1781: sex
  ```
  reghdfe repeatofficers_12callh pcasof parof d_previnc_off d_prevcrime_charge_off c_status callh_sex2
  ```
- Line 1803: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1825: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1850: loc
  ```
  estadd local wardinteractions "yes"
  ```
- Line 1915: gender
  ```
  *   Mean and regression of instrument on team age and gender (Section 3.1)
  ```
- Line 1929: sex
  ```
  xi: ivreghdfe action_arrest lsaocal pcasof parof d_previnc_off d_prevcrime_charge_off c_status callh
  ```
- Line 2066: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 2067: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 2068: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 2069: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 2070: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 2071: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 2106: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 2107: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 2108: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 2109: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 2110: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 2111: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 2113: loc
  ```
  local sign=sign(_b[action_arrest])
  ```
- Line 2119: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 2120: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 2121: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 2122: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 2123: loc
  ```
  estadd local ward_bank "yes"
  ```
- Line 2124: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 2130: loc
  ```
  local sign=sign(_b[action_arrest])
  ```
- Line 2158: loc
  ```
  estadd local ward_year "yes"
  ```
- Line 2159: loc
  ```
  estadd local ward_month "yes"
  ```
- Line 2160: loc
  ```
  estadd local ward_dayofweek "yes"
  ```
- Line 2161: loc
  ```
  estadd local ward_daytime "yes"
  ```
- Line 2162: loc
  ```
  estadd local ward_grade "yes"
  ```
- Line 2163: loc
  ```
  estadd local ward_bank "yes"
  ```

**/replication-package/replication_package_public/replication/code/0_install_dependencies.do**

- Line 23: loc
  ```
  local pkgs ftools reghdfe ranktest ivreghdfe estout moremata mtefe missings
  ```
- Line 25: loc
  ```
  foreach p of local pkgs {
  ```
- Line 42: loc
  ```
  local cmds reghdfe ivreghdfe esttab eststo mtefe
  ```
- Line 43: loc
  ```
  local missing ""
  ```
- Line 44: loc
  ```
  foreach c of local cmds {
  ```
- Line 48: loc
  ```
  local missing "`missing' `c'"
  ```

