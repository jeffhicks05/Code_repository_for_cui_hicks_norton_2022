preserve


	keep if participation == 1
	
	
	cap drop subsidy*  
	cap drop costs_participate*

	ds insurance_fund UI injury medical_insurance
	foreach var in `r(varlist)' {
		replace `var' = 0 if mi(`var')
	}

	gen subsidy = ((16/19.25)*insurance_fund + .5*UI +injury)*(11/12)  + (1/2)*(5/12)*(7.88/8)*medical_insurance if large ==0
	replace subsidy = ((16/19.25)*insurance_fund  + .5*UI +injury)*(5/12)/2 + (1/2)*(5/12)*(7.88/8)*medical_insurance if large == 1
	
	gen subsidy_costs = ln(subsidy / total_costs)
	gen average_wage = ln(wages / employees)
	replace labor_intensity = ln(labor_intensity)
	
	
	
	winsor2 subsidy_costs labor_intensity average_wage, by(firm_size_deciles_rev) cut(1 99) replace

	
	reghdfe subsidy_costs labor_intensity average_wage, noabsorb
	*absorb(fes = firm_size_deciles_rev)
	

	matrix temp = r(table)
	matrix b = temp[1,1..3]
	
	predict fitted
		
	gegen top_decile_intensity = mean(labor_intensity if firm_size_deciles_rev== 9)
	gegen top_decile_wage = mean(average_wage if firm_size_deciles_rev == 9)
	
	gen counterfactual1 = labor_intensity*b[1,1] + top_decile_wage*b[1,2] + b[1,3]  if !mi(fitted)
	gen counterfactual2 = top_decile_intensity*b[1,1] + top_decile_wage*b[1,2] + b[1,3]  if !mi(fitted)
	
	
	
	
	
	binscatter fitted counter* firm_size_deciles_rev, ///
	discrete ytitle("Ln(Subsidy/Total Costs)") line(connect)  ///
	legend(pos(6) cols(1) label(1 "Fitted Values") label(2 "Fitted Values at Top Decile Average Wages") ///
	label(3 "Fitted Values at Top Decile Average Wages and Top Decile Labor Intensity")) xtitle(Firm Revenue Deciles)
	
	graph export $output/gradient_decomposition.pdf, replace
	
restore
