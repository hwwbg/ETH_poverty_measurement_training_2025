*******************************************************************************
* Estimation of the Poverty line, 
* This program is based on the WAEMU standard      *
*******************************************************************************

pause off


********************************************************************************
*   A. Preliminary and Auxiliary Datasets                                      *
********************************************************************************

**** 1. Welfare deciles ********************************************************

use  "${out}/hces_household_2021_final.dta", clear
gen weight_pop =  weight_hh*hh_size 
xtile decile=cons_pc_day  [aw = weight_hh*hh_size], nq(10)
tab decile  [aw= weight_hh*hh_size]
keep hhid decile cons_pc_day weight_hh weight_pop
tempfile _decile
save `_decile'

keep if (decile >= $d_min & decile <= $d_max)
total weight_pop
local pop_ref = r(table)[1,1]


********************************************************************************
*   B. Food Basket / Food Poverty Line                                         *
********************************************************************************

use "${temp}\NISH2021_FOOD_CONS_detail.dta", clear
merge m:1 hhid using "${temp}/hces_survey_date_2021.dta", nogen keep(1 3) keepusing(int*) //interview date
clonevar month = int_month

**** 1. Select items ***********************************************************

**  a. keep only reference population
merge m:1 hhid using  `_decile'
keep  if _merge == 3
drop _merge

keep if (decile>=$d_min & decile<=$d_max)  /* (decile>=2 & decile<=6) excluding des extremes decile to build the national food basket */

**  b. drop FAFH
drop if inrange(itemc,1801,1998) | inrange(itemc,2001, 2198)  //drop 14,750

**  c. merge in deflators
* Food spatial price index 
merge m:1 REP using "${temp}\sptial_def.dta", assert(3) nogen

*Food temporal price index 
merge m:1 month using "${temp}\temporal_def.dta", assert(3) nogen

gen fd_spat  = fd_def*fd_temp

**  d. select to get reasonable total budget share with price per kg and calories per 100 g
replace cons_food = cons_food/fd_spat/365   //daily 
collapse (sum) cons_foodt=cons_food [pw=weight_hh], by(itemc)  

gsort -cons_foodt
egen cons_food_tot=sum(cons_foodt)
gen cobu=cons_foodt*100/cons_food_tot
gen cobuc=cobu if _n==1
replace cobuc=cobuc[_n-1]+cobu if _n>1
keep if cobuc<86  /* The food basket will include all items up to 85% overall food consumption, this is what most WAEMU countries did, and in line with most best practices */
s
** e. merge in prices
preserve
	use "${temp}\ph.dta", clear
	keep itemc pb_0 //national mean
	bys itemc (pb_0): keep if _n == 1
	tempfile ph
	save `ph', replace
restore

merge 1:1 itemc using `ph', keep(master match) nogen
 
**  f. merge in kcal per 100g and information on waste
preserve
	use "${temp}\NISH2021_FOOD_CONS_detail.dta", clear
	keep hhid netcal ann_quant_st itemc weight_hh MEASURMENT GROSSCAL
	gen Kcal_per_100g = netcal/ann_quant_st/10 if MEASURMENT == 1 | MEASURMENT == 20
	replace Kcal_per_100g = netcal/ann_quant_st/10 if item == 1001 | item == 1004 | item == 1009 | item == 1010 | item == 1105
	collapse (mean) Kcal_per_100g, by(itemc)
	drop if mi(Kcal_per_100g)
	tempfile calories
	save `calories'
restore

merge 1:1 itemc using `calories'
drop if _merge == 2
drop _merge

//Milling Charge (Cereals) (kilogram) did not have calorie data


**  g. look at basket
gsort -cons_foodt
list itemc cobu cobuc pb_0 Kcal_per_100g , noobs 

**  h. have 85.39% of consumption
gen cobu_matched = cobu if pb_0 < . & Kcal_per_100g < . 
total cobu_matched
local frac_using = r(table)[1,1]/100

**  i. Checking potential items with missing prices or conversion factor to Calories 
list itemc pb_0 Kcal_per_100g if pb_0 == . | Kcal_per_100g == .

** For now, we are dropping the only one item with that issue illing Charge (Cereals) (kilogram
drop if pb_0 == . | Kcal_per_100g == .

 
**** 2. Get quantities for target number of calories ***************************

** a. Daily consumption per capita  
gen conso_pc_val	=	cons_foodt/(`pop_ref')  // cons_foodt is total consumption of the item by the reference pop, pop_ref is size of referenece pop

gen conso_pc_qte	=	conso_pc_val*10/pb_0  // use national price per kg to convert value of consumption in to kg then 100g (factor of 10)
gen conso_pc_ener	=	conso_pc_qte*Kcal_per_100g  // get calories from the average per capital daily quantity consumed

//account for waste : *(1-(waste/100))

** b. Scaling up (or down?) to match the target here of 2200 kcal  
total conso_pc_ener
local kcal = r(table)[1,1]

di `kcal' / `frac_using' // suggests reference pop is consuming 1240.7674 kcal per person per day, quite reasonable. Influence by not taking FAFH, 86% of the spending, fatigue in the diary

gen quantity = conso_pc_qte  * $calories_pc/`kcal'  // scale up quantity of each item
gen calories = conso_pc_ener * $calories_pc/`kcal'  // scale up calories from each item

**  c. construct cost
gen cost = quantity * pb_0/10 // cost using national price, remembering quantities are per 100g

**  d. cost per calorie
gen cost_per_calorie = (pb_0/10)/Kcal_per_100g
sum cost_per_calorie, d

**** 3. Look at basket with costs **********************************************

**  a. basket by order of calories supplied
gsort -calories
list itemc pb_0 Kcal quantity calories cost cost_per_calorie, noobs string(50)

**  b. basket by order of cost
gsort -cost
list itemc pb_0 Kcal quantity calories cost cost_per_calorie, noobs string(50)

**  c. total cost
replace cost = cost*365 //annualized
total cost
glo zali0 = r(table)[1, 1] //food poverty line

**  d. export
export excel itemc pb_0 cobu conso_pc_qte conso_pc_ener quantity calories cost cost_per_calorie Kcal_per_100g using "${temp}\basket.xlsx", replace firstrow(var)

********************************************************************************
*   C. Nonfood component                                                       *
********************************************************************************

use "${out}/hces_household_2021_final.dta", clear

**** 1. Set up for Ravallion ***************************************************

**  a. construct total food and nonfood, and per capita and welfare aggregate and deciles 
gen totalfood    = food_exp_nom 
gen totalnonfood = nonfood_exp_nom
gen pcfoodexp = totalfood /hh_size 
gen pcnfexp = totalnonfood  /hh_size
gen pcexp  = (totalfood + totalnonfood) /hh_size //nominal term, because the food poverty line is nominal
cap drop welfare
gen welfare  = total_pc_r
xtile decile=welfare [aw = weight_hh*hh_size], nq(10)

**  b. Basic stat on food as a share of total exp.
gen 	totalexp  = totalfood+totalnonfood
gen 	alpha = totalfood / totalexp

tabstat alpha [w=weight_hh * totalexp], s(min p50 mean max)
tabstat alpha [w=weight_hh * totalexp], s(min p25 p50 p75 mean max) by(decile)

/*preserve
	collapse (min) min = alpha (p10) p10 = alpha (p25) p25 = alpha (p50) p50 = alpha (mean) mean = alpha (p75) p75 = alpha (p90) p90 = alpha (max) max = alpha [pw = weight_hh], by(decile)
	sort decile
	tw rarea min max decile, color(gs10) ///
	|| rarea p10 p90 decile, color(gs8)  ///
	|| rarea p25 p75 decile, color(gs6)  ///
	|| line p50 decile, lcolor(cranberry)  ///
	|| line mean decile, lcolor(navy) ///
	ytitle("alpha") xlabel(1(1)10) name(alpha_range, replace) ///
	legend(order(1 "min-max" 2 "p10-p90" 3 "p25-p75" 4 "median" 5 "mean"))
restore
*/

*gen decile_ur = decile * 10 + cod_CV_CP //cod_CV_CP (urban/rural)
*flagout alpha [pw = weight_hh], item(decile_ur) z(2)
*table decile if _flag == 0 [pw = weight_hh], stat(min alpha) stat(max alpha) stat(mean alpha)

*tabstat totalfood [w=weight_hh], s(sum) by(decile) format(%15.1g)

/*histogram alpha, start(0) width(0.05) name(food_share, replace) 
gen logtot = log(totalexp)
reg alpha logtot
predict alpha_hat
sort logtot
if $graphs tw scatter alpha logtot, name(alpha_totexp, replace) msize(tiny) mcolor(%10) || line alpha_hat logtot, legend(off) lcolor(stc1)
if $graphs graph box alpha, over(decile) name(alpha_box, replace) 
*/

**  c. define reference interval for Ravallion
gen zali0 = ${zali0}
gen dmin = (1 - ${rav_perc}/100) * zali0
gen dmax = (1 + ${rav_perc}/100) * zali0

**  d. look at population with Ravallion interval (for food and total)
if ${p_alpha} == 0 {
	gen excude = 0
}
else if ${p_alpha} > 0 & ${p_alpha} < 50 {
	bys decile: egen ex1 = wpctile(alpha), p(${p_alpha}) w(weight_hh)
	bys decile: egen ex2 = wpctile(alpha), p(`=100-${p_alpha}') w(weight_hh)
	gen exclude = alpha < ex1 | alpha > ex2
}


tab exclude
sum alpha if !exclude
tab exclude if pcexp>=dmin & pcexp<=dmax
tab exclude if pcfoodexp>=dmin & pcfoodexp<=dmax

/**  e. Additionnal statistics to check the number of observations used to compute the non food poverty line  //
gen hhw=round(weight_hh*pcexp)
tabstat alpha [fw=hhw], stat(min median mean max)
tabstat alpha if (pcexp>=dmin & pcexp<=dmax) [fw=hhw], stat(min median mean max) 
tabstat alpha if (pcfoodexp>=dmin & pcfoodexp<=dmax) [fw=hhw], stat(min median mean max)
*/

**** 2. Multiplicative Ravallion ***********************************************
** estimate alpha directly, as mean alpha over the Ravallion population
** not actually recommended by Ravallion
** commonly done, ie all WAEMU countries

**  a. lower Ravallion
tabstat alpha [aw = weight_hh]            if (pcexp>=dmin & pcexp<=dmax) & !exclude, s(p50 mean) save  // by hhs

local alpha1_min = r(StatTotal)[1,1]
local alpha2_min = r(StatTotal)[2,1]

gen zref_lowerM1 = zali0 * (1-`alpha1_min'+1) //median
gen zref_lowerM2 = zali0 * (1-`alpha2_min'+1) //mean


**  b. upper Ravallion
tabstat alpha [aw = weight_hh]           if (pcfoodexp>=dmin & pcfoodexp<=dmax) & !exclude, s(p50 mean) save // by hhs
local alpha1_max = r(StatTotal)[1,1]
local alpha2_max = r(StatTotal)[2,1]

gen zref_upperM1 = zali0/`alpha1_max'
gen zref_upperM2 = zali0/`alpha2_max'
/*
**** 3. Additive Ravallion *****************************************************
** estimate nonfood expenditure directly
** using exactly algorithm suggested in Ravallion 1998

** a. lower Ravallion
matrix RAV = J(4, $rav_perc, .) 
forval x = 1/$rav_perc {    
	local max = $zali0 * `=1+(`x'/100)'
	local min = $zali0 * `=1-(`x'/100)'
	qui tabstat pcnfexp [aw = weight_hh] if inrange(pcexp, `min', `max') & !exclude, s(p50 mean) save  // lower Ravallion by hh
	matrix RAV[1, `x'] = r(StatTotal)[1, 1]
	matrix RAV[2, `x'] = r(StatTotal)[2, 1]
	qui tabstat pcnfexp [aw = weight_hh] if inrange(pcfoodexp,  `min', `max') & !exclude, s(p50 mean) save  // upper Ravallion by hh
	matrix RAV[3, `x'] = r(StatTotal)[1, 1]
	matrix RAV[4, `x'] = r(StatTotal)[2, 1]
}
matrix M = J($rav_perc, 1, 1)
matrix NF = (RAV * M)/$rav_perc // averages over the matrix
matrix list RAV
matrix list NF
gen zref_lowerA1 = zali0 + NF[1,1]
gen zref_lowerA2 = zali0 + NF[2,1]
gen zref_upperA1 = zali0 + NF[3,1]
gen zref_upperA2 = zali0 + NF[4,1]

*/
**** 5. Compare all Ravallion implementations and select ***********************

** a. generate midlines for all
foreach x in M1 M2 /*A1 A2*/ {
    gen zref_mid`x' = (zref_lower`x' + zref_upper`x')/2
}

** b. compare
preserve
    keep welfare weight_hh hh_size zref* hhid
    reshape long zref_lower zref_upper zref_mid, i(hhid) j(method) string
    reshape long zref_, i(hhid method) j(level) string
    gen poor = 100 * (welfare < zref)
    lab var method method
    table method level, stat(mean zref) nform(%10.0fc) nototal
    table method level [aw = weight_hh * hh_size], stat(mean poor) nformat(%4.1fc) nototal
restore


**  e. clean up and save
lab var totalfood "total nominal food consumption"
lab var totalnonfood "total nominal nonfood consumption"
lab var pcexp "per capital nominal consumption"
lab var welfare "per capital real consumption"

save "${out}\NISH2021_CONS_FINA.dta", replace

