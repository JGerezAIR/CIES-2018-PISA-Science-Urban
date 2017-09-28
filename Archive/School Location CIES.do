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

************
* Analysis *
************

*Install repest package for estimations with weighted replicate samples and PVs

ssc install repest

***********************************************************************
* Table 1-a,b,c: Percentage distribution of school location, pre 2015 *
***********************************************************************

*Non-looped command

*repest PISA if year==2006 & cnt=="USA", estimate(freq sc001q01ta) flag
*Return list
	*mat list r(table)
	*cap mat drop A
	*mat A = r(table)
	
	*Coefficients
	*cap mat drop b
	*mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
	
	*Mat list b
	*mat rown b = "USA"
	*mat coln b = "% village" "SE village" "% small town" "SE small town" "% town" "SE town" "% city" "SE city" "% large city" "se large city"

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
	qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "% village" "SE village" "% small town" "SE small town" "% town" "SE town" "% city" "SE city" "% large city" "se large city"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationPercentTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}

***************************************************************
* Table 1-d: Percentage distribution of school location, 2015 *
***************************************************************

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
	qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "% village" "SE village" "% small town" "SE small town" "% town" "SE town" "% city" "SE city" "% large city" "se large city"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationPercentTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

***************
* Performance *
***************

**********************************
* Performance for all sc001q01ta *
**********************************

* Have to figure out how to group sc001q01ta *

*** Looped command, math performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@math, stats(mean)) over (sc001q01ta) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "village" "SE village" "small town" "SE small town" "town" "SE town" "city" "SE city" "large city" "SE large city"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationAllMathPerformanceTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

*** Looped command, math performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@math, stats(mean)) over (sc001q01ta) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "village" "SE village" "small town" "SE small town" "town" "SE town" "city" "SE city" "large city" "SE large city"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationAllMathPerformanceTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}

*** Looped command, science performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (sc001q01ta) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "village" "SE village" "small town" "SE small town" "town" "SE town" "city" "SE city" "large city" "SE large city"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationAllSciePerformanceTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

*** Looped command, science performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (sc001q01ta) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "village" "SE village" "small town" "SE small town" "town" "SE town" "city" "SE city" "large city" "SE large city"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationAllSciePerformanceTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}

*** Looped command, reading performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@read, stats(mean)) over (sc001q01ta) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "village" "SE village" "small town" "SE small town" "town" "SE town" "city" "SE city" "large city" "SE large city"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationAllReadPerformanceTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

*** Looped command, reading performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@read, stats(mean)) over (sc001q01ta) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "village" "SE village" "small town" "SE small town" "town" "SE town" "city" "SE city" "large city" "SE large city"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationAllReadPerformanceTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}

********************************
* Performance by village dummy *
********************************

*** Looped command, math performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@math, stats(mean)) over (village_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not village" "SE not village" "coef village" "se village" "diff" "se diff" "p-value"
	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationMathVillagePerformanceTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

*** Looped command, math performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@math, stats(mean)) over (village_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not village" "SE not village" "coef village" "se village" "diff" "se diff" "p-value"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationMathVillagePerformanceTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}

*** Looped command, science performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (village_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not village" "SE not village" "coef village" "se village" "diff" "se diff" "p-value"
	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationScienceVillagePerformanceTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

*** Looped command, science performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (village_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not village" "SE not village" "coef village" "se village" "diff" "se diff" "p-value"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationScienceVillagePerformanceTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}

*** Looped command, reading performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@read, stats(mean)) over (village_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not village" "SE not village" "coef village" "se village" "diff" "se diff" "p-value"
	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationReadVillagePerformanceTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

*** Looped command, reading performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@read, stats(mean)) over (village_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not village" "SE not village" "coef village" "se village" "diff" "se diff" "p-value"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationReadVillagePerformanceTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}

***********************************
* Performance by large city dummy *
***********************************

*** Looped command, math performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@math, stats(mean)) over (largecity_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not largecity" "SE not largecity" "coef largecity" "se largecity" "diff" "se diff" "p-value"
	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationMathLargecityPerformanceTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

*** Looped command, math performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@math, stats(mean)) over (largecity_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not largecity" "SE not largecity" "coef largecity" "se largecity" "diff" "se diff" "p-value"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationMathLargecityPerformanceTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}

*** Looped command, science performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (largecity_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not largecity" "SE not largecity" "coef largecity" "se largecity" "diff" "se diff" "p-value"
	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationScienceLargecityPerformanceTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

*** Looped command, science performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (largecity_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not largecity" "SE not largecity" "coef largecity" "se largecity" "diff" "se diff" "p-value"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationScienceLargecityPerformanceTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}

*** Looped command, reading performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@read, stats(mean)) over (largecity_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not largecity" "SE not largecity" "coef largecity" "se largecity" "diff" "se diff" "p-value"
	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationReadLargecityPerformanceTables.xls", modify sheet("2015", replace) 
putexcel A1 = matrix(analysis, names)

*** Looped command, reading performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)
local num = 0

foreach year in `j' {
foreach i of local cntryidlvls {
repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@read, stats(mean)) over (largecity_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not largecity" "SE not largecity" "coef largecity" "se largecity" "diff" "se diff" "p-value"

	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}

putexcel set "`PISApath'SchoolLocationReadLargecityPerformanceTables.xls", modify sheet("`year'", replace) 
putexcel A1 = matrix(analysis, names)

}
