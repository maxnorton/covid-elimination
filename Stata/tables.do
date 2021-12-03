use "../WHR2021/Cross-sectional data/nationalavg_mortalitymeasures_20211025.dta", clear

* Table 1
rename excessdeaths2020_relavg Excess_death_rate_2020
label variable deathrate1231 "Direct death rate"
label variable vae "Accountability"

replace vae = vae*3 // Why is this necessary
asdoc reg Excess_death_rate_2020 deathrate1231 vae, r save(Results/Table1.rtf) replace title(Indirect COVID-19 deaths increase more than direct deaths, especially if undercounted) label abb(.)

rename Excess_death_rate_2020 excessdeaths2020_relavg

* Table 2 
** Note this is GDP growth, not GDP.
** The coefficient of interest is correct, but other regression results (even the N, but that can't be the whole problem) don't match.
rename gdpgr2020 GDP_growth_2020_forecast
label variable deathrate1231 "Death rate"

asdoc reg GDP_growth_2020_forecast deathrate1231, r save(Results/Table2.rtf) replace title(2020 real GDP 1% less for every increase in COVID-19 deaths by 20 per 100, 000 people) label abb(.)

rename GDP_growth_2020_forecast gdpgr2020

* Table 3
** unemployed is not in the file, but it's in country_averages
** replication is approximate
gen year=2020
merge 1:1 wp5 year using DataProcessed/country_averages, keepusing(unemployed)
replace unemployed = unemployed*100

rename unemployed Unemployment_rate
label variable gdpgr2020 "2020 GDP growth"
label variable WHOWPR "WHOWPR"

asdoc reg Unemployment_rate deathrate1231 gdpgr2020 WHOWPR, r save(Results/Table3.rtf) replace title(2020 unemployment rate lower in countries with COVID elimination strategies) label abb(.)

rename Unemployment_rate unemployed

* Table 4
rename deathrate1231 COVID_death_rate_2020
label variable island1 "Island"
label variable is_ratio "Age-adjustment index"
label variable exposure0331cap1 "Early exposure to infections in other countries"
label variable femaleheadofstate "Female leadership"
label variable lndistcap_SARS "Ln average distance to SARS countries"
label variable TIDB "Institutional trust"
label variable gini "Income inequality (Gini index)"

asdoc reg COVID_death_rate_2020  island1 is_ratio exposure0331cap1 femaleheadofstate WHOWPR lndistcap_SARS TIDB gini, r save(Results/Table4.rtf) replace title(COVID deaths explained by geography, demography, exposure, leadership, science, trust, and inequality) label abb(.)

rename COVID_death_rate_2020 deathrate1231 

* Compare to the same model for:
rename excessdeaths2020_relavg Excess_death_rate_2020

asdoc reg Excess_death_rate_2020  island1 is_ratio exposure0331cap1 femaleheadofstate WHOWPR lndistcap_SARS TIDB gini, r save(Results/Table4_excess_deaths.rtf) replace title(Model from Table 4 using excess deaths rather than COVID deaths as the dependent variable) label abb(.)

rename Excess_death_rate_2020 excessdeaths2020_relavg
