*******************************************************************************
*        A. Paasche SPATIAL DEFLATOR                                          *
*******************************************************************************
use "${temp}\NISH2021_FOOD_CONS_LONG.dta", replace

**** 1. Weights ****************************************************************

**  plutocratic shares by region-urban
collapse (sum) cons_food (first) pa_0_wmean pa_h food_group [pw = weight_hh], by(itemc REP) // sum over purchases and own consumption for each item-hh
bys REP: egen domain_total = total(cons_food)
gen wh = cons_food/domain_total

**** 2. Combine weights and prices *********************************************

**  2.1 relative prices
gen p0_ph = pa_0_wmean/pa_h 
//pa_0_wmean: national weighted mean of medians price
//pa_h:local (to strata) median price

sum p0_ph, d // 98% of relative prices are with 0.5-2 range
cap assert p0_ph > 0.5 & p0_ph < 2 // check relative prices within a reasonable range, not a difference of more than a factor of 2 or 3 depending on context
if _rc {
	list REP food_group itemc wh pa_0_wmean pa_h if p0_ph >2, noobs sepby(itemc)
	replace p0_ph = 2 if p0_ph > 2
}

**** 3. Construct index ********************************************************

**  3.1 sum and take inverse
collapse (sum) sum_terms = p0_ph [pw = wh], by(REP)
gen deflator_spatial_paasche = 1/sum_terms

**  3.2 insepct
lab var deflator_spatial_paasche "spatial Paasche index, province-urban level, food prices from hh survey"
table REP, stat(mean deflator_spatial_paasche) nototal
mean deflator_spatial_paasche // should be close to 1.

drop sum_terms
save "${temp}/deflators_spatial_food.dta", replace

*******************************************************************************
*        B. Laspeyres SPATIAL DEFLATOR                                          *
*******************************************************************************
use "${temp}\NISH2021_FOOD_CONS_LONG.dta", replace

collapse (sum) cons_food (first) pa_0_wmean pa_h food_group major [pw = weight_hh], by(itemc REP)
**** 1. Weights (national weight) ****************************************************************
* 2. Bring in the expenditure share from 2011 food basket
* It is used to generate the share of each major commodity in the total expenditure as weights (national weights)
* From NSO
gen wi=	.		
replace wi=	 0.02396/0.46651 	if major==	0
replace wi=	 0.11466/0.46651 	if major==	1
replace wi=	 0.00820/0.46651 	if major==	2
replace wi=	 0.02157/0.46651 	if major==	3
replace wi=	 0.01142/0.46651 	if major==	4
replace wi=	 0.00075/0.46651 	if major==	5
replace wi=	 0.00271/0.46651 	if major==	6
replace wi=	 0.01031/0.46651 	if major==	7
replace wi=	 0.02908/0.46651 	if major==	8
replace wi=	 0.00028/0.46651 	if major==	9
replace wi=	 0.01881/0.46651 	if major==	10
replace wi=	 0.03217/0.46651 	if major==	11
replace wi=	 0.02986/0.46651 	if major==	12
replace wi=	 0.00170/0.46651 	if major==	13
replace wi=	 0.03216/0.46651 	if major==	14
replace wi=	 0.02859/0.46651 	if major==	15
replace wi=	 0.04450/0.46651 	if major==	16
replace wi=	 0.01294/0.46651	if major==	17
replace wi=	 0.00143/0.46651 	if major==	18
replace wi=	 0.03225/0.46651 	if major==	19
replace wi=	 0.00839/0.46651 	if major==	20
replace wi=	 0.00077/0.46651 	if major==	21

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