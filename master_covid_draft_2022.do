set more off
clear all
set scheme plotplainblind, permanently
pause on
set matsize 10000
***************
* Directories *
***************


if "`c(username)'" == "jeff" {
	global wei_input = "/home/weiproject/data/"
	global jeff_input = "/home/jeff/ChinaTax/Data"
	global output = "/home/jeff/ChinaTax/Output/SocialSecurity/covid"
	global code = "/home/jeff/ChinaTax/All_Code/socialsecurity/chinese_social_security/covid_draft_final"
}

if "`c(username)'" == "max" {
	global wei_input = "/home/weiproject/data/"
	global jeff_input = "/home/max/ChinaTax/Data"
	global output = "/home/max/chinese_social_security/Output/Covid"
	global code = "/home/max/chinese_social_security"
}

*****************************
* Create Analysis File Data *
*****************************


include $code/clean_covid.do
include $code/csy_comparison.do

include $code/merge_in_external_data.do
compress *
drop Q* skt*

*******************
* Other Variables *
*******************
gen wages_adj = wages - total_si
gen avg_wage = wages_adj / employees if wages_adj > 0
gen labor_intensity = wages_adj / total_costs if wages_adj > 0

gen rate2016 = rate_pension +rate_medical + rate_maternity + rate_unemployment + .0075
gen ATR = rate2016*12*min_pension/avg_wage if avg_wage < 12*min_pension
replace ATR = rate2016 if inrange(avg_wage,12*min_pension,12*max_pension)
replace ATR = rate2016*12*max_pension/avg_wage if avg_wage > 12*max_pension


***************************************
* Predict Covid Subsidy to Each Firm  *
***************************************


gen employer_share_boai_2016 = insurance_fund * (19.25/27.25)
gen employer_share_UI_2016 = UI * (1/1.75)
gen employer_share_injury_2016 =  injury * (.75/.75)
gen employer_share_med_2016 = medical_insurance * (8 / 10)
gen employer_share_total_2016 = employer_share_boai_2016 ///
	+ employer_share_UI_2016 ///
	+ employer_share_injury_2016 ///
	+ employer_share_med_2016

gen employer_share_nonmed_2019 = (16/19.25) * employer_share_boai_2016 ///
	+ (.5/1) * employer_share_UI_2016 ///
	+ (.75/.75) * employer_share_injury_2016
gen employer_share_med_2019 = (7.88/8) * employer_share_med_2016


gen subsidy = employer_share_nonmed_2019 * (1) * (11/12) ///
	+ employer_share_med_2019 * (50/100) * (5/12) if large==0
replace subsidy = employer_share_nonmed_2019 * (50/100) * (5/12) ///
	+ employer_share_med_2019 * (50/100) * (5/12) if large==1

** Revenue decline assumption applies equally across all SI categories
gen predicted_revenue_decline = -shock_period3 * revenue_lrb

** Cashflow decline assumption
gen cashflow = revenue_lrb - cost_goods_sold
gen cashflow_shock = -shock_period3 * cashflow
gen subsidy3 = (1+shock_period3) * subsidy

* Subsidy ratios
foreach d in costs liquidity cash cashflow {
	// This could be simplified by renaming some variables throughout the code
	if "`d'"=="costs" local v total_costs
	else if "`d'"=="liquidity" local v "liquidity"
	else if "`d'"=="cash" local v "cash"
	else if "`d'"=="cashflow" local v "cashflow_shock"

	gen subsidy_`d' = subsidy / `v'
	gen subsidy_`d'3 = subsidy3 / `v'
	gen subsidy_`d'_part = subsidy_`d' if participation2 == 1
}



**************************
* Sample Cut Tabulations *
**************************


// Generate singleton indicators for variables in final cut ONLY, to match the way
//  the singleton vars are computed in the Sample Selection section.
preserve
	keep if zero_remit == 0 & zero_report == 0 & total_costs > 10000 & revenue_lrb > 10000 & !mi(revenue_lrb) & total_costs > total_si
	bys district: gegen singleton_dist = nunique(firm)
	bys neighborhood: gegen singleton_nb = nunique(firm)
	bys pool: egen singleton_pool = count(revenue_lrb)
	tempfile singletons
	save `singletons', replace
restore

merge m:1 firm using `singletons', nogen
foreach lev in dist nb pool {
	replace singleton_`lev' = . if mi(firm)
}


count if zero_remit == 0 & zero_report == 0 & total_costs > 10000 & revenue_lrb > 10000 & ///
!mi(revenue_lrb) & total_costs > total_si & singleton_dist != 1 & singleton_nb != 1 ///
& singleton_pool != 1 & !mi(firm) & shock_period3 < 0 & cashflow > 0



********************
* Sample Selection *
********************

/* minor cleaning total si should not be less than totaln costs, which include wages */
keep if zero_remit == 0 & zero_report == 0 & total_costs > 10000 & revenue_lrb > 10000 & ///
!mi(revenue_lrb) & total_costs > total_si & shock_period3 < 0 & cashflow > 0

*drop singletons
drop if singleton_dist == 1 | singleton_nb == 1 | singleton_pool == 1

*****************************************************************
* Firm Size Deciles Throughout Province -- Used Throughout Code *
*****************************************************************

* revenue deciles
gegen firm_size_deciles_rev = cut(revenue_lrb), group(10) label

replace employees = 0 if mi(employees)
gegen firm_size_deciles_empl = cut(employees), group(5) label


gen rev10000 = revenue_lrb / 10000

replace firm_size_deciles_rev = firm_size_deciles_rev + 1
estpost tabstat rev10000,  by(firm_size_deciles_rev) statistics(max min) nototal

esttab, cells("min(fmt(%9.0fc)) max(fmt(%9.0fc))") noobs nomtitle nonumber varwidth(20) unstack noisily

estout using $output/revenue_decile_bins.tex, cells("min(fmt(%9.0fc)) max(fmt(%9.0fc))")  unstack ///
 prehead("\begin{tabular}{lcc} \toprule" " & Minimum (10,000s) & Maximum (10,000s) \\ \midrule") ///
 postfoot("\bottomrule \end{tabular}") ///
 mlabels(none) nonumbers style(tex) collabels(none) eqlabels(none) replace type

gegen assets = rowmax(total_assets_z*)

**********************************
* Descriptives table and figures *
**********************************

include $code/descriptive_table_covid.do
include $code/size_gradient_covid.do
include $code/cashflow_descriptive_figs.do
include $code/size_gradient_credit_access.do
include $code/liquidity_size_deciles.do

***********************
* Tax Burden Analysis *
***********************

include $code/tax_burden_analysis_covid.do

***********************************
* Covid Fiscal Responses Analysis *
***********************************

* analysis by firm size decile
include $code/subsidy_analysis_size.do

* analysis by industry
include $code/subsidy_analysis_industry.do

* decomposition of subsidy
include $code/decomposition_gradient.do
include $code/decomposition_industry.do

*aggregate subsidy split
include $code/aggregate_subsidy_split.do


*****************************
* Representativeness checks *
*****************************

include $code/compare_budgets_2016_2019.do


**************************************************************
* Participation Time Trends: Reloads Data for Multiple Years *
**************************************************************

include $code/participation_by_year.do
