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

***************************************************************************
* 																		  *
* Step 2: Append PISA data in order to perform calculations across years  *
*																		  *
***************************************************************************
