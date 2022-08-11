******************************************
* Appendix table on patterns by industry *
******************************************
preserve
	drop if indcode==1 // Drop outlier industry: agriculture
	replace indcode = 8 if indcode == 11 //put mining with hydrolics, environment, and other. Mining is too small of category.
	drop if indcode == 15 // drop public admin, too small
	replace indcode = 20 if ind2 == 52 // split wholesale and retail. 20 -- retail.
	replace indcode = 21 if inrange(ind2,25,41) // seprate equipment, chemincal, and relate manufacturing from textiles/food/related. 21 == the former.

	winsor2 subsidy_costs subsidy_liquidity, cut(5 95) by(indcode) suffix(_c)

	gcollapse (mean) participation2 subsidy_costs_c subsidy_liquidity_c ///
	 (count) count = participation2 ///
	 (sum) total_liquidity = liquidity total_si = total_si total_revenue = revenue_lrb ///
	 (sum) total_subsidy = subsidy total_costs = total_costs, by(indcode)

	gegen totalfirms = total(count)
	gen percent = 100*( count / totalfirms)

	gegen aggregate_si = total(total_si)
	gen fraction_si = 100*(total_si/ aggregate_si)

	gen fraction_costs = 100*(total_subsidy / total_costs)
	gen fraction_liquidity = 100*(total_subsidy / total_liquidity)

	replace participation2 = participation2*100
	replace subsidy_costs = subsidy_costs*100
	replace subsidy_liquidity = subsidy_liquidity*100

	keep indcode percent participation2 fraction_si  fraction_costs  subsidy_costs fraction_liquidity subsidy_liquidity
	order indcode percent participation2 fraction_si fraction_costs  subsidy_costs fraction_liquidity subsidy_liquidity
	gsort - participation

	label define ind_labels 20 "Retail" 21 "Equipment, Chemical, Metal Manufacturing" 19 "Wholesale" 10 "Textile, Food Manufacturing", modify
	decode indcode , generate(labels)

	mkmat percent participation2 fraction_si fraction_costs subsidy_costs fraction_liquidity subsidy_liquidity , rownames(labels) matrix(table)

	estout matrix(table, fmt(2 2 2 2 2 2 2 )) using $output/industry_table.tex, replace style(tex) nolegend ///
	prehead( "\begin{tabular}{lccccccc} \toprule &  \% of & \% Paying  & \% of Total & 100 $\times$ & Mean & 100$\times$ & Mean \\" ///
	" & Firms & SI & SI Payment & $\frac{\textnormal{Total Subsidy}}{\textnormal{Total Costs}}$ & $\frac{100\times \textnormal{Subsidy}}{\textnormal{Costs}}$" ///
	"& $\frac{\textnormal{Total Subsidy}}{\textnormal{Liquidity}}$ & $\frac{100\times \textnormal{Subsidy}}{\textnormal{Liquidity}}$ \\") ///
	posthead(\midrule) postfoot("\bottomrule" "\end{tabular}") mlabel(none) ///
	substitute(: "\#" _ " " ; "/") type eqlabels(none) collabels(none)
restore


******************************************************************
* Predicted Revenue Drop Against Effective Subsidy Participation *
******************************************************************

* Predicted Revenue Drop Against Subsidy by Industry x Firm Size Bins
foreach sample in part full {
	preserve
		if "`sample'"=="part" keep if participation2==1
		drop if indcode==1 // Drop outlier industry: agriculture
		replace indcode = 8 if indcode == 11 //put mining with hydrolics, environment, and other. Mining is too small of category.
		drop if indcode == 15 // drop public admin, too small
		replace indcode = 20 if ind2 == 52 // split wholesale and retail. 20 -- retail.
		replace indcode = 21 if inrange(ind2,25,41) // seprate equipment, chemincal, and relate manufacturing from textiles/food/related. 21 == the former.

		gen shock = shock_period3
		bys indcode size: gegen agg_costs = total(total_costs)
		gen temp = shock*total_costs/agg_costs
		bys indcode size: gegen shock_mean = total(temp)

		bys indcode size: gen N = _N
		drop if N < 10

		gcollapse (rawsum) total_costs subsidy liquidity revenue_lrb  ///
		(count) count=firm (firstnm) shock_mean, by(size indcode)
		replace shock = shock*100

		foreach den in costs liquidity {
			if "`den'" == "costs" {
				local denominator "total_costs"
				// Since we are only including the full-sample cost figs in the paper, optimize the y scale for that case
				if "`sample'"=="part" local yscale "0(1)7"
				else if "`sample'"=="full" local yscale "0(1)4.5"
				local ytitle "100 x Total Subsidy / Total Costs"
			}
			else if "`den'" == "liquidity" {
				local denominator "liquidity"
				local yscale "-1(1)8"
				local ytitle "100 x Total Subsidy / Total Liquidity"
			}
			gen subsidy_ratio = 100 * subsidy / `denominator'

			forval s=2/5 {
				reg subsidy_ratio shock if size==`s' [fw=count], robust
				matrix temp = r(table)
				local b`s': di %4.3f temp[1,1]
				local se`s': di %4.3f temp[2,1]
				local p: di temp[4,1]
				if `p'<.01 local ast`s' "***"
				else if `p'<.05 local ast`s' "**"
				else if `p'<.1 local ast`s' "*"
			}
			reg subsidy_ratio c.shock#i.size i.size  [fw=count], r 
			mat ncell = J(1,4,.)
			mat colnames ncell = "2.size#c.shock_mean" "3.size#c.shock_mean" "4.size#c.shock_mean" "5.size#c.shock_mean"
			bys size: egen ncell = total(count)
			forval s=2/5 {
				sum ncell if size==`s'
				assert r(sd) == 0
				mat ncell[1,`s'-1] = r(mean)
			}
			estadd matrix ncell
			est store `den'_`sample'

			twoway	(lfit subsidy_ratio shock if size ==2 [fw=count], fcolor(none) lcolor(blue)) ///
				(lfit subsidy_ratio shock if size == 3 [fw=count], fcolor(none) lcolor(green)) ///
				(lfit subsidy_ratio shock if size == 4 [fw=count], fcolor(none) lcolor(brown)) ///
				(lfit subsidy_ratio shock if size == 5 [fw=count], fcolor(none) lcolor(red)) ///
				(scatter subsidy_ratio  shock if size == 2, mcolor(blue)  msize(medlarge) ) ///
				(scatter subsidy_ratio  shock if size == 3, mcolor(green)  msize(medlarge))  ///
				(scatter subsidy_ratio  shock if  size == 4, mcolor(brown)  msize(medlarge)) ///
				(scatter subsidy_ratio  shock  if size == 5, mcolor(red) msize(medlarge)) ///
				, xlabel(#15, gmax) ylabel(#10, gmax) ysc(range(`yscale')) scale(1.1) ///
				xtitle(Predicted Percentage Change in Revenue, size(small)) ytitle(`ytitle', size(small)) ///
				legend(pos(0) bplacement(ne) ring(1) cols(5) order(5 1 6 2 7 3 8 4 ) ///
					label(5 "Micro") label(1 "Slope: `b2'`ast2' (`se2')") ///
					label(6 "Small") label(2 "Slope: `b3'`ast3' (`se3')") ///
					label(7 "Medium") label(3 "Slope: `b4'`ast4' (`se4')") ///
					label(8 "Large") label(4 "Slope: `b5'`ast5' (`se5')") ///
					col(2) row(4) size(small) bmargin(zero) )
			graph export $output/predicted_change_against_subsidy_`den'_`sample'.pdf, replace

			drop subsidy_ratio ncell
			mat drop ncell
		}
	restore
}


* Predicted Revenue Drop Against Subsidy by Industry
foreach sample in part full {
	foreach den in costs liquidity {
		preserve
			drop if indcode==1 // Drop outlier industry: agriculture
			drop if mi(size)
			if "`sample'"=="part" keep if participation2==1
			if "`den'" == "costs" {
				local denominator "total_costs"
				// Since we are only including the full-sample cost figs in the paper, optimize the y scale for that case
				if "`sample'"=="part" local yscale "0(.5)3"
				else if "`sample'"=="full" local yscale "0(.5)1.8"
				local ytitle "100 x Total Subsidy / Total Costs"
			}
			else if "`den'" == "liquidity" {
				local denominator "liquidity"
				local yscale "0(.5)4"
				local ytitle "100 x Total Subsidy / Total Liquidity"
			}

			replace indcode = 8 if indcode == 11 //put mining with hydrolics, environment, and other. Mining is too small of category.
			drop if indcode == 15 // drop public admin, too small
			replace indcode = 20 if ind2 == 52 // split wholesale and retail. 20 -- retail.
			replace indcode = 21 if inrange(ind2,25,41) // seprate equipment, chemincal, and relate manufacturing from textiles/food/related. 21 == the former.

			gen shock = shock_period3
			bys indcode: gegen agg_costs = total(total_costs)
			gen temp = shock*total_costs/agg_costs
			bys indcode: gegen shock_mean = total(temp)

			bys indcode size: gen N = _N
			drop if N < 10

			gcollapse (firstnm) shock_mean ///
			(sum) subsidy total_costs revenue_lrb liquidity ///
			(count) count= firm , by(indcode)

			replace shock = shock*100

			gen subsidy_ratio= 100* subsidy / `denominator'

			reg subsidy_ratio shock , robust
			matrix temp = r(table)
			local b: di %4.3f temp[1,1]
			local se: di %4.3f temp[2,1]
			local p: di temp[4,1]
			if `p'<.01 local ast "***"
			else if `p'<.05 local ast "**"
			else if `p'<.1 local ast "*"
			local bstarred "`b'`ast'"
			egen ncell = total(count)
			sum ncell
			assert r(sd) == 0
			local ncell = r(mean)
			est res `den'_`sample'
			estadd local allbstarred `bstarred'
			estadd local allse `se'
			estadd local allncell `ncell'
			eststo `den'_`sample'

			label define ind_labels 20 "Retail" 21 "Equipment, Chemical, Metal Manufacturing" 19 "Wholesale" 10 "Textile, Food Manufacturing", modify

			decode indcode, generate(labels)

			* tabstat shock_mean, by(indcode)

			twoway 	(scatter subsidy_ratio shock if inlist(indcode,3,4,12,14), mcolor(blue) msymbol(Oh) mlabel(labels) mlabpos(11) mlabangle(0)) ///
				(scatter subsidy_ratio shock if inlist(indcode, 9, 7, 13, 20), mcolor(blue) msymbol(Oh) mlabel(labels) mlabpos(1) mlabangle(0)) ///
				(scatter subsidy_ratio shock if !inlist(indcode,3,4,7,9,12,13,14,20), mcolor(black) msymbol(Oh)) ///
				(lfit subsidy_ratio shock [fw=count], fcolor(none) lcolor(grey) lpattern(shortdash))  ///
				, xlabel(#10, gmax) ylabel(#10, gmax) xtitle(Predicted Percentage Change in Industry Revenue, size(small)) ///
				ytitle(`ytitle', size(small)) scale(1.1) ysc(range(`yscale')) ///
				legend(pos(0) bplacement(ne) cols(1) order(4 5) label(4 "Slope: `b'`ast' (`se')"))
			graph export $output/predicted_change_against_subsidy_`den'_industry_`sample'.pdf, replace

			drop subsidy_ratio labels
		restore
	}
}

esttab costs_part costs_full liquidity_part liquidity_full ///
	using $output/industry_slopes_costs_liquidity.tex ///
	, tex replace type cells("b(star fmt(3))" "se(fmt(3) par)" "ncell(fmt(%11.0g) par([ ]))") ///
	coeflabels(2.size#c.shock_mean "Micro" 3.size#c.shock_mean "Small" 4.size#c.shock_mean "Medium" 5.size#c.shock_mean "Large") ///
	drop(2.size 3.size 4.size 5.size) ///
	stats(allbstarred allse allncell, layout("@" "(@)" "[@]") fmt(3 3 %11.0g) ///
	labels("All firms" " " " ")) starlevel(* .1 ** .05 *** .01) nonotes nomtitles collabels(none) ///
	prehead("\begin{tabular}{lcccc} \\ \toprule" " & \multicolumn{2}{c}{100 $\times$ Subsidy / Costs} & \multicolumn{2}{c}{100 $\times$ Subsidy / Liquidity}  \\ & Participants & Full Sample & Participants & Full Sample \\" ) ///
	posthead("\midrule") ///
	postfoot("\midrule \end{tabular}")


***********************************************************************
* Participation & labor intensity against predicted change in revenue *
***********************************************************************
preserve
	drop if indcode==1 // Drop outlier industry: agriculture
	replace indcode = 8 if indcode == 11 //put mining with hydrolics, environment, and other. Mining is too small of category.
	drop if indcode == 15 // drop public admin, too small
	replace indcode = 20 if ind2 == 52 // split wholesale and retail. 20 -- retail.
	replace indcode = 21 if inrange(ind2,25,41) // seprate equipment, chemincal, and relate manufacturing from textiles/food/related. 21 == the former.

	// Considered whether to winsorize for consistency with other figures, but does not seem needed at the aggregate level. -MN 17 Sep 2021
	gen shock = shock_period3
	gen costs2 = total_costs if participation2 == 1

	bys indcode size: gegen agg_costs = total(total_costs)
	gen temp = shock*total_costs/agg_costs
	bys indcode size: gegen shock_mean = total(temp)

	gcollapse (mean) shock_mean participation2 (count) count= firm (sum) wages total_costs costs2, by(indcode)

	gen share = costs2 / total_costs
	replace shock = shock*100
	gen intensity  = wages / total_costs

	label define ind_labels 20 "Retail" 21 "Equipment, Chemical, Metal Manufacturing" 19 "Wholesale" 10 "Textile, Food Manufacturing", modify
	decode indcode, generate(labels)

	reg share shock , robust
	matrix temp = r(table)
	local b: di %4.3f temp[1,1]
	local se: di %4.3f temp[2,1]
	local p: di temp[4,1]
	if `p'<.01 local ast "***"
	else if `p'<.05 local ast "**"
	else if `p'<.1 local ast "*"
	local bstarred "`b'`ast'"

	twoway (scatter share shock if inlist(indcode, 4, 7, 13, 20), mcolor(blue) msymbol(Oh) mlabel(labels) mlabpos(9) mlabangle(0)) ///
	(scatter share shock if inlist(indcode, 9, 3, 12, 14), mcolor(blue) msymbol(Oh) mlabel(labels) mlabpos(5) mlabangle(0)) ///
	(scatter share shock if !inlist(indcode, 3, 4, 7, 9, 12, 13, 14, 20), mcolor(black) msymbol(Oh)) ///
	, xlabel(#10, gmax) ylabel(#10, gmax) xtitle(Predicted Percentage Change in Industry Revenue) ///
	ytitle("Fraction of Industry Participating in SI") scale(1.2) ///
	legend(off)
	graph export $output/predicted_change_against_participation_industry.pdf, replace

	reg intensity shock , robust
	matrix temp = r(table)
	local b: di %4.3f temp[1,1]
	local se: di %4.3f temp[2,1]
	local p: di temp[4,1]
	if `p'<.01 local ast "***"
	else if `p'<.05 local ast "**"
	else if `p'<.1 local ast "*"
	local bstarred "`b'`ast'"

	twoway (scatter intensity shock if inlist(indcode, 4, 7, 12), mcolor(blue) msymbol(Oh) mlabel(labels) mlabpos(9) mlabangle(0)) ///
	(scatter intensity shock if inlist(indcode, 3), mcolor(blue) msymbol(Oh) mlabel(labels) mlabpos(12) mlabangle(0)) ///
	(scatter intensity shock if inlist(indcode, 9, 13, 14, 20), mcolor(blue) msymbol(Oh) mlabel(labels) mlabpos(2) mlabangle(0)) ///
	(scatter intensity shock if !inlist(indcode,3,4,7,9,12,13,14,20), mcolor(black) msymbol(Oh)) ///
	, xlabel(#10, gmax) ylabel(#10, gmax) xtitle(Predicted Percentage Change in Industry Revenue) ///
	ytitle("Total Industry Wages / Total Industry Costs") scale(1.2) yscale(titlegap(-7) outergap(0)) ///
	legend(off)
	graph export $output/predicted_change_against_labor_intensity_industry.pdf, replace
restore
