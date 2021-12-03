set scheme plottig

use DataProcessed/country_mortality, clear

keep if !mi(excessdeaths2020_relavg)

gen region_fig1 = .
replace region_fig1 = 1 if inlist(region1, 3, 5) | inlist(country, "Australia", "New Zealand")
replace region_fig1 = 2 if inlist(country, "Iceland", "Norway", "Finland", "Denmark")
replace region_fig1 = 3 if country=="Sweden"
replace region_fig1 = 4 if mi(region_fig1) & region1==0

label define regions 1 "Asia-Pacific" 2 "Nordic excluding Sweden" 3 "Sweden" 4 "Other Western Europe"
label values region_fig1 regions

graph bar deathrate1231 excessdeaths2020_relavg, over(region_fig1, label(labsize(medsmall))) plotregion(fcolor(white)) legend(pos(6) size(medsmall) label(1 "COVID-19 deaths") label(2 "Excess deaths = 2020 deaths minus the 2017-2019 average")) ytitle("Death rate per 100,000", size(medsmall)) ylabel(, labsize(medsmall))
graph save Results/Fig1.gph, replace
graph export Results/Fig1.png, replace

preserve
	collapse (mean) deathrate1231 excessdeaths2020_relavg, by(region_fig1)
	export excel using Results/Figs1to3_data.xls, sheet("Figure 1", modify) firstrow(varlabels)
restore

gen region_fig2 = .
replace region_fig2 = 1 if region_fig1==2
replace region_fig2 = 2 if region1==6
replace region_fig2 = 3 if country=="United States"
replace region_fig2 = 4 if country=="United Kingdom"
replace region_fig2 = 5 if country=="Italy"

label define regions2 1 "Other Nordic" 2 "Latin America" 3 "United States" 4 "United Kingdom" 5 "Italy"
label values region_fig2 regions2

graph bar deathrate1231 excessdeaths2020_relavg, over(region_fig2, label(labsize(medsmall))) plotregion(fcolor(white)) legend(pos(6) size(medsmall) label(1 "COVID-19 deaths") label(2 "Excess deaths = 2020 deaths minus the 2017-2019 average")) ytitle("Death rate per 100,000", size(medsmall)) ylabel(, labsize(medsmall))
graph save Results/Fig2.gph, replace
graph export Results/Fig2.png, replace

preserve
	collapse (mean) deathrate1231 excessdeaths2020_relavg, by(region_fig2)
	export excel using Results/Figs1to3_data.xls, sheet("Figure 2", modify) firstrow(varlabels)
restore

gen region_fig3 = .
replace region_fig3 = 1 if country=="Norway"
replace region_fig3 = 2 if country=="Iceland"
replace region_fig3 = 3 if country=="Finland"
replace region_fig3 = 4 if country=="Denmark"
replace region_fig3 = 5 if country=="Sweden"

label define regions3 1 "Norway" 2 "Iceland" 3 "Finland" 4 "Denmark" 5 "Sweden"
label values region_fig3 regions3

graph bar deathrate1231 excessdeaths2020_relavg, over(region_fig3, label(labsize(medsmall))) plotregion(fcolor(white)) legend(pos(6) size(medsmall) label(1 "COVID-19 deaths") label(2 "Excess deaths = 2020 deaths minus the 2017-2019 average")) ytitle("Death rate per 100,000", size(medsmall)) ylabel(, labsize(medsmall))
graph save Results/Fig3.gph, replace
graph export Results/Fig3.png, replace

preserve
	collapse (mean) deathrate1231 excessdeaths2020_relavg, by(region_fig3)
	export excel using Results/Figs1to3_data.xls, sheet("Figure 3", modify) firstrow(varlabels)
restore
