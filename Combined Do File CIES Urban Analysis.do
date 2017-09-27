clear

*First file

local PISApath "G:/Conferences/School Location CIES/"

use "`PISApath'/PISA_merged_allyears_foruse.dta"

****************************************************************
* Table 1-a,b,c: Percentage distribution urban dummy, pre 2015 *
****************************************************************

*** Looped command, percent distribution pre 2015 ***

local j 2012 2009 2006
levelsof cntryid, local(cntryidlvls)

foreach year in `j' {
	local num = 0
	foreach i of local cntryidlvls {
		local lb : label (cntryid)`i'
		repest PISA if year==`year' & cntryid==`i', estimate(freq urban_dummy) flag
		*Return list
			cap mat list r(table)
			cap mat drop A
			qui mat A = r(table)
			
			*Coefficients
			cap mat drop b
			qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2])
			
			*Mat list b
			qui mat rown b = `lb'
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
	local lb : label (cntryid)`i'
	repest PISA2015 if year==2015 & cntryid==`i', estimate(freq urban_dummy) flag
	*Return list
		cap mat list r(table)
		cap mat drop A
		qui mat A = r(table)
		
		*Coefficients
		cap mat drop b
		qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2])
		
		*Mat list b
		qui mat rown b = `lb'
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
	local lb : label (cntryid)`i'
	repest PISA2015 if year==2015 & cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (urban_dummy, test) flag
	*Return list
		cap mat list r(table)
		cap mat drop A
		qui mat A = r(table)
		
		*Coefficients
		cap mat drop b
		qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
		
		*Mat list b
		qui mat rown b = `lb'
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

putexcel set "`PISApath'SchoolLocationScienceUrbanPerformanceTables.xls", modify sheet("Urban Dummy 2015", replace) 
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
		local lb : label (cntryid)`i'
		repest PISA if year==`year' & cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (urban_dummy, test) flag
		*Return list
			cap mat list r(table)
			cap mat drop A
			qui mat A = r(table)
			
			*Coefficients
			cap mat drop b
			qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
			
			*Mat list b
			qui mat rown b = `lb'
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

putexcel set "`PISApath'SchoolLocationScienceUrbanPerformanceTables.xls", modify sheet("Urban Dummy `year'", replace) 
putexcel A1 = matrix(analysis, names)

}

**********************
* PISA 2015 Analysis *
**********************

clear

use "`PISApath'Data/PISA_orig_merged_2015_foruse.dta"

********************************************************
* Table 3-a: Percent school location, by country, 2015 *
********************************************************

*** Looped command, percent school location 2015, all categories ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
	local lb : label (cntryid)`i'
	repest PISA2015 if cntryid==`i', estimate(freq sc001q01ta) flag
	*Return list
		cap mat list r(table)
		cap mat drop A
		qui mat A = r(table)
		
		*Coefficients
		cap mat drop b
		qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
		
		*Mat list b
		qui mat rown b = `lb'
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

putexcel set "`PISApath'SchoolLocationPercentTable2015.xls", modify sheet("All Categories", replace) 
putexcel A1 = matrix(analysis, names)

*********************************************************************
* Table 3-b: Percent school location (urban dummy) by country, 2015 *
*********************************************************************

*** Looped command, percent school location 2015, all categories ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
	local lb : label (cntryid)`i'
	repest PISA2015 if cntryid==`i', estimate(freq urban_dummy) flag
	*Return list
		cap mat list r(table)
		cap mat drop A
		qui mat A = r(table)
		
		*Coefficients
		cap mat drop b
		qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2])
		
		*Mat list b
		qui mat rown b = `lb'
		qui mat coln b = "% not urban" "SE not urban" "% urban" "SE not urban"

		qui if `num' == 0 {
			cap mat drop analysis
			mat analysis = b
		}
		
		qui else {
			mat analysis = analysis \ b
		}
		
		local ++num
	}

putexcel set "`PISApath'SchoolLocationPercentTable2015.xls", modify sheet("Urban Dummy", replace) 
putexcel A1 = matrix(analysis, names)

***************************************************************
* Table 4-a: School location results, science, all categories *
***************************************************************

*** Looped command, science performance 2015 ***

levelsof cntryid, local(cntryidlvls)

local num = 0

foreach i of local cntryidlvls {
	local lb : label (cntryid)`i'
	repest PISA2015 if cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (sc001q01ta) flag
	*Return list
		cap mat list r(table)
		cap mat drop A
		qui mat A = r(table)
		
		*Coefficients
		cap mat drop b
		qui mat b = (A[1,1] , A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[1,4], A[2,4], A[1,5], A[2,5])
		
		*Mat list b
		qui mat rown b = `i'
		qui mat coln b = "% not urban" "SE not urban" "% urban" "SE not urban" "town" "SE town" "city" "SE city" "large city" "SE large city"

		qui if `num' == 0 {
			cap mat drop analysis
			mat analysis = b
		}
		
		qui else {
			mat analysis = analysis \ b
		}
		
		local ++num
	}

putexcel set "`PISApath'SchoolLocationResults2015.xls", modify sheet("All Categories Science", replace) 
putexcel A1 = matrix(analysis, names)

************************************************************
* Table 4-b: School location results, science, urban dummy *
************************************************************

*** Looped command, science performance 2015 ***

levelsof cntryid, local(cntryidlvls)
local num = 0

foreach i of local cntryidlvls {
repest PISA2015 if cntryid==`i', estimate(summarize pv@scie, stats(mean)) over (urban_dummy, test) flag
*Return list
	cap mat list r(table)
	cap mat drop A
	qui mat A = r(table)
	
	*Coefficients
	cap mat drop b
	qui mat b = (A[1,1], A[2,1], A[1,2], A[2,2], A[1,3], A[2,3], A[4,3])
	
	*Mat list b
	qui mat rown b = `i'
	qui mat coln b = "coef not urban" "SE not urban" "coef urban" "SE not urban" "diff" "se diff" "p-value"
	qui if `num' == 0 {
		cap mat drop analysis
		mat analysis = b
	}
	
	qui else {
		mat analysis = analysis \ b
	}
	
	local ++num
}
putexcel set "`PISApath'SchoolLocationResults2015.xls", modify sheet("Urban Dummy Science", replace) 
putexcel A1 = matrix(analysis, names)

*******************************************************************
* Table 5-*: School location results, science issues, urban dummy *
*******************************************************************

*Create dummy variables for each category of science issues

*local scienceissues st093q01ta st093q03ta st093q04ta st093q05ta st093q06ta st093q07na st093q08na

*foreach var in `scienceissues' {
	*gen improve_`var' = 0
	*replace improve_`var' = 1 if `var' == 1
	
	*gen same_`var' = 0
	*replace same_`var' = 1 if `var' == 2
	
	*gen worse_`var' = 0
	*replace worse_`var' = 1 if `var' == 3
	
*}

*** Looped command, science performance by science issues 2015 ***

levelsof cntryid, local(cntryidlvls)
local scienceissues st093q01ta st093q03ta st093q04ta st093q05ta st093q06ta st093q07na st093q08na

foreach var in `scienceissues'{
	local num = 0
	foreach i of local cntryidlvls {
		local lb: label (cntryid) `i'
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
putexcel set "`PISApath'SchoolLocationScienceIssuesTable2015.xls", modify sheet("`var'", replace) 
putexcel A1 = matrix(analysis, names)

}

********************************************************************
* Table 6-*: School location results, science beliefs, urban dummy *
********************************************************************

*** Looped command, science performance by science beliefs 2015 ***

levelsof cntryid, local(cntryidlvls)
local sciencebeliefs st131q01na st131q03na st131q04na st131q06na st131q08na st131q11na

foreach var in `sciencebeliefs'{
	local num = 0
	foreach i of local cntryidlvls {
		local lb: label (cntryid) `i'
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
putexcel set "`PISApath'SchoolLocationScienceBeliefsTable2015.xls", modify sheet("`var'", replace) 
putexcel A1 = matrix(analysis, names)

}

**********************************************************************
* Table 7-*: School location results, science awareness, urban dummy *
**********************************************************************

*** Looped command, science performance by science awareness 2015 ***

levelsof cntryid, local(cntryidlvls)
local scienceawareness st092q01ta st092q02ta st092q04ta st092q05ta st092q06na st092q08na st092q09na

foreach var in `scienceawareness'{
	local num = 0
	foreach i of local cntryidlvls {
		local lb: label (cntryid) `i'
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
putexcel set "`PISApath'SchoolLocationScienceAwarenessTable2015.xls", modify sheet("`var'", replace) 
putexcel A1 = matrix(analysis, names)

}
