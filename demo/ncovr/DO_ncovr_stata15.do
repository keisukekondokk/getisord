/**********************************************************
** (C) Keisuke Kondo
** Uploaded Date: September 28, 2015
** Updated Date: April 26, 2022
** 
** [Note]
** Code for Stata 15 or later
** 
** [References]
** GeoDa Center (2022) GeoDa: An Introduction to Spatial Data Science.
** URL: https://geodacenter.github.io/ (accessed on April 26, 2022)
** 
** Kondo, K (2016) "Hot and cold spot analysis using Stata," 
** Stata Journal, 16(3), pp. 613-631.
**********************************************************/

/*************************************************
** Convert Shape file to DTA file
** 
** 
*************************************************/
** Data from GeoDa Center (2022)
spshape2dta "shp/NAT.shp", replace

/*************************************************
** Getis-Ord G*i(d)
** 
** 
*************************************************/

** Load Data
use "NAT.dta", clear

** Stata Setting for Spatial Data
spset

** getisord
local distance = 50
getisord MFIL59, lat(_CY) lon(_CX) swm(bin) dist(`distance') dunit(km) app d
getisord MFIL69, lat(_CY) lon(_CX) swm(bin) dist(`distance') dunit(km) app d
getisord MFIL79, lat(_CY) lon(_CX) swm(bin) dist(`distance') dunit(km) app d
getisord MFIL89, lat(_CY) lon(_CX) swm(bin) dist(`distance') dunit(km) app d


/*************************************************
** Mapping
** Figures in black and white for Stata Journal
** 
*************************************************/

**
grmap, activate

** Figure
grmap go_z_MFIL59_b using "NAT_shp",  ///
	clm(custom) clb(-100 -2.576 -1.960 1.960 2.576 100) ///
	fcolor(white  white  white gs10 gs5) legtitle("{it:z}-value") ///
	legstyle(1) legcount legend(size(*1.8)) 
graph export "fig_bw/FIG_map_mfil59_b.svg", replace

** Figure
grmap go_z_MFIL69_b using "NAT_shp", ///
	clm(custom) clb(-100 -2.576 -1.960 1.960 2.576 100) ///
	fcolor(white  white  white gs10 gs5) legtitle("{it:z}-value") ///
	legstyle(1) legcount legend(size(*1.8)) 
graph export "fig_bw/FIG_map_mfil69_b.svg", replace

** Figure
grmap go_z_MFIL79_b using "NAT_shp", ///
	clm(custom) clb(-100 -2.576 -1.960 1.960 2.576 100) ///
	fcolor(white  white  white gs10 gs5) legtitle("{it:z}-value") ///
	legstyle(1) legcount legend(size(*1.8)) 
graph export "fig_bw/FIG_map_mfil79_b.svg", replace

** Figure
grmap go_z_MFIL89_b using "NAT_shp", ///
	clm(custom) clb(-100 -2.576 -1.960 1.960 2.576 100) ///
	fcolor(white  white  white gs10 gs5) legtitle("{it:z}-value") ///
	legstyle(1) legcount legend(size(*1.8)) 
graph export "fig_bw/FIG_map_mfil89_b.svg", replace

	
/*************************************************
** Mapping
** Color Figures 
** 
*************************************************/

** Figure
grmap go_z_MFIL59_b using "NAT_shp", ///
	clm(custom) clb(-100 -2.576 -1.960 1.960 2.576 100) ///
	fcolor(ebblue eltblue white orange red) legtitle("{it:z}-value") ///
	legstyle(1) legcount legend(size(*1.8)) 
graph export "fig_color/FIG_map_mfil59_b.svg", replace

** Figure
grmap go_z_MFIL69_b using "NAT_shp", ///
	clm(custom) clb(-100 -2.576 -1.960 1.960 2.576 100) ///
	fcolor(ebblue eltblue white orange red) legtitle("{it:z}-value") ///
	legstyle(1) legcount legend(size(*1.8)) 
graph export "fig_color/FIG_map_mfil69_b.svg", replace

** Figure
grmap go_z_MFIL79_b using "NAT_shp", ///
	clm(custom) clb(-100 -2.576 -1.960 1.960 2.576 100) ///
	fcolor(ebblue eltblue white orange red) legtitle("{it:z}-value") ///
	legstyle(1) legcount legend(size(*1.8)) 
graph export "fig_color/FIG_map_mfil79_b.svg", replace

** Figure
grmap go_z_MFIL89_b using "NAT_shp", ///
	clm(custom) clb(-100 -2.576 -1.960 1.960 2.576 100) ///
	fcolor(ebblue eltblue white orange red) legtitle("{it:z}-value") ///
	legstyle(1) legcount legend(size(*1.8)) 
graph export "fig_color/FIG_map_mfil89_b.svg", replace



/*************************************************
** Export distance matrix
** 
** 
*************************************************/

/*

** Drop
drop go_z_MFIL59_b go_p_MFIL59_b
** Exact
local distance = 50
getisord MFIL59, lat(_CY) lon(_CX) swm(bin) dist(`distance') dunit(km) d
putexcel set "export/distance_matrix_d1.xlsx", replace
putexcel A1=matrix(r(D))
putexcel close 
 
** Drop
drop go_z_MFIL59_b go_p_MFIL59_b
** Approximation
local distance = 50
getisord MFIL59, lat(_CY) lon(_CX) swm(bin) dist(`distance') app dunit(km) d
putexcel set "export/distance_matrix_d2.xlsx", replace
putexcel A1=matrix(r(D))
putexcel close

*/
