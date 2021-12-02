use ../WHR2021/SelectedFiles/gwp_micro_workingsample_2020final.dta, clear
keep if inlist(year, 2019, 2020) & in2019 & in2020

set scheme plottig
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


****************************************
* Generate stats used directly in text *
****************************************

*log using microstats.smcl, replace

tab ladder if year==2019 [iw=weightC]
tab ladder if year==2020 [iw=weightC]

bys female: sum ladder if year==2020 [iw=weightC]

gen hiladder = inrange(ladder, 8, 10)
gen loladder = inrange(ladder, 0, 3)

bys female: sum hiladder loladder if year==2020 [iw=weightC]

bys year: sum ladder if WHOWPR [aw=weightC]
bys year: sum ladder if !WHOWPR [aw=weightC]

bys year: sum healthproblem confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFriends freedom donation volunteering helpstranger [iw=weightC]
bys year: sum healthproblem confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFriends freedom donation volunteering helpstranger if WHOWPR [iw=weightC]
bys year: sum healthproblem confnatgov physicalpain worry stress sadness anger laugh enjoyment countOnFriends freedom donation volunteering helpstranger if !WHOWPR [iw=weightC]

*log close


*****************************
* Figure 6 - Global changes *
*****************************

preserve
	keep if year==2020
	collapse (mean) deathrate1231 elim, by(wp5)
	reghdfe deathrate1231 if elim, noabsorb vce(r)
	gen delta19 = _b[_cons] if elim
	gen se19 = _se[_cons] if elim
	gen ciup19 = delta19 + 1.96*_se[_cons] if elim 
	gen cidown19 = delta19 - 1.96*_se[_cons] if elim
	reghdfe deathrate1231 if !elim, noabsorb vce(r)
	replace delta19 = _b[_cons] if !elim
	replace se19 = _se[_cons] if !elim
	replace ciup19 = delta19 + 1.96*_se[_cons] if !elim 
	replace cidown19 = delta19 - 1.96*_se[_cons] if !elim
	bys elim: sum delta19 se19
	pause
	drop deathrate1231
	tempfile drest
	save `drest', replace
restore

preserve
	label variable confnatgov "Conf nat gov"
	label variable healthproblem "Health problem"
	label variable physicalpain "Physical pain"
	label variable worry "Worry"
	label variable stress "Stress"
	label variable sadness "Sadness"
	label variable anger "Anger"
	label variable laugh "Laughter"
	label variable enjoyment "Enjoyment"
	label variable countOnFriends "Friend to count on"
	label variable freedom "Freedom"
	label variable donation "Made donation"
	label variable volunteering "Volunteered"
	label variable helpstranger "Helped a stranger"
	gen is2020 = year==2020
	scalar num = 1
	foreach v in worry stress sadness anger laugh enjoyment healthproblem physicalpain countOnFriends freedom donation volunteering helpstranger confnatgov {
		if inlist("`v'", "laugh", "healthproblem", "countOnFriends") scalar num = num + 1
		reghdfe `v' is2020 if elim [aw=weightC], noabsorb vce(r)
		pause
		gen delta`=num' = _b[is2020] if elim
		gen ciup`=num' = delta`=num' + 1.96*_se[is2020] if elim 
		gen cidown`=num' = delta`=num' - 1.96*_se[is2020] if elim
		reghdfe `v' is2020 if !elim, noabsorb vce(r)
		pause
		replace delta`=num' = _b[is2020] if !elim
		replace ciup`=num' = delta`=num' + 1.96*_se[is2020] if !elim 
		replace cidown`=num' = delta`=num' - 1.96*_se[is2020] if !elim
		local lab : variable label `v'
		label define cats `=num' "`lab'", modify
		label variable delta`=num' "`lab'"
		scalar num = num + 1
	}
	scalar drop num
	merge m:1 wp5 using `drest', nogen keep(1 3)
	collapse (firstnm) delta* ci*, by(elim)
	reshape long delta ciup cidown, i(elim) j(cat)
	label define cats 5 " " 8 " " 11 " " 18 " " 19 "Death rate", modify
	label values cat cats
	label variable cat ""
	tempfile dupeobs
	save `dupeobs', replace
	append using `dupeobs', gen(dupe) 
	set scheme plotplainblind
	twoway (scatter delta cat if elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(range(-.08 .12) axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(-.08(.04).12, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "change" "from" "2019 to" "2020", size(medsmall) axis(1) orientation(horizonatal) justification(left)) /// 
			ymlabel(-.08(.01).12, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(scatter delta cat if !elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(rcap ciup cidown cat if !elim & cat!=19 & dupe==1, lcolor(gs5) yaxis(1)) ///
		(scatter delta cat if elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(scatter delta cat if !elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2) ) ///
		(rcap ciup cidown cat if !elim & cat==19 & dupe==0, lcolor(gs5) yaxis(2)) ///
		 , yline(0, lcolor(black) lpattern(dash)) ///
		xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(2 "Mitigation countries") order(1 2) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		text(0 19.2 "  ", bcolor(white) box)
	graph save fig6.gph, replace
	graph export fig6.png, replace
		twoway (scatter delta cat if elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(range(-.08 .12) axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(-.08(.04).12, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "change" "from" "2019 to" "2020", size(medsmall) axis(1) orientation(horizonatal) justification(left)) /// 
			ymlabel(-.08(.01).12, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(rcap ciup cidown cat if elim & cat!=19 & dupe==1, lcolor(red) yaxis(1)) ///
		(scatter delta cat if !elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(scatter delta cat if elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(rcap ciup cidown cat if elim & cat==19 & dupe==0, lcolor(red) yaxis(2)) ///
		(scatter delta cat if !elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2) ) ///
		 , yline(0, lcolor(black) lpattern(dash)) ///
		xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(3 "Mitigation countries") order(1 3) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		text(0 19.2 "  ", bcolor(white) box)
	graph save fig6_elimci.gph, replace
	graph export fig6_elimci.png, replace
restore 


****************************************
* Figure 7 - OECD and non-OECD changes *
****************************************

* OECD countries
preserve
	keep if OECD & year==2020
	collapse (mean) deathrate1231 oecd_elim, by(wp5)
	reghdfe deathrate1231 if oecd_elim, noabsorb vce(r)
	gen delta19 = _b[_cons] if oecd_elim
	gen ciup19 = delta19 + 1.96*_se[_cons] if oecd_elim 
	gen cidown19 = delta19 - 1.96*_se[_cons] if oecd_elim
	reghdfe deathrate1231 if !oecd_elim, noabsorb vce(r)
	replace delta19 = _b[_cons] if !oecd_elim
	replace ciup19 = delta19 + 1.96*_se[_cons] if !oecd_elim 
	replace cidown19 = delta19 - 1.96*_se[_cons] if !oecd_elim
	drop deathrate1231
	tempfile drest
	save `drest', replace
restore

preserve
	keep if OECD
	label variable confnatgov "Conf nat gov"
	label variable healthproblem "Health problem"
	label variable physicalpain "Physical pain"
	label variable worry "Worry"
	label variable stress "Stress"
	label variable sadness "Sadness"
	label variable anger "Anger"
	label variable laugh "Laughter"
	label variable enjoyment "Enjoyment"
	label variable countOnFriends "Friend to count on"
	label variable freedom "Freedom"
	label variable donation "Made donation"
	label variable volunteering "Volunteered"
	label variable helpstranger "Helped a stranger"
	gen is2020 = year==2020
	scalar num = 1
	foreach v in worry stress sadness anger laugh enjoyment healthproblem physicalpain countOnFriends freedom donation volunteering helpstranger confnatgov {
		if inlist("`v'", "laugh", "healthproblem", "countOnFriends") scalar num = num + 1
		reghdfe `v' is2020 if oecd_elim [aw=weightC], noabsorb vce(r)
		gen delta`=num' = _b[is2020] if oecd_elim
		gen ciup`=num' = delta`=num' + 1.96*_se[is2020] if oecd_elim 
		gen cidown`=num' = delta`=num' - 1.96*_se[is2020] if oecd_elim
		reghdfe `v' is2020 if !oecd_elim, noabsorb vce(r)
		replace delta`=num' = _b[is2020] if !oecd_elim
		replace ciup`=num' = delta`=num' + 1.96*_se[is2020] if !oecd_elim 
		replace cidown`=num' = delta`=num' - 1.96*_se[is2020] if !oecd_elim
		local lab : variable label `v'
		label define cats `=num' "`lab'", modify
		label variable delta`=num' "`lab'"
		scalar num = num + 1
	}
	scalar drop num
	merge m:1 wp5 using `drest', nogen keep(1 3)
	collapse (firstnm) delta* ci*, by(oecd_elim)
	reshape long delta ciup cidown, i(oecd_elim) j(cat)
	label define cats 5 " " 8 " " 11 " " 18 " " 19 "Death rate", modify
	label values cat cats
	label variable cat ""
	tempfile dupeobs
	save `dupeobs', replace
	append using `dupeobs', gen(dupe) 
	set scheme plotplainblind
	twoway (scatter delta cat if oecd_elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(range(-.08 .12) axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(-.08(.04).12, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "change" "from" "2019 to" "2020", size(medsmall) axis(1) orientation(horizonatal) justification(left)) /// 
			ymlabel(-.08(.01).12, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(scatter delta cat if !oecd_elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(rcap ciup cidown cat if !oecd_elim & cat!=19 & dupe==1, lcolor(gs5) yaxis(1)) ///
		(scatter delta cat if oecd_elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(scatter delta cat if !oecd_elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2) ) ///
		(rcap ciup cidown cat if !oecd_elim & cat==19 & dupe==0, lcolor(gs5) yaxis(2)) ///
		 , yline(0, lcolor(black) lpattern(dash)) ///
		xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(2 "Mitigation countries") order(1 2) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		text(0 19.2 "  ", bcolor(white) box) ///
		title("OECD countries")
	graph save fig7_oecd.gph, replace
	graph export fig7_oecd.png, replace
	twoway (scatter delta cat if oecd_elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(range(-.08 .12) axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(-.08(.04).12, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "change" "from" "2019 to" "2020", size(medsmall) axis(1) orientation(horizonatal) justification(left)) /// 
			ymlabel(-.08(.01).12, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(rcap ciup cidown cat if oecd_elim & cat!=19 & dupe==1, lcolor(red) yaxis(1)) ///
		(scatter delta cat if !oecd_elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(scatter delta cat if oecd_elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(rcap ciup cidown cat if oecd_elim & cat==19 & dupe==0, lcolor(red) yaxis(2)) ///
		(scatter delta cat if !oecd_elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2) ) ///
		 , yline(0, lcolor(black) lpattern(dash)) ///
		xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(3 "Mitigation countries") order(1 3) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		text(0 19.2 "  ", bcolor(white) box) ///
		title("OECD countries")
	graph save fig7_oecd_elimci.gph, replace
	graph export fig7_oecd_elimci.png, replace
restore 

* Non-OECD countries
preserve
	keep if !OECD & year==2020
	collapse (mean) deathrate1231 nonoecd_elim, by(wp5)
	reghdfe deathrate1231 if nonoecd_elim, noabsorb vce(r)
	gen delta19 = _b[_cons] if nonoecd_elim
	gen ciup19 = delta19 + 1.96*_se[_cons] if nonoecd_elim 
	gen cidown19 = delta19 - 1.96*_se[_cons] if nonoecd_elim
	reghdfe deathrate1231 if !nonoecd_elim, noabsorb vce(r)
	replace delta19 = _b[_cons] if !nonoecd_elim
	replace ciup19 = delta19 + 1.96*_se[_cons] if !nonoecd_elim 
	replace cidown19 = delta19 - 1.96*_se[_cons] if !nonoecd_elim
	drop deathrate1231
	tempfile drest
	save `drest', replace
restore

preserve
	keep if !OECD
	label variable confnatgov "Conf nat gov"
	label variable healthproblem "Health problem"
	label variable physicalpain "Physical pain"
	label variable worry "Worry"
	label variable stress "Stress"
	label variable sadness "Sadness"
	label variable anger "Anger"
	label variable laugh "Laughter"
	label variable enjoyment "Enjoyment"
	label variable countOnFriends "Friend to count on"
	label variable freedom "Freedom"
	label variable donation "Made donation"
	label variable volunteering "Volunteered"
	label variable helpstranger "Helped a stranger"
	gen is2020 = year==2020
	scalar num = 1
	foreach v in worry stress sadness anger laugh enjoyment healthproblem physicalpain countOnFriends freedom donation volunteering helpstranger confnatgov {
		if inlist("`v'", "laugh", "healthproblem", "countOnFriends") scalar num = num + 1
		reghdfe `v' is2020 if nonoecd_elim [aw=weightC], noabsorb vce(r)
		gen delta`=num' = _b[is2020] if nonoecd_elim
		gen ciup`=num' = delta`=num' + 1.96*_se[is2020] if nonoecd_elim 
		gen cidown`=num' = delta`=num' - 1.96*_se[is2020] if nonoecd_elim
		reghdfe `v' is2020 if !nonoecd_elim, noabsorb vce(r)
		replace delta`=num' = _b[is2020] if !nonoecd_elim
		replace ciup`=num' = delta`=num' + 1.96*_se[is2020] if !nonoecd_elim 
		replace cidown`=num' = delta`=num' - 1.96*_se[is2020] if !nonoecd_elim
		local lab : variable label `v'
		label define cats `=num' "`lab'", modify
		label variable delta`=num' "`lab'"
		scalar num = num + 1
	}
	scalar drop num
	merge m:1 wp5 using `drest', nogen keep(1 3)
	collapse (firstnm) delta* ci*, by(nonoecd_elim)
	reshape long delta ciup cidown, i(nonoecd_elim) j(cat)
	label define cats 5 " " 8 " " 11 " " 18 " " 19 "Death rate", modify
	label values cat cats
	label variable cat ""
	tempfile dupeobs
	save `dupeobs', replace
	append using `dupeobs', gen(dupe) 
	set scheme plotplainblind
	twoway (scatter delta cat if nonoecd_elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(range(-.08 .12) axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(-.08(.04).12, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "change" "from" "2019 to" "2020", size(medsmall) axis(1) orientation(horizonatal) justification(left)) /// 
			ymlabel(-.08(.01).12, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(scatter delta cat if !nonoecd_elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(rcap ciup cidown cat if !nonoecd_elim & cat!=19 & dupe==1, lcolor(gs5) yaxis(1)) ///
		(scatter delta cat if nonoecd_elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(scatter delta cat if !nonoecd_elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2) ) ///
		(rcap ciup cidown cat if !nonoecd_elim & cat==19 & dupe==0, lcolor(gs5) yaxis(2)) ///
		 , yline(0, lcolor(black) lpattern(dash)) ///
		xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(2 "Mitigation countries") order(1 2) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		text(0 19.2 "  ", bcolor(white) box) ///
		title("Non-OECD countries") xsc(on lcolor(white))
	graph save fig7_nonoecd.gph, replace
	graph export fig7_nonoecd.png, replace
	twoway (scatter delta cat if nonoecd_elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(range(-.08 .12) axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(-.08(.04).12, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "change" "from" "2019 to" "2020", size(medsmall) axis(1) orientation(horizonatal) justification(left)) /// 
			ymlabel(-.08(.01).12, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(rcap ciup cidown cat if nonoecd_elim & cat!=19 & dupe==1, lcolor(red) yaxis(1)) ///
		(scatter delta cat if !nonoecd_elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(scatter delta cat if nonoecd_elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(rcap ciup cidown cat if nonoecd_elim & cat==19 & dupe==0, lcolor(red) yaxis(2)) ///
		(scatter delta cat if !nonoecd_elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2) ) ///
		 , yline(0, lcolor(black) lpattern(dash)) ///
		xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(3 "Mitigation countries") order(1 3) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		text(0 19.2 "  ", bcolor(white) box) ///
		title("Non-OECD countries") xsc(on lcolor(white))
	graph save fig7_nonoecd_elimci.gph, replace
	graph export fig7_nonoecd_elimci.png, replace
restore 


***********************
* Fig levels - global *
***********************

preserve
	keep if year==2020
	collapse (mean) deathrate1231 elim, by(wp5)
	reghdfe deathrate1231 if elim, noabsorb vce(r)
	gen level19 = _b[_cons] if elim
	gen ciup19 = level19 + 1.96*_se[_cons] if elim 
	gen cidown19 = level19 - 1.96*_se[_cons] if elim
	reghdfe deathrate1231 if !elim, noabsorb vce(r)
	replace level19 = _b[_cons] if !elim
	replace ciup19 = level19 + 1.96*_se[_cons] if !elim 
	replace cidown19 = level19 - 1.96*_se[_cons] if !elim
	drop deathrate1231
	tempfile drest
	save `drest', replace
restore

preserve
	label variable confnatgov "Conf nat gov"
	label variable healthproblem "Health problem"
	label variable physicalpain "Physical pain"
	label variable worry "Worry"
	label variable stress "Stress"
	label variable sadness "Sadness"
	label variable anger "Anger"
	label variable laugh "Laughter"
	label variable enjoyment "Enjoyment"
	label variable countOnFriends "Friend to count on"
	label variable freedom "Freedom"
	label variable donation "Made donation"
	label variable volunteering "Volunteered"
	label variable helpstranger "Helped a stranger"
	keep if year==2020
	scalar num = 1
	foreach v in worry stress sadness anger laugh enjoyment healthproblem physicalpain countOnFriends freedom donation volunteering helpstranger confnatgov {
		if inlist("`v'", "laugh", "healthproblem", "countOnFriends") scalar num = num + 1
		reghdfe `v' if elim [aw=weightC], noabsorb vce(r)
		gen level`=num' = _b[_cons] if elim
		gen ciup`=num' = level`=num' + 1.96*_se[_cons] if elim 
		gen cidown`=num' = level`=num' - 1.96*_se[_cons] if elim
		reghdfe `v' if !elim [aw=weightC], noabsorb vce(r)
		replace level`=num' = _b[_cons] if !elim
		replace ciup`=num' = level`=num' + 1.96*_se[_cons] if !elim 
		replace cidown`=num' = level`=num' - 1.96*_se[_cons] if !elim
		local lab : variable label `v'
		label define cats `=num' "`lab'", modify
		label variable level`=num' "`lab'"
		scalar num = num + 1
	}
	scalar drop num
	merge m:1 wp5 using `drest', nogen keep(1 3)
	collapse (firstnm) level* ci*, by(elim)
	reshape long level ciup cidown, i(elim) j(cat)
	label define cats 5 " " 8 " " 11 " " 18 " " 19 "Death rate", modify
	label values cat cats
	label variable cat ""
	tempfile dupeobs
	save `dupeobs', replace
	append using `dupeobs', gen(dupe) 
	set scheme plotplainblind	
	twoway (scatter level cat if elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(0(.2)1, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "level" "in" "2020", size(medsmall) axis(1) orientation(horizontal) justification(left)) ///
			ymlabel(0(.2)1, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(scatter level cat if !elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(scatter level cat if elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(scatter level cat if !elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2)) ///
		(rcap ciup cidown cat if elim & cat==19 & dupe==0, lcolor(red) yaxis(2)) ///
		(rcap ciup cidown cat if !elim & cat==19 & dupe==0, lcolor(gs5) yaxis(2)) ///
		, xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(2 "Mitigation countries") order(1 2) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		text(0 19.2 "  ", bcolor(white) box)
	graph save figlevels.gph, replace
	graph export figlevels.png, replace
	twoway (scatter level cat if elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(0(.2)1, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "level" "in" "2020", size(medsmall) axis(1) orientation(horizontal) justification(left)) ///
			ymlabel(0(.2)1, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(scatter level cat if !elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(rcap ciup cidown cat if elim & cat!=19 & dupe==1, lcolor(red) yaxis(1)) ///
		(scatter level cat if elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(scatter level cat if !elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2)) ///
		(rcap ciup cidown cat if elim & cat==19 & dupe==0, lcolor(red) yaxis(2)) ///
		 , xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(2 "Mitigation countries") order(1 2) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		text(0 19.2 "  ", bcolor(white) box)
	graph save figlevels_elimci.gph, replace
	graph export figlevels_elimci.png, replace
restore 


**********************************
* Fig levels - OECD and non-OECD *
**********************************

preserve
	keep if year==2020 & OECD
	collapse (mean) deathrate1231 oecd_elim, by(wp5)
	reghdfe deathrate1231 if oecd_elim, noabsorb vce(r)
	gen level19 = _b[_cons] if oecd_elim
	gen ciup19 = level19 + 1.96*_se[_cons] if oecd_elim 
	gen cidown19 = level19 - 1.96*_se[_cons] if oecd_elim
	reghdfe deathrate1231 if !oecd_elim, noabsorb vce(r)
	replace level19 = _b[_cons] if !oecd_elim
	replace ciup19 = level19 + 1.96*_se[_cons] if !oecd_elim 
	replace cidown19 = level19 - 1.96*_se[_cons] if !oecd_elim
	drop deathrate1231
	tempfile drest
	save `drest', replace
restore

preserve
	label variable confnatgov "Conf nat gov"
	label variable healthproblem "Health problem"
	label variable physicalpain "Physical pain"
	label variable worry "Worry"
	label variable stress "Stress"
	label variable sadness "Sadness"
	label variable anger "Anger"
	label variable laugh "Laughter"
	label variable enjoyment "Enjoyment"
	label variable countOnFriends "Friend to count on"
	label variable freedom "Freedom"
	label variable donation "Made donation"
	label variable volunteering "Volunteered"
	label variable helpstranger "Helped a stranger"
	keep if year==2020
	scalar num = 1
	foreach v in worry stress sadness anger laugh enjoyment healthproblem physicalpain countOnFriends freedom donation volunteering helpstranger confnatgov {
		if inlist("`v'", "laugh", "healthproblem", "countOnFriends") scalar num = num + 1
		reghdfe `v' if oecd_elim [aw=weightC], noabsorb vce(r)
		gen level`=num' = _b[_cons] if oecd_elim
		gen ciup`=num' = level`=num' + 1.96*_se[_cons] if oecd_elim 
		gen cidown`=num' = level`=num' - 1.96*_se[_cons] if oecd_elim
		reghdfe `v' if !oecd_elim [aw=weightC], noabsorb vce(r)
		replace level`=num' = _b[_cons] if !oecd_elim
		replace ciup`=num' = level`=num' + 1.96*_se[_cons] if !oecd_elim 
		replace cidown`=num' = level`=num' - 1.96*_se[_cons] if !oecd_elim
		local lab : variable label `v'
		label define cats `=num' "`lab'", modify
		label variable level`=num' "`lab'"
		scalar num = num + 1
	}
	scalar drop num
	merge m:1 wp5 using `drest', nogen keep(1 3)
	collapse (firstnm) level* ci*, by(oecd_elim)
	reshape long level ciup cidown, i(oecd_elim) j(cat)
	label define cats 5 " " 8 " " 11 " " 18 " " 19 "Death rate", modify
	label values cat cats
	label variable cat ""
	tempfile dupeobs
	save `dupeobs', replace
	append using `dupeobs', gen(dupe) 
	set scheme plotplainblind	
	twoway (scatter level cat if oecd_elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(0(.2)1, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "level" "in" "2020", size(medsmall) axis(1) orientation(horizontal) justification(left)) ///
			ymlabel(0(.2)1, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(scatter level cat if !oecd_elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(scatter level cat if oecd_elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(scatter level cat if !oecd_elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2)) ///
		(rcap ciup cidown cat if oecd_elim & cat==19 & dupe==0, lcolor(red) yaxis(2)) ///
		(rcap ciup cidown cat if !oecd_elim & cat==19 & dupe==0, lcolor(gs5) yaxis(2)) ///
		 , xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(2 "Mitigation countries") order(1 2) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		title("OECD countries") text(0 19.2 "  ", bcolor(white) box)
	graph save figlevels_oecd.gph, replace
	graph export figlevels_oecd.png, replace
	twoway (scatter level cat if oecd_elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(0(.2)1, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "level" "in" "2020", size(medsmall) axis(1) orientation(horizontal) justification(left)) ///
			ymlabel(0(.2)1, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(scatter level cat if !oecd_elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(rcap ciup cidown cat if oecd_elim & cat!=19 & dupe==1, lcolor(red) yaxis(1)) ///
		(scatter level cat if oecd_elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(scatter level cat if !oecd_elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2)) ///
		(rcap ciup cidown cat if oecd_elim & cat==19 & dupe==0, lcolor(red) yaxis(2)) ///
		 , xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(2 "Mitigation countries") order(1 2) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		title("OECD countries") text(0 19.2 "  ", bcolor(white) box)
	graph save figlevels_oecd_elimci.gph, replace
	graph export figlevels_oecd_elimci.png, replace
restore 

preserve
	keep if year==2020 & !OECD
	collapse (mean) deathrate1231 nonoecd_elim, by(wp5)
	reghdfe deathrate1231 if nonoecd_elim, noabsorb vce(r)
	gen level19 = _b[_cons] if nonoecd_elim
	gen ciup19 = level19 + 1.96*_se[_cons] if nonoecd_elim 
	gen cidown19 = level19 - 1.96*_se[_cons] if nonoecd_elim
	reghdfe deathrate1231 if !nonoecd_elim, noabsorb vce(r)
	replace level19 = _b[_cons] if !nonoecd_elim
	replace ciup19 = level19 + 1.96*_se[_cons] if !nonoecd_elim 
	replace cidown19 = level19 - 1.96*_se[_cons] if !nonoecd_elim
	drop deathrate1231
	tempfile drest
	save `drest', replace
restore

preserve
	label variable confnatgov "Conf nat gov"
	label variable healthproblem "Health problem"
	label variable physicalpain "Physical pain"
	label variable worry "Worry"
	label variable stress "Stress"
	label variable sadness "Sadness"
	label variable anger "Anger"
	label variable laugh "Laughter"
	label variable enjoyment "Enjoyment"
	label variable countOnFriends "Friend to count on"
	label variable freedom "Freedom"
	label variable donation "Made donation"
	label variable volunteering "Volunteered"
	label variable helpstranger "Helped a stranger"
	keep if year==2020
	scalar num = 1
	foreach v in worry stress sadness anger laugh enjoyment healthproblem physicalpain countOnFriends freedom donation volunteering helpstranger confnatgov {
		if inlist("`v'", "laugh", "healthproblem", "countOnFriends") scalar num = num + 1
		reghdfe `v' if nonoecd_elim [aw=weightC], noabsorb vce(r)
		gen level`=num' = _b[_cons] if nonoecd_elim
		gen ciup`=num' = level`=num' + 1.96*_se[_cons] if nonoecd_elim 
		gen cidown`=num' = level`=num' - 1.96*_se[_cons] if nonoecd_elim
		reghdfe `v' if !nonoecd_elim [aw=weightC], noabsorb vce(r)
		replace level`=num' = _b[_cons] if !nonoecd_elim
		replace ciup`=num' = level`=num' + 1.96*_se[_cons] if !nonoecd_elim 
		replace cidown`=num' = level`=num' - 1.96*_se[_cons] if !nonoecd_elim
		local lab : variable label `v'
		label define cats `=num' "`lab'", modify
		label variable level`=num' "`lab'"
		scalar num = num + 1
	}
	scalar drop num
	merge m:1 wp5 using `drest', nogen keep(1 3)
	collapse (firstnm) level* ci*, by(nonoecd_elim)
	reshape long level ciup cidown, i(nonoecd_elim) j(cat)
	label define cats 5 " " 8 " " 11 " " 18 " " 19 "Death rate", modify
	label values cat cats
	label variable cat ""
	tempfile dupeobs
	save `dupeobs', replace
	append using `dupeobs', gen(dupe) 
	set scheme plotplainblind	
	twoway (scatter level cat if nonoecd_elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(0(.2)1, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "level" "in" "2020", size(medsmall) axis(1) orientation(horizontal) justification(left)) ///
			ymlabel(0(.2)1, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(scatter level cat if !nonoecd_elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(scatter level cat if nonoecd_elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(scatter level cat if !nonoecd_elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2)) ///
		(rcap ciup cidown cat if nonoecd_elim & cat==19 & dupe==0, lcolor(red) yaxis(2)) ///
		(rcap ciup cidown cat if !nonoecd_elim & cat==19 & dupe==0, lcolor(gs5) yaxis(2)) ///
		 , xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(2 "Mitigation countries") order(1 2) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		title("Non-OECD countries") text(0 19.2 "  ", bcolor(white) box)
	graph save figlevels_nonoecd.gph, replace
	graph export figlevels_nonoecd.png, replace
	twoway (scatter level cat if nonoecd_elim & cat!=19 & dupe==1, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(1) ysc(axis(1) lcolor(black) lpattern(solid)) ///
			ylabel(0(.2)1, axis(1) grid labcolor(black) labsize(medsmall) tlcolor(black)) ///
			ytitle("Average" "level" "in" "2020", size(medsmall) axis(1) orientation(horizontal) justification(left)) ///
			ymlabel(0(.2)1, axis(1) nolab notick grid glcolor(gs6) glpattern(dot)) ) ///
		(scatter level cat if !nonoecd_elim & cat!=19 & dupe==1, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(1)) ///
		(rcap ciup cidown cat if nonoecd_elim & cat!=19 & dupe==1, lcolor(red) yaxis(1)) ///
		(scatter level cat if nonoecd_elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
			yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
			ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
			ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
		(scatter level cat if !nonoecd_elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2)) ///
		(rcap ciup cidown cat if nonoecd_elim & cat==19 & dupe==0, lcolor(red) yaxis(2)) ///
		 , xtitle("Emotion (-)   Emotion (+)  Health        Social factors      COVID", size(medsmall) justification(left) margin(l=0 t=-27 b=20)) ///
		legend(label(1 "Elimination countries") label(2 "Mitigation countries") order(1 2) pos(6) rows(1) size(medsmall)) ///
		xlabel(1(1)19, val angle(50) noticks labcolor(black) labsize(small) grid glcolor(gs6) glpattern(dot) labgap(7) nogextend) ///
		title("") xsc(on lcolor(white)) ///
		xline(5, lcolor(gs13) lpattern(solid) noextend) ///
		xline(8, lcolor(gs13) lpattern(solid) noextend) ///
		xline(11, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18, lcolor(gs13) lpattern(solid) noextend) ///
		xline(18.45, lcolor(white) lpattern(solid) lwidth(vvvthick)) ///
		xline(18.625, lcolor(white) lpattern(solid) lwidth(vvvthick)) xline(19, lcolor(gs6) lpattern(dot) noextend) ///
		title("Non-OECD countries") text(0 19.2 "  ", bcolor(white) box)
	graph save figlevels_nonoecd_elimci.gph, replace
	graph export figlevels_nonoecd_elimci.png, replace
restore 


************
* Figure 4 *
************

preserve
	collapse (mean) mean = confnatgov (semean) se = confnatgov [aw=weightC], by(WHOWPR year)
	gen ciup = mean+1.96*se
	gen cidown = mean-1.96*se
	twoway (bar mean year, ///
			sort xsc(range(2019(1)2020)) ysc(range(0.42(0.1)0.56)) ///
			xlabel(2019(1)2020, noticks labcolor(black) labsize(medsmall)) ///
			color(gs7) barw(0.95)) ///
		(rcap ciup cidown year, lcolor(black) ysc(range(0.42(0.1)0.56))) ///
	, by(WHOWPR, note("") legend(off)) subtitle(,pos(6)) plotregion(fcolor(white)) ///
	xsc(lcolor(black)) ysc(lcolor(black)) ylabel(#15, grid glcolor(gs6) glpattern(dot) labcolor(black) labsize(medsmall)) ///
	xtitle("") 
	graph save fig4.gph, replace
	graph export fig4.png, replace
restore


************
* Figure 5 *
************

preserve
	forval l=0/10 {
		gen l`l' = ladder==`l'
	}
	collapse (sum) l0-l10 [aw=weightC], by(year)
	reshape long l, i(year) j(val)
	replace val = (val*2)*10 if year==2019
	replace val = ((val+1)*2 - 1)*10 if year==2020
	reshape wide l, i(year) j(val)
	egen sum = rowtotal(l0-l210)
	forval n=0(10)210 {
		gen lsh`n' = l`n' / sum
	}
	reshape long lsh, i(year) j(position)
	replace lsh = lsh*100
	label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
	label values position position
	twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
		(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
		, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
		ytitle("Within-year frequency (%)", size(medsmall)) ///
		xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
		ylabel(, labcolor(black) grid glcolor(gs6) glpattern(dot) labsize(medsmall)) ///
		xsc(lcolor(black)) ysc(lcolor(black)) xtitle("")
	graph save fig5.gph, replace
	graph export fig5.png, replace
restore

foreach v in lowinc midinc highinc {
	preserve
		keep if `v'==1
		sum ladder if year==2019 [aw=weightC]
		scalar n19 = r(N)
		sum ladder if year==2020 [aw=weightC]
		scalar n20 = r(N)
		if "`v'"=="lowinc" local title "Low income respondents"
		else if "`v'"=="midinc" local title "Middle income respondents"
		else if "`v'"=="highinc" local title "High income respondents"
		forval l=0/10 {
			gen l`l' = ladder==`l'
		}
		collapse (sum) l0-l10 [aw=weightC], by(year)
		reshape long l, i(year) j(val)
		replace val = (val*2)*10 if year==2019
		replace val = ((val+1)*2 - 1)*10 if year==2020
		reshape wide l, i(year) j(val)
		egen sum = rowtotal(l0-l210)
		forval n=0(10)210 {
			gen lsh`n' = l`n' / sum
		}
		reshape long lsh, i(year) j(position)
		replace lsh = lsh*100
		label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
		label values position position
		twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
			(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
			, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
			ytitle("Within-year frequency (%)", size(medsmall)) ///
			xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
			ylabel(0(5)25, labcolor(black) grid glcolor(gs6) glpattern(dot) gmin gmax labsize(medsmall)) ///
			xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") title(`title') ///
			note("N = `=n19' 2019 respondents and `=n20' 2020 respondents")
		graph save fig5_`v'.gph, replace
		graph export fig5_`v'.png, replace
	restore
}

foreach v in single sepdivwid marrAsMarr {
	preserve
		keep if `v'==1
		sum ladder if year==2019 [aw=weightC]
		scalar n19 = r(N)
		sum ladder if year==2020 [aw=weightC]
		scalar n20 = r(N)
		if "`v'"=="single" local title "Single respondents"
		else if "`v'"=="sepdivwid" local title "Separated/divorced/widowed respondents"
		else if "`v'"=="highinc" local title "Married/as married repsondents"
		forval l=0/10 {
			gen l`l' = ladder==`l'
		}
		collapse (sum) l0-l10 [aw=weightC], by(year)
		reshape long l, i(year) j(val)
		replace val = (val*2)*10 if year==2019
		replace val = ((val+1)*2 - 1)*10 if year==2020
		reshape wide l, i(year) j(val)
		egen sum = rowtotal(l0-l210)
		forval n=0(10)210 {
			gen lsh`n' = l`n' / sum
		}
		reshape long lsh, i(year) j(position)
		replace lsh = lsh*100
		label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
		label values position position
		twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
			(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
			, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
			ytitle("Within-year frequency (%)", size(medsmall)) ///
			xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
			ylabel(0(5)25, labcolor(black) grid glcolor(gs6) glpattern(dot) gmin gmax labsize(medsmall)) ///
			xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") title(`title') ///
			note("N = `=n19' 2019 respondents and `=n20' 2020 respondents")
		graph save fig5_`v'.gph, replace
		graph export fig5_`v'.png, replace
	restore
}

foreach v in elementary secondary college {
	preserve
		drop if elementary & secondary & college
		keep if `v'==1
		sum ladder if year==2019 [aw=weightC]
		scalar n19 = r(N)
		sum ladder if year==2020 [aw=weightC]
		scalar n20 = r(N)
		if "`v'"=="elementary" local title "Elementary education or less"
		else if "`v'"=="secondary" local title "Secondary or up to 3 years post-secondary education"
		else if "`v'"=="college" local title "Post-secondary graduate"
		forval l=0/10 {
			gen l`l' = ladder==`l'
		}
		collapse (sum) l0-l10 [aw=weightC], by(year)
		reshape long l, i(year) j(val)
		replace val = (val*2)*10 if year==2019
		replace val = ((val+1)*2 - 1)*10 if year==2020
		reshape wide l, i(year) j(val)
		egen sum = rowtotal(l0-l210)
		forval n=0(10)210 {
			gen lsh`n' = l`n' / sum
		}
		reshape long lsh, i(year) j(position)
		replace lsh = lsh*100
		label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
		label values position position
		twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
			(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
			, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
			ytitle("Within-year frequency (%)", size(medsmall)) ///
			xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
			ylabel(0(5)25, labcolor(black) grid glcolor(gs6) glpattern(dot) gmin gmax labsize(medsmall)) ///
			xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") title(`title') ///
			note("N = `=n19' 2019 respondents and `=n20' 2020 respondents")
		graph save fig5_`v'.gph, replace
		graph export fig5_`v'.png, replace
	restore
}

gen male = !female

foreach v in male female {
	preserve
		keep if `v'==1
		sum ladder if year==2019 [aw=weightC]
		scalar n19 = r(N)
		sum ladder if year==2020 [aw=weightC]
		scalar n20 = r(N)
		if "`v'"=="male" local title "Male respondents"
		else if "`v'"=="female" local title "Female respondents"
		forval l=0/10 {
			gen l`l' = ladder==`l'
		}
		collapse (sum) l0-l10 [aw=weightC], by(year)
		reshape long l, i(year) j(val)
		replace val = (val*2)*10 if year==2019
		replace val = ((val+1)*2 - 1)*10 if year==2020
		reshape wide l, i(year) j(val)
		egen sum = rowtotal(l0-l210)
		forval n=0(10)210 {
			gen lsh`n' = l`n' / sum
		}
		reshape long lsh, i(year) j(position)
		replace lsh = lsh*100
		label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
		label values position position
		twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
			(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
			, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
			ytitle("Within-year frequency (%)", size(medsmall)) ///
			xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
			ylabel(0(5)25, labcolor(black) grid glcolor(gs6) glpattern(dot) gmin gmax labsize(medsmall)) ///
			xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") title(`title') ///
			note("N = `=n19' 2019 respondents and `=n20' 2020 respondents")
		graph save fig5_`v'.gph, replace
		graph export fig5_`v'.png, replace
	restore
}

gen temp = avgladder5yr if year==2019
bys wp5: egen avgladder5yr2019 = mean(temp)
drop temp
gen hiladder = ladder > avgladder5yr2019
gen loladder = !hiladder

foreach v in loladder hiladder {
	preserve
		keep if `v'==1
		sum ladder if year==2019 [aw=weightC]
		scalar n19 = r(N)
		sum ladder if year==2020 [aw=weightC]
		scalar n20 = r(N)
		if "`v'"=="loladder" local title "Respondents with ladder repsonse below 2019 mean"
		else if "`v'"=="hiladder" local title "Respondents with ladder repsonse above 2019 mean"
		forval l=0/10 {
			gen l`l' = ladder==`l'
		}
		collapse (sum) l0-l10 [aw=weightC], by(year)
		reshape long l, i(year) j(val)
		replace val = (val*2)*10 if year==2019
		replace val = ((val+1)*2 - 1)*10 if year==2020
		reshape wide l, i(year) j(val)
		egen sum = rowtotal(l0-l210)
		forval n=0(10)210 {
			gen lsh`n' = l`n' / sum
		}
		reshape long lsh, i(year) j(position)
		replace lsh = lsh*100
		label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
		label values position position
		twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
			(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
			, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
			ytitle("Within-year frequency (%)", size(medsmall)) ///
			xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
			ylabel(0(5)25, labcolor(black) grid glcolor(gs6) glpattern(dot) gmin gmax labsize(medsmall)) ///
			xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") title(`title') ///
			note("N = `=n19' 2019 respondents and `=n20' 2020 respondents")
		graph save fig5_`v'.gph, replace
		graph export fig5_`v'.png, replace
	restore
}

gen notfgn = !fgnborn 

foreach v in notfgn fgnborn {
	preserve
		keep if `v'==1
		sum ladder if year==2019 [aw=weightC]
		scalar n19 = r(N)
		sum ladder if year==2020 [aw=weightC]
		scalar n20 = r(N)
		if "`v'"=="notfgn" local title "Respondents living in their country of birth"
		else if "`v'"=="fgnborn" local title "Foreign-born respondents"
		forval l=0/10 {
			gen l`l' = ladder==`l'
		}
		collapse (sum) l0-l10 [aw=weightC], by(year)
		reshape long l, i(year) j(val)
		replace val = (val*2)*10 if year==2019
		replace val = ((val+1)*2 - 1)*10 if year==2020
		reshape wide l, i(year) j(val)
		egen sum = rowtotal(l0-l210)
		forval n=0(10)210 {
			gen lsh`n' = l`n' / sum
		}
		reshape long lsh, i(year) j(position)
		replace lsh = lsh*100
		label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
		label values position position
		twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
			(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
			, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
			ytitle("Within-year frequency (%)", size(medsmall)) ///
			xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
			ylabel(0(5)25, labcolor(black) grid glcolor(gs6) glpattern(dot) gmin gmax labsize(medsmall)) ///
			xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") title(`title') ///
			note("N = `=n19' 2019 respondents and `=n20' 2020 respondents")
		graph save fig5_`v'.gph, replace
		graph export fig5_`v'.png, replace
	restore
}

label define OECD 0 "Non-OECD" 1 "OECD"
label values OECD OECD

preserve
	forval l=0/10 {
		gen l`l' = ladder==`l'
	}
	collapse (sum) l0-l10 [aw=weightC], by(year OECD)
	reshape long l, i(year OECD) j(val)
	replace val = (val*2)*10 if year==2019
	replace val = ((val+1)*2 - 1)*10 if year==2020
	reshape wide l, i(year OECD) j(val)
	egen sum = rowtotal(l0-l210)
	forval n=0(10)210 {
		gen lsh`n' = l`n' / sum
	}
	reshape long lsh, i(year OECD) j(position)
	replace lsh = lsh*100
	label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
	label values position position
	twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
		(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
		, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
		ytitle("Within-year frequency (%)", size(medsmall)) ///
		xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
		ylabel(, labcolor(black) grid glcolor(gs6) glpattern(dot) labsize(medsmall)) ///
		xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") by(OECD, note(""))
	graph save fig5_OECD.gph, replace
	graph export fig5_OECD.png, replace
restore

preserve
	gen elim = (WHOWPR | inlist(country, "Iceland", "Bhutan", "Rwanda"))
	label values elim elimination
	forval l=0/10 {
		gen l`l' = ladder==`l'
	}
	collapse (sum) l0-l10 [aw=weightC], by(year elim)
	reshape long l, i(year elim) j(val)
	replace val = (val*2)*10 if year==2019
	replace val = ((val+1)*2 - 1)*10 if year==2020
	reshape wide l, i(year elim) j(val)
	egen sum = rowtotal(l0-l210)
	forval n=0(10)210 {
		gen lsh`n' = l`n' / sum
	}
	reshape long lsh, i(year elim) j(position)
	replace lsh = lsh*100
	label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
	label values position position
	twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
		(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
		, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
		ytitle("Within-year frequency (%)", size(medsmall)) ///
		xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
		ylabel(, labcolor(black) grid glcolor(gs6) glpattern(dot) labsize(medsmall)) ///
		xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") by(elim, note(""))
	graph save fig5_strategies.gph, replace
	graph export fig5_strategies.png, replace
restore

preserve
	keep if OECD
	forval l=0/10 {
		gen l`l' = ladder==`l'
	}
	collapse (sum) l0-l10 [aw=weightC], by(year oecd_elim)
	reshape long l, i(year oecd_elim) j(val)
	replace val = (val*2)*10 if year==2019
	replace val = ((val+1)*2 - 1)*10 if year==2020
	reshape wide l, i(year oecd_elim) j(val)
	egen sum = rowtotal(l0-l210)
	forval n=0(10)210 {
		gen lsh`n' = l`n' / sum
	}
	reshape long lsh, i(year oecd_elim) j(position)
	replace lsh = lsh*100
	label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
	label values position position
	twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
		(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
		, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
		ytitle("Within-year frequency (%)", size(medsmall)) ///
		xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
		ylabel(, labcolor(black) grid glcolor(gs6) glpattern(dot) labsize(medsmall)) ///
		xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") by(oecd_elim, title("OECD countries") note(""))
	graph save fig5_OECD_strategies.gph, replace
	graph export fig5_OECD_strategies.png, replace
restore

preserve
	keep if !OECD
	forval l=0/10 {
		gen l`l' = ladder==`l'
	}
	collapse (sum) l0-l10 [aw=weightC], by(year nonoecd_elim)
	reshape long l, i(year nonoecd_elim) j(val)
	replace val = (val*2)*10 if year==2019
	replace val = ((val+1)*2 - 1)*10 if year==2020
	reshape wide l, i(year nonoecd_elim) j(val)
	egen sum = rowtotal(l0-l210)
	forval n=0(10)210 {
		gen lsh`n' = l`n' / sum
	}
	reshape long lsh, i(year nonoecd_elim) j(position)
	replace lsh = lsh*100
	label define position 5 "0" 25 "1" 45 "2" 65 "3" 85 "4" 105 "5" 125 "6" 145 "7" 165 "8" 185 "9" 205 "10"
	label values position position
	twoway (bar lsh position if mod(position,20)==0, barw(8) color(forest_green)) ///
		(bar lsh position if mod(position,20)==10, barw(8) color(ebblue)) ///
		, plotregion(fcolor(white)) legend(pos(6) rows(1) label(1 "2019") label(2 "2020") size(medsmall)) ///
		ytitle("Within-year frequency (%)", size(medsmall)) ///
		xlabel(5(20)205, valuelabel labcolor(black) labsize(medsmall)) ///
		ylabel(, labcolor(black) grid glcolor(gs6) glpattern(dot) labsize(medsmall)) ///
		xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") by(nonoecd_elim, title("Non-OECD countries") note(""))
	graph save fig5_nonOECD_strategies.gph, replace
	graph export fig5_nonOECD_strategies.png, replace
restore
