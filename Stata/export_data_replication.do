use ../WHR2021/SelectedFiles/gwp_micro_workingsample.dta, clear
keep if inlist(year, 2019, 2020) & in2019 & in2020

label define elimination 0 "Mitigation countries" 1 "Elimination countries"

gen elim = (WHOWPR | inlist(country, "Iceland", "Rwanda", "Bhutan"))
label values elim elimination 

gen oecd_elim = .
replace oecd_elim = 0 if OECD
replace oecd_elim = 1 if OECD & (WHOWPR | country=="Iceland")

gen nonoecd_elim = .
replace nonoecd_elim = 0 if !OECD
replace nonoecd_elim = 1 if !OECD &  (WHOWPR | inlist(country, "Bhutan", "Rwanda"))

label values oecd_elim elimination
label values nonoecd_elim elimination

forval l=0/10 {
	gen l`l' = ladder==`l'
}
gen lrange1 = inrange(ladder, 0, 3)
label variable lrange1 "Low ladder score (0-3)"
gen lrange2 = inrange(ladder, 4, 7)
label variable lrange2 "Medium ladder score (4-7)"
gen lrange3 = inrange(ladder, 8, 10)
label variable lrange3 "High ladder score (8-10)"

preserve
	gen weightnew=1
	gcollapse (sum) l0-l10 lrange1-lrange3 weightnew ///
		(mean) healthproblem confnatgov physicalpain worry stress sadness ///
		anger laugh enjoyment countOnFriends freedom donation volunteering helpstranger ///
		deathrate1231 ///
		[iw=weightC], by(female wp5 region1 year OECD elim WHOWPR)
	forval l=0/10 {
		label variable l`l' "Cum weight at ladder score `l'"
	}
	forval l=1/3 {
		label variable lrange`l' "Cum weight in ladder range `l'"
	}
	save DataProcessed/ladder_distribution.dta, replace
restore
