{smcl}
{* *! version 1.40  26 April 2022}{...}
{cmd:help getisord}{right: ({browse "http://www.stata-journal.com/article.html?article=st0446":SJ16-3: st0446})}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:getisord} {hline 2}}Getis-Ord G*i(d) statistic{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:getisord} {varname} {ifin}{cmd:,}
{opth lat(varname)}
{opth lon(varname)}
{opt swm(swmtype)}
{opt dist(#)}
{opt dunit}{cmd:(km}|{cmd:mi)}
[{it:options}]

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth lat(varname)}}specify the variable of latitude{p_end}
{p2coldent:* {opth lon(varname)}}specify the variable of longitude{p_end}
{p2coldent:* {opt swm(swmtype)}}specify a type of spatial weight matrix{p_end}
{p2coldent:* {opt dist(#)}}specify the threshold distance for the spatial weight matrix{p_end}
{p2coldent:* {opt dunit}{cmd:(km}|{cmd:mi)}}specify the unit of distance (kilometers or miles){p_end}
{synopt:{opt dms}}convert the degrees, minutes, and seconds format to a decimal format{p_end}
{synopt:{opt app:rox}}use bilateral distance approximated by the simplified version of the Vincenty formula{p_end}
{synopt:{opt cons:tant(#)}}specify a constant term added to the bilateral
distance when {cmd:swm(pow} {it:#}{cmd:)} is used{p_end}
{synopt:{opt d:etail}}display summary statistics of the bilateral distance{p_end}
{synopt:{opt nomat:save}}does not save the bilateral distance matrix on the memory{p_end}
{synopt:{opt large:size}}is used for large-sized data{p_end}
{synopt:{opt genall:bin}}generate all outcome variables for the Getis-Ord G*i(d) statistic{p_end}
{synoptline}
{p2colreset}{...}
{pstd}* {cmd:lat()}, {cmd:lon()}, {cmd:swm()}, {cmd:dist()}, and {cmd:dunit()}
are required.


{marker description}{...}
{title:Description}

{pstd}
{cmd:getisord} calculates the Getis-Ord G*i(d) statistic.


{marker options}{...}
{title:Options}

{phang}
{opth lat(varname)} specifies the variable of latitude in the dataset. The
decimal format is expected in the default setting. A positive value denotes
the north latitude, whereas a negative value denotes the south latitude. {cmd:lat()} is required.

{phang}
{opth lon(varname)} specifies the variable of longitude in the dataset. The
decimal format is expected in the default setting. A positive value denotes
the east longitude, whereas a negative value denotes the west longitude. {cmd:lon()} is required.

{phang}
{opt swm(swmtype)} specifies a type of spatial weight matrix. One of the
following four types of spatial weight matrix must be specified: {opt bin}
(binary), {opt knn} ({it:k}-nearest neighbor), {opt exp} (exponential), or {opt pow} (power).
The parameter {it:k} must be specified for the knn weights as follows: {cmd:swm(knn} {it:#}{cmd:)}.
The distance decay parameter {it:#} must be specified for the exponential and power function
types of spatial weight matrix as follows: {cmd:swm(exp} {it:#}{cmd:)} and
{cmd:swm(pow} {it:#}{cmd:)}. {cmd:swm()} is required.

{phang}
{opt dist(#)} specifies the threshold distance {it:#} for the spatial weight
matrix. The unit of distance is specified by the {opt dunit()} option.
Regions located within the threshold distance {it:#} take a value of 1 in the
binary spatial weight matrix or a positive value in the nonbinary spatial
weight matrix, and take 0 otherwise. {cmd:dist()} is required.

{phang}
{opt dunit}{cmd:(km}|{cmd:mi)} specifies the unit of distance. Either {cmd:km}
(kilometers) or {cmd:mi} (miles) must be specified. {cmd:dunit()} is required.

{phang}
{opt dms} converts the degrees, minutes, and seconds format to a decimal
format.

{phang}
{opt app:rox} uses the bilateral distance approximated by the simplified
version of the Vincenty formula.

{phang}
{opt cons:tant(#)}, when {cmd:swm(pow} {it:#}{cmd:)} is used, specifies a
constant term {it:#} in a unit specified by the {cmd:dunit()} option, which is
added to the bilateral distance, to avoid the denominator of the spatial
weight matrix taking a value of 0. The {opt constant(#)} option must be
specified when {cmd:swm(pow} {it:#}{cmd:)} is used.

{phang}
{opt d:etail} displays summary statistics of the bilateral distance.

{phang}
{opt nomat:save} does not save the bilateral distance matrix {bf:r(D)} and
the spatial weight matrix {bf:r(W)} on the memory.

{phang}
{opt large:size} is used for large-sized data. When this option is specified,
{opt nomat:save} and {opt app:rox} options are automatically applied.
The {opt d:etail} option displays only minimum and maximum distances.

{phang}
{opt genall:bin} generates three additional outcome variables (the
unstandardized Getis-Ord G*i(d), its expected value, and the standard
deviation) only when {cmd:swm(bin)} is specified.


{marker outcome}{...}
{title:Outcome}

{pstd}
In the default setting, the {cmd:getisord} command generates two outcome
variables in the dataset ({cmd:go_z_}{it:varname}{cmd:_}{it:swmtype} and
{cmd:go_p_}{it:varname}{cmd:_}{it:swmtype}). When the binary spatial weight
matrix, {cmd:swm(bin)}, is specified, the {opt genallbin} option becomes
valid, and {cmd:getisord} generates an additional three outcome variables
({cmd:go_u_}{it:varname}{cmd:_}{it:swmtype},
{cmd:go_e_}{it:varname}{cmd:_}{it:swmtype}, and
{cmd:go_sd_}{it:varname}{cmd:_}{it:swmtype}).

{phang}
{cmd:go_z_}{it:varname}{cmd:_}{it:swmtype} is the standardized Getis-Ord
G*i(d) statistic of {it:varname}, which is equivalent to the {it:z}-value of
Getis-Ord G*i(d). The {it:varname} is automatically inserted, and the suffix
{cmd:b}, {cmd:k}, {cmd:e}, or {cmd:p} is also inserted in accordance with {it:swmtype}:
{cmd:b} for {cmd:swm(bin)}, {cmd:k} for {cmd:swm(knn)}, {cmd:e} for
{cmd:swm(exp} {it:#}{cmd:)}, and {cmd:p} for {cmd:swm(pow} {it:#}{cmd:)}.

{phang}
{cmd:go_p_}{it:varname}{cmd:_}{it:swmtype} is the p-value of the standardized
Getis-Ord G*i(d) statistic of {it:varname}.

{phang}
{cmd:go_u_}{it:varname}{cmd:_}{it:swmtype} is the unstandardized Getis-Ord
G*i(d) statistic of {it:varname}. This is generated using the {cmd:genallbin}
option only when {cmd:swm(bin)} or {cmd:swm(knn)} is specified.

{phang}
{cmd:go_e_}{it:varname}{cmd:_}{it:swmtype} is the expected value of the
Getis-Ord G*i(d) statistic of {it:varname}. This is generated using the
{cmd:genallbin} option only when {cmd:swm(bin)} or {cmd:swm(knn)} is specified.

{phang}
{cmd:go_sd_}{it:varname}{cmd:_}{it:swmtype} is the standard deviation of the
Getis-Ord G*i(d) statistic of {it:varname}. This is generated using the
{cmd:genallbin} option only when {cmd:swm(bin)} or {cmd:swm(knn)} is specified.


{marker examples}{...}
{title:Examples}

{pstd}
Case 1: Binary spatial weight matrix{p_end}
{phang2}{cmd:. getisord MFIL59, lat(y_cntrd) lon(x_cntrd) swm(bin) dist(50) dunit(km) approx detail}{p_end}

{pstd}
Case 2: {it:k}-nearest neighbor spatial weight matrix{p_end}
{phang2}{cmd:. getisord MFIL59, lat(y_cntrd) lon(x_cntrd) swm(knn 10) dist(50) dunit(km) approx detail}{p_end}

{pstd}
Case 3: Nonbinary spatial weight matrix by exponential function{p_end}
{phang2}{cmd:. getisord MFIL59, lat(y_cntrd) lon(x_cntrd) swm(exp 0.03) dist(50) dunit(km) approx detail}{p_end}

{pstd}
Case 4: Nonbinary spatial weight matrix by power function{p_end}
{phang2}{cmd:. getisord MFIL59, lat(y_cntrd) lon(x_cntrd) swm(pow 1) dist(50) dunit(km) approx detail}{p_end}

{pstd}
Results can be displayed in a map using the {cmd:shp2dta} and {cmd:spmap} commands. See Kondo (2016) for more details.


{title:Stored results}

{pstd}
{cmd:getisord} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(td)}}threshold distance{p_end}
{synopt:{cmd:r(dd)}}distance decay parameter{p_end}
{synopt:{cmd:r(cons)}}constant for {cmd:swm(pow} {it:#}{cmd:)}{p_end}
{synopt:{cmd:r(dist_mean)}}mean of distance{p_end}
{synopt:{cmd:r(dist_sd)}}standard deviation of distance{p_end}
{synopt:{cmd:r(dist_min)}}minimum value of distance{p_end}
{synopt:{cmd:r(dist_max)}}maximum value of distance{p_end}
{synopt:{cmd:r(HS)}}number of hot spots (p<5%){p_end}
{synopt:{cmd:r(CS)}}number of cold spots (p<5%){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:getisord}{p_end}
{synopt:{cmd:r(varname)}}name of variable{p_end}
{synopt:{cmd:r(swm)}}type of spatial weight matrix{p_end}
{synopt:{cmd:r(dunit)}}unit of distance{p_end}
{synopt:{cmd:r(dist_type)}}exact or approximation{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(D)}}lower triangular distance matrix{p_end}
{synopt:{cmd:r(W)}}spatial weight matrix{p_end}


{title:Reference}

{phang}
Kondo, K. 2016. {browse "http://www.stata-journal.com/article.html?article=st0446":Hot and cold spot analysis using Stata}. {it:Stata Journal} 16: 613-631.


{marker author}{...}
{title:Author}

{pstd}Keisuke Kondo{p_end}
{pstd}Research Institute of Economy, Trade and Industry{p_end}
{pstd}Tokyo, Japan{p_end}
{pstd}kondo-keisuke@rieti.go.jp{p_end}
{pstd}{browse "https://keisukekondokk.github.io/":https://keisukekondokk.github.io/}{p_end}


{title:Also see}

{p 4 14 2}Article: {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=st0446":st0446}{p_end}
