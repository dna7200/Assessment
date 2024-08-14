
*****************************************************************
*			Standard Quality Assurance .do File					*
*						Version 6								*
*				Brought to you by the GTT						*
*****************************************************************


*****************************************************************
*						ADAPT THIS FILE:						*
* This is the start of the portion of the .do file that will	*
* need to be customized in order to fit your particular 		*
* dataset. First, give this file a new title so you don't 		*
* mess up the template. Then, get to work!						*
*****************************************************************

*****************************************************************
******************* Start Adaptation Here! **********************
*****************************************************************

clear

cd ~/Downloads

* Load the dataset. The command will either be use or usespss.
* Load dataset HHSurvey.dta

import delimited "IOM_CRP_WIDE.csv"

**Run SurveyCTO-generated .do file for cleaning imported .csv**
do "~/Downloads/import_IOM_CRP.do"

* Run cleaning/coding .do file to do any cleaning and coding
* so you don't have to fix the same problem twice.

do "G:\.shortcut-targets-by-id\1FcyT1D9PquU5GMI1rbI5JsdUXGMl85AL\Moz_Projects\Active\1953_IOM\9_Do files\QA and cleaning\IOM_ME_CRP_Pre-QA_cleaning_v1.do"


*Set working directory to tables folder
cd "G:\.shortcut-targets-by-id\1FcyT1D9PquU5GMI1rbI5JsdUXGMl85AL\Moz_Projects\Active\1953_IOM\6_Data\QA"


* Set the working directory to the folder where you want your
* QA or QC tables to end up.



*****************************************************************
*						SET MACROS:								*
* There are macros below that will adapt this .do file			*
* to the variables in your dataset.	Set these ahead of time 	*
* to identify the relevant variables that will be used in 		*
* the code below. Once these are set, you should not need to 	*
* make any further modifications to the	code below.				*
*																*
* If the .do file continues to produce errors, please contact 	*
* the GTT at techteam@forcierconsulting.com						*
*****************************************************************

* If your dataset does not have any of the following variables,
* please write "No_Variable" where the name of the variable would go.

local name CRP
* Make this something brief like an acronym

local duration duration
* Note, the duration variable will be de-strung automatically below.

local flagdur = 15
* This will automatically flag any interview that is less than N 
* minutes in duration. This is set to 10 min by default. Please think
* about your questionnaire's length and set this threshold so that 
* you can automatically flag all interviews that are clearly too short 
* to be valid.

local age age
* Note, the age variable will also be de-string automatically below.

local enum_name enum_name
local enum_code "No_Variable"


local gender gender
* Check your gender variable to make sure that the code for 
* female is 2

local test testlive

global consent consent age_confirm

global locations district community

* Note, if you have used a Kish listing to randomly select a respondent, 
* there is an optional check to see if the age entered during listing 
* matches the age entered once the respondent is selected. If you 
* wish to check this, please enter the age variable for the selected
* respondent from the kish listing (usually kish_selected_age) in 
* the macro below.

local kish_age "No_Variable"


* Do not alter any of the code below this line unless you need
* to further customize this .do file and you really know what
* you're doing.

*****************************************************************
******************* STOP Adaptation Here! ***********************
*****************************************************************







































*******************************************************************
*generate variables for use later

* Create ecode variable for programming use
* Note, this does not alter the enum_name variable

if "`enum_name'" != "No_Variable" {

capture confirm string var `enum_name'

if _rc == 0 {
		replace `enum_name' = substr(`enum_name',1,20)
		encode `enum_name', gen(ecode)
		}
		
else {
		decode `enum_name', gen(temp)
		replace temp = substr(temp,1,20)
		encode temp, gen(ecode)
		drop temp
	}
}

if "`enum_name'" == "No_Variable" {

capture confirm string var `enum_code'
if _rc==0 {
encode `enum_code', gen(ecode)
	}
else {
tostring `enum_code', gen(temp)
	encode temp, gen(ecode)
	drop temp

}
}

*destring key age and duration variables

if "`age'" == "No_Variable" {
foreach var of varlist `duration' {
	capture confirm string var `var'

	if _rc == 0 {
		destring `var', replace
	}
}

}

else {
foreach var of varlist `duration' `age' {
	capture confirm string var `var'

	if _rc == 0 {
		destring `var', replace
	}
}
}

if "`kish_age'" == "No_Variable" {
}

else {

capture confirm string var `kish_age'

	if _rc == 0 {
		destring `kish_age', replace
	}
}

foreach var of varlist $locations {
	capture confirm string var `var'

	if _rc == 0 {
		encode `var', gen(temp)
		drop `var' 
		rename temp `var'
	}
}


*check duration variable for negative values and multi-day interviews
replace `duration' = . if `duration' < 0
replace `duration' = `duration'/60 if `duration' > 500
replace `duration' = `duration'-1440 if `duration' > 1500

********************************************************************



*Flag interviews that are test or not consented
if "`test'" == "No_Variable" {

preserve

foreach var of varlist $consent {
	gen flag_`var' = 0
	replace flag_`var' = 1 if `var' == 0 | `var' == 2
}
	
collapse (sum) flag_* , by(ecode district community)

label var flag_consent "Flag Consent"
label var district "District"
label var community "Community"
label var flag_age_confirm "Flag Age"

export excel using `name'_QA, ///
	sheet("Consent-Test") first(varl) sheetreplace

restore

*Drop out all non-consented interviews
foreach var of varlist $consent {
	drop if `var' != 1 
}
}

else {
preserve

gen flag_test = 0
replace flag_test = 1 if `test' == 1

foreach var of varlist $consent {
	gen flag_`var' = 0
	replace flag_`var' = 1 if `var' == 0 | `var' == 2
}


collapse (sum) flag_* , by(ecode district community)

label var flag_test "Flag Test"
label var flag_consent "Flag Consent"
label var flag_age_confirm "Flag Age"
label var district "District"
label var community "Community"

export excel using `name'_QA, ///
	sheet("Consent-Test") first(varl) sheetreplace

restore

*Drop out all non-consented interviews
drop if `test' == 1

foreach var of varlist $consent {
	drop if `var' != 1 
}

}

************************************
*		Check Demographics
************************************

if "`gender'" == "No_Variable" {
	gen females = .
}

else {
	gen females = 0
	replace females = 1 if `gender' == 2
}

if "`age'" == "No_Variable" {
	gen age = .
	local age age
}

if "`age'" == "No_Variable" & "`gender'" == "No_Variable" {
drop age females
}

else {
preserve 

gen count = 1


collapse females `age' (sum)count, by(ecode district community)

replace females = females *100

label var district "District"
label var females "% Females"
label var `age' "Mean Age"
label var count "N"
label var community "Community"

export excel using `name'_QA, ///
	sheet("Demographics") first(varl) sheetreplace

restore
}


******************************************
*		Check sampling performance
******************************************

*Generate counter to use when collapsing

preserve 

gen count = 1

bysort district community: egen temp_count = total(count)

gen quota = 50

gen quota_percent = temp_count/quota


collapse (sum)count (mean) quota quota_percent, by(district community)

replace quota_percent = quota_percent * 100

label var district "District"
label var community "Community"
label var quota_percent "Quota Percent"
label var count "Completed Interviews"
label var quota "Quota"

export excel using `name'_QA, ///
	sheet("Tracker") first(varl) sheetreplace

restore



*********************************
*		Check Age matches
*********************************

if "`kish_age'" != "No_Variable" {

egen agematch_kish=diff(`age' `kish_age')
replace agematch=. if `age'==.
replace agematch=. if `kish_age'==99 ///
	| `kish_age' == 999

replace `kish_age' = . if `kish_age'==99 ///
	| `kish_age' == 999
	
twoway scatter `age' `kish_age' if `kish_age' <100 & `age' <100, ///
	msize(1.5) mlabc(gs3) msymbol(X) color(gs3) ///
	ytitle(Age Respondent Interviewed) xtitle(Age Respondent Selected) ///
	|| scatter `age' `kish_age' if `age' <80 &agematch==1, ///
	msize(1.5) mlabc(gs3) mlab(`enum_name') ///
	msymbol(X) ytitle(Age Respondent Interviewed) ///
	xtitle(Age Respondent Selected) legend(symx(*.3) ///
	col(1) position(3) region(lstyle(none))  ///
	label (1 "") label (2 "Errors")  order(2))

graph export Graph_ScatterAgeMatch_v1.png, as(png) replace
}

********************************************
*		Check DK and Refuse responses and extreme responses
********************************************

gen missing = 0
gen disagree = 0
gen agree = 0

count
gen n = r(N)

foreach var of varlist _all {
	capture confirm numeric var `var'

	if _rc == 0 {
	
	sum `var'
	gen x = r(N)
	
	if n == x {
		replace missing = missing+1 if `var' == 88 | `var' == 99 | ///
		`var' == 888 | `var' == 999
		replace disagree = disagree +1 if `var' == 1
		replace agree = agree +1 if `var' == 5
	}
	
	drop x
	
	}
}


sum missing, detail
gen miss90 = r(p90)


gen flag_miss = 1 if missing >= miss90 & missing>1

sum disagree, detail
gen disagree_90 = r(p90)

gen flag_disagree = 1 if disagree >= disagree_90 & disagree>1
replace flag_disagree = 0 if flag_disagree == .


sum agree, detail
gen agree_90 = r(p90)

gen flag_agree = 1 if agree >= agree_90 & agree>1
replace flag_agree = 0 if flag_agree == .

gen flag_dur = 1 if `duration' < `flagdur'

*Create scores (OBJECTIVE: HARMONY)
global varlist obj_harmony_conflict obj_trust_1 obj_trust_2 obj_inc_cohe_1 obj_inc_cohe_2 obj_inc_cohe_3 obj_rep_inf_1 obj_rep_inf_2 obj_rep_inf_3

foreach var in $varlist {
replace `var' = . if `var' == 88 | `var' == 99
}

egen obj_harmony_sum = rowtotal($varlist)
gen obj_harmony_count = 0

foreach var in $varlist {
replace obj_harmony_count = obj_harmony_count + 1 if `var' !=.

}

gen obj_harmony_mean = obj_harmony_sum/obj_harmony_count

gen obj_harmony = 0
replace obj_harmony = 1 if obj_harmony_mean >=4

*Create scores (OBJECTIVE: LIFE OPPORTUNITIES)
global varlist obj_opportunity_educ obj_opportunity_employ obj_opportunity_income obj_opportunity_support

foreach var in $varlist {
replace `var' = . if `var' == 88 | `var' == 99
}

egen obj_opport_sum = rowtotal($varlist)
gen obj_opport_count = 0

foreach var in $varlist {
replace obj_opport_count = obj_opport_count + 1 if `var' !=.

}

gen obj_opport_mean = obj_opport_sum/obj_opport_count

gen obj_opport = 0
replace obj_opport= 1 if obj_opport_mean >=4

preserve 




if "`kish_age'" == "No_Variable" {
gen agematch = 0
}

gen count = 1

gen project = 0
replace project = 1 if project_aware_88 == 1



collapse missing (sum)flag_miss flag_disagree flag_agree count  (mean)`duration'  project obj_harmony obj_opport (sum)flag_dur , by(ecode district community)

replace project = project * 100
replace obj_harmony = obj_harmony * 100
replace obj_opport = obj_opport * 100

label var missing "Mean Missing Values"
label var flag_miss "Flag Missing"
label var project "% don't know project"
label var flag_disagree "Flag disagree"
label var flag_agree "Flag agree"
label var flag_dur "Flag Short Interviews"
label var `duration' "Mean Duration"
label var obj_harmony "% harmony"
label var obj_opport "% opportunity"

label var community "Community"
label var district "District"

egen total = rowtotal(flag_*)

label var total "Total Flags"

gen flagrate = (total/count)*100

label var flagrate "Flag Percent"

sort community


drop count

export excel using `name'_QA, ///
	sheet("Enumerator Quality Flags") first(varl) sheetreplace

restore

**Keep flags for manual checks



********************************************************
*		Enumerator X Code, Enumerator X Location
********************************************************

*create variables to adjust for number of enumerators in dataset
gen less16 =0
replace less16 = 1 if ecode <16 & ecode!=.

gen greater15=0
replace greater15=1 if ecode>15 & ecode!=.

gen greater30=0
replace greater30=1 if ecode>30 & ecode!=.

gen greater45=0
replace greater45=1 if ecode>45 & ecode!=.

gen greater60=0
replace greater60=1 if ecode>60 & ecode!=.

egen anygreater=max(less16)
egen anygreater15=max(greater15)
egen anygreater30=max(greater30)
egen anygreater45=max(greater45)
egen anygreater60=max(greater60)

*create variables to adjust for number of enumerators in dataset


******************************************************************
*		Check enumerator codes against enumerator names
******************************************************************

*generate needed variables

if "`enum_name'" == "No_Variable" | "`enum_code'" == "No_Variable"  {
}

else {
	tab `enum_name', gen(enumerator_)

	levelsof `enum_code', local(levels)

	foreach n of local levels {
		gen code_`n' = 0
		replace code_`n' = 1 if `enum_code' == `n'
	}

	*first run for ecode<15


	if anygreater {
		preserve

		drop if ecode>14

		collapse (sum) code_* , by(`enum_name')

		foreach var of varlist code_* {
				egen total_`var' = total(`var')
				if total_`var' == 0 {
						drop `var' 
						}
				}

		drop total_*

		export excel using `name'_QA, ///
			sheet(enum_by_code) sheetrep firstrow(var)

		restore
	}

	*loop over all subsequent ecode levels
	local k = 17

	foreach n of numlist 15 30 45 60 {

		local j = `n'+14

		if anygreater`n' {
			preserve

			drop if ecode<`n' | ecode>`j'

			collapse (sum) code_* , by(`enum_name')

			foreach var of varlist code_* {
				egen total_`var' = total(`var')
				if total_`var' == 0 {
					drop `var' 
				}
			}

		drop total_*

		export excel using `name'_QA, ///
				sheet(enum_by_code) sheetmod cell(A`k') firstrow(var)

		restore

		local k = `k'+17

		}
	}
}

******Start here - need to get dummy variable with name of location

******************************************************************
*		Check locations against enumerator names
******************************************************************

foreach var of varlist $locations {

*first run for ecode<15


if anygreater {
preserve

drop if ecode>14

*Make the dummies and get their levels
tab `var', gen(location_)
levelsof `var', local(levels)

*Save the name of the value label
local val_label : value label `var'

*n = iterates from 1 to x, where x is the number of unique value labels in levels
*z = iterates through the unique values of the original variable
local n = 0

collapse (sum) location_* , by(ecode)

*apply variable labesl to dummies
foreach z of local levels{
local n = `n' + 1

*Save the value label corresponding to value z as vallab`z'
local vallab`z' : label `val_label' `z'

*Apply value label z to dummy variable n
label var location_`n' "`vallab`z''"
}

foreach x of varlist location_* {
	egen total_`x' = total(`x')
	if total_`x' == 0 {
		drop `x' 
		}
	}

drop total_*

export excel using `name'_QA, ///
	sheet(enum_by_`var') sheetrep firstrow(varl)

restore
}

*loop over all subsequent ecode levels
local k = 17
foreach n of numlist 15 30 45 60 {

local j = `n'+14

if anygreater`n' {
preserve

drop if ecode<`n' | ecode>`j'

*Make the dummies and get their levels
tab `var', gen(location_)
levelsof `var', local(levels)

*Save the name of the value label
local val_label : value label `var'

*n = iterates from 1 to x, where x is the number of unique value labels in levels
*z = iterates through the unique values of the original variable
local n = 0

collapse (sum) location_* , by(ecode)

*apply variable labesl to dummies
foreach z of local levels{
local n = `n' + 1

*Save the value label corresponding to value z as vallab`z'
local vallab`z' : label `val_label' `z'

*Apply value label z to dummy variable n
label var location_`n' "`vallab`z''"
}

foreach x of varlist location_* {
	egen total_`x' = total(`x')
	if total_`x' == 0 {
		drop `x' 
		}
	}

drop total_*

export excel using `name'_QA, ///
	sheet(enum_by_`var') sheetmod cell(A`k') firstrow(varl)

restore

local k = `k'+17

}
}
}


***************************************************



cd "G:\.shortcut-targets-by-id\1FcyT1D9PquU5GMI1rbI5JsdUXGMl85AL\Moz_Projects\Active\1953_IOM\6_Data\Data"

save "CRP_Raw", replace

* The End




