********************************************************************
*     This do-file performs calculations on the school location    *
*     			  variable across years in PISA                    *
********************************************************************

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

************
* Analysis *
************

*Install repest package for estimations with weighted replicate samples and PVs

ssc install repest

****************************************************************
* Table 1-a,b,c: Percentage distribution urban dummy, pre 2015 *
****************************************************************

*** Looped command, percent distribution pre 2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(freq sc001q01ta) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "% not urban" "SE not urban" "% urban" "SE urban"
	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'UrbanDummyPercentTables.xls", modify sheet("Urban Dummy `year'", replace) 
putexcel A1 = matrix(analysis, names)

}

***********************************************************
* Table 1-d: Percentage distribution of urban dummy, 2015 *
***********************************************************

*** Looped command, percent distrbution 2015 ***

levelsof cntryid, local(cntryidlvls)

local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(freq sc001q01ta) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "% not urban" "SE not urban" "% urban" "SE urban"
	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'UrbanDummyPercentTables.xls", modify sheet("Urban Dummy 2015", replace) 
putexcel A1 = matrix(analysis, names)

*******************************************************
* Table 2-a: Science performance by urban dummy, 2015 *
*******************************************************

*** Looped command, science performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (urban_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not urban" "SE not urban" "coef urban" "se urban" "diff" "se diff" "p-value"
	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationScienceUrbanPerformanceTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

***************************************************************
* Table 2-b,c,d: Science performance by urban dummy, pre 2015 *
***************************************************************

*** Looped command, science performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (urban_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not urban" "SE not urban" "coef urban" "se urban" "diff" "se diff" "p-value"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationScienceUrbanPerformanceTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}

