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
cd "`PISApath'"

* Install necessary packages

ssc install repest
ssc install outreg2

*********
* Index *
*********

* Step 1: Line 27 - Append PISA data
* Step 2: Line 117 - All years prep file
* Step 3: Line 225 - Urban distribution and performance
* Step 4: Line 400 - Prep file for other science variables, 2015
* Step 5: Line 471 - Urban variable and other science variables analyses, 2015

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

*****************************************************************
* 																*
* Step 3: Performs analyses, urban distribution and performance *
*																*
*****************************************************************

clear

local PISApath "G:/Conferences/School Location CIES/"

use "`PISApath'/PISA_merged_allyears_foruse.dta"

***********************************************************
* Table 1-a: Percentage distribution of urban dummy, 2015 *
***********************************************************

*** Looped command, percent distrbution 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
	repest PISA2015 if year==2015 & cntryid==`i', estimate(freq urban_dummy) flag
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

****************************************************************
* Table 1-b,c,d: Percentage distribution urban dummy, pre 2015 *
****************************************************************

*** Looped command, percent distribution pre 2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)

foreach year in `j' {
	local num = 0
	foreach i of local cntryidlvls {
		repest PISA if year==`year' & cntryid==`i', estimate(freq urban_dummy) flag
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

putexcel set "`PISApath'UrbanDummySciencePerformanceTables.xls", modify sheet("Urban Dummy 2015", replace) 
putexcel A1 = matrix(analysis, names)

***************************************************************
* Table 2-b,c,d: Science performance by urban dummy, pre 2015 *
***************************************************************

*** Looped command, science performance pre-2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)


foreach year in `j' {
	local num = 0
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

putexcel set "`PISApath'UrbanDummySciencePerformanceTables.xls", modify sheet("Urban Dummy `year'", replace) 
putexcel A1 = matrix(analysis, names)

}


******************************************************************
* 																 *
* Step 4: Sets up 2015 analyses, other variables by urban dummy  *
*																 *
******************************************************************

clear

set matsize 11000

local PISApath "G:/Conferences/School Location CIES/"

* Read-in data file

use "`PISApath'Data/PISA_orig_merged_2015.dta"

* Make all variables lowercase

rename *, lower

* Create dummy variables for each category of school location

gen village_dummy = 0
replace village_dummy = 1 if sc001q01ta == 1

gen smalltown_dummy = 0
replace smalltown_dummy = 1 if sc001q01ta == 2

gen town_dummy = 0
replace town_dummy = 1 if sc001q01ta == 3

gen city_dummy = 0
replace city_dummy = 1 if sc001q01ta == 4

gen largecity_dummy = 0
replace largecity_dummy = 1 if sc001q01ta == 5

* Create "urban" dummy variable

gen urban_dummy = .
replace urban_dummy = 1 if sc001q01ta == 4 | sc001q01ta == 5
replace urban_dummy = 0 if sc001q01ta == 1 | sc001q01ta == 2 | sc001q01ta == 3

* Create condensed versions of other variables

local sciencebeliefs st131q01na st131q03na st131q04na st131q06na st131q08na st131q11na

* 0 = disagree or strongly disagree
* 1 = agree or strongly agree

foreach var in `sciencebeliefs' {
	gen `var'_condensed = .
	replace `var'_condensed = 0 if `var' == 1 | `var' == 2
	replace `var'_condensed = 1 if `var' == 3 | `var' == 4
}

local scienceawareness st092q01ta st092q02ta st092q04ta st092q05ta st092q06na st092q08na st092q09na

* 0 = low familiarity
* 1 = high familiarity

foreach var in `scienceawareness' {
	gen `var'_condensed = .
	replace `var'_condensed = 0 if `var' == 1 | `var' == 2
	replace `var'_condensed = 1 if `var' == 3 | `var' == 4
}

local scienceissues st093q01ta st093q03ta st093q04ta st093q05ta st093q06ta st093q07na st093q08na

* 0 = get worse
* 1 = improve

foreach var in `scienceissues' {
	gen `var'_binary = .
	replace `var'_binary = 0 if `var' == 3
	replace `var'_binary = 1 if `var' == 1
	replace `var'_binary = . if `var' == 2
}	

* Save new file

save "`PISApath'Data/PISA_orig_merged_2015_foruse.dta", replace

******************************************************************
* 																 *
* Step 5: Conducts 2015 analyses, other variables by urban dummy *
*																 *
******************************************************************

clear

local PISApath "G:/Conferences/School Location CIES/Data"

use "`PISApath'/PISA_orig_merged_2015_foruse.dta"

*******************************************************************
* Table 3-*: School location results, science issues, urban dummy *
*******************************************************************

*** Looped command, science performance by science issues 2015 ***

levelsof cntryid, local(cntryidlvls)
local scienceissues st093q01ta st093q03ta st093q04ta st093q05ta st093q06ta st093q07na st093q08na

foreach var in `scienceissues'{
	local num = 0
	foreach i of local cntryidlvls {
		repest PISA2015 if cntryid==`i', estimate(freq `var') over (urban_dummy, test) flag
		*Return list
			cap mat list r(table)
			cap mat drop A
			qui mat A = r(table)
			
			*Coefficients
			cap mat drop b
			qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5], A[1,6], A[2,6], A[1,7], A[2,7], A[4,7], A[1,8], A[2,8], A[4,8], A[1,9], A[2,9], A[4,9])
			
			*Mat list b
			qui mat rown b = `i'
			qui mat coln b = "coef not urban improve" "SE not urban improve" "coef not urban same" "SE not urban same" "coef not urban worse" "SE not urban worse" "coef urban improve" "SE urban improve" "coef urban same" "SE urban same" "coef urban worse" "SE urban worse" "improve diff" "se improve diff" "p value improve diff" "same diff" "se same diff" "p value same diff" "worse diff" "se worse diff" "p value worse diff"
			if `num' == 0 { 
				cap mat drop analysis 
				mat analysis = b
			}
			else {
				mat analysis = analysis \ b
			}
			local ++num 
	}
putexcel set "`PISApath'UrbanScienceIssuesTable2015.xls", modify sheet("`var'", replace) 
putexcel A1 = matrix(analysis, names)

}

********************************************************************
* Table 4-*: School location results, science beliefs, urban dummy *
********************************************************************

*** Looped command, science performance by science beliefs 2015 ***

levelsof cntryid, local(cntryidlvls)
local sciencebeliefs st131q01na st131q03na st131q04na st131q06na st131q08na st131q11na

foreach var in `sciencebeliefs'{
	local num = 0
	foreach i of local cntryidlvls {
		repest PISA2015 if cntryid==`i', estimate(freq `var') over (urban_dummy, test) flag
		*Return list
			cap mat list r(table)
			cap mat drop A
			qui mat A = r(table)
			
			*Coefficients
			cap mat drop b
			qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5], A[1,6], A[2,6], A[1,7], A[2,7], A[1,8], A[2,8], A[1,9], A[2,9], A[4,9], A[1,10], A[2,10], A[4,10], A[1,11], A[2,11], A[4,11], A[1,12], A[2,12], A[4,12])			
			*Mat list b
			qui mat rown b = `i'
			qui mat coln b = "coef not urban strongly disagree" "SE not urban strongly disagree" "coef not urban disagree" "SE not urban disagree" "coef not urban agree" "SE not urban agree" "coef not urban strongly agree" "SE not urban strongly agree" "coef urban strongly disagree" "SE urban strongly disagree" "coef urban disagree" "SE urban disagree" "coef urban agree" "SE urban agree" "coef not urban strongly agree" "SE not urban strongly agree" "strongly disagree diff" "se strongly disagree diff" "p value strongly disagree diff" "disagree diff" "se disagree diff" "p value disagree diff" "agree diff" "se agree diff" "p value agree diff" "strongly agree diff" "se strongly agree diff" "p value strongly agree diff"
			if `num' == 0 { 	
				cap mat drop analysis 
				mat analysis = b
			}
			else {
				mat analysis = analysis \ b
			}
			local ++num 
	}
putexcel set "`PISApath'UrbanScienceBeliefsTable2015.xls", modify sheet("`var'", replace) 
putexcel A1 = matrix(analysis, names)

}

**********************************************************************
* Table 5-*: School location results, science awareness, urban dummy *
**********************************************************************

*** Looped command, science performance by science awareness 2015 ***

levelsof cntryid, local(cntryidlvls)
local scienceawareness st092q01ta st092q02ta st092q04ta st092q05ta st092q06na st092q08na st092q09na

foreach var in `scienceawareness'{
	local num = 0
	foreach i of local cntryidlvls {
		repest PISA2015 if cntryid==`i', estimate(freq `var') over (urban_dummy, test) flag
		*Return list
			cap mat list r(table)
			cap mat drop A
			qui mat A = r(table)
			
			*Coefficients
			cap mat drop b
			qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5], A[1,6], A[2,6], A[1,7], A[2,7], A[1,8], A[2,8], A[1,9], A[2,9], A[4,9], A[1,10], A[2,10], A[4,10], A[1,11], A[2,11], A[4,11], A[1,12], A[2,12], A[4,12])			
			*Mat list b
			qui mat rown b = `i'
			qui mat coln b = "coef not urban never heard" "SE not urban never heard" "coef not urban cannot explain" "SE not urban cannot explain" "coef not urban familiar" "SE not urban familiar" "coef not urban know something" "SE not urban know something" "coef urban never heard" "SE urban never heard" "coef urban cannot explain" "SE urban cannot explain" "coef urban familiar" "SE urban familiar" "coef not urban know something" "SE not urban know something" "never heard diff" "se never heard diff" "p value never heard diff" "cannot explain diff" "se cannot explain diff" "p value cannot explain diff" "familiar diff" "se familiar diff" "p value familiar diff" "know something diff" "se know something diff" "p value know something diff"
			if `num' == 0 { 	
				cap mat drop analysis 
				mat analysis = b
			}
			else {
				mat analysis = analysis \ b
			}
			local ++num 
	}
putexcel set "`PISApath'UrbanScienceAwarenessTable2015.xls", modify sheet("`var'", replace) 
putexcel A1 = matrix(analysis, names)

}


*****************************************************************************
* 																            *
* Step 6: Conducts 2015 analyses, other variables by urban dummy, condensed *
*																            *
*****************************************************************************

clear

local PISApath "G:/Conferences/School Location CIES/"

use "`PISApath'/PISA_orig_merged_2015_foruse.dta"

****************************************************************
* Table 6-*: Frequency, science issues, urban dummy, condensed *
****************************************************************

*** Looped command, frequency science issues 2015 ***

levelsof cntryid, local(cntryidlvls)
local scienceissues st093q01ta st093q03ta st093q04ta st093q05ta st093q06ta st093q07na st093q08na

foreach var in `scienceissues'{
	local num = 0
	foreach i of local cntryidlvls {
		repest PISA2015 if cntryid==`i', estimate(freq `var'_binary) over (urban_dummy, test) flag
		*Return list
			cap mat list r(table)
			cap mat drop A
			qui mat A = r(table)
			
			*Coefficients
			cap mat drop b
			qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5], A[4,5])
			
			*Mat list b
			qui mat rown b = `i'
			qui mat coln b = "coef not urban worse" "SE not urban worse" "coef not urban improve" "SE not urban improve" "coef urban worse" "SE urban worse" "coef urban improve" "SE urban improve" "diff" "diff se" "p value" 
				cap mat drop analysis 
				mat analysis = b
			}
			else {
				mat analysis = analysis \ b
			}
			local ++num 
	}
putexcel set "`PISApath'UrbanScienceIssuesCondensedTable2015.xls", modify sheet("`var'", replace) 
putexcel A1 = matrix(analysis, names)

}

*****************************************************************
* Table 7-*: Frequency, science beliefs, urban dummy, condensed *
*****************************************************************

*** Looped command, frequency by science beliefs 2015 ***

levelsof cntryid, local(cntryidlvls)
local sciencebeliefs st131q01na st131q03na st131q04na st131q06na st131q08na st131q11na

foreach var in `sciencebeliefs'{
	local num = 0
	foreach i of local cntryidlvls {
		repest PISA2015 if cntryid==`i', estimate(freq `var'_condensed) over (urban_dummy, test) flag
		*Return list
			cap mat list r(table)
			cap mat drop A
			qui mat A = r(table)
			
			*Coefficients
			cap mat drop b
			qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5], A[4,5])			
			*Mat list b
			qui mat rown b = `i'
			qui mat coln b = "coef not urban disagree" "SE not urban disagree" "coef not urban agree" "SE not urban agree" "coef urban disagree" "SE urban disagree" "coef urban agree" "SE urban agree" "diff" "se diff" "p value diff"
			if `num' == 0 { 	
				cap mat drop analysis 
				mat analysis = b
			}
			else {
				mat analysis = analysis \ b
			}
			local ++num 
	}
putexcel set "`PISApath'UrbanScienceBeliefsCondensedTable2015.xls", modify sheet("`var'", replace) 
putexcel A1 = matrix(analysis, names)

}

*******************************************************************
* Table 8-*: Frequency, science awareness, urban dummy, condensed *
*******************************************************************

*** Looped command, frequency by science awareness 2015 ***

levelsof cntryid, local(cntryidlvls)
local scienceawareness st092q01ta st092q02ta st092q04ta st092q05ta st092q06na st092q08na st092q09na

foreach var in `scienceawareness' {
	local num = 0
	foreach i of local cntryidlvls {
		repest PISA2015 if cntryid==`i', estimate(freq `var'_condensed) over (urban_dummy, test) flag
		*Return list
			cap mat list r(table)
			cap mat drop A
			qui mat A = r(table)
			
			*Coefficients
			cap mat drop b
			qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5], A[4,5])
			*Mat list b
			qui mat rown b = `i'
			qui mat coln b = "coef not urban unfamiliar" "SE not urban unfamiliar" "coef not urban familiar" "SE not urban familiar" "coef urban unfamiliar" "SE urban unfamiliar" "coef urban familiar" "SE urban familiar" "diff" "se diff" "p value diff"
			if `num' == 0 { 	
				cap mat drop analysis 
				mat analysis = b
			}
			else {
				mat analysis = analysis \ b
			}
			local ++num 
	}
putexcel set "`PISApath'UrbanScienceAwarenessCondensedTable2015.xls", modify sheet("`var'", replace) 
putexcel A1 = matrix(analysis, names)

}

********************************
* 							   *
* Step 6: Regression analyses  *
*							   *
********************************

********************************************************************
* Table 9-*: Regression, science awareness, urban dummy, condensed *
********************************************************************

*** Looped command, linear science awareness control for performance ***

levelsof cntryid, local(cntryidlvls)
local scienceawareness st092q01ta st092q02ta st092q04ta st092q05ta st092q06na st092q08na st092q09na

foreach var in `scienceawareness' {
	foreach i of local cntryidlvls {
		local lb : label (cntryid)`i'
		repest PISA2015 if cntryid==`i', estimate(stata: reg `var'_condensed pv@scie urban_dummy, robust)
		cap outreg2 using UrbanScienceAwarenessLinRegTable`var'2015.xls, ctitle("`lb'")
	}
}

*** Looped command, logistic science awareness control for performance ***

levelsof cntryid, local(cntryidlvls)
local scienceawareness st092q01ta st092q02ta st092q04ta st092q05ta st092q06na st092q08na st092q09na

foreach var in `scienceawareness' {
	foreach i of local cntryidlvls {
		local lb : label (cntryid)`i'
		repest PISA2015 if cntryid==`i', estimate(stata: logistic `var'_condensed pv@scie urban_dummy, or robust)
		cap outreg2 using UrbanScienceAwarenessLogRegTable`var'2015.xls, ctitle("`lb'")
	}
}

*** Looped command, probit science awareness control for performance ***

levelsof cntryid, local(cntryidlvls)
local scienceawareness st092q01ta st092q02ta st092q04ta st092q05ta st092q06na st092q08na st092q09na

foreach var in `scienceawareness' {
	foreach i of local cntryidlvls {
		local lb : label (cntryid)`i'
		repest PISA2015 if cntryid==`i', estimate(stata: probit `var'_condensed pv@scie urban_dummy, or robust)
		cap outreg2 using UrbanScienceAwarenessProbRegTable`var'2015.xls, ctitle("`lb'")
	}
}

******************************************************************
* Table 10-*: Regression, science issues, urban dummy, condensed *
******************************************************************

*** Looped command, linear science issues control for performance ***

levelsof cntryid, local(cntryidlvls)
local scienceissues st093q01ta st093q03ta st093q04ta st093q05ta st093q06ta st093q07na st093q08na

foreach var in `scienceissues' {
	foreach i of local cntryidlvls {
		local lb : label (cntryid)`i'
		repest PISA2015 if cntryid==`i', estimate(stata: reg `var'_binary pv@scie urban_dummy, robust)
		cap outreg2 using UrbanScienceIssuesLinRegTable`var'2015.xls, ctitle("`lb'")
	}
}

*** Looped command, logistic science issues control for performance ***

levelsof cntryid, local(cntryidlvls)
local scienceissues st093q01ta st093q03ta st093q04ta st093q05ta st093q06ta st093q07na st093q08na

foreach var in `scienceissues' {
	foreach i of local cntryidlvls {
		local lb : label (cntryid)`i'
		repest PISA2015 if cntryid==`i', estimate(stata: logistic `var'_binary pv@scie urban_dummy, or robust)
		cap outreg2 using UrbanScienceIssuesLogRegTable`var'2015.xls, ctitle("`lb'")
	}
}

*** Looped command, probit science awareness control for performance ***

levelsof cntryid, local(cntryidlvls)
local scienceissues st093q01ta st093q03ta st093q04ta st093q05ta st093q06ta st093q07na st093q08na

foreach var in `scienceissues' {
	foreach i of local cntryidlvls {
		local lb : label (cntryid)`i'
		repest PISA2015 if cntryid==`i', estimate(stata: probit `var'_binary pv@scie urban_dummy, or robust)
		cap outreg2 using UrbanScienceIssuesProbRegTable`var'2015.xls, ctitle("`lb'")
	}
}

*******************************************************************
* Table 11-*: Regression, science beliefs, urban dummy, condensed *
*******************************************************************

*** Looped command, linear science beliefs control for performance ***

levelsof cntryid, local(cntryidlvls)
local sciencebeliefs st131q01na st131q03na st131q04na st131q06na st131q08na st131q11na

foreach var in `sciencebeliefs' {
	foreach i of local cntryidlvls {
		local lb : label (cntryid)`i'
		repest PISA2015 if cntryid==`i', estimate(stata: reg `var'_condensed pv@scie urban_dummy, robust)
		cap outreg2 using UrbanScienceBeliefsLinRegTable`var'2015.xls, ctitle("`lb'")
	}
}

*** Looped command, logistic science beliefs control for performance ***

levelsof cntryid, local(cntryidlvls)
local sciencebeliefs st131q01na st131q03na st131q04na st131q06na st131q08na st131q11na

foreach var in `sciencebeliefs' {
	foreach i of local cntryidlvls {
		local lb : label (cntryid)`i'
		repest PISA2015 if cntryid==`i', estimate(stata: logistic `var'_condensed pv@scie urban_dummy, or robust)
		cap outreg2 using UrbanScienceBeliefsLogRegTable`var'2015.xls, ctitle("`lb'")
	}
}

*** Looped command, probit science beliefs control for performance ***

levelsof cntryid, local(cntryidlvls)
local sciencebeliefs st131q01na st131q03na st131q04na st131q06na st131q08na st131q11na

foreach var in `sciencebeliefs' {
	foreach i of local cntryidlvls {
		local lb : label (cntryid)`i'
		repest PISA2015 if cntryid==`i', estimate(stata: probit `var'_condensed pv@scie urban_dummy, or robust)
		cap outreg2 using UrbanScienceBeliefsProbRegTable`var'2015.xls, ctitle("`lb'")
	}
}
