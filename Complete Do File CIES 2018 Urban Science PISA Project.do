*********************************************************************
*																	*
* This do-file performs all data cleaning and calculations for CIES *
*        2018 proposal: PISA Urban Science (working title)          * 
*    															    *
*********************************************************************

* Created by Julian Gerez

clear
set matsize 11000

* Set directory

local PISApath "G:/Conferences/School Location CIES/Data"

*********
* Index *
*********

* Step 1:
* Step 2:

***************************************************************************
* 																		  *
* Step 1: Append PISA data in order to perform calculations across years  *
*																		  *
***************************************************************************

*******************************************
* Drop unecessary variables to save space *
*******************************************

*2006

use "`PISApath'/PISA_orig_merged_2006.dta"
keep cnt schoolid stidstd oecd SC07Q01 PV*SCIE W_*
save "`PISApath'/PISA_merged_2006.dta"

*2009

clear
use "`PISApath'/PISA_orig_merged_2009.dta"
keep cnt schoolid StIDStd oecd SC04Q01 PV*SCIE W_*     
save "`PISApath'/PISA_merged_2009.dta"

*2012

clear
use "`PISApath'/PISA_orig_merged_2012.dta"
keep cnt schoolid StIDStd oecd SC03Q01 PV*SCIE W_*     
save "`PISApath'/PISA_merged_2012.dta"

*2015

clear
use "`PISApath'/PISA_orig_merged_2015.dta"
keep cnt cntschid cntstuid oecd SC001Q01TA PV*SCIE W_*
save "`PISApath'/PISA_merged_2015.dta"

**********************************************************
* Looped command 1: generate year variable for all files *
**********************************************************

local i 2015 2012 2009 2006

foreach file in `i' {
	clear
	use "`PISApath'/PISA_merged_`file'.dta"
	generate year = `file'
	save "`PISApath'/PISA_merged_`file'.dta", replace
}


****************************
* Rename location variable *
****************************

*2006

use "`PISApath'/PISA_merged_2006.dta"
rename SC07Q01 SC001Q01TA
save "`PISApath'/PISA_merged_2006.dta", replace

*2009

use "`PISApath'/PISA_merged_2009.dta"
rename SC04Q01 SC001Q01TA
save "`PISApath'/PISA_merged_2009.dta", replace

*2012

use "`PISApath'/PISA_merged_2012.dta"
rename SC03Q01 SC001Q01TA
save "`PISApath'/PISA_merged_2012.dta", replace


**********************************
* Looped command 2: append files *
**********************************

clear
use "`PISApath'/PISA_merged_2015.dta"

local j 2012 2009 2006

foreach file in `j' {
	quietly append using "`PISApath'/PISA_merged_`file'.dta", force
}

save "`PISApath'/PISA_merged_allyears.dta"
export delimited using "`PISApath'/PISA_merged_allyears.csv", replace

************************************************************************
* 																	   *
* Step 2: Sets up for calculations on the urban variable across years  *
*																	   *
************************************************************************

******************
* Important note *
******************

* In order to use this file, you must have:
  *1) Merged PISA 2006-2015 file (this file is created in step 1)
  *2) PISA Country Crosswalk for 2006-2015 saved as .dta
  *3) install repest package (occurs in this do-file, but don't forget it!)

clear
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

*Create "urban" dummy variable

gen urban_dummy = .
replace urban_dummy = 1 if SC001Q01TA == 4 | SC001Q01TA == 5
replace urban_dummy = 0 if SC001Q01TA == 1 | SC001Q01TA == 2 | SC001Q01TA == 3

order urban_dummy, after (oecd)

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

save "`PISApath'/PISA_merged_allyears_foruse.dta", replace

