cap program drop flagout2
program flagout2
    version 15
    syntax varname [pweight] [if], [item(varlist max=1) over(varlist) z(real 3) minn(integer 20) zscore(string)]
    tempfile stats
    *tempvar p10 p25 center p75 p90 n scale group


    foreach var in _group _obs _flag _min _max _scale {
        cap drop `var'
        if !_rc di "`var' already exists, dropping"
    }
	
	if mi("`zscore'") loc zscore = "qn"
	if !inlist("`zscore'","qn","sd","iqr","mad","s") {
		di as error "zsore should be either qn, sd, iqr or mad"
		di in r "sd, standard deviation"
		di in r "mad, median absolute deviation"
		di in r "iqr, interquartile range"
		di in r "s, S-statistic (Rousseeuw and Croux, 1993)"
		di in r "qn, Q-statistic (Rousseeuw and Croux, 1993) (default)"
		error 198
	}

    gen i = 1 if `varlist' < .
	egen group_1 = group(`item')
	capture confirm numeric variable `item'
	if (_rc==0) decode `item', gen (s_`item')
	else	 gen s_`item' = `item'
	bys group_1: gen n_1 = _N
	if "`zscore'" != "iqr" {
		gen _scale = .
		gen _center =.
		qui robstat `varlist' [pw`exp'], statistics(`zscore') over(group_1)
		forv i = 1/`=e(N_over)'{
			replace _scale = r(table)[1,`i'] if n_1 >= `minn' & group_1 == `i'
		}
		qui robstat `varlist' [pw`exp'], statistics(median) over(group_1)
		forv i = 1/`=e(N_over)'{
			replace _center = r(table)[1,`i'] if n_1 >= `minn' & group_1 == `i'
		}	
	}
	else{ //iqr
		preserve
			collapse (p10) p10 = `varlist' (p25) p25 = `varlist' (p50) _center = `varlist' (p75) p75 = `varlist' (p90) p90 = `varlist' (rawsum) n_1 = i [pw`exp'], by(group_1)
			qui drop if n_1 < `minn'
			qui gen _scale = (p75 - p25)/1.35 
			qui replace _scale = (p90-p10)/2.56 if _scale == 0
			keep _center _scale group_1 n_1
			qui save `stats'
		restore
		qui merge m:1 group_1 using `stats', assert(match) nogen
    }
	cap gen _group = s_`item'
	cap gen _obs = n_1 
	cap drop group_1
	cap drop n_1
    
	if "`over'" != "" {
		foreach var of varlist `over' {
			noi di in r "`var'"
			capture confirm numeric variable `var'
			if (_rc==0) decode `var', gen (s_`var')
			else	 gen s_`var' = `var'
			tempfile stats_`var'
			
			egen group_2 = group(`item' `var')
			bys group_2: gen n_2 = _N
			replace _obs = n_2 if n_2 >= `minn'
			replace _group = s_`item' + "+" + s_`var' if n_2 >= `minn'
			cap drop n_2
			if "`zscore'" != "iqr"{
				qui robstat `varlist' [pw`exp'], statistics(`zscore') over(group_2)
				forv i = 1/`=e(N_over)'{{
					replace _scale = r(table)[1,`i'] if n_2 >= `minn' & group_2 == `i'
				}
				qui robstat `varlist' [pw`exp'], statistics(median) over(group_2)
				forv i = 1/`=e(N_over)'{
					replace _center = r(table)[1,`i'] if n_2 >= `minn' & group_2 == `i'
				}	
			}
			else{ //iqr
				preserve
					collapse (p10) p10 = `varlist' (p25) p25 = `varlist' (p50) center_2 = `varlist' (p75) p75 = `varlist' (p90) p90 = `varlist' (rawsum) n_2 = i [pw`exp'], by(group_2)
					noi drop if n_2 < `minn'
					qui gen scale_2 = (p75 - p25)/1.35 
					qui replace scale_2 = (p90-p10)/2.56 if scale_2 == 0 
					keep group_2 center_2 scale_2
					qui save `stats_`var'', replace
				restore
				merge m:1 group_2 using `stats_`var'',  update replace nogen assert(1 3)
				replace _scale = scale_2 if !mi(scale_2)
				replace _center = center_2 if !mi(center_2)
			}
			cap drop group_2
			cap drop n_2
			cap drop scale_2 
			cap drop center_2 
		}
	}

    qui count if _scale == 0
    if r(N) > 0 {
        di as err _n "warning: items with 0 scale (p10 = p90)."
        di as err "Any value not equal to p10 = p90 will be flagged as outlier"
        li `item' `over' if _scale == 0 & `varlist' < .
    }
    qui count if _obs < `minn' 
    if r(N) > 0 {
        di as err _n "warning: items with less than `minn' observations"
        di as err "No values flagged as outlier for this items."
        list `item' `over' _obs if _obs < `minn' & `varlist' < .
    }

    qui gen _flag = 0 if `varlist' < . & _obs > `minn'
    qui gen _min  = _center - `z'*_scale
    qui gen _max  = _center + `z'*_scale

	
	ren _center _median
    *qui gen _median = `center' // can use this to impute
    qui replace _flag = -1 if `varlist' < _min & `varlist' < . & _obs > `minn'
    qui replace _flag = 1  if `varlist' > _max & `varlist' < . & _obs > `minn'

    tempname xx
    lab def `xx' -1 "lower" 0 "nonoutlier" 1 "upper"
    lab val _flag `xx'

    tab _flag if `varlist' < ., m
	cap drop i
	cap drop s_*
end
