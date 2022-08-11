preserve

	set more off
	xtset firm year
	
	******************
	* Firm Variables *
	******************
	
	gen meanwage = wages_adj/ employees if wages_adj > 0 
	
	foreach var in revenue_lrb assets wages_adj total_liquid_assets total_costs {
		replace `var' = 0 if mi(`var')
		replace `var' = `var' / 10000
		
	}
	
	
	
	*winsor2 total_liquid_assets costs_lrb  revenue_lrb assets employees wages_adj, replace cut(1 99)
	
	
	*****************
	* Tax Variables *
	*****************
	gen sales = VAT + bt + consumption
	gen fraction_sales = sales /  total
	gen fraction_cit = cit / total
	gen fraction_other = other_remittance / total
	gen fraction_pit = pit / total
	
	
	
	********************
	* Budget Variables *
	********************
	
	gen avgwage = 12*max_pension/3
	gen ratio1 = pension_outlay*10000 /(working_age)	
	gen ratio2 = pension_outlay*10000 /(working_age*avgwage)
	
	
	*drop if mi(pension_outlay)
	
	matrix storage = J(8,7,1)
	
	matrix rownames storage = Revenue(10000s) Costs(10000s) Total_Assets(10000s) Liquid_Assets(10000s) Employees Net_of_SI_Total_Wages(10000s) Mean_Wage Statutory_Mean_Wage
*SI_Taxes;Total_Taxes VAT_and_Sales;Total_Taxes CIT;Total_Taxes PIT;Total_Taxes Other_Taxes;Total_Taxes	
	matrix colnames storage = Mean P25 P50 P75 P90 P95 N 
	
	local vars = "revenue_lrb total_costs  assets total_liquid_assets employees wages_adj meanwage avgwage"
	
	local index = 1
	
	foreach var of local vars {
	

		winsor2 `var', cut(5 95) replace 	

/*
		if inlist(`index',1,2,3,4, 5,6, 13)  local round = 0
		else if inlist(`index',5,6,7,8,9,10) local round = 3		
		else local round = 2
				*/
			
		local round = 0	
		su `var' , d
		local mean: di %7.`round'f `r(mean)'
		local sd: di %7.`round'f `r(sd)'
		local median: di %7.`round'f `r(p50)'
		local p25: di %7.`round'f `r(p25)'
		local p75: di %7.`round'f `r(p75)'
		local p90: di %7.`round'f `r(p90)'
		local p95: di %7.`round'f `r(p95)'
		local N: di %7.0f `r(N)'
		
		
		
		matrix storage[`index',1] = `mean'
		matrix storage[`index',2] = `p25'
		matrix storage[`index',3] = `median'
		matrix storage[`index',4] = `p75'
		matrix storage[`index',5] = `p90'	
		matrix storage[`index',6] = `p95'
		matrix storage[`index',7] = `N'

			
		local index = `index' + 1
		
	}	
	
	estout matrix(storage) using $output/descriptives_table_small_covid.tex, replace style(tex) nolegend ///
	prehead( "\begin{tabular}{lcccccccc} \toprule ") ///
	posthead(\midrule) prefoot(\midrule) postfoot("\bottomrule" "\end{tabular}") mlabel(none) substitute(: "\#" _ " " ; "/") type

restore
