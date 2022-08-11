*******************************
* Total Remittance Break Down *
*******************************


preserve

	gen sales = VAT + bt + consumption

	gen fraction_sales = sales /  total
	gen fraction_cit = cit / total
	gen fraction_other = other_remittance / total
	gen fraction_pit = pit / total
	winsor2 fraction*, replace cut(1 99)
	
	gcollapse (mean) fraction* (sum) sales cit total_si pit other_remittance total, by(firm_size_deciles_rev)
	
	foreach var in sales cit total_si pit other_remittance {
		gen ratio_`var' = `var' / total
	}
	

	twoway line fraction_si firm_size_deciles , lwidth(medthick) fintensity(inten20) || ///
		line fraction_pit firm_size ,fintensity(inten20)   lwidth(medthick)  lpattern(dash) || ///
		connected fraction_cit firm_size , fintensity(inten20)  lwidth(medthick)  msize(medlarge)  || ///
		connected fraction_sales firm_size,fintensity(inten20)   lwidth(medthick) msize(medlarge)  || ///
		connected fraction_other firm_size, fintensity(inten20)  lwidth(medthick) msize(medlarge) msymbol(Oh) , ///
		legend(pos(6) cols(5) label(1 "SI Contributions") label(2 "PIT") label(3 "CIT") label(4 "VAT & Sales Taxes") label(5 "Other")) ///
		xtitle(Firm Revenue Deciles) ytitle(Fraction of Total Remittances) ///
		xlabel(#10) scale(1.2)
	graph export $output/remittance_shares_by_decile.pdf, replace
		
restore

*********************
* Average Tax Rates *
*********************


preserve

		
	// 2019 Rates
	gen rate2019 = .16 + .005 + .0075 + .0788 +.008 

	// February to June
	gen rate_temporary1 = .0388 +.008 if large == 0
	replace rate_temporary1 = (.16 + .005 + .0075)*.5 + .0388 +.008 if large == 1

	// July to December
	gen rate_temporary2 = .0788 +.008 if large == 0
	replace rate_temporary2 = (.16 + .005 + .0075) + .0788 +.008 if large == 1

	// Average wage
	winsor2 wages_adj employees, by(firm_size_deciles_rev participation2) cut(1 99) replace
	gen avgwage = wages_adj / employee

	// Anualzied contribution thresholds
	gen min = 12*min_pension
	gen max = 12*max_pension
	
	keep min max rate_temporary* rate2016 rate2019 avgwage firm
	
	tempfile atrs
	save "`atrs'"


restore


preserve
	drop if wages <=0 | employees <=0
	drop ATR*
	
	merge 1:1 firm using "`atrs'", nogen

	gen ATR = rate2016*min/avgwage if avgwage < min
	replace ATR = rate2016 if inrange(avgwage,min,max)
	replace ATR = rate2016*max/avgwage if avgwage > max
		
	gen ATR2019 = rate2019*min/avgwage if avgwage < min
	replace ATR2019 = rate2019 if inrange(avgwage,min,max)
	replace ATR2019 = rate2019*max/avgwage if avgwage > max
	
	gen ATRtemp1 = rate_temporary1*min/avgwage if avgwage < min
	replace ATRtemp1 = rate_temporary1 if inrange(avgwage,min,max)
	replace ATRtemp1 = rate_temporary1*max/avgwage if avgwage > max
	
	gen ATRtemp2 = rate_temporary2*min/avgwage if avgwage < min
	replace ATRtemp2 = rate_temporary2 if inrange(avgwage,min,max)
	replace ATRtemp2 = rate_temporary2*max/avgwage if avgwage > max
	
	gcollapse (median) min max avgwage ATR rate2016 (sum) wages employees , by(firm_size_deciles_rev participation2)
	
	twoway 	(connected avgwage firm_size_deciles_rev if participation2, lwidth(medthick) lpattern(dash) msymbol(Oh)  msize(medlarge) lcolor(black) mcolor(black)) ///
		(connected avgwage firm_size_deciles_rev if !participation2, lwidth(medthick) lpattern(dash) msymbol(Oh)  msize(medlarge) lcolor(gs7) mcolor(gs7)) ///
		(line min firm_size_deciles_rev if participation2, lwidth(medthick) lpattern(dash) msymbol(Oh)  msize(medlarge) lcolor(red) mcolor(red)) ///
		(line max firm_size_deciles_rev if participation2, lwidth(medthick) lpattern(dash) msymbol(Oh)  msize(medlarge) lcolor(red) mcolor(red)) ///
		, xtitle("Firm Revenue Decile") ///
		xlabel(#10 ,labels) ylabel(#10) ///
		ytitle("Average monthly wage (CNY)") ///
		legend(pos(6) ring(2) rows(1) ///
		label(1 "SI participating firms") ///
		label(2 "Non-participants") ///
		label(3 "Min and max taxable wages") ///
		order(1 2 3))
	graph export $output/avg_wage_by_decile.pdf, replace
	
	
	sort firm_size_deciles
	su rate2016
	local mean = r(mean)
	twoway (connected ATR firm_size_decile if participation2 == 0, mcolor(blue) msize(medlarge)) ///
	(connected ATR firm_size_decile if participation2 == 1, mcolor(brown) msize(medlarge)), xlabel(#10) ///
	xtitle("Firm Revenue Decile") ytitle(Average Tax Rate) legend(pos(6) cols(2) label(1 "Non-Contributors") label(2 "Contributors")) ///
	yline(`mean', lcolor(red)) scale(1.2)
	
	graph export $output/ATR_firm_size.pdf, replace
		

restore


preserve
	drop if wages <=0 | employees <=0
	
	keep if participation2 == 1
	drop ATR*
	merge 1:1 firm using "`atrs'", nogen

	gen ATR = rate2016*min/avgwage if avgwage < min
	replace ATR = rate2016 if inrange(avgwage,min,max)
	replace ATR = rate2016*max/avgwage if avgwage > max
		
	gen ATR2019 = rate2019*min/avgwage if avgwage < min
	replace ATR2019 = rate2019 if inrange(avgwage,min,max)
	replace ATR2019 = rate2019*max/avgwage if avgwage > max
	
	gen ATRtemp1 = rate_temporary1*min/avgwage if avgwage < min
	replace ATRtemp1 = rate_temporary1 if inrange(avgwage,min,max)
	replace ATRtemp1 = rate_temporary1*max/avgwage if avgwage > max
	
	gen ATRtemp2 = rate_temporary2*min/avgwage if avgwage < min
	replace ATRtemp2 = rate_temporary2 if inrange(avgwage,min,max)
	replace ATRtemp2 = rate_temporary2*max/avgwage if avgwage > max
	
	gcollapse (median) ATR* (sum) wages employees , by(firm_size_deciles_rev)

	tab ATRtemp2
		
	sort firm_size_deciles 
		
	twoway (connected ATR2019 firm_size_decile , mcolor(blue) msize(medlarge)) ///
	(connected ATRtemp1 firm_size_decile, mcolor(brown) msize(medlarge) lcolor(black)) ///
	(connected ATRtemp2 firm_size_decile, mcolor(brown) msize(medlarge) lcolor(black)), xlabel(#10) ///
	xtitle("Firm Revenue Decile") ytitle(Average Tax Rate) ///
	legend(pos(6) cols(3) label(1 "2019") label(2 "February to June 2020") label(3 "July to December 2020")) scale(1.2)
	
	graph export $output/ATR_firm_size_policy.pdf, replace
	
	

restore




******************
* ATR Robustness *
******************
preserve

	drop if wages_adj <=0| employees <=0

	winsor2 wages_adj employees, by(firm_size_deciles_rev participation2) cut(1 99)  replace
	
	foreach v in rate2016 rate2019 min max avgwage {
		cap drop `v'
	}
	
	// 2016 Rates
	gen rate2016 = rate_pension +rate_medical + rate_maternity + rate_unemployment + .0075
	gen rate2019 = .16 + .005 + .0075 + .0788 +.008 

	// Anualzied contribution thresholds
	gen min = 12*min_pension
	gen max = 12*max_pension
	
	gcollapse (sum) wages_adj employees (mean) min max rate2016,  by(firm_size_deciles_rev participation2)

	gen avgwage = wages_adj / employees

	
	
	gen ATR = rate2016*min/avgwage if avgwage < min
	replace ATR = rate2016 if inrange(avgwage,min,max)
	replace ATR = rate2016*max/avgwage if avgwage > max
			
	sort firm_size_deciles
	
	sort firm_size_deciles
	su rate2016
	local mean = r(mean)
			
	twoway (connected ATR firm_size_decile if participation2 == 0, mcolor(blue) msize(medlarge)) ///
	(connected ATR firm_size_decile if participation2 == 1, mcolor(brown) msize(medlarge)), xlabel(#10) ///
	xtitle("Firm Revenue Decile") ytitle(Average Tax Rate) legend(pos(6) cols(2) label(1 "Non-Contributors") label(2 "Contributors")) ///
	yline(`mean', lcolor(red)) scale(1.2)
	
	graph export $output/ATR_firm_size2.pdf, replace		

restore


preserve
	drop if wages <=0 | employees <=0
	
	keep if participation2 == 1

	winsor2 wages_adj employees, by(firm_size_deciles_rev) cut(5 95) replace
	merge 1:1 firm using "`atrs'", nogen

	gcollapse  (sum) wages_adj employees (mean) min max rate2016 rate2019 rate_temp*, by(firm_size_deciles_rev)

	gen avgwage = wages_adj / employee
	
	gen ATR = rate2016*min/avgwage if avgwage < min
	replace ATR = rate2016 if inrange(avgwage,min,max)
	replace ATR = rate2016*max/avgwage if avgwage > max
		
	gen ATR2019 = rate2019*min/avgwage if avgwage < min
	replace ATR2019 = rate2019 if inrange(avgwage,min,max)
	replace ATR2019 = rate2019*max/avgwage if avgwage > max
	
	gen ATRtemp1 = rate_temporary1*min/avgwage if avgwage < min
	replace ATRtemp1 = rate_temporary1 if inrange(avgwage,min,max)
	replace ATRtemp1 = rate_temporary1*max/avgwage if avgwage > max
	
	gen ATRtemp2 = rate_temporary2*min/avgwage if avgwage < min
	replace ATRtemp2 = rate_temporary2 if inrange(avgwage,min,max)
	replace ATRtemp2 = rate_temporary2*max/avgwage if avgwage > max

		
	sort firm_size_deciles
		
	twoway (connected ATR2019 firm_size_decile , mcolor(blue) msize(medlarge)) ///
	(connected ATRtemp1 firm_size_decile, mcolor(brown) msize(medlarge) lcolor(black)) ///
	(connected ATRtemp2 firm_size_decile, mcolor(brown) msize(medlarge) lcolor(black)), xlabel(#10) ///
	xtitle("Firm Revenue Decile") ytitle(Average Tax Rate) ///
	legend(pos(6) cols(3) label(1 "2019") label(2 "February to June 2020") label(3 "July to December 2020")) scale(1.2)
	
	graph export $output/ATR_firm_size_policy2.pdf, replace
	

restore

