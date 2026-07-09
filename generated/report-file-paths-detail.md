## Filepaths Analysis Details

**/var/folders/5q/yhcyv3z55wvg6lhgc3h22kk00000gq/T/20241048-1/replication-package/replication_package_public/replication/code/02_analysis.do**

- Line 785, unix : replace hh_resptime_minw95=hh_resptime_minw95/100
- Line 786, unix : replace Slsaohh_resptime_minw95_dvcallh=Slsaohh_resptime_minw95_dvcallh/100
- Line 1333, unix : gen dist_cathedral = [(eastings-cathedral_eastings)^2 + (northings-cathedral_northings)^2]^(1/2)
- Line 1906, unix : gen casesperofficer=lsaocal_cas/nr_officers
- Line 1979, unix : forvalues n=1/6{
- Line 2156, unix : forvalues day=1/2 {

**/var/folders/5q/yhcyv3z55wvg6lhgc3h22kk00000gq/T/20241048-1/replication-package/replication_package_public/replication/code/01_build_sample.do**

- Line 305, unix : gen bb=seconds/60
- Line 339, unix : gen wardcalls_perpop = sum_dvcallsbyward/ward_pop
- Line 665, unix : gen bb=seconds/60
- Line 948, unix : bysort int_ref_number: gen Team`altiv2' = Team`altiv2'time/Team`altiv2'cases
- Line 1012, unix : gen equal_weight=1/help_offnumb_lsao
- Line 1017, unix : gen offstring=offarrests_lsao/offcases_lsao
- Line 1022, unix : gen maxoffstring=offarrests_lsao/offcases_lsao if maxcases==offcases_lsao
- Line 1124, unix : bysort int_ref_number: gen r_share_females = female_officers_involved/r_nr_officers_involved
- Line 1188, unix : forvalues i=1/502{
- Line 1210, unix : forvalues i=1/502{
- Line 1232, unix : forvalues i=1/502{
- Line 1259, unix : forvalues i=1/502{
- Line 1302, unix : forvalues day=1/2 {
- Line 1318, unix : forvalues mon=0/12{
- Line 1324, unix : forvalues day=0/16{
- Line 1331, unix : forvalues i=1/502{
- Line 1358, unix : forvalues day=2/2 {
- Line 1383, unix : forvalues day=1/2 {
- Line 1421, unix : gen wardcalls_perpop = sum_dvcallsbyward/ward_pop
- Line 1666, unix : forvalues day=1/2 {

