*************************************************************
* Descriptive figures related to cash flow and COVID shock  *
*************************************************************


preserve

	gen variable_share = cost_goods_sold / total_costs
	gen grossprofitmargin = (revenue_lrb - cost_goods_sold) / revenue_lrb
	gen cashflow_shock_level = -cashflow_shock
	gen shock_share = -cashflow_shock / (revenue_lrb - cost_goods_sold) if cashflow_shock >= 0 & revenue_lrb >= cost_goods_sold


	drop if shock_period3 > 0
	
	foreach v in variable_share grossprofitmargin shock_period3 cashflow_shock_level shock_share {
		gen `v'_cond = `v' if revenue_lrb >= cost_goods_sold
	}

	local v variable_share

	gcollapse (median) variable_share variable_share_cond , by(firm_size_deciles_rev)
	if "`v'" == "variable_share" {
		local ytitle "Variable Costs / Total Costs"
		local filesuff "vc_over_tc"
	}
	else if "`v'" == "grossprofitmargin" {
		local ytitle "Gross Profit Margin"
		local filesuff "gpm"
	}
	else if "`v'" == "shock_period3" {
		local ytitle "Estimated sales shock (Chen, et al. 2020)"
		local filesuff "chenshock"
	}
	else if "`v'" == "cashflow_shock_level" {
		local ytitle "Cash Flow Loss"
		local filesuff "cashflow_shock"
	}
	else if "`v'" == "shock_share" {
		local ytitle "Cash Flow Loss / Total Cash Flow"
		local filesuff "cashflow_shock_over_cashflow"
	}
	twoway	(scatter `v' firm_size_deciles_rev, msymbol(O) msize(medlarge)) ///
		(scatter `v'_cond firm_size_deciles_rev, msymbol(Dh) msize(medlarge) mcolor(dkorange) mlwidth(medthick)) ///
		, ytitle("`ytitle'") ///
		xtitle("Revenue Decile") xsc(range(1(1)10)) xlabel(1(1)10) ///
		legend(label(1 "Median Within Decile") ///
			label(2 "Median Within Decile | revenue_lrb >= total_costs") on pos(6))
	graph export $output/bydecile_`filesuff'_2series.pdf, replace

	sum `v'
	local avg: di %5.2f r(mean)*100

	twoway	(connected `v' firm_size_deciles_rev) ///
		, ytitle("`ytitle'") ymtick(0(.1)1, grid gmax) ylab(0(.2)1) ///
		xtitle("Revenue Decile") xsc(range(1(1)10)) xlabel(1(1)10) ///
		caption("Average variable costs as % of total costs: `avg'%" ///
		,pos(11) ring(1) fcolor(white) bcolor(white) box size() ) ///
		legend(off) scale(1.2)
	graph export $output/bydecile_`filesuff'.pdf, replace
restore
