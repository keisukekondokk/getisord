/**********************************************************
** (C) Keisuke Kondo
** Upload Date: April 26, 2022
** Updated Date: April 26, 2022
** 
** [Reference]
** Kondo, K (2015) "Spatial persistence of Japanese unemployment rates,"
** Japan and the World Economy, 36, pp. 113-122.
** 
** Kondo, K (2016) "Hot and cold spot analysis using Stata," 
** Stata Journal, 16(3), pp. 613-631.
**********************************************************/

/************************
** Getis-Ord G*i(d)
************************/

** Load Dataset (Kondo, 2015)
use "data/DTA_ur_1980_2005_all.dta", clear

** Getis-Ord G*i(d) statistic
getisord ur2005, lon(lon) lat(lat) swm(bin) dist(30) dunit(km) approx
drop go_z_ur2005* go_p_ur2005*

getisord ur2005, lon(lon) lat(lat) swm(knn 10) dist(5) dunit(km) approx
drop go_z_ur2005* go_p_ur2005*

getisord ur2005, lon(lon) lat(lat) swm(knn 10) dist(.) dunit(km) approx
drop go_z_ur2005* go_p_ur2005*

getisord ur2005, lon(lon) lat(lat) swm(pow 5) const(1) dist(.) dunit(km) approx
drop go_z_ur2005* go_p_ur2005*
