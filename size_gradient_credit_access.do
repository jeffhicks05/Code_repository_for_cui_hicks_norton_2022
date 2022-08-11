set more off


foreach v in interest_deduction fin_liabilities {
	preserve
		if "`v'"=="interest_book_liabilities" keep if interest_book_105 > 0 & !mi(interest_book_105) & credit > 0 & !mi(credit)
		else if "`v'"=="deductions_liabilities" keep if interest_tax_105 > 0 & !mi(interest_tax_105) & credit > 0 & !mi(credit)
		else if "`v'"=="fin_liabilities" keep if financial_expenses_lrb > 0 & !mi(financial_expenses_lrb) & credit > 0 & !mi(credit)
		if "`v'" != "interest_deduction" winsor2 `v', by(firm_size_deciles_rev) cuts(5 95) replace
		
		xi i.firm_size_deciles_rev, noomit
		reg `v' _Ifirm_size_*, r nocons
		gen ciup = .
		gen cidown = .
		forval d=1/10 {
			replace ciup = _b[_Ifirm_size_`d'] + 1.96*_se[_Ifirm_size_`d'] if firm_size_deciles_rev==`d'
			replace cidown = _b[_Ifirm_size_`d'] - 1.96*_se[_Ifirm_size_`d'] if firm_size_deciles_rev==`d'
		}
		sum `v'
		local avg_`v': di %5.3f r(mean)
		count
		local N = r(N)
		
		if "`v'"=="interest_deduction" {
			local ytitle "Share claiming interest deduction"
			local caption "% of firms claiming interest deduction: `avg_`v''"
			local ylab "0(.05).2"
			local ymtick "0(.025).2"
		}
		else if "`v'"=="fin_liabilities" {
			local ytitle "Financing Costs / Liabilities"
			local caption `""Avg financing costs / liabilities | Costs, liabilities > 0: `avg_`v''" "Number of firms: `N'""'
			local ylab "0(.02).12, gmax"
			local ymtick ""
		}
		
		gcollapse (mean) `v' ci*, by(firm_size_deciles_rev)
		
		twoway	(connected `v' firm_size_deciles_rev, lcolor(black) mcolor(black)) ///
			, scale(1.2) ytitle(`ytitle') xtitle("Revenue Decile") ///
			xlabel(#10, gmax labels) ylabel(`ylab') ///
			ymtick(`ymtick', grid gmax) legend(off) ///
			caption(`caption', pos(11) ring(1) fcolor(white) bcolor(white) box size() ) 			
		graph export $output/gradient_`v'.pdf, replace
	restore
}

