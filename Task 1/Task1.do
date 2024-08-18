//////////////////TASK 1////////////////////

clear 
set more off

*****Set directories*****
global taskfolder1 "~\Downloads\P3 Assessment\Task 1"
global testfolder "~\Downloads\UNICEF-P3-assessment-public-main\UNICEF-P3-assessment-public-main\01_rawdata"

*****Import data: sab and SAB*****
cd "$testfolder"

import delimited using fusion_GLOBAL_DATAFLOW_UNICEF_1.0_.MNCH_ANC4+MNCH_SAB.csv

**Delete Unnecessary Variables
drop dataflow sexsex unit_multiplierunitmultiplier unit_measureunitofmeasure obs_statusobservationstatus obs_confobservationconfidentaili lower_boundlowerbound upper_boundupperbound wgtd_sampl_sizeweightedsamplesiz obs_footnoteobservationfootnote series_footnoteseriesfootnote data_sourcedatasource source_linkcitationoforlinktothe custodiancustodian time_period_methodtimeperiodacti ref_periodreferenceperiod coverage_timetheperiodoftimeforw agecurrentage

**Rename Indicators and Variables
rename obs_val value
rename time_period year
rename indicatorindicator indicator
rename ref_ countryandcode

replace indicator = "ANC4" if regex(indicator, "Antenatal care")
replace indicator = "SAB" if regex(indicator, "birth attendant")

**Separate country code, country name and drop non-countries
split countryandcode, parse(":")
rename countryandcode1 country_code
rename countryandcode2 country

replace country_code = trim(country_code)
replace country = trim(country)

order country_code, first
order country, after(country_code)

drop countryandcode

drop if regex(country_code, "WHO") | regex(country_code, "UNFPA") | regex(country_code, "UNICEF") | regex(country_code, "UNSDG") | regex(country_code, "WORLD")

**Genearate latest SAB and ANC4 values and drop values that are not the latest
sort country year
by country: gen latest_year_anc4 = year[_N] if indicator == "ANC4"
by country: gen latest_year_sab = year[_N] if indicator == "SAB"

by country (year): egen value_latest_anc4 = total(value) if year == latest_year_anc4
by country (year): egen value_latest_sab = total(value) if year == latest_year_sab

drop if value_latest_sab == . & value_latest_anc4 == .

tempfile values

save `values', replace

******Import data: On-track and off-track countries*****
clear

import excel using "On-track and off-track countries", firstrow


rename ISO3Code country_code
rename OfficialName country
rename StatusU5MR status

tempfile onoff
save `onoff', replace

******Merge Values table with on/offtrack table*****
use `values', clear

merge m:1 country_code using `onoff'

**Drop the 61 countries where on/off classification was not present (2) and for which there were no sab/SAB values (59)
*NOTE IN THE REPORT THE COUNTRIES DROPPED: country
/*
Bermuda
Kosovo (UNSCR 1244)
Angola
Andorra
Armenia
Belgium
Botswana
Switzerland
Congo
Cook Islands
Comoros
Czechia
Djibouti
Eritrea
Micronesia (Federated States of)
Gabon
United Kingdom
Equatorial Guinea
Grenada
Guatemala
Haiti
Hungary
Ireland
Iran (Islamic Republic of)
Israel
Republic of Korea
Lao People's Democratic Republic
Lebanon
Libya
Sri Lanka
Luxembourg
Latvia
Monaco
Maldives
Mexico
Marshall Islands
Myanmar
Namibia
Nicaragua
Niue
Netherlands (Kingdom of the)
Nauru
Democratic People's Republic of Korea
Kosovo (UNSCR 1244)
Sudan
Solomon Islands
San Marino
Slovenia
Sweden
Eswatini
Syrian Arab Republic
Togo
Tajikistan
Trinidad and Tobago
United Republic of Tanzania
Ukraine
Saint Vincent and the Grenadines
British Virgin Islands
Vanuatu
Yemen
South Africa
*/

drop if _merge == 1 | _merge == 2
drop _merge

tempfile values_and_onoff
save `values_and_onoff', replace

***Import: Population Data***
clear
import excel using "WPP2022_GEN_F01_DEMOGRAPHIC_INDICATORS_COMPACT_REV1", sheet("Projections") cellrange(A16)

drop in 1

cd "$taskfolder1"

export excel using "population_data_temp.xlsx", replace

clear

import excel using "population_data_temp.xlsx", firstrow

rename Regionsubregioncountryorar country
rename ISO3Alphacode country_code
rename Year year
rename Birthsthousands births



**Drop unnecessary variables (lee[y year, country code, country name and births
drop Index Variant Notes Locationcode ISO2Alphacode SDMXcode Type Parentcode TotalPopulationasof1Januar TotalPopulationasof1July MalePopulationasof1Julyt FemalePopulationasof1July PopulationDensityasof1July PopulationSexRatioasof1Ju MedianAgeasof1Julyyears NaturalChangeBirthsminusDea RateofNaturalChangeper100 PopulationChangethousands PopulationGrowthRatepercenta PopulationAnnualDoublingTime Birthsbywomenaged15to19t CrudeBirthRatebirthsper10 TotalFertilityRatelivebirth NetReproductionRatesurviving MeanAgeChildbearingyears SexRatioatBirthmalesper10 TotalDeathsthousands MaleDeathsthousands FemaleDeathsthousands CrudeDeathRatedeathsper10 LifeExpectancyatBirthboths MaleLifeExpectancyatBirthy FemaleLifeExpectancyatBirth LifeExpectancyatAge15both MaleLifeExpectancyatAge15 FemaleLifeExpectancyatAge15 LifeExpectancyatAge65both MaleLifeExpectancyatAge65 FemaleLifeExpectancyatAge65 LifeExpectancyatAge80both MaleLifeExpectancyatAge80 FemaleLifeExpectancyatAge80 InfantDeathsunderage1thou InfantMortalityRateinfantde LiveBirthsSurvivingtoAge1 UnderFiveDeathsunderage5 UnderFiveMortalitydeathsund MortalitybeforeAge40bothse MaleMortalitybeforeAge40de FemaleMortalitybeforeAge40 MortalitybeforeAge60bothse MaleMortalitybeforeAge60de FemaleMortalitybeforeAge60 MortalitybetweenAge15and50 MaleMortalitybetweenAge15an FemaleMortalitybetweenAge15 MortalitybetweenAge15and60 BJ BK NetNumberofMigrantsthousand NetMigrationRateper1000po

**Drop unnecessary observations, keeping only countries and data for 2022
destring year, replace

drop if year !=2022

**Drop 1 more country with no data
drop if country_code == "" | country_code == "VAT"

destring births, replace

replace births = births * 1000

tempfile population_file
save `population_file', replace

*****Merge with master file
use `values_and_onoff', clear

merge m:1 country_code using `population_file'

drop if _merge == 2
drop _merge

*****Prepare master file for analysis*****
replace status = "1" if status == "Acceleration Needed"
replace status = "2" if status == "On Track"
replace status = "2" if status == "Achieved"

destring status, replace

label define status 1 "Off-track countries" 2 "On-Track countries", modify
label values status status

*****Create weighted coverage for on-track countries: ANC4; noting that latest available anc4 is used*****
egen total_weighted_anc4_ontrack = total(value_latest_anc4 * births) if status == 2


egen total_weight_ontrack = total(births) if status == 2
gen weighted_anc4_coverage_ontrack = total_weighted_anc4_ontrack / total_weight_ontrack if status == 2

*****Create weighted coverage for off-track countries: ANC4; noting that latest available sab is used*****
egen total_weighted_anc4_offtrack = total(value_latest_anc4 * births) if status == 1


egen total_weight_offtrack = total(births) if status == 1
gen weighted_anc4_coverage_offtrack = total_weighted_anc4_offtrack / total_weight_offtrack if status == 1

*****Conduct a quick weighted regression to see statisical significant
reg value_latest_anc4 status [pweigh=births]
*not statistically significant!


*****Create weighted coverage for on-track countries: sab; noting that latest available sab is used*****
egen total_weighted_sab_ontrack = total(value_latest_sab * births) if status == 2


gen weighted_sab_coverage_ontrack = total_weighted_sab_ontrack / total_weight_ontrack if status == 2

*****Create weighted coverage for off-track countries: sab; noting that latest available sab is used*****
egen total_weighted_sab_offtrack = total(value_latest_sab * births) if status == 1


gen weighted_sab_coverage_offtrack = total_weighted_sab_offtrack / total_weight_offtrack if status == 1

*****Conduct a quick weighted regression to see statisical significant
reg value_latest_sab status [pweigh=births]
*statistically significant!


*****Graph both variables*****
gen weighted_anc4_coverage_all = .
replace weighted_anc4_coverage_all = weighted_anc4_coverage_offtrack if status == 1
replace weighted_anc4_coverage_all = weighted_anc4_coverage_ontrack if status == 2

gen weighted_sab_coverage_all = .
replace weighted_sab_coverage_all = weighted_sab_coverage_offtrack if status == 1
replace weighted_sab_coverage_all = weighted_sab_coverage_ontrack if status == 2

global varlist "weighted_anc4_coverage_all weighted_sab_coverage_all"
local byvar "status"
local filename coverage_by_status
	
graph hbar (mean) $varlist, over(`byvar', sort(1) descending) ///
	plotregion(lcolor(none)) ysc(noline) yscale(off) yla(none)  ytitle("Percentage") bar(1, color(eltblue)) ///
	bar(2,  color(orange*.8)) title("") ///
	blabel(bar, format(%3.1f) pos(inside) color(black) size(medsmall)) legend(label(1 "ANC4 Coverage (%)") label(2 "SAB Coverage (%)") size(small) symx(*.3) col(3) position(6) region(lstyle(none)))
	

graph export `filename'.png, replace as(png)


****Save clean data*****
drop total_weighted_anc4_ontrack total_weight_ontrack total_weighted_anc4_offtrack total_weighted_sab_offtrack total_weight_offtrack total_weighted_sab_ontrack

erase "population_data_temp.xlsx"
save "task1_clean.dta", replace
	


