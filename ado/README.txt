SUBJECT:    Hot and cold spot analysis in Stata

AUTHOR(S):  Keisuke Kondo
            Research Institute of Economy, Trade and Industry

SUPPORT:    <email address for person(s) supporting files listed below>
            Email: kondo-keisuke@rieti.go.jp
            URL: https://sites.google.com/site/keisukekondokk/

HELP:       After installation, type

            . help getisord

FILES:

getisord.ado
getisord.sthlp

UPDATE INFO:
            Apr. 26, 2022: Version 1.40
            - "swm(knn #)" option added
            - "r(W)" option added
            - Added alert message for spatial weight matrix
            - Added alert message for missing observations
            Jun. 19, 2017: Version 1.32
            - Bug fix for error check of latitude and longitude ranges
            May  15, 2017: Version 1.31
            - Small bug fix for error indication in Vincenty formula
            - Changed max. number of iteration in Vincenty formula
            Apr. 24, 2017: Version 1.30
            - "largesize" option added
            - Improved calculation process of bilateral distance matrix
            Feb. 23, 2017: Version 1.20
            - "nomatsave" option added
            - Bug fix for long variable name
            - Improved calculation process of bilateral distance matrix
            Jan. 21, 2016: Version 1.10
            - "dunit(km|mi)" option added
            - "genallbin" option added
            Oct. 24, 2015: Version 1.01
            - Bug fix for `touse', multiple variables
            - "detail" option added
            Oct. 15, 2015: Version 1.00
            - Released