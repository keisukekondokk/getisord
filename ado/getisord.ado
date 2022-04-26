/*******************************************************************************
** (C) KEISUKE KONDO
** 
** Release Date: October 13, 2015
** Last Updated: April 26, 2022
** Version: 1.40
** 
** [Reference]
** Kondo, K. (2016) "Hot and cold spot analysis using Stata," Stata Journal, 
** 16(3), pp. 613-631
**
** [Contact]
** Email: kondo-keisuke@rieti.go.jp
** URL: https://keisukekondokk.github.io/
*******************************************************************************/
** Version: 1.40
** Added swm(knn #) option
** Added "r(W)" in r()
** Alert message for missing observations
** Alert message for spatial weight matrix 
** Coding improvement for saving memory space
** Version: 1.32
** Bug fix for error check of latitude and longitude ranges
** Version: 1.31
** Small bug fix for error indication in Vincenty formula
** Changed maximum number of iteration in Vincenty formula (100000<-100)
** Version: 1.30
** Improved calculation process of bilateral distance matrix
** Added "largesize" option
** Version: 1.20
** Added "nomatsave" option
** Bug fix for long variable name
** Improved calculation process of bilateral distance matrix
** Version: 1.10
** Added "dunit" option for unit of distance
** Added "genallbin" option for calculation results
** 
capture program drop getisord
program getisord, sortpreserve rclass
	version 10
	syntax varlist [if] [in], /*
			*/ lat(varname) /*
			*/ lon(varname) /*
			*/ swm(string) /*
			*/ dist(real) /*
			*/ dunit(string) /*
			*/ [ /*
			*/ DMS /*
			*/ APProx /*
			*/ CONStant(real 0) /*
			*/ Detail /*
			*/ NOMATsave /*
			*/ LARGEsize /*
			*/ GENALLbin ]

	/*Settings*/
	local vY `varlist'
	local swmtype = substr("`swm'", 1, 3)
	local unit = "`dunit'"
	marksample touse
	markout `touse' `lat' `lon'
	
	/*Check Variable*/
	if( strpos("`vY'", " ") > 0 ){
		display as error "Multiple variables are not allowed."
		exit 198
	}
	
	/*Check Missing Values of Variable*/
	qui: egen ______missing_count_spgen = rowmiss(`vY')
	qui: count if ______missing_count_spgen > 0
	local nummissing = r(N)
	local errormissing = 0
	if(`nummissing' > 0){
		local errormissing = 1
	}
	if( `errormissing' == 1){
		if(`nummissing' == 1){
			display as text "Warning: `nummissing' observation with missing value is dropped."
		}
		if(`nummissing' > 1){
			display as text "Warning: `nummissing' observations with missing value are dropped."
		}
	}
	qui: drop ______missing_count_spgen
	
	/*Check Latitude Range*/
	qui: sum `lat'
	local max_lat = r(max)
	local min_lat = r(min)
	if( `max_lat' < -90 | `min_lat' < -90 ){
		display as error "lat() must be within -90 to 90."
		exit 198
	}
	if( `max_lat' > 90 | `min_lat' > 90 ){
		display as error "lat() must be within -90 to 90."
		exit 198
	}
	
	/*Check Longitude Range*/
	qui: sum `lon'
	local max_lon = r(max)
	local min_lon = r(min)
	if( `max_lon' < -180 | `min_lon' < -180 ){
		display as error "lon() must be within -180 to 180."
		exit 198
	}
	if( `max_lon' > 180 | `min_lon' > 180 ){
		display as error "lon() must be within -180 to 180."
		exit 198
	}
	
	/*Check Spatial Weight Matrix*/
	if( "`swmtype'" != "bin" & "`swmtype'" != "knn" & "`swmtype'" != "exp" & "`swmtype'" != "pow" ){
		display as error "swm(swmtype) must be one of bin, knn, exp, and pow."
		exit 198
	}

	/*Check Distance Decay Parameter of Spatial Weight Matrix*/
	if( "`swmtype'" == "bin" ){
		if( substr("`swm'", strpos("`swm'", "bin") + length("bin"), 1) != "" ){
			display as error "Error in swm(bin)."
			exit 198
		}
		local dd = . /*not used*/
		local cons = . /*not used*/
	}
	else if( "`swmtype'" == "knn" ){
		if( substr("`swm'", strpos("`swm'", "knn") + length("knn"), 1) != " " ){
			display as error "Error in swm(knn #)."
			exit 198
		}
		local dd = real(substr("`swm'", strpos("`swm'", "knn") + length("knn") + 1, .))
		local cons = . /*not used*/
		capture confirm integer number `dd'
		if( _rc != 0 ){
			display as error "Parameter {it:k} of swm(knn) must be integer."
			exit 198
		}
		if( `dd' <= 0 ){
			display as error "Parameter {it:k} of swm(knn) must be more than 0."
			exit 198
		}
		if( `dd' > _N ){
			qui: count
			local totalobs = r(N)
			display as error "Parameter {it:k} of swm(knn) must be less than `totalobs' (# of obs)."
			exit 198
		}
		else if( `dd' == . ){
			display as error "Numerical type is expected for distance-decay parameter."
			exit 198
		}
	}
	else if( "`swmtype'" == "exp" ){
		if( substr("`swm'", strpos("`swm'", "exp") + length("exp"), 1) != " " ){
			display as error "Error in swm(exp #)."
			exit 198
		}
		local dd = real(substr("`swm'", strpos("`swm'", "exp") + length("exp") + 1,.))
		local cons = . /*not used*/
		if( `dd' <= 0 ){
			display as error "Distance-decay parameter in swm(exp #) must be more than 0."
			exit 198
		}
		else if( `dd' == . ){
			display as error "Confirm distance-decay parameter in swm(exp #) again."
			exit 198
		}
	}
	else if( "`swmtype'" == "pow" ){
		if( substr("`swm'", strpos("`swm'", "pow") + length("pow"), 1) != " " ){
			display as error "Error in swm(pow #)."
			exit 198
		}
		local dd = real(substr("`swm'", strpos("`swm'", "pow") + length("pow") + 1, .))
		local cons = `constant'
		if( `cons' == 0 ){
			display as error "constant(#) must be specified when swm(pow #) is used."
			exit 198
		}
		if( `cons' < 0 ){
			display as error "constant(#) must be more than 0."
			exit 198
		}
		if( `dd' <= 0 ){
			display as error "Distance decay parameter in swm(pow #) must be more than 0."
			exit 198
		}
		else if( `dd' == . ){
			display as error "Confirm distance decay parameter in swm(pow #) again."
			exit 198
		}
	}
	
	/*Check Parameter Range*/
	if( `dist' <= 0 ){
		display as error "dist(#) must be more than 0."
		exit 198
	}
	
	/*Check Unit of Distance*/
	if( "`unit'" != "km" & "`unit'" != "mi" ){
		display as error "dunit(unit) must be either km or mi."
		exit 198
	}

	/*DMS or Decimal*/
	local fmdms = 0
	if( "`dms'" != "" ){
		local fmdms = 1
	}
	
	/*Approximation of Distance*/
	local appdist = 0
	if( "`approx'" != "" ){
		local appdist = 1
	}
	
	/*Display Details*/
	local dispdetail= 0
	if( "`detail'" != "" ){
		local dispdetail = 1
	}
	
	/*Distance Matrix Save Option*/
	local matsave = 1
	if( "`nomatsave'" != "" ){
		local matsave = 0
	}
	
	/*Large Size Option*/
	local large = 0
	if( "`largesize'" != "" ){
		local large = 1
		local matsave = 0
		local appdist = 1
	}
	
	/*Extend Outcome Variables of Getis-Ord G*i(d) Statistic*/
	local generateallbin = 0
	if( "`genallbin'" != "" ){
		if( "`swmtype'" == "bin" | "`swmtype'" == "knn" ){
			local generateallbin = 1
		}
		else if( "`swmtype'" == "exp" | "`swmtype'" == "pow" ){
			display as error "genallbin option is invalid when either swm(exp #) or swm(pow #) is specified."
			exit 198
		}
	}
	
	/*Make Variables for Error Check*/
	local error1 = 0
	local error2 = 0
	local error3 = 0
	local error4 = 0
	local error5 = 0
	if( "`swmtype'" == "bin" ){
		capture confirm new variable go_z_`vY'_b, exact
		local error1 = _rc
		capture confirm new variable go_p_`vY'_b, exact
		local error2 = _rc
		if( `generateallbin' == 1 ){
			capture confirm new variable go_u_`vY'_b, exact
			local error3 = _rc
			capture confirm new variable go_e_`vY'_b, exact
			local error4 = _rc
			capture confirm new variable go_sd_`vY'_b, exact
			local error5 = _rc
		}
	}
	else if( "`swmtype'" == "knn" ){
		capture confirm new variable go_z_`vY'_k, exact
		local error1 = _rc
		capture confirm new variable go_p_`vY'_k, exact
		local error2 = _rc
		if( `generateallbin' == 1 ){
			capture confirm new variable go_u_`vY'_k, exact
			local error3 = _rc
			capture confirm new variable go_e_`vY'_k, exact
			local error4 = _rc
			capture confirm new variable go_sd_`vY'_k, exact
			local error5 = _rc
		}
	}
	else if( "`swmtype'" == "exp" ){
		capture confirm new variable go_z_`vY'_e, exact
		local error1 = _rc
		capture confirm new variable go_p_`vY'_e, exact
		local error2 = _rc
	} 
	else if( "`swmtype'" == "pow" ){
		capture confirm new variable go_z_`vY'_p, exact
		local error1 = _rc
		capture confirm new variable go_p_`vY'_p, exact
		local error2 = _rc
	}

	/*Error Check*/
	if( `error1' == 110 | `error2' == 110 | `error3' == 110 | `error4' == 110 | `error5' == 110 ){
		display as error "Outcome variables already exist. Change variable names."
		exit 110
	}
	
	/*+++++CALL Mata Program+++++*/
	if( `large' == 0 ){
		mata: calcgetisord_matrix("`vY'", "`lat'", "`lon'", `fmdms', "`swmtype'", `dist', "`unit'", `dd', `cons', `appdist', `dispdetail', `matsave', `generateallbin', "`touse'")
	}
	else if( `large' == 1 ){
		mata: calcgetisord_vector("`vY'", "`lat'", "`lon'", `fmdms', "`swmtype'", `dist', "`unit'", `dd', `cons', `appdist', `dispdetail', `matsave', `generateallbin', "`touse'")
	}
	/*+++++END Mata Program+++++*/

	/*Return rclass*/
	return add
	
	/*Label for Outcome Variables*/
	if( "`swmtype'" == "bin" ){
		label var go_z_`vY'_b "z-value of G-O G*i(d), swm(bin), td=`dist', dunit=`unit'"
		label var go_p_`vY'_b "p-value of G-O G*i(d), swm(bin), td=`dist', dunit=`unit'"
		if( `generateallbin' == 0 ){
			display as txt "{bf:go_z_`vY'_b} was generated in the dataset."
			display as txt "{bf:go_p_`vY'_b} was generated in the dataset."
		}
		if( `generateallbin' == 1 ){
			label var go_u_`vY'_b "G-O G*i(d), swm(bin), td=`dist', dunit=`unit'"
			label var go_e_`vY'_b "Expected value of G-O G*i(d), swm(bin), td=`dist', dunit=`unit'"
			label var go_sd_`vY'_b "Standard deviation of G-O G*i(d), swm(bin), td=`dist', dunit=`unit'"
			display as txt "{bf:go_z_`vY'_b} was generated in the dataset."
			display as txt "{bf:go_p_`vY'_b} was generated in the dataset."
			display as txt "{bf:go_u_`vY'_b} was generated in the dataset."
			display as txt "{bf:go_e_`vY'_b} was generated in the dataset."
			display as txt "{bf:go_sd_`vY'_b} was generated in the dataset."
		}
	} 
	else if( "`swmtype'" == "knn" ){
		label var go_z_`vY'_k "z-value of G-O G*i(d), swm(bin), td=`dist', dunit=`unit'"
		label var go_p_`vY'_k "p-value of G-O G*i(d), swm(bin), td=`dist', dunit=`unit'"
		if( `generateallbin' == 0 ){
			display as txt "{bf:go_z_`vY'_k} was generated in the dataset."
			display as txt "{bf:go_p_`vY'_k} was generated in the dataset."
		}
		if( `generateallbin' == 1 ){
			label var go_u_`vY'_k "G-O G*i(d), swm(bin), td=`dist', dunit=`unit'"
			label var go_e_`vY'_k "Expected value of G-O G*i(d), swm(bin), td=`dist', dunit=`unit'"
			label var go_sd_`vY'_k "Standard deviation of G-O G*i(d), swm(bin), td=`dist', dunit=`unit'"
			display as txt "{bf:go_z_`vY'_k} was generated in the dataset."
			display as txt "{bf:go_p_`vY'_k} was generated in the dataset."
			display as txt "{bf:go_u_`vY'_k} was generated in the dataset."
			display as txt "{bf:go_e_`vY'_k} was generated in the dataset."
			display as txt "{bf:go_sd_`vY'_k} was generated in the dataset."
		}
	} 
	else if( "`swmtype'" == "exp" ){
		label var go_z_`vY'_e "z-value of G-O G*i(d), swm(exp `dd'), td=`dist', dunit=`unit'"
		label var go_p_`vY'_e "p-value of G-O G*i(d), swm(exp `dd'), td=`dist', dunit=`unit'"
		display as txt "{bf:go_z_`vY'_e} was generated in the dataset."
		display as txt "{bf:go_p_`vY'_e} was generated in the dataset."
	} 
	else if( "`swmtype'" == "pow" ){
		label var go_z_`vY'_p "z-value of G-O G*i(d), swm(pow `dd'), td=`dist', dunit=`unit'"
		label var go_p_`vY'_p "p-value of G-O G*i(d), swm(pow `dd'), td=`dist', dunit=`unit'"
		display as txt "{bf:go_z_`vY'_p} was generated in the dataset."
		display as txt "{bf:go_p_`vY'_p} was generated in the dataset."
	} 
end

/*## MATA ## Getis-Ord G*i(d) Calculation for Large-Sized Data*/
version 10
mata:
void calcgetisord_matrix(vY, lat, lon, fmdms, swmtype, dist, unit, dd, cons, appdist, dispdetail, matsave, generateallbin, touse)
{
	/*Check format of latitude and longitude*/
	if( fmdms == 1 ){
		printf("{txt}...Converting DMS format to decimal format\n")
		convlonlat2decimal(lat, lon, touse, &vlat, &vlon)
	} 
	else {
		st_view(vlat, ., lat, touse)
		st_view(vlon, ., lon, touse)
	}
	latr = ( pi() / 180 ) * vlat; 
	lonr = ( pi() / 180 ) * vlon; 
	
	/*Make Variable*/
	st_view(vy, ., vY, touse)
	cN = rows(vlon)
	mean_vy = mean(vy)
	variance_vy = variance(vy)
	
	/*Size of SWM*/
	printf("{txt}Size of spatial weight matrix:{res} %1.0f * %1.0f\n", cN, cN)
	
	/*Variables*/
	mD = J(cN, cN, 0)
	mW = J(cN, cN, 0)

	/*Variables*/
	mD_L = .
	cN_vD = .
	dist_mean = .
	dist_sd = .
	dist_min = .
	dist_max = 0
	numErrorSwm = 0
	numErrorSwmNoNeighbor = 0
	numErrorSwmFewerNeighbor = 0
	
	/*Variables*/
	vSGO_N = J(cN, 1, 0)
	vSGO_D = J(cN, 1, 0)
	vSGO = J(cN, 1, 0)
	vPSGO = J(cN, 1, 0)
	if( generateallbin == 1 ){
		vGO = J(cN, 1, 0)
		vGO_E = J(cN, 1, 0)
		vGO_S = J(cN, 1, 0)
	}
	
	/*Getis-Ord G*i(d) Statistics*/
	itr = 0
	cItr = cN*(cN-1)/2
	itr10percent = trunc(cItr/10)
	itr20percent = 2 * trunc(cItr/10)
	itr30percent = 3 * trunc(cItr/10)
	itr40percent = 4 * trunc(cItr/10)
	itr50percent = trunc(cItr/2)
	itr60percent = trunc(cItr/2) + trunc(cItr/10)
	itr70percent = trunc(cItr/2) + 2 * trunc(cItr/10)
	itr80percent = trunc(cItr/2) + 3 * trunc(cItr/10)
	itr90percent = trunc(cItr/2) + 4 * trunc(cItr/10)
	
	/*Vincenty Formula*/
	if( appdist == 0 ){
	
		/*Variables*/
		a = 6378.137
		b = 6356.752314245
		f = (a-b)/a
		eps = 1e-12
		maxIt = 1e+5
		
		/*LOOP for Vincenty Formula*/
		for( i = 1; i <= cN; ++i ){
			for( j = i + 1; j <= cN; ++j ){

				++itr
				if( itr == 1 ){
					printf("{txt}Calculating bilateral distance...\n")
					printf("{txt}{c TT}{hline 15}{c TT}\n")
				}

				/*Variables*/
				U1 = atan( (1-f)*tan(latr[i]) )
				U2 = atan( (1-f)*tan(latr[j]) )
				L = lonr[i] - lonr[j]
				lam = L
				l1_lam = lam
				cnt = 0
				
				/*Iteration for Vincenty Formula*/
				do{
					numer1 = ( cos(U2)*sin(lam) )^2;
					numer2 = ( cos(U1)*sin(U2) - sin(U1)*cos(U2)*cos(lam) )^2;
					numer = sqrt( numer1 + numer2 );
					denom = sin(U1)*sin(U2) + cos(U1)*cos(U2)*cos(lam);
					sig = atan2( denom, numer );
					sinalp = (cos(U1)*cos(U2)*sin(lam)) / sin(sig);
					cos2alp = 1 - sinalp^2;
					cos2sigm = cos(sig) - ( 2*sin(U1)*sin(U2) ) / cos2alp;
					C = f/16 * cos2alp * ( 4+f*(4-3*cos2alp) );
					lam = L + (1-C)*f*sinalp*( sig+C*sin(sig)*( cos2sigm+C*cos(sig)*(-1+2*cos2sigm^2) ) );
					cri = abs( lam - l1_lam );
					l1_lam = lam;
					if( cnt++ > maxIt ){
						printf("{err}Convergence not achieved in Vincenty formula \n")
						printf("{err}region %f, \t region %f \n", i, j )
						printf("{err}Add approx option to avoid convergence error \n")
						exit(error(430))
					}
				}while( cri > eps )
				
				/*After Iteration*/
				u2 = cos2alp * ( (a^2-b^2)/b^2 )
				A = 1 + (u2/16384) * ( 4096 + u2*(-768+u2*(320-175*u2)) )
				B = u2/1024 * (256 + u2*(-128+u2*(74-47*u2)) )
				dsig = B*sin(sig)*( cos2sigm + 0.25*B*( cos(sig)*(-1+2*cos2sigm^2)-1/6*B*cos2sigm*(-3+4*sin(sig)^2)*(-3+4*cos2sigm) ) )
				mD[i,j] = b*A*(sig-dsig)
				
				/*Display Iteration Progress*/
				if( itr == itr10percent ){
					printf("{txt}{c |}Completed:  10%%{c |}\n")
				}
				else if( itr == itr20percent ){
					printf("{txt}{c |}Completed:  20%%{c |}\n")
				}
				else if( itr == itr30percent ){
					printf("{txt}{c |}Completed:  30%%{c |}\n")
				}
				else if( itr == itr40percent ){
					printf("{txt}{c |}Completed:  40%%{c |}\n")
				}
				else if( itr == itr50percent ){
					printf("{txt}{c |}Completed:  50%%{c |}\n")
				}
				else if( itr == itr60percent ){
					printf("{txt}{c |}Completed:  60%%{c |}\n")
				}
				else if( itr == itr70percent ){
					printf("{txt}{c |}Completed:  70%%{c |}\n")
				}
				else if( itr == itr80percent ){
					printf("{txt}{c |}Completed:  80%%{c |}\n")
				}
				else if( itr == itr90percent ){
					printf("{txt}{c |}Completed:  90%%{c |}\n")
				}
				else if( itr == cItr ){
					printf("{txt}{c |}Completed: 100%%{c |}\n")
					printf("{txt}{c BT}{hline 15}{c BT}\n")
				}
			}
		}
	}
	/*Simplified Version of Vincenty Formula*/
	else if( appdist == 1 ){
	
		for( i = 1; i <= cN; ++i ){
			for( j = i + 1; j <= cN; ++j ){

				++itr
				if( itr == 1 ){
					printf("{txt}Calculating bilateral distance...\n")
					printf("{txt}{c TT}{hline 15}{c TT}\n")
				}
				
				difflonr = abs( lonr[i] - lonr[j] )
				numer1 = ( cos(latr[j])*sin(difflonr) )^2
				numer2 = ( cos(latr[i])*sin(latr[j]) - sin(latr[i])*cos(latr[j])*cos(difflonr) )^2
				numer = sqrt( numer1 + numer2 )
				denom = sin(latr[i])*sin(latr[j]) + cos(latr[i])*cos(latr[j])*cos(difflonr)
				mD[i,j] = 6378.137 * atan2( denom, numer )
				
				/*Display Iteration Progress*/
				if( itr == itr10percent ){
					printf("{txt}{c |}Completed:  10%%{c |}\n")
				}
				else if( itr == itr20percent ){
					printf("{txt}{c |}Completed:  20%%{c |}\n")
				}
				else if( itr == itr30percent ){
					printf("{txt}{c |}Completed:  30%%{c |}\n")
				}
				else if( itr == itr40percent ){
					printf("{txt}{c |}Completed:  40%%{c |}\n")
				}
				else if( itr == itr50percent ){
					printf("{txt}{c |}Completed:  50%%{c |}\n")
				}
				else if( itr == itr60percent ){
					printf("{txt}{c |}Completed:  60%%{c |}\n")
				}
				else if( itr == itr70percent ){
					printf("{txt}{c |}Completed:  70%%{c |}\n")
				}
				else if( itr == itr80percent ){
					printf("{txt}{c |}Completed:  80%%{c |}\n")
				}
				else if( itr == itr90percent ){
					printf("{txt}{c |}Completed:  90%%{c |}\n")
				}
				else if( itr == cItr ){
					printf("{txt}{c |}Completed: 100%%{c |}\n")
					printf("{txt}{c BT}{hline 15}{c BT}\n")
				}
			}
		}
	}
			
	/*Distance = 0 between i and i*/
	mD = mD + mD'
	
	/*Convert Unit of Distance*/
	if( unit == "mi" ){
		mD = 0.621371 :* mD
	}
	
	/*Message*/
	printf("{txt}Calculating Getis-Ord G*i(d) statistics...\n")

	/*Binary SWM*/
	if( swmtype == "bin" ){
		mW = ( mD :< dist )
		/*ERROR CHECK*/
		numErrorSwm = colsum( rowsum(mW :!= 0) :== 1 )
	}
	/*K-Nearest Neighbor SWM*/
	else if( swmtype == "knn" ){
		/*Obtain Threshold Distance for KNN*/
		vDknn = J(cN, 1, 0)
		_diag(mD, .)
		for (i = 1; i <= cN; ++i) {
			vDSorted = sort(mD[i, .]', 1)
			vDknn[i] = vDSorted[dd]
		}
		_diag(mD, 0)
		mW = ( mD :< dist ) :* ( mD :<= vDknn )
		/*ERROR CHECK*/
		numErrorSwm = colsum( rowsum(mW :!= 0) :> dd + 1 )
		/*ERROR CHECK*/
		numErrorSwmNoNeighbor = colsum( (rowsum(mW :!= 0) :== 1) )
		/*ERROR CHECK*/
		numErrorSwmFewerNeighbor = colsum( rowsum(mW :!= 0) :< dd + 1 )
	}
	/*Exponential SWM*/
	else if( swmtype == "exp" ){
		mW = ( mD :< dist ) :* exp( - dd :* mD )
		/*ERROR CHECK*/
		numErrorSwm = colsum( rowsum(mW :!= 0) :== 1 )
	}
	/*Power SWM*/
	else if( swmtype == "pow" ){
		mW = ( mD :< dist ) :* (J(cN, cN, cons) + mD):^(-dd)
		/*ERROR CHECK*/
		numErrorSwmNoNeighbor = colsum( (rowsum(mW :!= 0) :== 1) )
		/*ERROR CHECK*/
		numErrorSwm = colsum( rowsum(mW :== .) :> 0 )
	}
	
	/*REPORT ERROR CHECK*/
	if( swmtype == "bin" ){
		if(numErrorSwm > 0){
			if(numErrorSwm == 1){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
			if(numErrorSwm > 1){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
		}
	}
	else if( swmtype == "knn" ){
		if(numErrorSwm > 0){
			if(numErrorSwm == 1){
				printf("{txt}Warning: %1.0f observation has multiple k-nearest neighbors.\n", numErrorSwm)
			}
			if(numErrorSwm > 1){
				printf("{txt}Warning: %1.0f observations have multiple k-nearest neighbors.\n", numErrorSwm)
			}
		}
		if(numErrorSwmNoNeighbor > 0){
			if(numErrorSwmNoNeighbor == 1){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if(numErrorSwmNoNeighbor > 1){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
		}
		if(numErrorSwmFewerNeighbor > 0){
			if(numErrorSwmFewerNeighbor == 1){
				printf("{txt}Warning: %1.0f observation has fewer neighbors than k. Confirm dist() option.\n", numErrorSwmFewerNeighbor)
			}
			if(numErrorSwmFewerNeighbor > 1){
				printf("{txt}Warning: %1.0f observations have fewer neighbors than k. Confirm dist() option.\n", numErrorSwmFewerNeighbor)
			}
		}
	}
	else if( swmtype == "exp" ){
		if(numErrorSwm > 0){
			if(numErrorSwm == 1){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
			if(numErrorSwm > 1){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
		}
	}
	else if( swmtype == "pow" ){
		if(numErrorSwmNoNeighbor > 0){
			if(numErrorSwmNoNeighbor == 1){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if(numErrorSwmNoNeighbor > 1){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
		}
		if(numErrorSwm > 0){
			if(numErrorSwm == 1){
				printf("{txt}Warning: %1.0f observation has missing value.\n", numErrorSwm)
			}
			if(numErrorSwm > 1){
				printf("{txt}Warning: %1.0f observations have missing values.\n", numErrorSwm)
			}
		}
	}
	
	/*Summary Statistics of Distance Matrix*/
	mD_L = lowertriangle(mD)
	mD = .
	vD = select(vech(mD_L), vech(mD_L):>0)
	cN_vD = rows(vD)
	dist_mean = mean(vD)
	dist_sd = sqrt(variance(vD))
	dist_min = min(vD)
	dist_max = max(vD)
	vD = .
	if( matsave == 0 ){
		mD_L = .
	}
	
	/*Check Variance*/
	vTemp = cN*rowsum(mW:^(2))-rowsum(mW):^(2)
	if( colsum(vTemp :<= 0) > 0 ){
		printf("\n")
		printf("{err}Variance of G*i(d) cannot be defined. Try lower threshold distance in dist(#) option.\n")
		exit(error(912))
	}
		
	/*Getis-Ord G*i Statistic*/
	vwy = mW * vy
	vSGO_N = ( vwy - mean_vy*rowsum(mW) )
	vSGO_D = ( sqrt( (variance_vy*(cN*rowsum(mW:^2)-rowsum(mW):^2)) / (cN-1) ) )
	vSGO = vSGO_N :/ vSGO_D
	vPSGO = 2 :* ( 1 :- normal(abs(vSGO)) );
	if( generateallbin == 1 ){
		vGO = vwy :/ colsum(vy)
		vGO_E = rowsum(mW) :/ cN
		vGO_S = sqrt( variance_vy:*(cN:*rowsum(mW)-(rowsum(mW):^2)) ) :/ ( cN:*mean_vy:*sqrt(cN-1) ) 
	}

	/*Delete Matrix*/
	if( matsave == 0 ){
		mD = .
		mW = .
	}
	
	/*Classification of Results*/
	dStat1 = colsum( (vSGO :< invnormal(0.005)) )
	dStat2 = colsum( (invnormal(0.005) :<= vSGO) :+ (vSGO :< invnormal(0.025)) :- 1 )
	dStat4 = colsum( (invnormal(0.975) :< vSGO) :+ (vSGO :<= invnormal(0.995)) :- 1 )
	dStat5 = colsum( (invnormal(0.995) :< vSGO) )
	dStat3 = cN - dStat1 - dStat2 - dStat4 - dStat5
	
	/*Display Results of Distance Matrix*/
	printf("\n")
	if( appdist == 1 ){
		if( unit == "km" ){
			printf("{txt}Distance by simplified version of Vincenty formula (unit: km)\n")
		}
		else if( unit == "mi" ){
			printf("{txt}Distance by simplified version of Vincenty formula (unit: mi)\n")
		}
	}
	else {
		if( unit == "km" ){
			printf("{txt}Distance by Vincenty formula (unit: km)\n")
		}
		else if( unit == "mi" ){
			printf("{txt}Distance by Vincenty formula (unit: mi)\n")
		}
	}
	if( dispdetail == 1 ){
		printf("\n")
		printf("{txt}{hline 21}{c TT}{hline 62} \n")
		printf("{txt}{space 20} {c |}{space 7} Obs.{space 7} Mean{space 7} S.D.{space 7} Min.{space 8} Max\n")
		printf("{txt}{hline 21}{c +}{hline 62} \n")
		printf("{txt}{space 12}Distance {c |}{res}  %10.0f  %10.3f  %10.3f  %10.3f  %10.3f\n", 
					cN_vD, dist_mean, dist_sd, dist_min, dist_max )	
		printf("{txt}{hline 21}{c BT}{hline 62} \n")
	}
	
	/*For Long Variable Name*/
	sY = abbrev(vY, 20)
	
	/*Summary Statistics of Getis-Ord G* Statistic*/
	printf("\n\n")
	printf("{txt}Getis-Ord G*i(d) Statistics \n")
	printf("{txt}{space 59} Number of Obs = {res}%8.0f \n",cN)
	printf("\n")
	printf("{txt}{hline 21}{c TT}{hline 62} \n")
	printf("{txt}{space 12}Variable {c |} z<=-2.58  -2.58<z<=-1.96  -1.96<z<1.96  1.96<=z<2.58  2.58<=z \n")
	printf("{txt}{hline 21}{c +}{hline 62} \n")
	printf("{txt}%20s {c |} {res}%7.0f   %9.0f     %9.0f     %9.0f     %9.0f \n", 
				sY, dStat1, dStat2, dStat3, dStat4, dStat5 )
	printf("{txt}{hline 21}{c BT}{hline 62} \n")
	
	/*Return Resutls in Mata to Stata*/
	if( swmtype == "bin" ){
		st_store(., st_addvar("float", "go_z_"+vY+"_b"), st_local("touse"), vSGO)
		st_store(., st_addvar("float", "go_p_"+vY+"_b"), st_local("touse"), vPSGO)
		if( generateallbin == 1 ){
			st_store(., st_addvar("float", "go_u_"+vY+"_b"), st_local("touse"), vGO)
			st_store(., st_addvar("float", "go_e_"+vY+"_b"), st_local("touse"), vGO_E)
			st_store(., st_addvar("float", "go_sd_"+vY+"_b"), st_local("touse"), vGO_S)
		}
	} 
	else if( swmtype == "knn" ){
		st_store(., st_addvar("float", "go_z_"+vY+"_k"), st_local("touse"), vSGO)
		st_store(., st_addvar("float", "go_p_"+vY+"_k"), st_local("touse"), vPSGO)
		if( generateallbin == 1 ){
			st_store(., st_addvar("float", "go_u_"+vY+"_k"), st_local("touse"), vGO)
			st_store(., st_addvar("float", "go_e_"+vY+"_k"), st_local("touse"), vGO_E)
			st_store(., st_addvar("float", "go_sd_"+vY+"_k"), st_local("touse"), vGO_S)
		}
	} 
	else if( swmtype == "exp" ){
		st_store(., st_addvar("float", "go_z_"+vY+"_e"), st_local("touse"), vSGO)
		st_store(., st_addvar("float", "go_p_"+vY+"_e"), st_local("touse"), vPSGO)
	} 
	else if( swmtype == "pow" ){
		st_store(., st_addvar("float", "go_z_"+vY+"_p"), st_local("touse"), vSGO)
		st_store(., st_addvar("float", "go_p_"+vY+"_p"), st_local("touse"), vPSGO)
	} 
	
	/*rreturn in Stata*/
	st_rclear()
	st_numscalar("r(CS)", dStat1 + dStat2)
	st_numscalar("r(HS)", dStat4 + dStat5)
	st_numscalar("r(dist_max)", dist_max)
	st_numscalar("r(dist_min)", dist_min)
	st_numscalar("r(dist_sd)", dist_sd)
	st_numscalar("r(dist_mean)", dist_mean)
	st_numscalar("r(cons)", cons)
	st_numscalar("r(dd)", dd)
	st_numscalar("r(td)", dist)
	st_numscalar("r(N)", cN)
	st_matrix("r(W)", mW)
	st_matrix("r(D)", mD_L)
	if( appdist == 1 ){
		st_global("r(dist_type)", "approximation")
	}
	else {
		st_global("r(dist_type)", "exact")
	}
	if( unit == "km" ){ 
		st_global("r(dunit)", "km")
	}
	else if( unit == "mi" ){
		st_global("r(dunit)", "mi")
	}
	if( swmtype == "bin" ){
		st_global("r(swm)", "binary")
	} 
	else if( swmtype == "knn" ){
		st_global("r(swm)", "knn")
	} 
	else if( swmtype == "exp" ){
		st_global("r(swm)", "exponential")
	}
	else if( swmtype == "pow" ){
		st_global("r(swm)", "power")
	}
	st_global("r(varname)", vY)
	st_global("r(cmd)", "getisord")
}
end

/*## MATA ## Getis-Ord G*i(d) Calculation for Large-Sized Data*/
version 10
mata:
void calcgetisord_vector(vY, lat, lon, fmdms, swmtype, dist, unit, dd, cons, appdist, dispdetail, matsave, generateallbin, touse)
{
	/*Check format of latitude and longitude*/
	if( fmdms == 1 ){
		printf("{txt}...Converting DMS format to decimal format\n")
		convlonlat2decimal(lat, lon, touse, &vlat, &vlon)
	} 
	else {
		st_view(vlat, ., lat, touse)
		st_view(vlon, ., lon, touse)
	}
	latr = ( pi() / 180 ) * vlat; 
	lonr = ( pi() / 180 ) * vlon; 
	
	/*Make Variable*/
	st_view(vy, ., vY, touse)
	cN = rows(vlon)
	mean_vy = mean(vy)
	variance_vy = variance(vy)
	
	/*Size of SWM*/
	printf("{txt}Size of spatial weight matrix:{res} %1.0f * %1.0f\n", cN, cN)
	
	/*Variables*/
	if( matsave == 1 ){
		mD = J(cN, cN, 0)
		mW = J(cN, cN, 0)
	}
	else {
		mD = .
		mW = .
	}

	/*Variables*/
	mD_L = .
	cN_vD = .
	dist_mean = .
	dist_sd = .
	dist_min = .
	dist_max = 0
	numErrorSwm = 0
	numErrorSwmNoNeighbor = 0
	numErrorSwmFewerNeighbor = 0

	/*Variables*/
	vDist = J(1, cN, 0)
	vW = J(1, cN, 0)
	vWy = J(cN, 1, 0)
	vSGO_N = J(cN, 1, 0)
	vSGO_D = J(cN, 1, 0)
	vSGO = J(cN, 1, 0)
	vPSGO = J(cN, 1, 0)
	if( generateallbin == 1 ){
		vGO = J(cN, 1, 0)
		vGO_E = J(cN, 1, 0)
		vGO_S = J(cN, 1, 0)
	}
	
	/*Iteration Progress*/
	itr10percent = trunc(cN/10)
	itr20percent = 2 * trunc(cN/10)
	itr30percent = 3 * trunc(cN/10)
	itr40percent = 4 * trunc(cN/10)
	itr50percent = trunc(cN/2)
	itr60percent = trunc(cN/2) + trunc(cN/10)
	itr70percent = trunc(cN/2) + 2 * trunc(cN/10)
	itr80percent = trunc(cN/2) + 3 * trunc(cN/10)
	itr90percent = trunc(cN/2) + 4 * trunc(cN/10)
	
	/*Getis-Ord G*i(d) Statistics*/
	printf("{txt}Calculating Getis-Ord G*i(d) statistics...\n")
	printf("{txt}{c TT}{hline 15}{c TT}\n")
	
	/*Vincenty Formula*/
	if( appdist == 0 ){
	
		/*Variables*/
		a = 6378.137
		b = 6356.752314245
		f = (a-b)/a
		eps = 1e-12
		maxIt = 1e+5
		
		/*LOOP for Vincenty Formula*/
		for( i = 1; i <= cN; ++i ){
		
			/*Variable*/
			Alon = J(1, cN, 1) :* lonr[i]
			Blon = J(1, cN, 1) :* lonr'
			Clat = J(1, cN, 1) :* latr[i]
			Dlat = J(1, cN, 1) :* latr'
			U1 = atan( (1-f) :* tan(Clat) )
			U2 = atan( (1-f) :* tan(Dlat) )
			L = abs( Alon :- Blon )
			lam = L
			l1_lam = lam
			
			/*Loop*/
			cnt = 0
			do{
				numer1 = ( cos(U2) :* sin(lam) ):^2
				numer2 = ( cos(U1) :* sin(U2) :- sin(U1) :* cos(U2) :* cos(lam) ):^2
				numer = sqrt( numer1 :+ numer2 )
				denom = sin(U1) :* sin(U2) :+ cos(U1) :* cos(U2) :* cos(lam)
				sig = atan2( denom, numer )
				sinalp = (cos(U1) :* cos(U2) :* sin(lam)) :/ sin(sig)
				cos2alp = 1 :- sinalp:^2
				cos2sigm = cos(sig) :- ( 2 :* sin(U1) :* sin(U2) ) :/ cos2alp
				C = f:/16 :* cos2alp :* ( 4 :+ f :* (4 :- 3 :* cos2alp) )
				lam = L :+ (1:-C) :* f :* sinalp :* ( sig :+ C :* sin(sig) :* ( cos2sigm :+ C :* cos(sig) :*(-1 :+ 2 :* cos2sigm:^2) ) )
				cri = abs( max(lam :- l1_lam) )
				l1_lam = lam;
				if( cnt++ > maxIt ){
					printf("{err}Convergence not achieved in Vincenty formula \n")
					printf("{err}Add approx option to avoid convergence error \n")
					exit(error(430))
				}
			}while( cri > eps )

			/*After Iteration*/
			u2 = cos2alp :* ( (a^2 - b^2) / b^2 )
			A = 1 :+ (u2 :/ 16384) :* ( 4096 :+ u2 :* (-768 :+ u2 :* (320 :- 175 :* u2)) )
			B = u2 :/ 1024 :* (256 :+ u2 :* (-128 :+ u2 :* (74 :- 47 :*u2)) )
			dsig = B:*sin(sig) :* ( cos2sigm :+ 0.25:*B:*( cos(sig):*(-1:+2:*cos2sigm:^2) :- 1:/6:*B:*cos2sigm:*(-3:+4:*sin(sig):^2):*(-3:+4:*cos2sigm) ) )
			vDist = b :* A :* (sig :- dsig)
			
			/*Distance = 0*/
			if(missing(vDist) > 1){
				_editmissing(vDist, 0)
			}
			
			/*Distance = 0 between i and i*/
			vDist[i] = 0
			
			/*Convert Unit of Distance*/
			if( unit == "mi" ){
				vDist = 0.621371 :* vDist
			}
			
			/*Store Min and Max Distance*/
			if( min(vDist) < dist_min ){
				dist_min = min(vDist)
			}
			if( max(vDist) > dist_max ){
				dist_max = max(vDist)
			}
			
			/*Binary SWM*/
			if( swmtype == "bin" ){
				vW = ( vDist :< dist )
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :!= 0) == 1)
			}
			/*K-Nearest Neighbor SWM*/
			else if( swmtype == "knn" ){
				/*Obtain Threshold Distance for KNN*/
				vDist[i] = .
				vDistSorted = sort(vDist', 1)'
				dDistKnn = vDistSorted[dd]
				vDist[i] = 0
				vW = ( vDist :< dist ) :* ( vDist :<= dDistKnn )
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :!= 0) > dd + 1)
				/*ERROR CHECK*/
				numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + (rowsum(vW :!= 0) == 1)
				/*ERROR CHECK*/
				numErrorSwmFewerNeighbor = numErrorSwmFewerNeighbor + (rowsum(vW :!= 0) < dd + 1)
			}
			/*Exponential SWM*/
			else if( swmtype == "exp" ){
				vW = ( vDist :< dist ) :* exp( - dd :* vDist )
			}
			/*Power SWM*/
			else if( swmtype == "pow" ){
				vW = ( vDist :< dist ) :* (J(1, cN, cons) + vDist):^(-dd)
				/*ERROR CHECK*/
				numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + (rowsum(vW :!= 0) == 1)
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :== .) > 0)
			}
					
			/*Save Distance Matrix and Spatial Weight Matrix*/
			if( matsave == 1 ){
				mD[i,] = vDist
				mW[i,] = vW
			}

			/*Check Variance*/
			Temp = cN*rowsum(vW:^(2)) - rowsum(vW)^(2)
			if( Temp <= 0 ){
				printf("\n")
				printf("{err}Variance of G*i(d) cannot be defined. Try lower threshold distance in dist(#) option.\n")
				exit(error(912))
			}
			
			/*Getis-Ord G*i(d) Statistic*/
			vWy[i] = vW * vy
			vSGO_N[i] = ( vWy[i] - mean_vy*rowsum(vW) )
			vSGO_D[i] = ( sqrt( (variance_vy*(cN*rowsum(vW:^2)-rowsum(vW):^2))/(cN-1) ) )
			vSGO[i] = vSGO_N[i] :/ vSGO_D[i]
			vPSGO[i] = 2 :* ( 1 :- normal(abs(vSGO[i])) );
			if( generateallbin == 1 ){
				vGO[i] = vWy[i] :/ colsum(vy)
				vGO_E[i] = rowsum(vW) :/ cN
				vGO_S[i] = sqrt( variance_vy:*(cN:*rowsum(vW)-(rowsum(vW):^2)) ) :/ ( cN:*mean_vy:*sqrt(cN-1) ) 
			}
			
			/*Display Iteration Progress*/
			if( i == itr10percent ){
				printf("{txt}{c |}Completed:  10%%{c |}\n")
			}
			else if( i == itr20percent ){
				printf("{txt}{c |}Completed:  20%%{c |}\n")
			}
			else if( i == itr30percent ){
				printf("{txt}{c |}Completed:  30%%{c |}\n")
			}
			else if( i == itr40percent ){
				printf("{txt}{c |}Completed:  40%%{c |}\n")
			}
			else if( i == itr50percent ){
				printf("{txt}{c |}Completed:  50%%{c |}\n")
			}
			else if( i == itr60percent ){
				printf("{txt}{c |}Completed:  60%%{c |}\n")
			}
			else if( i == itr70percent ){
				printf("{txt}{c |}Completed:  70%%{c |}\n")
			}
			else if( i == itr80percent ){
				printf("{txt}{c |}Completed:  80%%{c |}\n")
			}
			else if( i == itr90percent ){
				printf("{txt}{c |}Completed:  90%%{c |}\n")
			}
			else if( i == cN ){
				printf("{txt}{c |}Completed: 100%%{c |}\n")
				printf("{txt}{c BT}{hline 15}{c BT}\n")
			}
		}
	}
	/*Simplified Version of Vincenty Formula*/
	else if( appdist == 1 ){
		for( i = 1; i <= cN; ++i ){
		
			/*Distance between i and j*/
			A = J(1, cN, 1) :* lonr[i]
			B = J(1, cN, 1) :* lonr'
			C = J(1, cN, 1) :* latr[i]
			D = J(1, cN, 1) :* latr'
			difflonr = abs( A - B )
			numer1 = ( cos(D):*sin(difflonr) ):^2
			numer2 = ( cos(C):*sin(D) :- sin(C):*cos(D):*cos(difflonr) ):^2
			numer = sqrt( numer1 :+ numer2 )
			denom = sin(C):*sin(D) :+ cos(C):*cos(D):*cos(difflonr)
			vDist = 6378.137 * atan2( denom, numer )
			
			/*Distance = 0*/
			if(missing(vDist) > 1){
				_editmissing(vDist, 0)
			}
			
			/*Distance = 0 between i and i*/
			vDist[i] = 0

			/*Convert Unit of Distance*/
			if( unit == "mi" ){
				vDist = 0.621371 :* vDist
			}
			
			/*Store Min and Max Distance*/
			if( min(select(vDist, vDist:>0)) < dist_min ){
				dist_min = min(select(vDist, vDist:>0))
			}
			if( max(vDist) > dist_max ){
				dist_max = max(vDist)
			}
			
			/*Binary SWM*/
			if( swmtype == "bin" ){
				vW = ( vDist :< dist )
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :!= 0) == 1)
			}
			/*K-Nearest Neighbor SWM*/
			else if( swmtype == "knn" ){
				/*Obtain Threshold Distance for KNN*/
				vDist[i] = .
				vDistSorted = sort(vDist', 1)'
				dDistKnn = vDistSorted[dd]
				vDist[i] = 0
				vW = ( vDist :< dist ) :* ( vDist :<= dDistKnn )
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :!= 0) > dd + 1)
				/*ERROR CHECK*/
				numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + (rowsum(vW :!= 0) == 1)
				/*ERROR CHECK*/
				numErrorSwmFewerNeighbor = numErrorSwmFewerNeighbor + (rowsum(vW :!= 0) < dd + 1)
			}
			/*Exponential SWM*/
			else if( swmtype == "exp" ){
				vW = ( vDist :< dist ) :* exp( - dd :* vDist )
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :!= 0) == 1)
			}
			/*Power SWM*/
			else if( swmtype == "pow" ){
				vW = ( vDist :< dist ) :* (J(1, cN, cons) + vDist):^(-dd)
				/*ERROR CHECK*/
				numErrorSwmNoNeighbor = numErrorSwmNoNeighbor + (rowsum(vW :!= 0) == 1)
				/*ERROR CHECK*/
				numErrorSwm = numErrorSwm + (rowsum(vW :== .) > 0)
			}
					
			/*Save Distance Matrix and Spatial Weight Matrix*/
			if( matsave == 1 ){
				mD[i,] = vDist
				mW[i,] = vW
			}
		
			/*Check Variance*/
			Temp = cN*rowsum(vW:^(2)) - rowsum(vW)^(2)
			if( Temp <= 0 ){
				printf("\n")
				printf("{err}Variance of G*i(d) cannot be defined. Try lower threshold distance in dist(#) option.\n")
				exit(error(912))
			}
			
			/*Getis-Ord G*i(d) Statistic*/
			vWy[i] = vW * vy
			vSGO_N[i] = ( vWy[i] - mean_vy*rowsum(vW) )
			vSGO_D[i] = ( sqrt( (variance_vy*(cN*rowsum(vW:^2)-rowsum(vW):^2))/(cN-1) ) )
			vSGO[i] = vSGO_N[i] :/ vSGO_D[i]
			vPSGO[i] = 2 :* ( 1 :- normal(abs(vSGO[i])) );
			if( generateallbin == 1 ){
				vGO[i] = vWy[i] :/ colsum(vy)
				vGO_E[i] = rowsum(vW) :/ cN
				vGO_S[i] = sqrt( variance_vy:*(cN:*rowsum(vW)-(rowsum(vW):^2)) ) :/ ( cN:*mean_vy:*sqrt(cN-1) ) 
			}
			
			/*Display Iteration Progress*/
			if( i == itr10percent ){
				printf("{txt}{c |}Completed:  10%%{c |}\n")
			}
			else if( i == itr20percent ){
				printf("{txt}{c |}Completed:  20%%{c |}\n")
			}
			else if( i == itr30percent ){
				printf("{txt}{c |}Completed:  30%%{c |}\n")
			}
			else if( i == itr40percent ){
				printf("{txt}{c |}Completed:  40%%{c |}\n")
			}
			else if( i == itr50percent ){
				printf("{txt}{c |}Completed:  50%%{c |}\n")
			}
			else if( i == itr60percent ){
				printf("{txt}{c |}Completed:  60%%{c |}\n")
			}
			else if( i == itr70percent ){
				printf("{txt}{c |}Completed:  70%%{c |}\n")
			}
			else if( i == itr80percent ){
				printf("{txt}{c |}Completed:  80%%{c |}\n")
			}
			else if( i == itr90percent ){
				printf("{txt}{c |}Completed:  90%%{c |}\n")
			}
			else if( i == cN ){
				printf("{txt}{c |}Completed: 100%%{c |}\n")
				printf("{txt}{c BT}{hline 15}{c BT}\n")
			}
		}
	}
	
	/*REPORT ERROR CHECK*/
	if( swmtype == "bin" ){
		if(numErrorSwm > 0){
			if(numErrorSwm == 1){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
			if(numErrorSwm > 1){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
		}
	}
	else if( swmtype == "knn" ){
		if(numErrorSwm > 0){
			if(numErrorSwm == 1){
				printf("{txt}Warning: %1.0f observation has multiple k-nearest neighbors.\n", numErrorSwm)
			}
			if(numErrorSwm > 1){
				printf("{txt}Warning: %1.0f observations have multiple k-nearest neighbors.\n", numErrorSwm)
			}
		}
		if(numErrorSwmNoNeighbor > 0){
			if(numErrorSwmNoNeighbor == 1){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if(numErrorSwmNoNeighbor > 1){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
		}
		if(numErrorSwmFewerNeighbor > 0){
			if(numErrorSwmFewerNeighbor == 1){
				printf("{txt}Warning: %1.0f observation has fewer neighbors than k. Confirm dist() option.\n", numErrorSwmFewerNeighbor)
			}
			if(numErrorSwmFewerNeighbor > 1){
				printf("{txt}Warning: %1.0f observations have fewer neighbors than k. Confirm dist() option.\n", numErrorSwmFewerNeighbor)
			}
		}
	}
	else if( swmtype == "exp" ){
		if(numErrorSwm > 0){
			if(numErrorSwm == 1){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
			if(numErrorSwm > 1){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwm)
			}
		}
	}
	else if( swmtype == "pow" ){
		if(numErrorSwmNoNeighbor > 0){
			if(numErrorSwmNoNeighbor == 1){
				printf("{txt}Warning: %1.0f observation has no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
			if(numErrorSwmNoNeighbor > 1){
				printf("{txt}Warning: %1.0f observations have no neighbors. Confirm dist() option.\n", numErrorSwmNoNeighbor)
			}
		}
		if(numErrorSwm > 0){
			if(numErrorSwm == 1){
				printf("{txt}Warning: %1.0f observation has missing value.\n", numErrorSwm)
			}
			if(numErrorSwm > 1){
				printf("{txt}Warning: %1.0f observations have missing values.\n", numErrorSwm)
			}
		}
	}
	
	/*Classification of Results*/
	dStat1 = colsum( (vSGO :< invnormal(0.005)) )
	dStat2 = colsum( (invnormal(0.005) :<= vSGO) :+ (vSGO :< invnormal(0.025)) :- 1 )
	dStat4 = colsum( (invnormal(0.975) :< vSGO) :+ (vSGO :<= invnormal(0.995)) :- 1 )
	dStat5 = colsum( (invnormal(0.995) :< vSGO) )
	dStat3 = cN - dStat1 - dStat2 - dStat4 - dStat5
	
	/*Display Results of Distance Matrix*/
	printf("\n")
	if( appdist == 1 ){
		if( unit == "km" ){
			printf("{txt}Distance by simplified version of Vincenty formula (unit: km)\n")
		}
		else if( unit == "mi" ){
			printf("{txt}Distance by simplified version of Vincenty formula (unit: mi)\n")
		}
	}
	else {
		if( unit == "km" ){
			printf("{txt}Distance by Vincenty formula (unit: km)\n")
		}
		else if( unit == "mi" ){
			printf("{txt}Distance by Vincenty formula (unit: mi)\n")
		}
	}
	if( dispdetail == 1 ){
		printf("\n")
		printf("{txt}{hline 21}{c TT}{hline 62} \n")
		printf("{txt}{space 20} {c |}{space 7} Obs.{space 7} Mean{space 7} S.D.{space 7} Min.{space 8} Max\n")
		printf("{txt}{hline 21}{c +}{hline 62} \n")
		printf("{txt}{space 12}Distance {c |}{res}  %10.0f  %10.3f  %10.3f  %10.3f  %10.3f\n", 
					cN_vD, dist_mean, dist_sd, dist_min, dist_max )	
		printf("{txt}{hline 21}{c BT}{hline 62} \n")
	}
	
	/*For Long Variable Name*/
	sY = abbrev(vY, 20)
	
	/*Summary Statistics of Getis-Ord G* Statistic*/
	printf("\n\n")
	printf("{txt}Getis-Ord G*i(d) Statistics \n")
	printf("{txt}{space 59} Number of Obs = {res}%8.0f \n",cN)
	printf("\n")
	printf("{txt}{hline 21}{c TT}{hline 62} \n")
	printf("{txt}{space 12}Variable {c |} z<=-2.58  -2.58<z<=-1.96  -1.96<z<1.96  1.96<=z<2.58  2.58<=z \n")
	printf("{txt}{hline 21}{c +}{hline 62} \n")
	printf("{txt}%20s {c |} {res}%7.0f   %9.0f     %9.0f     %9.0f     %9.0f \n", 
				sY, dStat1, dStat2, dStat3, dStat4, dStat5 )
	printf("{txt}{hline 21}{c BT}{hline 62} \n")
	
	/*Return Resutls in Mata to Stata*/
	if( swmtype == "bin" ){
		st_store(., st_addvar("float", "go_z_"+vY+"_b"), st_local("touse"), vSGO)
		st_store(., st_addvar("float", "go_p_"+vY+"_b"), st_local("touse"), vPSGO)
		if( generateallbin == 1 ){
			st_store(., st_addvar("float", "go_u_"+vY+"_b"), st_local("touse"), vGO)
			st_store(., st_addvar("float", "go_e_"+vY+"_b"), st_local("touse"), vGO_E)
			st_store(., st_addvar("float", "go_sd_"+vY+"_b"), st_local("touse"), vGO_S)
		}
	} 
	else if( swmtype == "knn" ){
		st_store(., st_addvar("float", "go_z_"+vY+"_k"), st_local("touse"), vSGO)
		st_store(., st_addvar("float", "go_p_"+vY+"_k"), st_local("touse"), vPSGO)
		if( generateallbin == 1 ){
			st_store(., st_addvar("float", "go_u_"+vY+"_k"), st_local("touse"), vGO)
			st_store(., st_addvar("float", "go_e_"+vY+"_k"), st_local("touse"), vGO_E)
			st_store(., st_addvar("float", "go_sd_"+vY+"_k"), st_local("touse"), vGO_S)
		}
	} 
	else if( swmtype == "exp" ){
		st_store(., st_addvar("float", "go_z_"+vY+"_e"), st_local("touse"), vSGO)
		st_store(., st_addvar("float", "go_p_"+vY+"_e"), st_local("touse"), vPSGO)
	} 
	else if( swmtype == "pow" ){
		st_store(., st_addvar("float", "go_z_"+vY+"_p"), st_local("touse"), vSGO)
		st_store(., st_addvar("float", "go_p_"+vY+"_p"), st_local("touse"), vPSGO)
	} 
	
	/*rreturn in Stata*/
	st_rclear()
	st_numscalar("r(CS)", dStat1 + dStat2)
	st_numscalar("r(HS)", dStat4 + dStat5)
	st_numscalar("r(dist_max)", dist_max)
	st_numscalar("r(dist_min)", dist_min)
	st_numscalar("r(dist_sd)", dist_sd)
	st_numscalar("r(dist_mean)", dist_mean)
	st_numscalar("r(cons)", cons)
	st_numscalar("r(dd)", dd)
	st_numscalar("r(td)", dist)
	st_numscalar("r(N)", cN)
	st_matrix("r(W)", mW)
	st_matrix("r(D)", mD_L)
	if( appdist == 1 ){
		st_global("r(dist_type)", "approximation")
	}
	else {
		st_global("r(dist_type)", "exact")
	}
	if( unit == "km" ){ 
		st_global("r(dunit)", "km")
	}
	else if( unit == "mi" ){
		st_global("r(dunit)", "mi")
	}
	if( swmtype == "bin" ){
		st_global("r(swm)", "binary")
	} 
	else if( swmtype == "knn" ){
		st_global("r(swm)", "knn")
	} 
	else if( swmtype == "exp" ){
		st_global("r(swm)", "exponential")
	}
	else if( swmtype == "pow" ){
		st_global("r(swm)", "power")
	}
	st_global("r(varname)", vY)
	st_global("r(cmd)", "getisord")
}
end

/*## MATA ## Convert DMS format to Decimal Format*/
version 10
mata:
void convlonlat2decimal(lat, lon, touse, vlat, vlon)
{
	st_view(vlat_, ., lat, touse)
	st_view(vlon_, ., lon, touse)
	(*vlat) = floor(vlat_) :+ (floor((vlat_:-floor(vlat_)):*100):/60) :+ (floor((vlat_:*100:-floor(vlat_:*100)):*100):/3600)
	(*vlon) = floor(vlon_) :+ (floor((vlon_:-floor(vlon_)):*100):/60) :+ (floor((vlon_:*100:-floor(vlon_:*100)):*100):/3600)
}
end
