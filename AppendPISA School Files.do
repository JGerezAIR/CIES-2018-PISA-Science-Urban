********************************************************************
* This do-file appends PISA data in order to perform calculations  *
*                  with all years, school level                    *
********************************************************************

*Created by Julian Gerez

*Set directory

local PISApath "H:/5.2_main/Conferences/CIES 2018/School Location/Data"

****************************
* Sample command (no loop) *
****************************

*Generate year variable for each file

*use "`PISApath'/PISA_sch_2015"
*generate year = 2015
*save "`PISApath'/PISA_sch_2015", replace

*clear
*use "`PISApath'/PISA_sch_2012"
*generate year = 2012
*save "`PISApath'/PISA_sch_2012", replace

*Open first file, append second file

*clear
*use "`PISApath'/PISA_sch_2015"
*append using "`PISApath'/PISA_sch_2012", force

**********************************************************
* Looped command 1: generate year variable for all files *
**********************************************************

local i 2015 2012 2009 2006 2003 2000

foreach file in `i' {
	clear
	use "`PISApath'/PISA_sch_`file'.dta"
	drop year
	generate year = `file'
	save "`PISApath'/PISA_sch_`file'.dta", replace
}


****************************
* Rename location variable *
****************************

*2000

use "`PISApath'/PISA_sch_2000.dta"
recode sc01q01 6=5
rename sc01q01 SC001Q01TA
save "`PISApath'/PISA_sch_2000.dta", replace

*2003

use "`PISApath'/PISA_sch_2003.dta"
rename SC01Q01 SC001Q01TA
save "`PISApath'/PISA_sch_2003.dta", replace

*2006

use "`PISApath'/PISA_sch_2006.dta"
rename SC07Q01 SC001Q01TA
save "`PISApath'/PISA_sch_2006.dta", replace

*2009

use "`PISApath'/PISA_sch_2009.dta"
rename SC04Q01 SC001Q01TA
save "`PISApath'/PISA_sch_2009.dta", replace

*2012

use "`PISApath'/PISA_sch_2012.dta"
rename SC03Q01 SC001Q01TA
save "`PISApath'/PISA_sch_2012.dta", replace


**********************************
* Looped command 2: append files *
**********************************

clear
use "`PISApath'/PISA_sch_2015.dta"

local j 2012 2009 2006 2003 2000

foreach file in `j' {
	quietly append using "`PISApath'/PISA_sch_`file'.dta", force
}

save "`PISApath'/PISA_sch_allyears.dta"
export delimited using "`PISApath'/PISA_sch_allyears.csv", replace
