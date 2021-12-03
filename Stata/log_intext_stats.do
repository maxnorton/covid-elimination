****************************************
* Generate stats used directly in text *
****************************************

log using Results/intext_stats.log, replace
log off

use DataProcessed/ladder_distribution.dta, clear

preserve
	gcollapse (sum) l0-l10, by(year)
	reshape long l, i(year) j(ladder)
	label variable ladder "Ladder score"
	label values ladder .
	label variable l "Cum weight"

	log on
	tab ladder if year==2019 [iw=l]
	tab ladder if year==2020 [iw=l]
	log off
restore

preserve
	gcollapse (sum) l0-l10, by(year female)
	reshape long l, i(year female) j(ladder)
	label variable ladder "Ladder score"
	label values ladder .
	label variable l "Cum weight"

	log on
	bys female: sum ladder if year==2020 [iw=l]
	log off
restore

preserve
	gcollapse (sum) lrange*, by(female year)
	forval i=1/3 {
		replace lrange`i' = lrange`i' / lrange`i'_wt
	}
	log on
	bys female: sum lrange1-lrange3 if year==2020
	log off
restore

preserve
	gcollapse (sum) l0-l10, by(year WHOWPR)
	reshape long l, i(year WHOWPR) j(ladder)
	label variable ladder "Ladder score"
	label values ladder .
	label variable l "Cum weight"

	log on
	bys year: sum ladder if WHOWPR [iw=l]
	bys year: sum ladder if !WHOWPR [iw=l]
	log off
restore

preserve
	gcollapse (sum)	*_wt healthprob confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger, by(year)
	foreach v in healthprob confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger {
		replace `v' = `v' / `v'_wt
	}

	log on
	bys year: sum healthprob confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger
	log off
restore

preserve
	gcollapse (sum)	*_wt healthprob confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger, by(year WHOWPR)
	foreach v in healthprob confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger {
		replace `v' = `v' / `v'_wt
	}

	log on
	bys year: sum healthprob confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger if WHOWPR
	bys year: sum healthprob confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFrs freedom donation volunteering helpstranger if !WHOWPR
	log off
restore

log close
