//////////////////TASK 2////////////////////

clear 
set more off

*****Set directories*****
global taskfolder2 "~\Downloads\P3 Assessment\Task 2"
global testfolder "~\Downloads\UNICEF-P3-assessment-public-main\UNICEF-P3-assessment-public-main\01_rawdata"

*****Import data*****
cd "$testfolder"

import delimited using Zimbabwe_children_under5_interview.csv

cd "$taskfolder2"

**** Keep note
/*
interview_date: "Date of Interview"
child_age_years: "Child age in years"
child_birthday: "Child date of birth"
EC6: "Can (name) identify or name at least ten letters of the alphabet?" "Yes=1/No=2/DK=8"
EC7: "Can (name) read at least four simple, popular words?" "Yes=1/No=2/DK=8"
EC8: "Does (name) know the name and recognize the symbol of all numbers from 1 to 10?" "Yes=1/No=2/DK=8"
EC9: "Can (name) pick up a small object with two fingers, like a stick or a rock from the ground?" "Yes=1/No=2/DK=8"
EC10: "Is (name) sometimes too sick to play?" "Yes=1/No=2/DK=8"
EC11: "Does (name) follow simple directions on how to do something correctly?" "Yes=1/No=2/DK=8"
EC12: "When given something to do, is (name) able to do it independently?" "Yes=1/No=2/DK=8"
EC13: "Does (name) get along well with other children?" "Yes=1/No=2/DK=8"
EC14: "Does (name) kick, bite, or hit other children or adults?" "Yes=1/No=2/DK=8"
EC15: "Does (name) get distracted easily?" "Yes=1/No=2/DK=8"

The following educational areas (and related variables) can be considered:
Literacy + Math: EC6, EC7, EC8
Physical: EC9, EC10
Learning: EC11, EC12
Socio-emotional: EC13, EC14, EC15

*/

*****Clean dates, since we are interested in month-on-month variations*****
rename ïinterview_date interview_date

gen interviewdate_temp = ""
replace interviewdate_temp = "2018-12" if regex(interview_date, "2018-12")

forvalues i = 1/4 {

replace interviewdate_temp = "2019-0`i'" if regex(interview_date, "2019-0`i'")

}

gen interviewdate_clean = monthly(interviewdate_temp, "YM")
format interviewdate_clean %tm


*****Check for missing******
foreach var in ec6 ec7 ec8 ec9 ec10 ec11 ec12 ec13 ec14 ec15 {
tab `var', m
}


*****Construct Indicators (Binary) for Literacy + Math, Physical, Learning and Socio-emotional*****
**As per page 13 of https://data.unicef.org/wp-content/uploads/2023/09/ECDI2030_Technical_Manual_Sept_2023.pdf

*****But first, clean variables*****
**Recode "Don't know" to missing for now
foreach var in ec6-ec15 {
recode `var' (8=.)
}


**Recode "No" to 0
foreach var in ec6-ec15 {
recode `var' (2=0)
}

*****Generate binary for Literacy-numeracy where = 1 if meets at least 2 requirements and =0 if not*****

egen litnum_ontrack_temp = rowtotal(ec6-ec8)
tab litnum_ontrack_temp

gen litnum_ontrack = 0
replace litnum_ontrack = 1 if litnum_ontrack_temp >=2
replace litnum_ontrack = 0 if litnum_ontrack_temp <2


**Drop survey that contains errros
drop if litnum_ontrack_temp == 27

**Drop only survey from 2018 December as it is only n=1
drop if interviewdate_temp == "2018-12"

drop litnum_ontrack_temp

**Categorize DKs for presentation later**

forvalues i = 6/15{

replace ec`i' = 2 if ec`i' == .

label define label 0 "No" 1 "Yes" 2 "Don't know", modify
label val ec`i' label
}


******Generate binary for Physical where = 1 if meets both requirements and =0 if not*****
gen physical_ontrack = 0
replace physical_ontrack = 1 if ec9 == 1 & ec10 == 0

tab ec9 ec10 if physical_ontrack == 1

*****Generate binary for Learning where = 1 if meets both requirements and =0 if not*****
gen learning_ontrack = 0
replace learning_ontrack = 1 if ec11 == 1 & ec12 == 1

*****Generate binary for Social-emotional where = 1 if meets at least 2 requirements and =0 if not *****
***Gen temporary ec14 and ec15 for easy artithmetic calculation
gen ec14_temp = ec14
gen ec15_temp = ec15

recode ec14_temp (1=0) (0=1)
recode ec15_temp (1=0) (0=1)

egen soc_emo_ontrack_temp = rowtotal(ec13 ec14_temp ec15_temp)

gen soc_emo_ontrack = 1 if soc_emo_ontrack_temp >=2
replace soc_emo_ontrack = 0 if soc_emo_ontrack_temp <2

drop soc_emo_ontrack_temp ec14_temp ec15_temp

***** Generate stacked bars for each area, including missings and DK *****
gen age_binary = 0
replace age_binary = 1 if child_age_years == 4
label define age 0 "3 y/o" 1 "4 y/o"
label values age_binary age

local var "ec6"

catplot `var', perc ///
	stack asyvars l1title("") ytitle("Identify/name 10 letters", size(large)) ///
	bar(1, color(orange*.8)) bar(2, color(eltblue)) ///
	blab(bar, ///
	position(center) format(%3.1f) size(large)) ///
	legend(region(lp(blank)) lstyle(none) col(4) pos(6) symxsize(1) size(small)) ///
	yla(none) ///
	ysc(noline) ///
	plotregion(lcolor(none)) nofill ysize(2) name(j6, replace)

local var "ec7"

catplot `var', perc ///
	stack asyvars l1title("") ytitle("Name at least 4 words", size(large)) ///
	bar(1, color(orange*.8)) bar(2, color(eltblue)) ///
	blab(bar, ///
	position(center) format(%3.1f) size(large)) ///
	legend(region(lp(blank)) lstyle(none) col(4) pos(6) symxsize(3)) ///
	yla(none) ///
	ysc(noline) ///
	plotregion(lcolor(none)) nofill ysize(2) name(j7, replace)
	
local var "ec8"

catplot `var', perc ///
	stack asyvars l1title("") ytitle("Recognize symbols 1-10", size(large)) ///
	bar(1, color(orange*.8)) bar(2, color(eltblue)) ///
	blab(bar, ///
	position(center) format(%3.1f) size(large)) ///
	legend(region(lp(blank)) lstyle(none) col(4) pos(6) symxsize(3)) ///
	yla(none) ///
	ysc(noline) ///
	plotregion(lcolor(none)) nofill ysize(2) name(j8, replace)
	
local var "ec9"

catplot `var', perc ///
	stack asyvars l1title("") ytitle("Pick small objects w/ fingers", size(large)) ///
	bar(1, color(orange*.8)) bar(2, color(eltblue)) ///
	blab(bar, ///
	position(center) format(%3.1f) size(large)) ///
	legend(region(lp(blank)) lstyle(none) col(4) pos(6) symxsize(3)) ///
	yla(none) ///
	ysc(noline) ///
	plotregion(lcolor(none)) nofill ysize(2) name(j9, replace)
	
local var "ec10"

catplot `var', perc ///
	stack asyvars l1title("") ytitle("Sometimes too sick to play", size(large)) ///
	bar(1, color(orange*.8)) bar(2, color(eltblue)) ///
	blab(bar, ///
	position(center) format(%3.1f) size(large)) ///
	legend(region(lp(blank)) lstyle(none) col(4) pos(6) symxsize(3)) ///
	yla(none) ///
	ysc(noline) ///
	plotregion(lcolor(none)) nofill ysize(2) name(j10, replace)
	
local var "ec11"

catplot `var', perc ///
	stack asyvars l1title("") ytitle("Follow simple directions", size(large)) ///
	bar(1, color(orange*.8)) bar(2, color(eltblue)) ///
	blab(bar, ///
	position(center) format(%3.1f) size(large)) ///
	legend(region(lp(blank)) lstyle(none) col(4) pos(6) symxsize(3)) ///
	yla(none) ///
	ysc(noline) ///
	plotregion(lcolor(none)) nofill ysize(2) name(j11, replace)
	
	
local var "ec12"

catplot `var', perc ///
	stack asyvars l1title("") ytitle("Able to do something independently", size(large)) ///
	bar(1, color(orange*.8)) bar(2, color(eltblue)) ///
	blab(bar, ///
	position(center) format(%3.1f) size(large)) ///
	legend(region(lp(blank)) lstyle(none) col(4) pos(6) symxsize(3)) ///
	yla(none) ///
	ysc(noline) ///
	plotregion(lcolor(none)) nofill ysize(2) name(j12, replace)
	
local var "ec13"

catplot `var', perc ///
	stack asyvars l1title("") ytitle("Gets along with other children", size(large)) ///
	bar(1, color(orange*.8)) bar(2, color(eltblue)) ///
	blab(bar, ///
	position(center) format(%3.1f) size(large)) ///
	legend(region(lp(blank)) lstyle(none) col(4) pos(6) symxsize(3)) ///
	yla(none) ///
	ysc(noline) ///
	plotregion(lcolor(none)) nofill ysize(2) name(j13, replace)
	
local var "ec14"

catplot `var', perc ///
	stack asyvars l1title("") ytitle("Kicks/bites/hits other children/adults", size(large)) ///
	bar(1, color(orange*.8)) bar(2, color(eltblue)) ///
	blab(bar, ///
	position(center) format(%3.1f) size(large)) ///
	legend(region(lp(blank)) lstyle(none) col(4) pos(6) symxsize(3)) ///
	yla(none) ///
	ysc(noline) ///
	plotregion(lcolor(none)) nofill ysize(2) name(j14, replace)
	
local var "ec15"

catplot `var', perc ///
	stack asyvars l1title("") ytitle("Easily distracted", size(large)) ///
	bar(1, color(orange*.8)) bar(2, color(eltblue)) ///
	blab(bar, ///
	position(center) format(%3.1f) size(large)) ///
	legend(region(lp(blank)) lstyle(none) col(4) pos(6) symxsize(3)) ///
	yla(none) ///
	ysc(noline) ///
	plotregion(lcolor(none)) nofill ysize(2) name(j15, replace)
	
	
grc1leg j6 j7 j8, legendfrom(j6) col(1) name(combine1, replace) title("Literacy-Numeracy", size(large))
grc1leg j9 j10, col(1) legendfrom(j9) name(combine2, replace) title("Physical", size(large))
grc1leg j11 j12, col(1) legendfrom(j11) name(combine3, replace) title("Learning", size(large))
grc1leg j13 j14 j15, col(1) legendfrom(j14) name(combine4, replace) title("Social-emotional", size(large))

local filename "litnum_physical"

grc1leg combine1 combine2, legendfrom(combine1) col(1)

graph export `filename'.png, replace as(png)

local filename "learning_soc-emo"
grc1leg combine3 combine4, legendfrom(combine4) col(1)

graph export `filename'.png, replace as(png)

*note, manually edited the thickness of bars


*****Two-way line chart plotting changes over time, by age*****
***Literacy-numberacy



preserve

local filename "litnum_over_time"
local var "litnum_ontrack"
	

collapse (mean) `var', by(age_binary interviewdate_clean)

twoway connected `var' interviewdate_clean if age_binary==1 , ///
	cmissing(n) ///
	lcolor(eltblue) ///
	mcolor(eltblue) ///
	msymbol(O) || ///
connected `var' interviewdate_clean if age_binary==0 , ///
	legend(symx(3) pos(3) col(1) label(1 "4 year-olds") label(2 "3 year-olds") region(lstyle(none))) ///
	cmissing(n) ///
	connect(l) ///
	msymbol(O) ///
	lcolor(orange) ///
	mcolor(orange) ///
	ylabel(0 "0%" .05 "5%" .1 "10%" .15 "15%" .2 "20%" .25 "25%", grid angle(hor)) ///
	ytitle("Developmentally on Track") ///
	xtitle("") ///
	title("Literacy-Numeracy") ///
	name(g1, replace) ///

restore

graph export `filename'.png, replace as(png)


***Physical

preserve

local filename "phyiscal_over_time"
local var "physical_ontrack"
	

collapse (mean) `var', by(age_binary interviewdate_clean)

twoway connected `var' interviewdate_clean if age_binary==1 , ///
	cmissing(n) ///
	lcolor(eltblue) ///
	mcolor(eltblue) ///
	msymbol(O) || ///
connected `var' interviewdate_clean if age_binary==0 , ///
	legend(off) ///
	cmissing(n) ///
	connect(l) ///
	msymbol(O) ///
	lcolor(orange) ///
	mcolor(orange) ///
	ylabel(.5 "50%" .55 "55%" .6 "60%" .65 "65%" .7 "70%", grid angle(hor)) ///
	ytitle("Developmentally on Track") ///
	xtitle("") ///
	title("Physical") ///
	name(g2, replace) ///

restore

graph export `filename'.png, replace as(png)

***Learning

preserve

local filename "learning_over_time"
local var "learning_ontrack"
	

collapse (mean) `var', by(age_binary interviewdate_clean)

twoway connected `var' interviewdate_clean if age_binary==1 , ///
	cmissing(n) ///
	lcolor(eltblue) ///
	mcolor(eltblue) ///
	msymbol(O) || ///
connected `var' interviewdate_clean if age_binary==0 , ///
	legend(symx(3) pos(3) col(1) label(1 "4 year-olds") label(2 "3 year-olds") region(lstyle(none))) ///
	cmissing(n) ///
	connect(l) ///
	msymbol(O) ///
	lcolor(orange) ///
	mcolor(orange) ///
	ylabel(.6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%", grid angle(hor)) ///
	ytitle("Developmentally on Track") ///
	xtitle("") ///
	title("Learning") ///
	name(g3, replace) ///

restore

graph export `filename'.png, replace as(png)

***Social-emotional

preserve

local filename "soc_emo_over_time"
local var "soc_emo_ontrack"
	

collapse (mean) `var', by(age_binary interviewdate_clean)

twoway connected `var' interviewdate_clean if age_binary==1 , ///
	cmissing(n) ///
	lcolor(eltblue) ///
	mcolor(eltblue) ///
	msymbol(O) || ///
connected `var' interviewdate_clean if age_binary==0 , ///
	legend(off) ///
	cmissing(n) ///
	connect(l) ///
	msymbol(O) ///
	lcolor(orange) ///
	mcolor(orange) ///
	ylabel(0.6 "60%" 0.65 "65%" 0.7 "70%" .75 "75%" .8 "80%" .85 "85%", grid angle(hor)) ///
	ytitle("Developmentally on Track") ///
	xtitle("") ///
	title("Social-emotional") ///
	name(g4, replace) ///

restore

graph export `filename'.png, replace as(png)

***Put the 4 graphs together
local filename "combined_ontrack"

graph combine g1 g2 g3 g4, rows(2) xsize(9)

graph export `filename'.png, replace as(png)

save task2_data_clean.dta, replace


