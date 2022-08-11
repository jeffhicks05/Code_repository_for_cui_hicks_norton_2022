set more off

local firmtraits total_assets_zcf current_assets_zcf accounts_receivable_zcf inventory_zcf total_liabilities_zcf revenue_lrb total_costs sales_expenses_lrb management_expenses_lrb financial_expenses_lrb total_profit_lrb employees

preserve

	import excel using $jeff_input\CSY_edy2017_table13-2.xlsx, clear firstrow
	
	drop if ind2 == 9999

	keep ind2 N `firmtraits'
	
	destring `firmtraits' , replace 
	 
	 
	gen indcombined = "oil" if inlist(ind2, 7, 25)
	replace indcombined =  "mining" if inlist(ind2, 6, 8, 9, 10, 11, 12)
	replace indcombined = "agmanuf" if inlist(ind2, 13, 14, 15, 16)
	replace indcombined = "textile" if inlist(ind2, 17, 18, 19)
	replace indcombined = "wood" if inlist(ind2, 20, 21, 22)
	replace indcombined = "cult" if inlist(ind2, 23, 24)
	replace indcombined = "chemical" if inlist(ind2, 26, 28)
	replace indcombined = "pharma" if inlist(ind2, 27)
	replace indcombined = "other" if inlist(ind2, 29, 30, 31, 32)
	replace indcombined = "manuf" if inrange(ind2, 33, 41) | ind2==43
	replace indcombined = "waste" if ind2==42
	replace indcombined = "energy" if inlist(ind2, 44, 45)
	replace indcombined = "water" if ind2==46
	
	drop if mi(indcombined)
	
	gcollapse (sum) N (sum) `firmtraits', by(indcombined) 
	
	foreach var in `firmtraits' {
		
		if "`var'" != "employees" replace `var' = `var' * 100000000
		if "`var'" == "employees" replace `var' = `var' * 10000
	}
	
	
	gegen nationwide_total = total(N)
	gen industry_share = N / nationwide_total
	drop nationwide_total

	gen sample = "csy"
	tempfile csy
	save "`csy'"


restore


preserve
	rename total_liquid_assets current_assets_zcf 

	* Select firms in the ASIF sample only
	keep if ((revenue_lrb>20000000 & !mi(revenue_lrb)) | ((org==1) & !inlist(otype, 120, 142, 143, 149)) ) & year==2016 & inrange(ind2,6,46) 
		
	gen indcombined = "oil" if inlist(ind2, 7, 25)
	replace indcombined =  "mining" if inlist(ind2, 6, 8, 9, 10, 11, 12)
	replace indcombined = "agmanuf" if inlist(ind2, 13, 14, 15, 16)
	replace indcombined = "textile" if inlist(ind2, 17, 18, 19)
	replace indcombined = "wood" if inlist(ind2, 20, 21, 22)
	replace indcombined = "cult" if inlist(ind2, 23, 24)
	replace indcombined = "chemical" if inlist(ind2, 26, 28)
	replace indcombined = "pharma" if inlist(ind2, 27)
	replace indcombined = "other" if inlist(ind2, 29, 30, 31, 32)
	replace indcombined = "manuf" if inrange(ind2, 33, 41) | ind2==43
	replace indcombined = "waste" if ind2==42
	replace indcombined = "energy" if inlist(ind2, 44, 45)
	replace indcombined = "water" if ind2==46
	
	drop if mi(indcombined)

	count
	local N = r(N)
	* Generate weights by ind2
	gcollapse (count) N = firm (sum) `firmtraits'  , by(indcombined)
	
	gegen nationwide_total = total(N)
	gen industry_share_prov = N / nationwide_total
	drop nationwide_total

	merge 1:1 indcombined using "`csy'", nogen keepusing(industry_share)


	mkmat industry_share_prov industry_share, matrix(industry_share)
	mat colnames industry_share = Provincial_Admin_Data China_Statistical_Yearbook	
	mat rownames industry_share = Agricultural_manuf Chemical Cultural_products Energy General_manuf Mining ///
	Oil_extraction_and_processing Other_raw_materials Pharmaceuticals Textiles ///
	Waste_processing Water Wood_and_wood_products 
	 
	
	esttab matrix(industry_share, fmt(%5.3f)) using $output/representativeness_sector.tex, tex replace type ///
	lz nonotes nonumbers nomtitles collabels(none) noobs ///
	prehead("\begin{tabular}{lcc} \\ \toprule" " & Provincial Admin Data & China Statistical Yearbook \\" ) ///
	posthead("\midrule") ///
	prefoot("\midrule") ///
	postfoot("Number of firms & `N' & 378599 \\ \bottomrule \end{tabular}") substitute(_ " ")


	keep indcombined `firmtraits' N industry_share_prov
	tempfile prov 
	save "`prov'"
	
	use "`csy'", clear
	foreach var in `firmtraits' {
		replace `var' = `var' / N
	}	
	
	merge 1:1 indcombined using "`prov'", keepusing(industry_share_prov)
	gcollapse (mean) `firmtraits' [aw= industry_share_prov]
	gen sample = " csy" 	
	tempfile csymeans
	save "`csymeans'"
	
	
	use "`prov'", clear
	foreach var in `firmtraits' {
		replace `var' = `var' / N
	}
	gcollapse (mean) `firmtraits' [aw = N]
	gen sample = "prov" 
	append using "`csymeans'"
	
	foreach var in `firmtraits' {
		
		if "`var'" != "employees" replace `var' = `var' / 100000000
		if "`var'" == "employees" replace `var' = `var' 
	}
	
	xpose, clear varname
	
	rename v1 provincial_data
	rename v2 csy_data
	rename _varname variable
	drop if variable == "sample"
	
	
	mkmat provincial_data csy_data, matrix(industry_chars)
	mat colnames industry_chars = Provincial_Admin_Data China_Statistical_Yearbook	
	mat rownames industry_chars = Total_Assets Current_Assets Accounts_Receivable Inventory Total_Liabilities Revenue ///
	Total_Costs Sales_Expenses Management_Expenses Financial_Expenses Total_Profit Emplyoees
	 
	esttab matrix(industry_chars, fmt(%5.3f)) using $output/representativeness_firmtraits_reweighted.tex, tex replace type ///
	lz nonotes nonumbers nomtitles collabels(none) noobs ///
	prehead("\begin{tabular}{lcc} \\ \toprule" " & Provincial Admin Data & China Statistical Yearbook \\" ) ///
	posthead("\midrule") ///
	prefoot("\midrule") ///
	postfoot(" \bottomrule \end{tabular}") substitute(_ " ")

	
	
	
restore





