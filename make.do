* Data compilation script provided for transparency; execution
*   requires access to Gallup World Poll microdata.            
* Outputs: 
* - DataProcessed/ladder_distribution.dta
* - DataProcessed/country_mortality.dta
do Stata/export_data_replication.do

* Generate Figures 1-3: 
* - Requires: DataProcessed/country_mortality.dta
* - Outputs: 
*    + Results/Fig1-Fig3 as .gph and .png
*    + Results/Figs1-3_data.xls reporting underlying counts
do Stata/plot_deaths.do

* Generate Figures 4 & 6-8: Changes in key subjective variables
* - Requires: DataProcessed/country_averages.dta
* - Outputs: Results/Fig4, Fig6-Fig8 as .gph and .png
do Stata/plot_changes.do

* Output statistics quoted directly in text
* - Requires: DataProcessed/ladder_distribution.dta
* - Output: Results/intext_stats.log
do Stata/log_intext_stats.do

