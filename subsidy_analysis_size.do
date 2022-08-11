*****************************************************
* Compare targeting bw participants and full sample *
*****************************************************
set more off
preserve
	rename subsidy sub
	rename total_costs cost
	gen cf = cashflow_shock
	drop subsidy_cashflow subsidy_cashflow_part
	gen sub_cf = sub / cf
	gen sub_cf_part = sub_cf if participation2 == 1
	rename liquidity liq
	rename subsidy_costs* sub_cost*
	rename subsidy_liquidity* sub_liq*
	rename subsidy_cash* sub_cash*
	foreach v in cost liq cash cf {
		gen `v'_part = `v' if participation2==1
	}
	winsor2 sub cost liq cash cf cost_part liq_part cash_part cf_part ///
		sub_cost sub_cost_part sub_liq sub_liq_part sub_cash ///
		sub_cash_part sub_cf sub_cf_part ///
		, cuts(5 95) by(firm_size_deciles_rev) replace
	gcollapse (sum) sub cost liq cash cf ///
		(sum) cost_part liq_part cash_part cf_part ///
		(mean) avg_sub_cost = sub_cost avg_sub_cost_part = sub_cost_part ///
		(mean) avg_sub_liq = sub_liq avg_sub_liq_part = sub_liq_part ///
		(mean) avg_sub_cash = sub_cash avg_sub_cash_part = sub_cash_part ///
		(mean) avg_sub_cf = sub_cf avg_sub_cf_part = sub_cf_part ///
		, by(firm_size_deciles_rev)
	egen sub_agg = total(sub)
	gen one = 1
	gen one_part = 1
	foreach d in one cost liq cash cf {
		foreach s in "" "_part" {
			gen sub_`d'`s' = sub / `d'`s'
			egen sub_`d'`s'_int = total(sub_`d'`s')

			* Calculate share of subsidy / d ratio above and below top decile value
			gegen sub_`d'`s'_top_dec = mean(sub_`d'`s' if firm_size_deciles_rev==10)
			gen sub_`d'`s'_above_top_dec = sub_`d'`s' - sub_`d'`s'_top_dec
			gen sub_`d'`s'_below_top_dec = -sub_`d'`s'_above_top_dec if sub_`d'`s'_above_top_dec<0
			replace sub_`d'`s'_above_top_dec = 0 if sub_`d'`s'_above_top_dec<0
			replace sub_`d'`s'_below_top_dec = 0 if mi(sub_`d'`s'_below_top_dec)

			egen sub_`d'`s'_above_top_dec_int = total(sub_`d'`s'_above_top_dec)
			egen sub_`d'`s'_below_top_dec_int = total(sub_`d'`s'_below_top_dec)
			gen sub_`d'`s'_nonunif_above = sub_`d'`s'_above_top_dec_int / sub_`d'`s'_int
			su sub_`d'`s'_nonunif_above
			assert r(sd)==0
			local sub_`d'`s'_nonunif_above = r(mean)
			gen sub_`d'`s'_nonunif_below = sub_`d'`s'_below_top_dec_int / sub_`d'`s'_int
			su sub_`d'`s'_nonunif_below
			assert r(sd)==0
			local sub_`d'`s'_nonunif_below = r(mean)

			* Calculate decile-to-decile comparison ratios
			if "`d'"!="one" {
				gegen avg_sub_`d'`s'_top_dec = mean(avg_sub_`d'`s' if firm_size_deciles_rev==10)
				gen dec_ratio_`d'`s' = avg_sub_`d'`s' / avg_sub_`d'`s'_top_dec
				forval dec=1/10 {
					sum dec_ratio_`d'`s' if firm_size_deciles_rev==`dec'
					local dec`dec'_ratio_`d'`s' = r(mean)
				}
			}

			cap drop sub_`d'*
			cap drop dec_ratio_`d'*
			cap drop *_top_dec
		}
	}

	* Build table with shares of subsidy / d ratio above and below top decile value
	mat sub_shares = J(4, 3, .)
	mat colnames sub_shares = "Cash Flow Loss" "Cost" "Liquidity"
	mat rownames sub_shares = "Share above, participants" "Share above, all firms" "Share below, participants" "Share below, all firms"

	forval c=1/3 {
		if `c'==1 local d cf
		else if `c'==2 local d cost
		else if `c'==3 local d liq

		mat sub_shares[1,`c'] = `=round(`sub_`d'_part_nonunif_above', .001)'
		mat sub_shares[2,`c'] = `=round(`sub_`d'_nonunif_above', .001)'
		mat sub_shares[3,`c'] = `=round(`sub_`d'_part_nonunif_below', .001)'
		mat sub_shares[4,`c'] = `=round(`sub_`d'_nonunif_below', .001)'
	}

	* Build table with decile-to-decile comparison ratios
	mat dec_comparisons = J(9, 10, .)
	mat colnames dec_comparisons = "1" "2" "3" "4" "5" "6" "7" "8" "9" "10"
	mat rownames dec_comparisons = "Subsidy / Cash Flow Loss" "Participants" "All firms" "Subsidy / Total Costs" "Participants" "All firms" "Subsidy / Liquidity" "Participants" "All firms"

	forval r=1/9 {
		di "r=`r'"
		di "mod(r,3) = `=mod(`r',3)'"
		if mod(`r',3)!=1 { // Leave rows empty as section breaks
			if mod(`r',3)==2 local s "_part"
			else if mod(`r',3)==0 local s ""

			di "ceil(r/3) = `=ceil(`r'/3)'"
			if ceil(`r'/3)==1 local d cf
			else if ceil(`r'/3)==2 local d cost
			else if ceil(`r'/3)==3 local d liq

			di "`s'`d' = sd"
			forval c=1/10 {
				di "c=`c'"
				di "local = dec`c'_ratio_`d'`s'"
				mat dec_comparisons[`r',`c'] = `=round(`dec`c'_ratio_`d'`s'', .1)'
			}
		}
	}

	sort firm_size_deciles_rev
	tab firm_size_deciles_rev avg_sub_cf_part, nol
restore

esttab 	matrix(sub_shares, fmt(3)) ///
	using $output/subsidy_shares.tex ///
	, tex replace type ///
	nomtitles ///
	postfoot("\hline \hline \end{tabular}") ///
	prehead("\begin{tabular}{lcccc} \hline \hline & \multicolumn{4}{c}{Subsidy Over} \\ \cline{2-5} \\")

esttab 	matrix(dec_comparisons, fmt(1)) ///
	using $output/decile_comparisons.tex ///
	, tex replace type ///
	nomtitles ///
	postfoot("\hline \hline \end{tabular}") ///
	prehead("\begin{tabular}{lcccccccccc} \hline \hline & \multicolumn{10}{c}{Ratio for decile \$d\$ / Ratio for top decile} \\ \cline{2-11} \multicolumn{1}{r}{\$d=\$}")

************************************************************
* Simulated Cut by Firm Size: Participants and full sample *
************************************************************

* Revenue Size Bins *
preserve
	winsor2 subsidy_costs subsidy_liquidity subsidy_cash subsidy_cashflow ///
		subsidy_costs_part subsidy_liquidity_part subsidy_cash_part ///
		subsidy_cashflow_part labor_intensity ///
		, replace cut(5 95) by(firm_size_deciles_rev)

	su subsidy_liquidity , d
	local avgliquidratio1: di %9.3f `r(mean)'

	su subsidy_costs, d
	local avgcostratio1: di %9.3f `r(mean)'

	su subsidy_cashflow, d
	local avgcashflowratio1: di %9.3f `r(mean)'

	su subsidy_liquidity if participation2==1, d
	local avgliquidratio2: di %9.3f `r(mean)'

	su subsidy_costs if participation2==1, d
	local avgcostratio2: di %9.3f `r(mean)'

	su subsidy_cashflow if participation2==1, d
	local avgcashflowratio2: di %9.3f `r(mean)'

	su participation2
	local percent: di %9.2f 100*`r(mean)'

	gcollapse (mean) labor_intensity participation2 ///
	(mean)  subsidy_liquidity subsidy_liquidity_part ///
	(mean) subsidy_costs subsidy_costs_part ///
	(mean) subsidy_cash subsidy_cash_part ///
	(mean) subsidy_cashflow subsidy_cashflow_part ///
	, by(firm_size_deciles_rev)

	// labor intensity appendix graph
	twoway (connected labor_intensity firm_size, lwidth(medthick) msize(medlarge)) , ///
	ytitle(Total Wages / Total Costs) xtitle("Revenue Decile") ///
	xlabel(#10, gmax labels) ylabel(#10, gmax axis(1)) scale(1.2)
	graph export $output/labor_intensity_by_size.pdf, replace


	// subsidy to costs ratio graph
	twoway (connected subsidy_costs firm_size, lwidth(medthick) lpattern(shortdash) msymbol(Oh)  msize(medlarge) lcolor(black) mcolor(black)) ///
		(connected subsidy_costs_part firm_size, msize(large) lwidth(medthick) msymbol(Sh)  lpattern(solid)  msize(medlarge) lcolor(blue) mcolor(blue) ), ///
		 xtitle("Revenue Decile") ///
		xlabel(#10, gmax labels) ylabel(#10, gmax) ///
		legend(pos(6) ring(2) cols(2) label(1 "Mean (Subsidy / Costs)") ///
		 label(2 "Mean (Subsidy / Costs) | Subsidy > 0"))   ///
		 caption("Mean (Subsidy / Costs) : `avgcostratio1'" ///
		 "Mean (Subsidy / Costs) | Subsidy > 0: `avgcostratio2'" ///
		,pos(11) ring(1) fcolor(white) bcolor(white) box ) scale(1.2) graphregion(margin(medlarge))
	graph export $output/predicted_subsidy_costs.pdf, replace

	// subsidy to liquidity ratio graph
	twoway (connected subsidy_liquidity firm_size, lwidth(medthick) msize(medlarge) msymbol(Oh) lpattern(shortdash)  lcolor(black) mcolor(black)) ///
		(connected subsidy_liquidity_part firm_size,msize(large) lwidth(medthick) msymbol(Sh) msize(medlarge) lpattern(solid)  lcolor(blue) mcolor(blue)), ///
		xtitle("Revenue Decile") ///
		xlabel(#10, gmax labels) ylabel(#10, gmax) yscale(titlegap(-4) outergap(0)) ///
		legend(pos(6) ring(2) cols(2) label(1 "Mean (Subsidy / Liquidity)") ///
		 label(2 "Mean (Subsidy / Liquidity)  | Subsidy > 0") )  ///
		 caption("Mean (Subsidy / Liquidity): `avgliquidratio1'" ///
		 "Mean (Subsidy / Liquidity) | Subsidy > 0: `avgliquidratio2'",pos(11) ring(1) fcolor(white) bcolor(white) box ) scale(1.2) graphregion(margin(medlarge))
	graph export $output/predicted_subsidy_liquidity.pdf, replace

	// subsidy to cashflow shock ratio graph
	twoway (connected subsidy_cashflow firm_size, lwidth(medthick) msize(medlarge) msymbol(Oh) lpattern(shortdash)  lcolor(black) mcolor(black)) ///
		(connected subsidy_cashflow_part firm_size,msize(large) lwidth(medthick) msymbol(Sh) msize(medlarge) lpattern(solid)  lcolor(blue) mcolor(blue)), ///
		xtitle("Revenue Decile") ///
		xlabel(#10, gmax labels) ylabel(#10, gmax) yscale(titlegap(-4) outergap(0)) ///
		legend(pos(6) ring(2) cols(1) label(1 "Mean (Subsidy / Cash Flow Loss)") ///
		 label(2 "Mean (Subsidy / Cash Flow Loss)  | Subsidy > 0") )  ///
		 caption("Mean (Subsidy / Cash Flow Loss): `avgcashflowratio1'" ///
		 "Mean (Subsidy / Cash Flow Loss) | Subsidy > 0: `avgcashflowratio2'",pos(11) ring(1) fcolor(white) bcolor(white) box ) scale(1.2) graphregion(margin(medlarge))
	graph export $output/predicted_subsidy_cashflow_loss.pdf, replace

restore


*Employee Size Bins*

preserve

	gegen firm_size_deciles_emp = cut(employees), group(5)
	replace firm_size_deciles_emp = firm_size_deciles_emp +1
	winsor2 subsidy_costs subsidy_liquidity subsidy_cash subsidy_cashflow ///
		subsidy_costs_part subsidy_liquidity_part subsidy_cash_part ///
		subsidy_cashflow_part labor_intensity ///
		, replace cut(5 95) by(firm_size_deciles_emp)

	su subsidy_liquidity , d
	local avgliquidratio1: di %9.3f `r(mean)'

	su subsidy_costs, d
	local avgcostratio1: di %9.3f `r(mean)'

	su subsidy_cashflow, d
	local avgcashflowratio1: di %9.3f `r(mean)'

	su subsidy_liquidity if participation2==1, d
	local avgliquidratio2: di %9.3f `r(mean)'

	su subsidy_costs if participation2==1, d
	local avgcostratio2: di %9.3f `r(mean)'

	su subsidy_cashflow if participation2==1, d
	local avgcashflowratio2: di %9.3f `r(mean)'

	su participation2
	local percent: di %9.2f 100*`r(mean)'

	gcollapse (mean) labor_intensity participation2 ///
	(mean)  subsidy_liquidity subsidy_liquidity_part ///
	(mean) subsidy_costs subsidy_costs_part ///
	(mean) subsidy_cash subsidy_cash_part ///
	(mean) subsidy_cashflow subsidy_cashflow_part ///
	, by(firm_size_deciles_emp)

	// labor intensity appendix graph
	twoway (connected labor_intensity firm_size, lwidth(medthick) msize(medlarge)) , ///
	ytitle(Total Wages / Total Costs) xtitle("Employee Quantile") ///
	xlabel(#10, gmax labels) ylabel(#10, gmax axis(1)) scale(1.2)
	graph export $output/labor_intensity_by_sizeB.pdf, replace


	// subsidy to costs ratio graph
	twoway (connected subsidy_costs firm_size, lwidth(medthick) lpattern(shortdash) msymbol(Oh)  msize(medlarge) lcolor(black) mcolor(black)) ///
		(connected subsidy_costs_part firm_size, msize(large) lwidth(medthick) msymbol(Sh)  lpattern(solid)  msize(medlarge) lcolor(blue) mcolor(blue) ), ///
		 xtitle("Employee Quintile") ///
		xlabel(#5, gmax labels) ylabel(#10, gmax) ///
		legend(pos(6) ring(2) cols(2) label(1 "Mean (Subsidy / Costs)") ///
		 label(2 "Mean (Subsidy / Costs) | Subsidy > 0"))   ///
		 caption("Mean (Subsidy / Costs) : `avgcostratio1'" ///
		 "Mean (Subsidy / Costs) | Subsidy > 0: `avgcostratio2'" ///
		,pos(11) ring(1) fcolor(white) bcolor(white) box ) scale(1.2) graphregion(margin(medlarge))
	graph export $output/predicted_subsidy_costsB.pdf, replace

	// subsidy to liquidity ratio graph
	twoway (connected subsidy_liquidity firm_size, lwidth(medthick) msize(medlarge) msymbol(Oh) lpattern(shortdash)  lcolor(black) mcolor(black)) ///
		(connected subsidy_liquidity_part firm_size,msize(large) lwidth(medthick) msymbol(Sh) msize(medlarge) lpattern(solid)  lcolor(blue) mcolor(blue)), ///
		xtitle("Employee Quintile") ///
		xlabel(#5, gmax labels) ylabel(#10, gmax) yscale(titlegap(-4) outergap(0)) ///
		legend(pos(6) ring(2) cols(2) label(1 "Mean (Subsidy / Liquidity)") ///
		 label(2 "Mean (Subsidy / Liquidity)  | Subsidy > 0") )  ///
		 caption("Mean (Subsidy / Liquidity): `avgliquidratio1'" ///
		 "Mean (Subsidy / Liquidity) | Subsidy > 0: `avgliquidratio2'",pos(11) ring(1) fcolor(white) bcolor(white) box ) scale(1.2) graphregion(margin(medlarge))
	graph export $output/predicted_subsidy_liquidityB.pdf, replace

	// subsidy to cashflow shock ratio graph
	twoway (connected subsidy_cashflow firm_size, lwidth(medthick) msize(medlarge) msymbol(Oh) lpattern(shortdash)  lcolor(black) mcolor(black)) ///
		(connected subsidy_cashflow_part firm_size,msize(large) lwidth(medthick) msymbol(Sh) msize(medlarge) lpattern(solid)  lcolor(blue) mcolor(blue)), ///
		xtitle("Employee Quintile") ///
		xlabel(#5, gmax labels) ylabel(#10, gmax) yscale(titlegap(-4) outergap(0)) ///
		legend(pos(6) ring(2) cols(1) label(1 "Mean (Subsidy / Cash Flow Loss)") ///
		 label(2 "Mean (Subsidy / Cash Flow Loss)  | Subsidy > 0") )  ///
		 caption("Mean (Subsidy / Cash Flow Loss): `avgcashflowratio1'" ///
		 "Mean (Subsidy / Cash Flow Loss) | Subsidy > 0: `avgcashflowratio2'",pos(11) ring(1) fcolor(white) bcolor(white) box ) scale(1.2) graphregion(margin(medlarge))
	graph export $output/predicted_subsidy_cashflow_lossB.pdf, replace

restore


** MIIT Size


preserve
	winsor2 subsidy_costs subsidy_liquidity subsidy_cash subsidy_cashflow ///
		subsidy_costs_part subsidy_liquidity_part subsidy_cash_part ///
		subsidy_cashflow_part labor_intensity ///
		, replace cut(5 95) by(miitsize)

	su subsidy_liquidity , d
	local avgliquidratio1: di %9.3f `r(mean)'

	su subsidy_costs, d
	local avgcostratio1: di %9.3f `r(mean)'

	su subsidy_cashflow, d
	local avgcashflowratio1: di %9.3f `r(mean)'

	su subsidy_liquidity if participation2==1, d
	local avgliquidratio2: di %9.3f `r(mean)'

	su subsidy_costs if participation2==1, d
	local avgcostratio2: di %9.3f `r(mean)'

	su subsidy_cashflow if participation2==1, d
	local avgcashflowratio2: di %9.3f `r(mean)'

	su participation2
	local percent: di %9.2f 100*`r(mean)'

	gcollapse (mean) labor_intensity participation2 ///
	(mean)  subsidy_liquidity subsidy_liquidity_part ///
	(mean) subsidy_costs subsidy_costs_part ///
	(mean) subsidy_cash subsidy_cash_part ///
	(mean) subsidy_cashflow subsidy_cashflow_part ///
	, by(miitsize)

	// labor intensity appendix graph
	twoway (connected labor_intensity miitsize, lwidth(medthick) msize(medlarge)) , ///
	ytitle(Total Wages / Total Costs) xtitle("MIIT Firm Size") ///
	xlabel(#10, gmax labels) ylabel(#10, gmax axis(1)) scale(1.2)
	graph export $output/labor_intensity_by_sizeC.pdf, replace


	// subsidy to costs ratio graph
	twoway (connected subsidy_costs miitsize, lwidth(medthick) lpattern(shortdash) msymbol(Oh)  msize(medlarge) lcolor(black) mcolor(black)) ///
		(connected subsidy_costs_part miitsize, msize(large) lwidth(medthick) msymbol(Sh)  lpattern(solid)  msize(medlarge) lcolor(blue) mcolor(blue) ), ///
		 xtitle("MIIT Firm Size") ///
		xlabel(#5, gmax labels) ylabel(#10, gmax) ///
		legend(pos(6) ring(2) cols(2) label(1 "Mean (Subsidy / Costs)") ///
		 label(2 "Mean (Subsidy / Costs) | Subsidy > 0"))   ///
		 caption("Mean (Subsidy / Costs) : `avgcostratio1'" ///
		 "Mean (Subsidy / Costs) | Subsidy > 0: `avgcostratio2'" ///
		,pos(11) ring(1) fcolor(white) bcolor(white) box ) scale(1.2) graphregion(margin(medlarge))
	graph export $output/predicted_subsidy_costsC.pdf, replace

	// subsidy to liquidity ratio graph
	twoway (connected subsidy_liquidity miitsize, lwidth(medthick) msize(medlarge) msymbol(Oh) lpattern(shortdash)  lcolor(black) mcolor(black)) ///
		(connected subsidy_liquidity_part miitsize,msize(large) lwidth(medthick) msymbol(Sh) msize(medlarge) lpattern(solid)  lcolor(blue) mcolor(blue)), ///
		xtitle("MIIT Firm Size") ///
		xlabel(#5, gmax labels) ylabel(#10, gmax) yscale(titlegap(-4) outergap(0)) ///
		legend(pos(6) ring(2) cols(2) label(1 "Mean (Subsidy / Liquidity)") ///
		 label(2 "Mean (Subsidy / Liquidity)  | Subsidy > 0") )  ///
		 caption("Mean (Subsidy / Liquidity): `avgliquidratio1'" ///
		 "Mean (Subsidy / Liquidity) | Subsidy > 0: `avgliquidratio2'",pos(11) ring(1) fcolor(white) bcolor(white) box ) scale(1.2) graphregion(margin(medlarge))
	graph export $output/predicted_subsidy_liquidityC.pdf, replace

	// subsidy to cashflow shock ratio graph
	twoway (connected subsidy_cashflow miitsize, lwidth(medthick) msize(medlarge) msymbol(Oh) lpattern(shortdash)  lcolor(black) mcolor(black)) ///
		(connected subsidy_cashflow_part miitsize,msize(large) lwidth(medthick) msymbol(Sh) msize(medlarge) lpattern(solid)  lcolor(blue) mcolor(blue)), ///
		xtitle("MIIT Firm Size") ///
		xlabel(#5, gmax labels) ylabel(#10, gmax) yscale(titlegap(-4) outergap(0)) ///
		legend(pos(6) ring(2) cols(1) label(1 "Mean (Subsidy / Cash Flow Loss)") ///
		 label(2 "Mean (Subsidy / Cash Flow Loss)  | Subsidy > 0") )  ///
		 caption("Mean (Subsidy / Cash Flow Loss): `avgcashflowratio1'" ///
		 "Mean (Subsidy / Cash Flow Loss) | Subsidy > 0: `avgcashflowratio2'",pos(11) ring(1) fcolor(white) bcolor(white) box ) scale(1.2) graphregion(margin(medlarge))
	graph export $output/predicted_subsidy_cashflow_lossC.pdf, replace

restore



**********************************************************
* Simulated cut by Firm Size: With/wo employment decline *
*  (Participants and full sample)                        *
**********************************************************

foreach d in costs liquidity cash cashflow {
	foreach sample in participants fullsample {
		preserve
			if "`sample'"=="participants" keep if participation2==1
			winsor2 subsidy_`d'*, replace cut(5 95) by(firm_size_deciles_rev)

			su subsidy_`d', d
			local avgsubsidyratio1: di %9.3f `r(mean)'

			su subsidy_`d'3, d
			local avgsubsidyratio3: di %9.3f `r(mean)'

			gcollapse (mean)  subsidy_`d'* , by(firm_size_deciles_rev)

			if "`d'"=="costs" local dname "Costs"
			else if "`d'"=="liquidity" local dname "Liquidity"
			else if "`d'"=="cash" local dname "Cash"
			else if "`d'"=="cashflow" local dname "Cash Flow"

			// subsidy to `d' ratio graph
			twoway (connected subsidy_`d' firm_size_deciles_rev, lwidth(medthick) lpattern(solid) msymbol(Oh)  msize(medlarge) lcolor(black) mcolor(black)) ///
				(connected subsidy_`d'3 firm_size_deciles_rev, msize(large) lwidth(medthick) msymbol(Sh)  lpattern(shortdash)  msize(medlarge) lcolor(blue) mcolor(blue) ), ///
				 xtitle("Revenue Decile") ytitle("Mean (Subsidy / `dname')") ///
				xlabel(#10, gmax labels) ylabel(#10, gmax) ///
				legend(pos(6) ring(2) cols(2) label(1 "Baseline") ///
				 label(2 "Employment decline equal to cash flow decline"))   ///
				 caption("Mean (Subsidy / `dname') : `avgsubsidyratio1'" ///
				 "Mean (Subsidy / `dname') with Employment Decline: `avgsubsidyratio3'" ///
				,pos(11) ring(1) fcolor(white) bcolor(white) box )
			graph export $output/predicted_subsidy_`d'_employmentdecline_`sample'.pdf, replace

		restore
	}
}
