*****************************
* Figure 6 - Global changes *
*****************************

use DataProcessed/country_averages, clear

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

scalar num = 1
foreach v in worry stress sadness anger laugh enjoyment healthproblem physicalpain countOnFriends freedom donation volunteering helpstranger confnatgov {
	reghdfe `v' is2020 if elim, noabsorb vce(r)
	gen delta`=num' = _b[is2020] if elim  
	reghdfe `v' is2020 if !elim, noabsorb vce(r)
	replace delta`=num' = _b[is2020] if !elim
	local lab : variable label `v'
	label define cats `=num' "`lab'", modify
	label variable delta`=num' "`lab'"
	scalar num = num + 1
	if inlist(num, 5, 8, 11) scalar num = num + 1
}

* Calculate avg death rate point est and CI for elim and non-elim countries
reghdfe deathrate1231 if elim, noabsorb vce(r)
gen delta19 = _b[_cons] if elim
reghdfe deathrate1231 if !elim, noabsorb vce(r)
replace delta19 = _b[_cons] if !elim

collapse (firstnm) delta*, by(elim)
reshape long delta, i(elim) j(cat)

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
	(scatter delta cat if elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
		yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
		ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
		ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
	(scatter delta cat if !elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2) ) ///
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
graph save Results/Fig6.gph, replace
graph export Results/Fig6.png, replace


****************************************
* Figure 7 - Changes in OECD countries *
****************************************

use DataProcessed/country_averages, clear
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

scalar num = 1
foreach v in worry stress sadness anger laugh enjoyment healthproblem physicalpain countOnFriends freedom donation volunteering helpstranger confnatgov {
	reghdfe `v' is2020 if elim, noabsorb vce(r)
	gen delta`=num' = _b[is2020] if elim  
	reghdfe `v' is2020 if !elim, noabsorb vce(r)
	replace delta`=num' = _b[is2020] if !elim
	local lab : variable label `v'
	label define cats `=num' "`lab'", modify
	label variable delta`=num' "`lab'"
	scalar num = num + 1
	if inlist(num, 5, 8, 11) scalar num = num + 1
}

* Calculate avg death rate point est and CI for elim and non-elim countries
reghdfe deathrate1231 if elim, noabsorb vce(r)
gen delta19 = _b[_cons] if elim
reghdfe deathrate1231 if !elim, noabsorb vce(r)
replace delta19 = _b[_cons] if !elim

collapse (firstnm) delta*, by(elim)
reshape long delta, i(elim) j(cat)

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
	(scatter delta cat if elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
		yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
		ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
		ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
	(scatter delta cat if !elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2) ) ///
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
graph save Results/Fig7.gph, replace
graph export Results/Fig7.png, replace


********************************************
* Figure 8 - Changes in Non-OECD countries *
********************************************

use DataProcessed/country_averages, clear
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

scalar num = 1
foreach v in worry stress sadness anger laugh enjoyment healthproblem physicalpain countOnFriends freedom donation volunteering helpstranger confnatgov {
	reghdfe `v' is2020 if elim, noabsorb vce(r)
	gen delta`=num' = _b[is2020] if elim  
	reghdfe `v' is2020 if !elim, noabsorb vce(r)
	replace delta`=num' = _b[is2020] if !elim
	local lab : variable label `v'
	label define cats `=num' "`lab'", modify
	label variable delta`=num' "`lab'"
	scalar num = num + 1
	if inlist(num, 5, 8, 11) scalar num = num + 1
}

* Calculate avg death rate point est and CI for elim and non-elim countries
reghdfe deathrate1231 if elim, noabsorb vce(r)
gen delta19 = _b[_cons] if elim
reghdfe deathrate1231 if !elim, noabsorb vce(r)
replace delta19 = _b[_cons] if !elim

collapse (firstnm) delta*, by(elim)
reshape long delta, i(elim) j(cat)

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
	(scatter delta cat if elim & cat==19 & dupe==0, mcolor(red) msymbol(X) msize(medium) mlwidth(.4) ///
		yaxis(2) ysc(range(0 100) axis(2) lcolor(black) lpattern(solid)) ///
		ylabel(0(20)100, axis(2) nogrid tlcolor(black)) ///
		ytitle("2020" "COVID" "death" "rate per" "100,000", size(medsmall) axis(2) justification(left) orientation(horizontal)) ) ///
	(scatter delta cat if !elim & cat==19 & dupe==0, mcolor(gs5) msymbol(O) msize(vsmall) mlwidth(.4) yaxis(2) ) ///
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
graph save Results/Fig8.gph, replace
graph export Results/Fig8.png, replace
