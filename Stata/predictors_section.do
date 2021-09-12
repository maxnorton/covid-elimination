use "../WHR2021/Cross-sectional data/nationalavg_mortalitymeasures_Apr23.dta", clear
set scheme plottig

gen tidcat = .
scalar cat = 1
forval break = .1(.1)1 {
		replace tidcat = cat if TIDB<=`break' & mi(tidcat)
		scalar cat = cat + 1
}
count if !mi(TIDB)
scalar tot = r(N)
bys tidcat: egen catcount = count(TIDB)
gen freq = catcount / tot
twoway (scatter freq TID, msymbol(O)) ///
		(scatter freq TIDB if mi(TID), msymbol(Oh)), ///
		xline(.10, lcolor(gs7) lstyle(dot)) ///
		xline(.20, lcolor(gs7) lstyle(dot)) ///
		xline(.30, lcolor(gs7) lstyle(dot)) ///
		xline(.40, lcolor(gs7) lstyle(dot)) ///
		xline(.50, lcolor(gs7) lstyle(dot)) ///
		xline(.60, lcolor(gs7) lstyle(dot)) ///
		xline(.70, lcolor(gs7) lstyle(dot)) ///
		xline(.80, lcolor(gs7) lstyle(dot)) ///
		xline(.90, lcolor(gs7) lstyle(dot)) ///
		xline(1, lcolor(gs7) lstyle(dot)) ///
		xsc(lcolor(black)) ysc(lcolor(black)) ///
		plotregion(fcolor(white)) ///
		legend(label(1 "Surveyed countries") label(2 "Imputed countries"))

* Table 4
reg deathrate1231  island1 is_ratio exposure0331cap femaleheadofstate WHOWPR lndistcap_SARS TIDB gini , r

* Compare to:
reg excessdeaths2020_relavg  island1 is_ratio exposure0331cap femaleheadofstate WHOWPR lndistcap_SARS TIDB gini , r
