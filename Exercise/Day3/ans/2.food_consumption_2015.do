  
*=============================================================================
*Project:       Ethiopia Poverty Measurement Training 2025
*Author: 	    Haoyu Wu
*Create Date:   8/15/2025
*Modify Date:   8/18/2025
*Data source:   HoWStat combines HCES and WMS (2021) and conducted by the        
*		        Ethiopian Statistics Services (ESS)  
*=============================================================================
	
*==============================================================================
*   1. unit/ measurement data checking
*==============================================================================	
*	use "${temp}\NISH2021_FOOD_CONS.dta", clear
	use "${temp}\HCES2015sample_FOOD_CONS.dta", clear


	* 1.1 check measurement and stunit
	tab MEASURE
	//ISSUE 2: missing measurement
	/*preserve
		keep if MEASURE == 99
		export excel using "${path}\issue\issue_general.xlsx", sheet("MEASURE") sheetmodify firstrow(variables) 
	restore*/
	

	* 1.2 check the stunit for different measurement
	* 1.2.1 Gram, the stunit should not be larger than 1000
	cap assert STUNIT <= 1000 if MEASURE == 1
	if (_rc){
		tab STUNIT if MEASURE == 1 //the regular STUNIT for Gram should be 1000, however they are quite a few obs have more than 10000 as STUNIT
		//ISSUE 3: extreme stunit
		/*preserve
			keep if MEASURE == 1 & STUNIT > 1000
			export excel using "${path}\issue\issue_general.xlsx", sheet("stunit_g") sheetmodify firstrow(variables) 
		restore*/
	}
	
	* 1.2.2 Cubic Centermetter, the stunit should not be large than 1000
	cap assert STUNIT <= 1000 if MEASURE == 3
	if (_rc) {
		tab STUNIT if MEASURE == 3
		//ISSUE 4: extreme stunit
		/*preserve
			keep if MEASURE == 3 & STUNIT > 1000
			export excel using "${path}\issue\issue_general.xlsx", sheet("stunit_cc") sheetmodify firstrow(variables) 
		restore*/
	}
	
	* 1.2.3 kg
	cap assert STUNIT <= 1 if MEASURE == 20
	if (_rc) {
		tab STUNIT if MEASURE == 20
		//ISSUE 5: extreme stunit
		/*preserve
			keep if MEASURE == 20 & STUNIT > 1
			export excel using "${path}\issue\issue_general.xlsx", sheet("stunit_kg") sheetmodify firstrow(variables) 
		restore*/
	}
	
	* 1.2.4 number/services: should have stunit as 1
	cap assert STUNIT == 1 if MEASURE == 4     //STUNT is 1 when measurement is Number
	if (_rc) {
		tab STUNIT if MEASURE == 4
		//ISSUE 6: extreme stunit
		/*preserve
			keep if MEASURE == 4 & STUNIT != 1
			export excel using "${path}\issue\issue_general.xlsx", sheet("stunit_number") sheetmodify firstrow(variables) 
		restore*/
	}	
	
	
	assert STUNIT == 1 if MEASURE == 21    //STUNT is 1 when measurement is services
	if (_rc) {
		tab STUNIT if MEASURE == 21
		//ISSUE 7: extreme stunit
		/*preserve
			keep if MEASURE == 21 & STUNIT != 1
			export excel using "${path}\issue\issue_general.xlsx", sheet("stunit_service") sheetmodify firstrow(variables) 
		restore*/
	}	
	
	* 1.3 convert quantity to standard unit
	gen ann_quant_st = ann_quant/STUNIT //standard unit is kg/l or items
	
	* 1.4 generate class
	gen class = 1 if MEASURE == 1 | MEASURE == 3 | MEASURE == 20
	replace class = 2 if class == .
	label define class 1 "kg/l" 2 "piece"
	label values class class //each item have one class only
	
	preserve
		keep itemc class
		duplicates drop
		cap isid itemc
		if (_rc) di in y "item in the survy my with different class"
		else	 di in y "item have a unique class"
	restore
	
*==============================================================================
*   2. Outliers
*==============================================================================

	gen log_quant = log10(ann_quant_st/hh_size)  //log per capita
	gen log_value = log10(ann_value/hh_size)

	
	* 2.1 Large quantity
	flagout log_quant [pw=weight_hh], item(itemc)
	ren _flag qunat_flag
	//ISSUE 8: large quantity 
	/*preserve
		keep if qunat_flag != 0
		keep hhid hh_size major itemc TYPE SOURCE MEASURE ann_value ann_quant ann_quant_st
		export excel using "${path}\issue\issue_general.xlsx", sheet("large quantity") sheetmodify firstrow(variables) 
	restore*/

	* 2.2 Large value
	flagout log_value [pw=weight_hh], item(itemc)
	ren _flag value_flag
	//ISSUE 9: large quantity 
	/*preserve
		keep if qunat_flag  1= 0
		keep hhid hh_size major itemc TYPE SOURCE MEASURE ann_value ann_quant ann_quant_st
		export excel using "${path}\issue\issue_general.xlsx", sheet("large value") sheetmodify firstrow(variables) 
	restore*/

*==============================================================================
*   2. UNIT PRICE - clean
*==============================================================================
	
	* 2.1 construct per kg/L or piece prices
	gen p = ann_value/ann_quant_st

	* 2.2 outliers in prices based on standard method
	flagout p [pw = weight_hh], item(itemc) z(${z})
	rename _flag p_flag

	
	* 2.3 percentiles of prices, quantities in kg and in piece
	gen n = 1
	preserve
		collapse (p25) p_p25 = p q_p25 = ann_quant_st (p75) p_p75 = p q_p75 = ann_quant_st (rawsum) n [pw = weight_hh], by(itemc)
		tempfile pctiles
		save `pctiles'
	restore
	merge m:1 itemc using `pctiles', assert(match) nogen

	* 2.4 classify by percentile of price
	gen pclass = 0 if p < .  
	replace pclass = -1 if p < p_p25 & n >= ${nmin}
	replace pclass =  1 if p > p_p75 & n >= ${nmin}

	* 2.5 classify by percentile of quantity
	gen qclass = 0 if ann_quant_st < .
	replace qclass = -1 if ann_quant_st < q_p25 & n >= ${nmin}
	replace qclass =  1 if ann_quant_st > q_p75 & n >= ${nmin}

	* 2.6 look at crosstabs
	tab pclass qclass

	* 2.7 drop prices if price is unusually high and quantity unusually low or vice versa
	replace p = . if pclass ==  1 & qclass == -1
	replace p = . if pclass == -1 & qclass ==  1

	* 2.8 also drop prices originally identified as outliers using flagout
	replace p = . if p_flag == 1 | p_flag == -1
	
	* 2.9 clean up and save
	// all data
	tempfile data
	save `data', replace
	
	// purchase data only
	keep if TYPE == 1 //keep pay in cash
		
	tempfile maindata
	save `maindata'

*******************************************************************************
*        3. Unit price at local market level                                  *
*******************************************************************************

	keep if p > 0 & !mi(p)

	* 3.1 define levels for aggregation and minimum number of observations needed
	gen national = 1
	local l0 national
	local l1 region
	local l2 REP
	
	* 3.2 construct median and mean price at each level of aggregationitm
	gen x = 1  // to use with rawsum in collapse to count observations
	forval i = 0/2 {
		preserve
			collapse (p50) pa_`i' = p (mean) pb_`i' = p (rawsum) N`i' = x [pw = weight_hh], by(itemc `l`i'')
			assert pa_`i' != .
			tempfile f`i'
			save `f`i''
		restore
	}
	//pa = median, pb = mean

	* 3.3 construct framework dataset of each possible REP-item
	use `data', clear
	keep REP itemc region
	duplicates drop
	count
	fillin itemc REP region // rectangularize the data set
	sort itemc _fillin
	drop _fillin
	
	* 3.4 merge in prices at all levels
	gen national = 1
	forval i = 0/2 {
		merge m:1 itemc `l`i'' using `f`i'', nogen
	}

	* 3.5 take as the local price the price at the lowest level with the minimum # of obs
	*assert pa_0 < . // have obs without any national prices
	gen pa_h = pa_0
	gen pb_h = pb_0
	gen level = 0
	forval i = 1/2 { //replace national price with lower lever price if they are not missing (province price first, then province-urban/rural price) (HW)
		replace pa_h = pa_`i' if pa_`i' < . & N`i' >= ${nmin} 
		replace pb_h = pb_`i' if pb_`i' < . & N`i' >= ${nmin} 
		replace level = `i' if pa_`i' < . & N`i' >= ${nmin}
	}

	lab def levs 0 "national" 1 "region" 2 "REP" 
	lab val level levs

	drop national
	lab var N0   "# of obs for itemc at national level"
	lab var N1   "# of obs for itemc at regional level"
	lab var N2   "# of obs for itemc at REP level"
	
	lab var pa_0 "national median price"
	lab var pb_0 "national mean price"
	lab var pa_h "local (to strata) median price"
	lab var pb_h "local (to strata) mean price"
	lab var level "level at which price was constructed"

	tempfile ph
	save `ph'

	**** 3. Weighted National Prices ***********************************************

	**  a. sum of weights by province-urban-quarter
*	use "${temp}\NISH2021_FOOD_CONS.dta", clear
	use "${temp}\HCES2015sample_FOOD_CONS.dta", clear
	keep if TYPE == 1
	keep hhid weight_hh REP
	duplicates drop
	isid hhid
	collapse (sum) weight_domain = weight_hh, by(REP)

	**  b. construct national price as weighted average of province-urban prices
	merge 1:m REP using `ph', assert(match) nogen
	collapse (mean) pa_0_wmean = pa_h pb_0_wmean = pb_h [pw = weight_domain], by(itemc)
	merge 1:m itemc using `ph', assert(match) nogen

	**  c. look at correlation
	corr pa_0 pa_0_wmean
	sum pa_0 pa_0_wmean
	corr pb_0 pb_0_wmean
	sum pb_0 pb_0_wmean

	**  d. clean up and save
	lab var pa_0_wmean "national weighted mean of medians price"
	lab var pb_0_wmean "national weighted mean of means price"
	order item pa_h pb_h pa_0 pa_0_wmean pb_0 pb_0_wmean

	save "${temp}\ph.dta", replace
*/
*******************************************************************************
*        4. Final touch                                                       *
*******************************************************************************
	**  i. clean up and save
	use `data', clear
	
	merge m:1 itemc REP region using "${temp}\ph.dta"
	drop if _merge == 2
	drop _merge
	
	corr pa_h p if TYPE != 1
	corr pa_0_wmean p if TYPE != 1
	corr pb_h p if TYPE != 1
	corr pb_0_wmean p if TYPE != 1
	
	gen cons_food_impute = ann_quant_st*pa_h //you can use other price here
	
	sum cons_food_impute, d
	
	* 4.2 final food consumption
	gen cons_food = ann_value
	sum cons_food, d
	
	**  c. address upper outliers at itemc Level
	gen logpcval = log(cons_food/hh_size)
	flagout logpcval [pw = weight_hh*hh_size], item(itemc) z($z)
	replace cons_food = hh_size * exp(_max) if _flag == 1 // winsorize upper outliers
	rename _flag full_flag //(HW) update 
	
	**  f. impute missing values with mddian for the rest item. 
	replace cons_food = hh_size * exp(_med) if cons_food == .
	
	** use imputed comsumption for not-purchase case 
	replace cons_food = cons_food_impute if TYPE != 1
	lab var cons_food "annulized nominal food consumption"

*	save "${temp}\NISH2021_FOOD_CONS_detail.dta", replace
	save "${temp}\HCES2015sample_FOOD_CONS_detail.dta", replace

	
*==============================================================================
*   2. Categorize the food items
*==============================================================================		
		
	recode itemc                                                             ///
	(1/3 101/103					=1 "Teff")                               ///
	(4/6 17/20 104/106		            	                                 ///
	41 47 71 74						=2 "Wheat")                              ///
	(12 21 25/26 34 44 49/52 72 111 =3 "Maize")                              ///
	(7/11 13/16 22/24 27/33 35/40 			                                 ///
	42/43 45/46 48 53/70 73 75/98      		                                 ///
	107/110 112/198 		  		=4 "Other cereals")                      ///
	(201/498						=5 "Pulses")                             ///
	(601/698      					=6 "Pasta")                              ///
	(701/798						=7 "Bread and other prepared food")      ///
	(801/898						=8 "Meat")                               ///
	(901/998						=9 "Fish")                               ///
	(1001/1098						=10 "Milk, Cheese, and Egg")             ///
	(1101/1198 501/598				=11 "Oils and fats")                     ///
	(1201/1298						=12 "Vegetables")                        ///
	(1301/1398						=13 "Fruits")                            ///
	(1501/1598						=14 "Potatoes, other Tubers, and Stems") ///
	(1601/1698						=15 "Coffee, Tea, Chat, and Buck-thorn leaves") ///
	(1401/1498						=16 "Spices")                            ///
	(1701/1798 	 					=17 "Sugar, Salt, and others")           ///
	(2201/2298   					=18 "Nonalcoholic beverages")            ///
	(1801/1998 2001/2198    		=19 "Food away from home")               ///
	(2401/2498                      =20 "Other food")                        /// NOT FOOD, IT IS SERVICES
	, gen(food_group)
	lab var food_group "Food expenditure groups" 
	label values food_group food_group
	*note: fafh includes food (11201101/11202198) and non-alcoholic beverages (12201101/12202301)
	*note: other food includes milling services, baking services, butchering services, winowing/splitting/grinding services charges 
		 
	forvalues i=1(1)20 {
		gen exp_`i' = 0
		replace exp_`i' = cons_food if food_group==`i' //use actual consumption for purchase case
	 }
	 
	* Expenditure from school feeding      
	gen school_feed_sfp=0
*	gen food_exp_sfp   = cons_food if school_feed_sfp==1 // food cons from SFP 
	gen food_exp_wosfp = cons_food if school_feed_sfp==0 // food cons exp excl. SFP 
	
	
	* COLLAPSE EVERYTHING TO HOUSEHOLD LEVEL      
	collapse (sum) cons_food exp_* food_exp_*, by(hhid weight_hh)
	ren cons_food foodexp 
	s
	* Total expenditure by food group (nominal) per year 
	ren (exp_1 exp_2 exp_3 exp_4 exp_5 exp_6 exp_7 exp_8 exp_9 exp_10 exp_11 exp_12 exp_13 exp_14 exp_15 exp_16 exp_17 ///
		exp_18 exp_19 exp_20) ///
	    (exp_teff exp_wheat exp_maize exp_cereal exp_pulse exp_pasta exp_bread exp_meat exp_fish exp_milk  ///
		 exp_fats exp_veget exp_fruit exp_potat exp_coffee exp_spice exp_sugar exp_nonalc exp_fafh exp_othf)

	lab var foodexp            "food expenditure"
	lab var exp_teff           "expenditure on teff"
	lab var exp_wheat  		   "expenditure on wheat"
	lab var exp_maize 		   "expenditure on maize"
	lab var exp_cereal         "expenditure on other cereals and grains"
	lab var exp_pulse          "expenditure on pulses"
	lab var exp_pasta 		   "expenditure on pasta"
	lab var exp_bread          "expenditure on bread and prepared food"
	lab var exp_meat  		   "expenditure on meat and fish"
	lab var exp_fish           "expenditure on fish and sea food"
	lab var exp_milk           "expenditure on milk, cheese, and eggs"
	lab var exp_fats           "expenditure on fats and oils"
	lab var exp_veget          "expenditure on vegetables"
	lab var exp_fruit          "expenditure on fruits"
	lab var exp_potat          "expenditure on root crops"
	lab var exp_coffee         "expenditure on coffee, tea, and related"
	lab var exp_spice          "expenditure on spices"
	lab var exp_sugar          "expenditure on sugar, salt, and related"
	lab var exp_nonalc         "expenditure on nonalcoholic beverages"
	lab var exp_fafh           "expenditure on food away from home"
	lab var exp_othf           "expenditure on other food (services)"
*	lab var food_exp_sfp       "food cons from school feeding"
    lab var food_exp_wosfp     "food cons excluding school feeding"
    preserve 
		* Calories 
		*use "${temp}\NISH2021_FOOD_CONS.dta", clear
		use "${temp}\HCES2015sample_FOOD_CONS.dta", clear

		gen school_feed_sfp=0
		gen netcal_sfp   = netcal if school_feed_sfp==1
		gen netcal_wosfp = netcal if school_feed_sfp==0
		collapse (sum) netcal* , by(hhid)
		lab var netcal       "total annual calories (HH)"
		lab var netcal_sfp   "total annual calories from SFP (HH)"
		lab var netcal_wosfp "total annual calories excluding SFP (HH)"
		tempfile calorie
		save `calorie'
	restore 
	
	merge 1:1 hhid using `calorie', nogen keep(1 3)
	compress 
*	save "${out}\NISH2021_FOOD_CONS.dta", replace
	save "${out}\HCES2015sample_FOOD_CONS.dta", replace
	
	//graph checking
	
	gen logfconsimpute = log10(foodexp)
	tw histogram logfconsimpute [fw = round(weight_hh)], lalign(inside) width(0.05) ///
    || normal logfconsimpute [fw = round(weight_hh)], legend(off) ///
       ysca(off) title("Food consumption NISH2015sample")
	
