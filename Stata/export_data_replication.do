use ../WHR2021/SelectedFiles/gwp_micro_workingsample_2020final.dta, clear
keep if inlist(year, 2019, 2020) & in2019 & in2020

gen Elim = (WHOWPR | inlist(country, "Iceland"))
label values Elim Elimination 
label define elimination 0 "Mitigation countries" 1 "Elimination countries"

gen nonOECD = !OECD

gen OecdElim = .
replace OecdElim = 0 if OECD
replace OecdElim = 1 if OECD & Elim

gen NonoecdElim = .
replace NonoecdElim = 0 if !OECD
replace NonoecdElim = 1 if !OECD & Elim

gen Mitig = !Elim

gen OecdMitig = .
replace OecdMitig = 0 if OECD 
replace OecdMitig = 1 if OECD & Mitig 

gen NonoecdMitig = . 
replace NonoecdMitig = 0 if !OECD
replace NonoecdMitig = !OECD & Mitig

rename countOnFriends countOnFrs
rename healthproblem healthprob

forval l=0/10 {
	gen l`l' = ladder==`l'
}
forval l=0/10 {
	gen l`l'_wt = 1
}

gen notfgn = !fgnborn 
gen male = !female

gen temp = avgladder5yr if year==2019
bys wp5: egen avgladder5yr2019 = mean(temp)
drop temp
gen hiladder = ladder > avgladder5yr2019
gen loladder = !hiladder

foreach v in lowinc midinc highinc single sepdivwid marrAsMarr male female loladder hiladder notfgn fgnborn OECD nonOECD Elim Mitig {
	forval l=0/10 {
		gen `v'_l`l' = ladder==`l' & `v'
	}
}

foreach v in elementary secondary college {
	forval l=0/10 {
		gen `v'_l`l' = ladder==`l' & `v' & !(elementary & secondary & college)
	}
}

gen lrange1 = inrange(ladder, 0, 3)
label variable lrange1 "Low ladder score (0-3)"
gen lrange2 = inrange(ladder, 4, 7)
label variable lrange2 "Medium ladder score (4-7)"
gen lrange3 = inrange(ladder, 8, 10)
label variable lrange3 "High ladder score (8-10)"

foreach v in lrange1 lrange2 lrange3 healthprob confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger {
			gen `v'_wt = 1 if !mi(`v')
}

preserve
	rename Elim elim
	gcollapse (sum) *_wt l0-l10 lrange1-lrange3 ///
		(sum) healthprob confnatgov physicalpain worry stress sadness ///
		anger laugh enjoyment countOnFrs freedom donation volunteering ///
		helpstranger *_l0 *_l1 *_l2 *_l3 *_l4 *_l5 *_l6 *_l7 *_l8 *_l9 *_l10 ///
		[iw=weightC], by(female wp5 region1 year OECD elim WHOWPR)
	forval l=0/10 {
		label variable l`l' "Cum weight at ladder score `l'"
	}
	forval l=1/3 {
		label variable lrange`l' "Cum weight in ladder range `l'"
	}
	save DataProcessed/ladder_distribution.dta, replace
restore

gen is2020 = year==2020

foreach sample in Elim Mitig OecdElim OecdMitig NonoecdElim NonoecdMitig {
	foreach v in worry stress sadness anger laugh enjoyment healthprob physicalpain countOnFrs freedom donation volunteering helpstranger confnatgov {
		reghdfe `v' is2020 if `sample'==1 [aw=weightC], noabsorb vce(r)
		gen seDelta_`v'`sample' = _se[is2020] if `sample'==1 
	}
}

foreach sample in Elim Mitig OecdElim OecdMitig NonoecdElim NonoecdMitig {
	reghdfe deathrate1231 if `sample'==1 [aw=weightC], noabsorb vce(r)
	gen seDeathrate`sample' = _se[_cons] if `sample'==1
}

rename Elim elim

gen seMean_confnatgov = .
forval yr = 2019/2020 {
	reghdfe confnatgov if WHOWPR & year==`yr', noabsorb vce(r)
	replace seMean_confnatgov = _se[_cons] if WHOWPR & year==`yr'
	reghdfe confnatgov if !WHOWPR & year==`yr', noabsorb vce(r)
	replace seMean_confnatgov = _se[_cons] if !WHOWPR & year==`yr'
}

gcollapse (mean) *_wt unemployed deathrate1231 confnatgov healthprob physicalpain worry stress sadness anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger is2020 (firstnm) se* [iw=weightC], by(wp5 region1 year OECD elim WHOWPR)

save DataProcessed/country_averages.dta, replace

use "../WHR2021/Cross-sectional data/nationalavg_mortalitymeasures_20211025.dta", clear
save DataProcessed/country_mortality.dta, replace
