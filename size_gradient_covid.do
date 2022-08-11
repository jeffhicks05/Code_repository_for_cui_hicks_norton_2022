
preserve

	gen revenue_participate = revenue_lrb if participation2 ==1

	su participation
	local percent: di %9.2f 100*`r(mean)'

	gegen aggregate_employees = total(employees)
	gegen aggregate_employees_p = total(employees if participation ==1)
	gen fraction_covered_employees = aggregate_employees_p / aggregate_employees

	su fraction_covered_employees
	local percent3: di %9.2f 100*`r(mean)'

	gcollapse (mean) participation2 partalt ///
	(count) count = participation2 count_poswage = partalt ///
	(sum) total = subsidy revenue_lrb revenue_participate, by(firm_size_deciles_rev)

	gegen total_rev_participation = total(revenue_participate)
	gegen total_rev = total(revenue_lrb)

	gegen aggregate_contributions = total(total)


	gen fraction = total / aggregate_contributions
	gen fraction_covered = total_rev_participation / total_rev

	su fraction_covered
	local percent2: di %9.2f 100*`r(mean)'

	* Covid paper size gradient
	twoway  (connected participation2 firm_size, lwidth(medthick) msize(medlarge)) ///
		(connected fraction firm_size,  lwidth(medthick) lpattern(dash) lcolor(pink) msize(medlarge)) ///
	, ytitle(Share) xtitle("Size Decile") ///
	xlabel(#10 ,labels) ylabel(0(.1)1, gmax)  ///
	legend(pos(6) ring(1) cols(1) label(1 "SI Participation") ///
	label(2 "Fraction of Total SI Contributions Made by Decile")) ///
	caption("% of firms remitting SI contributions:`percent'" ///
	"% of total revenue accounted for by SI contributors:`percent2'" ///
	"% of total employees accounted for by SI contributors:`percent3'"   ///
	,pos(11) ring(1) fcolor(white) bcolor(white) box size() )
	
	graph export $output/participation_by_size_covid.pdf, replace



restore
