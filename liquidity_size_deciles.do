
**************************************
* Descriptives of Liquidity to Costs *
**************************************

//appendix figure
su cash_to, d
local temp1: di %9.2f  `r(p50)'

su liquidity_to , d
local temp2: di %9.2f `r(p50)'


binscatter cash_to liquidity_to firm_size_deciles_rev, discrete line(connect) ytitle(Median) xtitle(Firm Revenue Decile) ///
xlabel(#10) ylabel(#10) median legend(pos(3) ring(0) cols(2) label(1 "Cash / Costs") label(2 "Total Liquidity / Costs")) ///
	caption("Median Cash/Costs: `temp1'" ///
	"Median Liquidity/Costs: `temp2'" ,pos(1) ring(0) fcolor(white) bcolor(white) box ) scale(1.2)

graph export $output/liquidity_size_deciles.pdf, replace
