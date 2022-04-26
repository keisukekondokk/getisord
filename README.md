# GETISORD: Stata module to compute Getis-Ord <i>G<sub>i</sub><sup>*</sup>(d)</i> statistic

The `getisord` command computes Getis-Ord <i>G<sub>i</sub><sup>*</sup>(d)</i> statistic in Stata.


## Install

### Stata

```
net install st0446_1.pkg, replace
```

### GitHub

```
net install getisord, replace from("https://raw.githubusercontent.com/keisukekondokk/getisord/main/")
```

## Uninstall

```
ado uninstall st0446_1
```


## Manual
See Kondo (2016) in *Stata Journal*.

URL: https://www.stata-journal.com/article.html?article=st0446  
URL: https://doi.org/10.1177%2F1536867X1601600304  

## Demo Files
See [`demo`](./demo) directory. There are two examples.

<pre>
.demo/
|-- japan_muni_unemp //Municipal unemployment rates in Japan (Kondo, 2015)
|-- ncovr //County-level data in the U.S. (Geoda Center, 2022)
</pre>


## Source Files
See [`ado`](./ado) directory. There are `getisord.ado` and `getisord.sthlp` files. 

<pre>
.ado/
|-- getisord.ado //Stata ado file
|-- getisord.sthlp //Stata help file
</pre>


## Software Update History

### Ver. 1.40 - April 26, 2022
- `swm(knn #)` option added
- `r(W)` option added
- Alert message for spatial weight matrix added
- Alert message for missing observations added

### Ver. 1.32 - June 19, 2017
- Bug fix for error check of latitude and longitude ranges

### Ver. 1.31 - May 15, 2017
- Small bug fix for error indication in Vincenty formula
- Changed maximum number of iteration in Vincenty formula

### Ver. 1.30 - April 24, 2017
- `largesize` option added
- Calculation process of bilateral distance matrix improved

### Ver. 1.20 - February 23, 2017
- `nomatsave` option added
- Bug fix for long variable name
- Calculation process of bilateral distance matrix improved

### Ver. 1.10 - January 21, 2016
- `dunit(km|mi)` option added
- `genallbin` option added

### Ver. 1.01 - October 24, 2015
- Bug fix of `touse` for multiple variables  
- `detail` option added

### Ver. 1.00 - October 15, 2015
- Released


## Licence
The Stata code developed by Keisuke Kondo is released under the agreement between Keisuke Kondo (Author) and Stata Press, a division of StataCorp LP (Publisher). Author grants to Publisher a perpetual, irrevocable, transferable, royalty-free license to modify, reproduce, and distribute the software code, with the right to sublicense through multiple tiers of distribution. Author retains the right to modify, reproduce or distribute software code.


## Terms of Use
Users (hereinafter referred to as the User or Users depending on context) of the content on this web site (hereinafter referred to as the "Content") are required to conform to the terms of use described herein (hereinafter referred to as the Terms of Use). Furthermore, use of the Content constitutes agreement by the User with the Terms of Use. The contents of the Terms of Use are subject to change without prior notice.

### Copyright
The copyright of the Stata code developed by Keisuke Kondo belongs to Stata Press, a division of StataCorp LP. 

### Copyright of Third Parties
The statistical data and shapefile in the demo file [`.demo/ncovr`](./demo/ncovr) were taken from GeoDa Center (2022). Users must confirm the terms of use of the GeoDa, prior to using the Content.

### Disclaimer 
- Keisuke Kondo makes the utmost effort to maintain, but nevertheless does not guarantee, the accuracy, completeness, integrity, usability, and recency of the Content.
- Keisuke Kondo and any organization to which Keisuke Kondo belongs hereby disclaim responsibility and liability for any loss or damage that may be incurred by Users as a result of using the Content. 
- Keisuke Kondo and any organization to which Keisuke Kondo belongs are neither responsible nor liable for any loss or damage that a User of the Content may cause to any third party as a result of using the Content
The Content may be modified, moved or deleted without prior notice.

## Author
Keisuke Kondo  
Senior Fellow, Research Institute of Economy, Trade and Industry  
Email: kondo-keisuke@rieti.go.jp  
URL: https://keisukekondokk.github.io/  

## Reference

GeoDa Center (2022) GeoDa: An Introduction to Spatial Data Science.  
URL: https://geodacenter.github.io/  (accessed on April 26, 2022)  

Kondo, Keisuke (2015) "Spatial persistence of Japanese unemployment rates," *Japan and the World Economy*, 36, pp. 113-122.  
URL: https://doi.org/10.1016/j.japwor.2015.11.001  

Kondo, Keisuke (2016) "Hot and cold spot analysis using Stata," *Stata Journal*, 16(3), pp. 613-631.  
URL: https://doi.org/10.1177%2F1536867X1601600304  
