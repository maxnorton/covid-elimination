use DataProcessed/ladder_distribution.dta, clear

***************************************************
* Figure 5: Distribution of ladder in 2019 & 2020 *
***************************************************

preserve
	collapse (sum) l0-l10 l*_wt, by(year)
	forval l = 0/10 {
		replace l`l' = l`l' / l`l'_wt
	}
	drop *_wt
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
	graph save Results/Fig5.gph, replace
	graph export Results/Fig5.png, replace
restore

* Annual ladder distributions disaggregated by income, marital status, education, gender, previous ladder level, foreign birth, OECD status, & elimination status
foreach v in lowinc midinc highinc single sepdivwid marrAsMarr elementary secondary college male female loladder hiladder fgnborn notfgn OECD nonOECD Elim Mitig {
	preserve
		collapse (sum) `v'_l0-`v'_l10, by(year)
		if "`v'"=="lowinc" local title "Low income respondents"
		else if "`v'"=="midinc" local title "Middle income respondents"
		else if "`v'"=="highinc" local title "High income respondents"
		else if "`v'"=="single" local title "Single respondents"
		else if "`v'"=="sepdivwid" local title "Separated/divorced/widowed respondents"
		else if "`v'"=="marrAsMarr" local title "Married/as married repsondents"
		else if "`v'"=="elementary" local title "Elementary education or less"
		else if "`v'"=="secondary" local title "Secondary or up to 3 years post-secondary education"
		else if "`v'"=="college" local title "Post-secondary graduate"
		else if "`v'"=="male" local title "Male respondents"
		else if "`v'"=="female" local title "Female respondents"
		else if "`v'"=="loladder" local title "Respondents with ladder repsonse below 2019 mean"
		else if "`v'"=="hiladder" local title "Respondents with ladder repsonse above 2019 mean"
		else if "`v'"=="notfgn" local title "Respondents living in their country of birth"
		else if "`v'"=="fgnborn" local title "Foreign-born respondents"
		else if "`v'"=="OECD" local title "OECD countries"
		else if "`v'"=="nonOECD" local title "Non-OECD countries"
		else if "`v'"=="Elim" local title "Elimination countries"
		else if "`v'"=="Mitig" local title "Mitigation countries"
		reshape long `v'_l, i(year) j(val)
		replace val = (val*2)*10 if year==2019
		replace val = ((val+1)*2 - 1)*10 if year==2020
		reshape wide `v'_l, i(year) j(val)
		egen sum = rowtotal(`v'_l0-`v'_l210)
		forval n=0(10)210 {
			gen lsh`n' = `v'_l`n' / sum
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
			xsc(lcolor(black)) ysc(lcolor(black)) xtitle("") title(`title')
		graph save Results/Fig5_`v'.gph, replace
		graph export Results/Fig5_`v'.png, replace
	restore
}
