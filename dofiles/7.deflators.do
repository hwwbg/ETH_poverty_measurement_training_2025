
*******************************************************************************
*        A. Paasche SPATIAL DEFLATOR                                          *
*******************************************************************************
use "${temp}\NISH2021_FOOD_CONS_LONG.dta", replace
drop if major == 24 //exlcude food away from home
gen food = 1
append using "${temp}\NISH2021_NONFOOD_CONS_LONG.dta"
drop if eligible_nonfood == 0
drop if durable == 0
replace p = pa_h if food  == 1
gen cons = ann_value_fix if food == .
replace cons = cons_food if food == 1

preserve
	collapse (mean) p0 = p [pw = weight_hh], by(itemc) // sum over purchases and own consumption for each item-hh
	tempfile p
	save `p', replace
restore

**** 1. Weights ****************************************************************

**  plutocratic shares by region-urban
collapse (sum) cons (first) p food_group [pw = weight_hh], by(itemc) // sum over purchases and own consumption for each item-hh
egen domain_total = total(cons)
gen wh = cons/domain_total

**** 2. Combine weights and prices *********************************************

**  2.1 relative prices
*gen p0_ph = pa_0_wmean/pa_h 
//pa_0_wmean: national weighted mean of medians price
//pa_h:local (to strata) median price
merge m:1 itemc using `p', assert(3) nogen
gen p0_ph = p0/p

sum p0_ph, d // 98% of relative prices are with 0.5-2 range
cap assert p0_ph > 0.5 & p0_ph < 2 // check relative prices within a reasonable range
if _rc {
	replace p0_ph = 0.5 if p0_ph < 0.5
	replace p0_ph = 2 if p0_ph > 2
}

**** 3. Construct index ********************************************************

**  3.1 sum and take inverse
collapse (sum) sum_terms = p0_ph [pw = wh]
gen deflator_spatial_paasche = 1/sum_terms

**  3.2 insepct
lab var deflator_spatial_paasche "spatial Paasche index, province-urban level, all prices from hh survey"
*table REP, stat(mean deflator_spatial_paasche) nototal
mean deflator_spatial_paasche // should be close to 1.

save "${temp}/deflators_spatial_Paasche.dta", replace

*******************************************************************************
*        B. Laspeyres SPATIAL DEFLATOR                                          *
*******************************************************************************
use "${temp}\NISH2021_FOOD_CONS_LONG.dta", replace
drop if major == 24 //exlcude food away from home
gen food = 1
append using "${temp}\NISH2021_NONFOOD_CONS_LONG.dta"
drop if eligible_nonfood == 0 
replace p = pa_h if food  == 1
gen cons = ann_value_fix if food == .
replace cons = cons_food if food == 1

preserve
	collapse (mean) p0 = p [pw = weight_hh], by(itemc) // sum over purchases and own consumption for each item-hh
	tempfile p
	save `p', replace
restore

**** 1. Weights (national weight) ****************************************************************
* 2. Bring in the expenditure share from 2011 food basket by item From NSO

gen wi=	.		
replace wi=	 0.02396 	if itemc == 1

**** 2. Combine weights and prices *********************************************

**  a. relative prices
gen p0_ph = pa_0_wmean/pa_h 
//pa_0_wmean: national weighted mean of medians price
//pa_h:local (to strata) median price

sum p0_ph, d // 98% of relative prices are with 0.5-2 range
cap assert p0_ph > 0.5 & p0_ph < 2 // check relative prices within a reasonable range, not a difference of more than a factor of 2 or 3 depending on context
if _rc {
	list REP food_group itemc wi pa_0_wmean pa_h if p0_ph >2, noobs sepby(itemc)
	replace p0_ph = 3 if p0_ph > 3
}

**** 3. Construct index ********************************************************

**  a. sum and take inverse
collapse (sum) sum_terms = p0_ph [pw = wi], by(REP)
gen deflator_spatial = 1/sum_terms

**  b. insepct
lab var deflator_spatial "spatial Laspeyres index, province-urban level, food prices from hh survey"
table REP, stat(mean deflator_spatial) nototal
mean deflator_spatial // should be close to 1.

**  C. save
drop sum_terms
save "${temp}/deflators_spatial_Paasche.dta", replace



