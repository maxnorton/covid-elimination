****************************************
* Generate stats used directly in text *
****************************************

log using Results/intext_stats.log, replace

use DataProcessed/ladder_distribution.dta, clear

preserve
	gcollapse (sum) l0-l10, by(year)
	reshape long l, i(year) j(ladder)
	label variable ladder "Ladder score"
	label values ladder .
	label variable l "Cum weight"

	tab ladder if year==2019 [iw=l]
	tab ladder if year==2020 [iw=l]
restore

preserve
	gcollapse (sum) l0-l10, by(year female)
	reshape long l, i(year female) j(ladder)
	label variable ladder "Ladder score"
	label values ladder .
	label variable l "Cum weight"

	bys female: sum ladder if year==2020 [iw=l]
restore

preserve
	gcollapse (sum) lrange1-lrange3 weightnew, by(female year)
	forval i=1/3 {
		replace lrange`i' = lrange`i' / weightnew
	}
	bys female: sum lrange1-lrange3 if year==2020
	reshape long lrange, i(female year) j(range)
restore

preserve
	gcollapse (sum) l0-l10, by(year WHOWPR)
	reshape long l, i(year WHOWPR) j(ladder)
	label variable ladder "Ladder score"
	label values ladder .
	label variable l "Cum weight"

	bys year: sum ladder if WHOWPR [iw=l]
	bys year: sum ladder if !WHOWPR [iw=l]
restore

log close
