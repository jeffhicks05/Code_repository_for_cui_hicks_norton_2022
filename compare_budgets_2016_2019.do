
tempfile working
save "`working'"

******************************************
* Compare pooling units in 2016 and 2019 *
******************************************

import delimited using $jeff_input/crosswalk_budget_2016_2019.csv, varnames(1) encoding(utf8) clear

destring pension_*, force replace

* inflation adjusted according to the CPI index publisherd by FRED.
* Use December 2019 and December 2016 index to adjust 2019 values to 2016.
* https://fred.stlouisfed.org/series/CHNCPIALLMINMEI
replace pension_outlay_2019 = pension_outlay_2019*(102.4/108.84)
replace pension_rev_2019 = pension_rev_2019*(102.4/108.84)


foreach v in pension_outlay_2016 pension_outlay_2019 pension_rev_2016 pension_rev_2019 {


	gen ln_`v' = ln(`v')

	
}


gen growthoutlay = ln_pension_outlay_2019 - ln_pension_outlay_2016 
gen growthrev = ln_pension_rev_2019 - ln_pension_rev_2016 


foreach depvar in outlay rev {
preserve
	keep if !mi(ln_pension_`depvar'_2019) & !mi(ln_pension_`depvar'_2016)
	sort ln_pension_`depvar'_2016
	gen rank16 = _n
	sort ln_pension_`depvar'_2019
	gen rank19 = _n
	corr rank16 rank19
	scalar rcor = r(rho)
	reg ln_pension_`depvar'_2019 ln_pension_`depvar'_2016
	matrix temp = r(table)
	local temp = temp[1,1]
	local slope: di %4.2f `temp'
	scalar r2 = e(r2)
	
	su growth`depvar' [aw=ln_pension_`depvar'_2016]
	local growth: di %4.2f r(mean)
	
	twoway (scatter ln_pension_`depvar'_2019 ln_pension_`depvar'_2016) ///
		(lfit ln_pension_`depvar'_2019 ln_pension_`depvar'_2016) ///
		, text(12.01 13 "Slope = `slope'", justification(left) placement(ne) size(medlarge)) ///
		text(11.51 13 "R-squared = `=round(r2,.001)'", justification(left) placement(ne) size(medlarge)) ///
		text(11.01 13 "Rank correlation = `=round(rcor,.001)'", justification(left) placement(ne) size(medium)) ///
		text(10.51 13 "Average Growth Rate = `growth'", justification(left) placement(ne) size(medium)) ///
		legend(off) ytitle("Ln(2019 pension `depvar')") xtitle("Ln(2016 pension `depvar')") xlabel(10(1)15) ///
		 xscale(range(10(1)15))
	graph export $output/pension_`depvar'_2016_2019.pdf, replace
restore

}


use "`working'", clear
