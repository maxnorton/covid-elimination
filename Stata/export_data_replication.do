use ../WHR2021/SelectedFiles/gwp_micro_workingsample_2020final.dta, clear
keep if inlist(year, 2019, 2020) & in2019 & in2020

rename countOnFriends countOnFrs
rename healthproblem healthprob

label define elimination 0 "Mitigation countries" 1 "Elimination countries"

gen Elim = (WHOWPR | inlist(country, "Iceland"))
label values Elim Elimination 

forval l=0/10 {
	gen l`l' = ladder==`l'
}
gen lrange1 = inrange(ladder, 0, 3)
label variable lrange1 "Low ladder score (0-3)"
gen lrange2 = inrange(ladder, 4, 7)
label variable lrange2 "Medium ladder score (4-7)"
gen lrange3 = inrange(ladder, 8, 10)
label variable lrange3 "High ladder score (8-10)"

foreach v in lrange1 lrange2 lrange3 healthprob confnatgov physicalpain worry stress sadness ///
		anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger {
			gen `v'_wt = 1 if !mi(`v')
}

preserve
	rename Elim elim
	gcollapse (sum) *_wt l0-l10 lrange1-lrange3 ///
		(sum) healthprob confnatgov physicalpain worry stress sadness ///
		anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger ///
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
