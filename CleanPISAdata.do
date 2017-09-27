********************************************************
* This do-file cleans data in preparation for analysis *
*    m   for the school location variable, PISA        *
********************************************************

* Created by Julian Gerez

******************
* Important note *
******************

* In order to use this file, you must have:
  *1) Merged PISA 2006-2015 file (this file is created in the AppendMergedPISA.do)
  *2) PISA Country Crosswalk for 2006-2015 saved as .dta
  *3) install repest package (occurs in .do file line _____)

local PISApath "G:/Conferences/School Location CIES/"

use "`PISApath'PISA_merged_allyears.dta"

**********************
* Clean data further *
**********************

*Move weight and pv variables to the end of the dataset for convenience

order PV*, last
order W*, last

*Convert 2015 concatenated country-school and country-student ids to strings

rename cntschid cntschid_orig
tostring cntschid_orig, generate(cntschid_string)

rename cntstuid cntstuid_orig
tostring cntstuid_orig, generate(cntstuid_string)

*Extract schid and stuids respectively

gen schid_2015 = substr(cntschid_string, -5, 5)
gen stuid_2015 = substr(cntstuid_string, -5, 5)

*Create new schid variable for all years, 7-digit

gen schid_string=schid_2015
replace schid_string=schoolid if missing(schid_string)
destring schid_string, generate(schid)
format schid %07.0f

*Create new stuid variable for all years, 5-digit

gen stuid_string=stuid_2015
replace stuid_string=StIDStd if missing(stuid_string)
replace stuid_string=stidstd if missing(stuid_string)
destring stuid_string, generate(stuid)
format stuid %05.0f

*Move intermediate id variables to end of dataset for convenience

order cntschid_orig cntschid_string cntstuid_orig cntstuid_string schoolid, last
order StIDStd stidstd schid_2015 stuid_2015 schid_string stuid_string, last

*Rename using variables

rename schid SchoolID
rename stuid StudentID

*Label new variables

label var year "PISA Cycle"
label var SchoolID "School ID"
label var StudentID "Student ID"

*Create dummy variables for each category of school location

gen village_dummy = 0
replace village_dummy = 1 if SC001Q01TA == 1

gen smalltown_dummy = 0
replace smalltown_dummy = 1 if SC001Q01TA == 2

gen town_dummy = 0
replace town_dummy = 1 if SC001Q01TA == 3

gen city_dummy = 0
replace city_dummy = 1 if SC001Q01TA == 4

gen largecity_dummy = 0
replace largecity_dummy = 1 if SC001Q01TA == 5

order village_dummy smalltown_dummy town_dummy city_dummy largecity_dummy, after (oecd)

*Make weight variables lowercase

rename W*, lower
rename PV*, lower
rename SC001Q01TA, lower

*Rename old id variables to avoid ambiguous abbreviations

rename cntschid_string string_cntschid
rename cntstuid_string string_cntstuid

*Merge cntryid crosswalk

drop cntryid
merge m:1 cnt using "`PISApath'PISA Country Crosswalk.dta"

*Check number of observations with tab merge, should be 1,914,216

drop _merge

*Order new countryid variable

order cntrid, after(cnt)
rename cntrid cntryid

*Save file

save "PISApath'PISA_merged_allyears_clean.dta"
