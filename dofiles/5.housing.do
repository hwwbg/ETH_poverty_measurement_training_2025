*=============================================================================
*Project:       Ethiopia Poverty Measurement Training 2025
*Author: 	    Haoyu Wu
*Create Date:   8/8/2025
*Modify Date:   8/13/2025
*Data source:   HoWStat combines HCES and WMS (2021) and conducted by the        
*		        Ethiopian Statistics Services (ESS)  
*=============================================================================

log close _all
 

* Load final survey dataset
use "${temp}\NISH2021_NONFOOD_CONS.dta", clear
keep if major == 301 //keep rental section

bys hhid: gen a = _N
tab a //some household have more than one rental payment
duplicates drop hhid, force //70 obs dropped

tab itemc
tab TYPE

replace ann_value = . if itemc == 30101 //kebele rental is partly covered by gov. The ann_value is only a fraction of the acutal rent.
replace ann_value = . if itemc == 30102 | itemc == 30106 |itemc == 30105 //subsidized housing

gen rental1 = inlist(itemc,30103)
tab rental1 

//compute the monthly rental
tab ann_quant
gen rent_m = ann_value/ann_quant

gen value1 = 0
replace value1 = rent_m if rental1 == 1
gen value2 = 0
replace value2 = rent_m if rental1 == 0

collapse (sum) value1 value2, by(hhid REP ur rental1) 
label var value1 "mothly rental for acutal payment"
label var value2 "mothly rental for self estimation"
tempfile rental
save `rental', replace

********************************************************************************
** A. Create dwelling characteristic variables                                **
********************************************************************************
use "C:\Users\wb545671\OneDrive - WBG\AFE_work\Mission\3.ETH_Aug2025\NISH2021\Poverty Measurement\Data\temp\WMS_2022_hh_level.dta", clear
keep hhid - wq7105_30 wgt1
ren wgt1 weight_hh
ren ur urban
merge 1:1 hhid using `rental', assert(3) nogen

tab wq5103
gen rental2 =  wq5103 == 52

tab rental1 rental2

count if value2!=0 & rental2 == 1 //
count if value1!=0 & rental2 == 0 //# hh report acutal pay rent, but they own the house 

**  a. number of rooms
tab wq5104a
recode wq5104a (7/max = 7), gen(nrooms)
tab nrooms

/**  b. number of besrooms
tab wq5104b
recode wq5104b (5/max = 5), gen(bedrooms)
tab bedrooms*/

**  c. walls
tab wq5105, nol
recode wq5105 (11 12 13 61 62 73 = 1) (21 22 23 = 2) (31 32= 3) (41 42 = 4) (51 52 71 = 5) (. = . ) (else = 6), gen(walls)
tab walls

**  d. roof
tab wq5106, nol m
recode wq5106 (1 = 1) (2 = 2) (3 = 3) (4 = 4) (5 = 5) (6 = 6) (. = . )  (else = 7), gen(roof)
tab roof

**  e. floor
tab wq5107, nol m
recode wq5107 (1 = 1) (4 = 2) (6= 3) (7 = 4)(. = . ) (else = 5), gen(floor)
tab floor

**  f. ceiling
tab wq5108, nol m
recode wq5108 (1 = 1) (2 = 2) (4= 3) (7 = 4)(8 = 5)(. = . ) (else = 6), gen(ceiling)
tab ceiling

**  g. light source
tab wq5202, nol m
recode wq5202 (11 = 1) (12 = 2) (21= 3) (31 = 4)(42 = 5)(. = . ) (else = 6), gen(light)
tab light

**  h. kitchen
tab wq5208, nol m
gen kitchen = wq5208 
tab kitchen

** i.cooking energy
tab wq5214, nol m
recode wq5208 (1= 1) (2 = 2) (3 = 3) (9 = 4) (. = . ) (else = 5) , gen(cooking)
tab cooking

**  j. water source dry season
tab wq5302, nol m
recode wq5302 (11/14 51 = 1) (21= 2) (22/23 = 3) (31/32=4)(61/67=4)(81=5)(. = . ) (else = 6) , gen(water1)
tab water1 

/**  k. water source rain season
tab wq5307, nol m
recode wq5307 (11/14 51 = 1) (21= 2) (22/23 = 3) (31/32=4)(61/67=4)(81=5)(. = . ) (else = 6) , gen(water2)
tab water2 */

**  l. toilet
tab wq5402, nol m
recode wq5402 (1= 1) (2 = 2) (3 = 3) (4 = 4) (5 = 5)(15 = 6)(. = . )  (else = 7), gen(toilet)
tab toilet

**  m. waste disposal
tab wq5411, nol m
recode wq5411 (5 = 4)(6 = 5)(7 = 6)(8 = 7)(4 9 = 8), gen(waste)
tab waste

** n.bath
tab wq5407, nol m
*gen bath = wq5407
recode wq5407 (11 12 = 1)(21 22 = 2)(31 32 = 3)(41 = 4), gen(bath)
*replace bath = . if bath == 22 | bath == 41 //conterintuitive cases
tab bath

** o.no_electricity
gen elec_hours = wq5205

** p.no_water
tab wq5312, nol m
gen prob_water = wq5407
tab prob_water

** q. distanace to facility
/*
0	1	Primary school (Grade 1-4)
0	2	Primary school (Grade 5-8)
0	3	Secondary school (Grade 9-10)
0	4	Secondary school (Preparatory)(Grade 11-12)
0	5	Health post
0	6	Clinic
0	7	Health Center
0	8	Hospital
0	9	Mobile Network
1	0	Internet service
1	1	Public transport (residence area)
1	2	Public transport (cross country)
1	3	Milling service
1	4	Drinking water (Dry season)
1	5	Drinking water (rain season)
1	6	Drinking water (Livestock- Dry season)
1	7	Food Market 
1	8	Livestock market
1	9	All weather roads for driving
2	0	Dry season roads for driving
2	1	Agricultural extension service
2	2	Veterinary service
2	3	Fertilizer  Market /suplier
2	4	Improved seeds market /suplier
2	5	Pesticide/insecticide/herbicide market /suplier
2	6	Police station
2	7	Court
2	8	Kebele administration office
2	9	Bank including public and private
3	0	Small scale loan and saving (Micro finance) 
*/
// 6 km per hour
gen dist1 = wq7103_01 if !mi(wq7103_01)
replace dist1 = wq7103_02 if !mi(wq7103_02) & wq7103_02 < 
replace dist1 = wq7103_03 if !mi(wq7103_03) & wq7103_02 < dist1
replace dist1 = wq7103_02 if !mi(wq7103_02) & wq7103_02 < dist1

gen dist3 = wq7103_03 if !mi(wq7103_03)
replace dist1 = wq7103_04 if !mi(wq7103_04) & mi(dist2)


* Number of missing housing characteristics (for flagging)
local indvars nrooms floor roof walls cooking water1 toilet light waste ceiling bath prob_water ceiling
*egen nmiss = rowmiss(`indvars')
misstable summarize `indvars'


********************************************************************************
** B. Prepare monthly rent data and currency conversion                       **
********************************************************************************

**  c. check distribution for obvious issues
gen rent = .
replace rent = value2 if !mi(value2) & value2>0 //add the self report rent
replace rent = value1 if value1>0 & rent == . //actual rent (priority)

sum rent, d //some extreme values

**  d. tenancy status
gen market_tenant = rent == value1
lab var market_tenant "tenancy status"
tab market_tenant 

*assert mi(value2) if market_tenant == 1  //tennats did not have self-report rent

*  d. winsorize rent (actual) at ~ top and bottom 10% for purposes of graphing
*winsor2 rent_amt, suffix(_win) label cut(1 90)

********************************************************************************
** C. Flag outliers in actual and self-est rent                               **
********************************************************************************
gen logrent = log10(rent)

** log 10 to make it easier to label axes in graphs (2 -> 100, 3 -> 1000 etc)
flagout logrent [pw = weight_hh], item(market_tenan) over(REP) z(${z}) 

tab _flag market_tenant, nol

********************************************************************************
** D. Hedonic Regression                                                      **
********************************************************************************
////////////////////////////////////////////////////////////////////////////////
/////              Model A: using actual renters, urban and rural       ////////
////////////////////////////////////////////////////////////////////////////////
local indv nrooms i.floor i.walls i.cooking i.water1 i.toilet i.light i.waste i.ceiling /*i.bath*/ i.ceiling i.prob_water

*local indv  wq5104a i.wq5105 i.wq5106 i.wq5107 i.wq5108 i.wq5208 i.wq5302 wq5205 i.wq5202 i.wq5312 i.wq5402 i.wq5411 nrooms 
// 1. Regression ** actual rent ** urban
**  b. stepwise selection of variables
stepwise, pr(.2): reg logrent `indv' [aw=weight_hh] if urban == 1 & _flag == 0 & market_tenant, r
matrix A = e(beta)
local selected_vars: colnames(A)

//residual check
*rvfplot, yline(0)
//multicollinearity
*vif

**  c. the model
glm logrent `selected_vars' [pw = weight_hh] if urban & _flag == 0 & market_tenant, link(log)
predict logrental_equivA if urban == 1

// 2. Regression ** actual rent ** rural
**  b. stepwise selection of variables
local indv nrooms i.floor i.walls i.cooking i.water1 i.toilet i.light i.waste i.ceiling /*i.bath*/ i.ceiling i.prob_water

stepwise, pr(.2): reg logrent `indv' [aw=weight_hh] if urban == 2 & _flag == 0 & market_tenant, r
matrix A = e(beta)
local selected_vars: colnames(A)

**  c. the model
glm logrent `selected_vars' [pw = weight_hh] if urban == 2 & _flag == 0 & market_tenant, link(log)
predict logrental_equivA2 if urban ==2


**  3. combine urban and rural
replace logrental_equivA = logrental_equivA2 if urban == 2
gen rental_equivA =10^logrental_equivA

******* 3. Inspect results *****************************************************
//acutal pay vs prediction
tw scatter logrental_equivA logrent if market_tenant == 1 & _flag == 0, by(urban, legend(off)) aspectratio(0.85) ///
|| function y = x, range(2 4) lcolor(gs10) ///
	ytitle("predicted rental equivalent, monthly") xtitle("actual rental value, monthly")  title("Model A: without selfreport rent") ///
	xsize(8) name(g1, replace)
*graph export "${graph}\Rent_acutal_vs_predict_A.png", as(png) name("g1") replace
s

//slef_estimation vs prediction
gen logrent_self = log10(value2)
tw scatter logrental_equivA logrent_self if market_tenant == 0 & logrent_self>0, by(urban, legend(off)) aspectratio(0.85) ///
|| function y = x, range(2 4) lcolor(gs10) ///
	ytitle("predicted rental equivalent, monthly USD") xtitle("self-estimated value, monthly USD")  title("Model B: without selfreport rent") ///
	xsize(8) name(g2, replace) 
*graph export "${graph}\Rent_selfrepot_vs_predict_A.png", as(png) name("g2") replace


////////////////////////////////////////////////////////////////////////////////
/////              Model B: using all obs, urban and rural             ////////
////////////////////////////////////////////////////////////////////////////////
local indv nrooms i.floor i.walls i.cooking i.water1 i.toilet i.light i.waste i.ceiling /*i.bath*/ i.ceiling i.prob_water
// 1. Regression ** all obs ** urban 
*local indv nrooms bedrooms i.dwelling_type i.floor i.walls i.cooking i.water i.toilet i.light i.waste i.elect dist_* market_tenant 
**  b. stepwise selection of variables
stepwise, pr(.2): reg logrent `indv' [aw=weight_hh] if urban == 1 & _flag == 0 , r
matrix A = e(beta)
local selected_vars: colnames(A)

**  c. the model
glm logrent `selected_vars' [pw = weight_hh] if urban == 1 & _flag == 0 , link(log)
predict logrental_equivB if urban == 1


// 2. Regression ** all obs ** rural
**  b. stepwise selection of variables
stepwise, pr(.2): reg logrent `indv' [aw=weight_hh] if urban == 2  & _flag == 0 , r
matrix A = e(beta)
local selected_vars: colnames(A)

**  c. the model
glm logrent `selected_vars' [pw = weight_hh] if urban == 2 & _flag == 0 , link(log)
predict logrental_equivB2 if urban == 2


**  3. combine urban and rural
replace logrental_equivB = logrental_equivB2 if urban == 2
gen rental_equivB =10^logrental_equivB
s

******* 3. Inspect results *****************************************************
//acutal pay vs prediction
tw scatter logrental_equivB logrent if market_tenant == 1 & _flag == 0, by(urban, legend(off)) aspectratio(0.85) ///
|| function y = x, range(2 4) lcolor(gs10) ///
	ytitle("predicted rental equivalent, monthly USD") xtitle("actual rental value, monthly USD") title("Model B: with selfreport rent") ///
	xsize(8) name(g1, replace)
*graph export "${graph}\Rent_acutal_vs_predict_B.png", as(png) name("g1") replace

//slef_estimation vs prediction
tw scatter logrental_equivB logrent if market_tenant == 0 & logrent>0, by(urban, legend(off)) aspectratio(0.85) ///
|| function y = x, range(2 4) lcolor(gs10) ///
	ytitle("predicted rental equivalent, monthly USD") xtitle("self-estimated value, monthly USD")  title("Model B: with selfreport rent") ///
	xsize(8) name(g2, replace) 
*graph export "${graph}\Rent_selfrepot_vs_predict_B.png", as(png) name("g2") replace

////////////////////////////////////////////////////////////////////////////////
/////            Model C: using actual renters, district model          ////////
////////////////////////////////////////////////////////////////////////////////
local indv nrooms i.floor i.walls i.cooking i.water1 i.toilet i.light i.waste i.ceiling /*i.bath*/ i.ceiling i.prob_water i.REP
// 1. Regression ** actual rent ** national 
*local indv nrooms bedrooms i.dwelling_type i.floor i.walls i.cooking i.water i.toilet i.light i.waste i.elect dist* i.district

**  b. stepwise selection of variables
stepwise, pr(.2): reg logrent `indv' [aw=weight_hh] if _flag == 0 & market_tenant, r
matrix A = e(beta)
local selected_vars: colnames(A)

**  c. the model
glm logrent `selected_vars' [pw = weight_hh] if _flag == 0 & market_tenant, link(log)
predict logrental_equivC

**  3. combine urban and rural
gen rental_equivC =10^logrental_equivC

//graph
tw scatter logrental_equivC logrent if market_tenant == 1 & _flag == 0, by(urban, legend(off)) aspectratio(0.85) ///
|| function y = x, range(2 4) lcolor(gs10) ///
	ytitle("predicted rental equivalent, monthly USD") xtitle("actual rental value, monthly USD")  title("Model C: without selfreport rent/natioanl") ///
	xsize(8) name(g1, replace)
*graph export "${graph}\Rent_acutal_vs_predict_C.png", as(png) name("g1") replace

//slef_estimation vs prediction
tw scatter logrental_equivC logrent if market_tenant == 0 & logrent>0, by(urban, legend(off)) aspectratio(0.85) ///
|| function y = x, range(2 4) lcolor(gs10) ///
	ytitle("predicted rental equivalent, monthly USD") xtitle("self-estimated value, monthly USD")  title("Model C: without selfreport rent/national") ///
	xsize(8) name(g2, replace) 
*graph export "${graph}\Rent_selfrepot_vs_predict_C.png", as(png) name("g2") replace

********************************************************************************
** E. Compare Results                                                         **
********************************************************************************

**  a. percentiles and correlations
tabstat rent rental_equiv* if market_tenant == 0, by(urban) s(p25 p50 mean p75) format(%8.0fc) // SLIDE 7  left
tabstat rent rental_equiv* if market_tenant == 1, by(urban) s(p25 p50 mean p75) format(%8.0fc) // SLIDE 7  right
bys urban: corr rent rental_equiv* if market_tenant == 0
bys urban: corr rent rental_equiv* if market_tenant == 1

**  b. box graphs of all models
graph box logrent logrental_equivA logrental_equivB logrental_equivC, over(urban) over(market_tenant) name(g7, replace) legend(title("rental value (monthly)") order(1 "self-estimated" 2 "model A" 3 "model B" 4 "model C")) xsize(10)
*graph export "${graph}\Rent_box_all.png", as(png) replace

**  c. histograms of all models
sum rent*

tw histogram rent if !market_tenant, start(-100) width(100) by(urban, note("nonmarket tentants only")) color(stc1%20) ///
|| histogram rental_equivA  if !market_tenant, start(-100) width(100) by(urban) color(stc2%20) ///
	ylabel(none)  legend(order(1 "self-estimated" 2 "model A"))
*graph export "${graph}\Rent_hist_self_A.png", as(png) replace

tw histogram rent if !market_tenant, start(-100) width(100) by(urban, note("nonmarket tentants only")) color(stc1%20) ///
|| histogram rental_equivB  if !market_tenant, start(-100) width(100) by(urban) color(stc2%20) ///
	ylabel(none)  legend(order(1 "self-estimated" 2 "model B")) 
*graph export "${graph}\Rent_hist_self_B.png", as(png) replace
	
tw histogram rent if !market_tenant, start(-100) width(100) by(urban, note("nonmarket tentants only")) color(stc1%20) ///
|| histogram rental_equivC  if !market_tenant, start(-2500) start(-100) width(100) color(stc2%20) ///
	ylabel(none)  legend(order(1 "self-estimated" 2 "model C")) 
*graph export "${graph}\Rent_hist_self_C.png", as(png) replace

tw histogram rent if market_tenant, start(-100) width(100) by(urban, note("market renters only")) color(stc1%20) ///
|| histogram rental_equivA  if market_tenant, start(-100) width(100) by(urban) color(stc2%20) ///
	ylabel(none)  legend(order(1 "actually paid" 2 "model A")) 
*graph export "${graph}\Rent_hist_real_A.png", as(png) replace

tw histogram rent if market_tenant, start(-100) width(100) by(urban, note("market renters only")) color(stc1%20) ///
|| histogram rental_equivB  if market_tenant, start(-100) width(100) by(urban) color(stc2%20) ///
	ylabel(none)  legend(order(1 "actually paid" 2 "model B"))
*graph export "${graph}\Rent_hist_real_B.png", as(png) replace

tw histogram rent if market_tenant, start(-100) width(100) by(urban, note("market renters only")) color(stc1%20) ///
|| histogram rental_equivC  if market_tenant, start(-100) width(100) by(urban) color(stc2%20) ///
	ylabel(none)  legend(order(1 "actually paid" 2 "model C"))
*graph export "${graph}\Rent_hist_real_C.png", as(png) replace

********************************************************************************
** F. Select model and save                                          **
********************************************************************************

******* 1. Winsorize outliers in actual rent paid and self-estimated ***********

count if rent == .
count if rent == 0

**  a. flag outliers using higher cutoff
flagout logrent [pw = weight_hh], item(market_tenan) over(REP) z(${z}) 
tab _flag market_ten, nofreq col
 
**  b. winsorize
replace rent = 10^(_min) if _flag == -1 
replace rent = 10^(_max) if _flag == 1

**  c. fill in one missing
replace rent = 10^(_median) if rent >= .


******* 2. Select option for nonmarket tenants *********************************

/*if self-estimated
	gen exp_house_1 = 12* rent if !market_tenant 
	lab var exp_house_! "self-estimated rental value for nonmarket"
*/
	gen exp_house_1 = 12* rental_equivC if !market_tenant
	lab var exp_house_1 "imputed rental value (mode ${housing_model}) for nonmarket"



******* 3. Use actual rent paid for market tenants *****************************

gen exp_house_2 = 12* rent if market_tenant
lab var exp_house_2 "actual rent paid for renters"

******* 4. Save ****************************************************************

tabstat exp_house_1 exp_house_2, stat(min p25 p50 mean p75 max) format(%8.0fc)

log close _all
keep interview__key exp_house_1 exp_house_2
save "${temp}/consumption_housing.dta", replace




