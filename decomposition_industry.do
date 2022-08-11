preserve

	keep if participation == 1

	ds insurance_fund UI injury medical_insurance
	foreach var in `r(varlist)' {
		replace `var' = 0 if mi(`var')
	}

	replace subsidy_costs = ln(subsidy_costs)
	replace avg_wage = ln(avg_wage)
	replace labor_intensity = ln(labor_intensity)

	replace indcode = 8 if indcode == 11 //put mining with hydrolics, environment, and other. Mining is too small of category.
	drop if indcode == 15 // drop public admin, too small
	replace indcode = 20 if ind2 == 52 // split wholesale and retail. 20 -- retail.
	replace indcode = 21 if inrange(ind2,25,41) // seprate equipment, chemincal, and relate manufacturing from textiles/food/related. 21 == the former.

	winsor2 subsidy_costs labor_intensity avg_wage, by(indcode) cut(5 95) replace

	reghdfe subsidy_costs labor_intensity avg_wage, noabsorb
	matrix temp = r(table)
	matrix b = temp[1,1..3]

	gcollapse (mean) subsidy_costs labor_intensity avg_wage, by(indcode)

	egen min_labor_intensity = min(labor_intensity)
	sum min_labor_intensity
	assert r(sd) == 0
	egen max_avg_wage = max(avg_wage)
	sum max_avg_wage
	assert r(sd) == 0

	predict fitted
	gsort -subsidy_costs
	gen indsort = _n

	count
	local N = r(N)

	recode indcode (12=11) (13=12) (14=13) (16=14) (17=15)(18=16) (19=17) (20=18) (21=19), gen(indlabels)
	label define indlabels 1 "Agriculture" 2 "Construction" 3 "Culture" 4 "Education" 5 "Utilities" 6 "Finance" 7 "Health care/social services" 8 "Environment" 9 "Hospitality" 10 "Light manufacturing" 11 "Real estate" 12 "Rental/business services" 13 "Residential services" 14 "Science" 15 "Communications, software, IT" 16 "Transportation" 17 "Wholesale" 18 "Retail" 19 "Heavy manufacturing"
	label values indlabels indlabels

	label define indsort 0 "", replace
	forval i = 1/`N' {
		sum indlabels if indsort == `i'
		local label_number = `r(mean)'
		local this_label : label indlabels `label_number'
		label define indsort `i' "`this_label'", modify
	}
	label values indsort indsort

	gen counterfactual1 = labor_intensity*b[1,1] + max_avg_wage*b[1,2] + b[1,3]  if !mi(fitted)
	gen counterfactual2 = min_labor_intensity*b[1,1] + max_avg_wage*b[1,2] + b[1,3]  if !mi(fitted)

	twoway	(connected subsidy_costs indsort) ///
		(connected fitted indsort) ///
		(connected counterfactual1 indsort) ///
		(connected counterfactual2 indsort) ///
		, xlabel(1(1)19, gmax val angle(30)) xtitle("") ///
		legend(label(1 "Mean (Simulated Subsidy / Costs)") label(2 "Fitted Values") ///
		label(3 "Fitted Values at Max Average Wage") ///
		label(4 "Fitted Values at Min Labor Intensity and Max Average Wage") ///
		rows(4) pos(6)) ///
		ytitle("Ln(Subsidy / Total Costs)") ylabel(, gmax)
	graph export $output/industry_decomposition.pdf, replace
restore
