  
*=============================================================================
*Project:       Ethiopia Poverty Measurement Training 2025
*Author: 	    Haoyu Wu
*Create Date:   8/15/2025
*Modify Date:   8/18/2025
*Data source:   HoWStat combines HCES and WMS (2021) and conducted by the        
*		        Ethiopian Statistics Services (ESS)  
*=============================================================================
	
*==============================================================================
*   NONFOOD CONSUMPTION
*============================================================================


	******************************************************
	*[4] <<<<<<<<<< Consumption flow from durables >>>>>>>>>>>*
	*******************************************************
	
	*The following was part of the initial data cleaning 
	
	use "$raw/WMS 2021/WMS 2022 HH Level Data.dta", clear	
    
	* Generate unique household ID  
	tostring wq11, gen(r) format(%02.0f) 
	tostring wq12, gen(z) format(%02.0f) 
	tostring wq13, gen(w) format(%02.0f) 
	tostring wq14, gen(t) format(%01.0f) 
	tostring wq15, gen(s) format(%02.0f) 
	tostring wq16, gen(k) format(%02.0f) 
	tostring wq17, gen(e) format(%02.0f) 
	tostring id202, gen(f) format(%03.0f) 
	tostring wq18, gen(b) format(%06.0f)
	egen hhid = concat(r z w t s k e f b)
	drop r z w t s k e f b
	replace hhid = "1" + hhid 
	lab var hhid "Household identifier"
	order hhid
	isid hhid 
	
	* Bring household domain variables 
	merge m:1 hhid using "${temp}/hces_hh_data_2021.dta", nogen keep(1 3)
	

	
	* Clean and keep the assets variables
	* Restructure the data for durable items
	* 8201, 8203: asset types
	* 8204: how many owns
	* 8205: length of the ownership
	* 8206: purchase price
	* 8207: resale price
	foreach x in wq8201 wq8203 wq8204 wq8205 wq8206 wq8207 {
		forvalues i=1/9 {
			ren `x'_0`i' `x'_`i' 
		}
	}	
		
	reshape long wq8201_ wq8203_ wq8204_ wq8205_ wq8206_ wq8207_, i(hhid) j(asset)
		
	*Rename variables 
	ren wq8201_ asset_type 
	ren wq8203_ asset_yesno 
	ren wq8204_ asset_quant 
	ren wq8205_ asset_ageyrs 
	ren wq8206_ asset_pprice 
	ren wq8207_ asset_curval

	*Label variables 
	lab var asset_type    "asset type"
	lab var asset_yesno   "asset possession dummy"
	lab var asset_quant   "asset quantity"
	lab var asset_ageyrs  "asset age in years"
	lab var asset_pprice  "asset purchase price"
	lab var asset_curval  "asset current sale price"

	*Check price and current value missing values 	

	tabstat asset_quant asset_ageyrs asset_pprice asset_curval , by(asset_type) stat(mean p50 min max)



	*Which assets to include in the calculations?
	gen durable = (inrange(asset_type, 8,28) | inrange(asset_type, 38,41) | inrange(asset_type, 45,47))
	    
	/*
	 lablist asset_type
			1 Mofer and Kember?
			2 Sickle (Machid)/'Mencha'
			3 Axe (Gejera)
			4 Pick axe (Geso)
			5 Plough (traditional)
			6 Plough (modern)
			7 Water pump
			8 Kerosene stove
			9 Butane Gas stove
			10 Electric stove
			11 Blanket/Gabi
			12 Mattress and/or Bed
			13 Wrist watch/clock
			14 Iron (coal)
			15 Electric Iron
			16 Fixed line telephone
			17 Wireless Telephone
			18 Mobile Telephone/Tablet
			19 Desktop/Laptop Computer
			20 Radio/tape/Radio and tape
			21 Television
			22 Video Deck
			23 VCD/DVD/G-PASS
			24 Dish
			25 Sofa set
			26 Chair and table (excluding stool and bench)
			27 Bicycle
			28 Motor cycle
			29 Cart (Hand pushed)
			30 Cart (animal drawn)- for transporting people	& goods
			31 Sewing machine
			32 Weaving equipment
			33 Builder?s equipment
			34 Carpenter?s equipment
			35 Welding equipment
			36 Wood cutting equipment
			37 Block production equipment
			38 Mitad-Electrical
			39 Mitad-power saving (modified)
			40 Refrigerator
			41 Private car
			42 Car-Commercial
			43 Bajaj
			44 Jewels (Gold and silver)
			45 Wardrobe
			46 Shelf for storing goods
			47 Biogas stove (pit)
			48 Water storage pit
			49 Others (specify)
		 */
		 
	* data check
	
	recode asset_pprice (9999999=.)
	recode asset_ageyrs (25/99=25) (0 = 0.5) //0 years as 0.5, over 25 as 35 (recommend)
	
	count if asset_pprice < asset_curval & !mi(asset_pprice) & !mi(asset_curval)
	//ISSUE 11: resale values higer than purchase value
	/*preserve
		keep if asset_pprice < asset_curval & !mi(asset_pprice) & !mi(asset_curval)
		export excel using "${path}\issue\issue_general.xlsx", sheet("durables_issue") sheetmodify firstrow(variables) 
	restore*/
     
	 //If not treatment, the depreciation rate will be replaced as the regional median (HW)
	
	*Identify and treat asset price/value outliers 

	* Generate asset purchase price outlier flag
    gen ln_asset_pp = log(asset_pprice) 
	flagout ln_asset_pp [pw=weight_hh], item(asset_type) over(region REP) z(${z})
	ren _flag pprice_flag
	/*

		  _flag |      Freq.     Percent        Cum.
	------------+-----------------------------------
		  lower |      3,275        1.38        1.38
	 nonoutlier |    231,563       97.61       98.99
		  upper |      2,360        0.99       99.99
			  . |         27        0.01      100.00
	------------+-----------------------------------
		  Total |    237,225      100.00

	*/
		
	*asset current values 
	gen ln_asset_cval = log(asset_curval)
	flagout ln_asset_cval [pw=weight_hh], item(asset_type) over(region REP) z(${z})
	ren _flag cval_flag
	/*
      _flag |      Freq.     Percent        Cum.
------------+-----------------------------------
      lower |      2,316        0.98        0.98
 nonoutlier |    231,498       98.23       99.21
      upper |      1,825        0.77       99.99
          . |         27        0.01      100.00
------------+-----------------------------------
      Total |    235,666      100.00
	*/
	
	keep hhid wq11 - weight_hh asset_type - cval_flag durable
	save "${temp}/assets_clean.dta", replace  
    
	
	// Estimate depreciation rate

	* Method 1 - The methodology is described in M&V (2022) 
    use "${temp}/assets_clean.dta", clear 

	*weights 
	local wgt = weight_hh
	
	*other variables
	gen double ptmk = asset_pprice
	label var ptmk "price paid in year t- k"
	
	gen double k = asset_ageyrs  
	label var k "no of complete years owned"

	*inspect age   
    *tabstat k [aw=weight_hh], by(asset_type) s(mean median min max count) format(%9.2f)  
	
	*Check current market value and purchase price - pt should be lower than or equal to ptmk (goods depreciate overtime)
	gen double pt = asset_curval 
	lab var pt "current market value"
	
	*tabstat pt ptmk [aw=weight_hh], by(asset_type) s(mean) format(%9.0f)
	count if pt>ptmk & pt!=. // 42,506 cases!
	gen price_diff = ptmk - pt
	*tabstat price_diff , by(asset_type) s(mean) format(%9.0f) // high difference for car, which makes sense! 

	*Depreciation rate estimated at the household level, separately by durable
	gen double drate = 1 - (pt/(ptmk*(1+${inf})^k))^(1/k)
	lab var drate "depreciation rate"
	
	*Inspect deterioration rates
	*tabstat drate, by(asset_type) s(mean median min max count) format(%9.2f)  
	
	*We are going to use national level median deterioration rates
	preserve
		replace drate = . if drate >= 1
		replace drate = . if drate < 0
		collapse (median) dratem=drate [aw=weight_hh] , by(asset_type durable)  
		
		assert dratem >= 0

		*tabstat dratem if durable==1, by(asset_type) s(mean) format(%9.2f) save 
		save "${temp}/dratem", replace
	restore
    
	merge m:1 asset_type using "${temp}/dratem"
	drop _m
		
	// Estimate consumption flow
	ren asset_quant dur_no
	label var dur_no "total number of durables"
	
	*The asset types to include
	//CF1: use by NSO
	gen double cf_dur_1 = [(pt * (${int}- ${inf} + dratem))]*durable
	//if dratem rate is lower than 28%, the ${int}- ${inf} + dratem will be negative
	label var cf_dur_1 "estimated unit consumption flow from durable goods (NSO)"

	//CF2: REVISED
	gen a = dratem*${inf}
	sum a 
	// a is not zero, then the pi*deprate != 0
	gen double cf_dur_2 = [(pt * (${int}- ${inf} + dratem + dratem*${inf}))]*durable

	//zero or negative CF (use the item_level median unit cf)
	preserve
		collapse (p50) cf_dur_1_med = cf_dur_1 if cf_dur_1 >0 & cf_dur_1<., by(asset_type)
		tempfile data
		save `data', replace
	restore
	
	preserve
		collapse (p50) cf_dur_2_med = cf_dur_2 if cf_dur_2 >0 & cf_dur_2<., by(asset_type)
		tempfile data2
		save `data2', replace
	restore
	
	merge m:1 asset_type using `data', assert(1 3) nogen
	merge m:1 asset_type using `data2', assert(1 3) nogen
	
	replace cf_dur_1 = cf_dur_1_med if cf_dur_1 <= 0 & !mi(cf_dur_1_med)
	replace cf_dur_2 = cf_dur_2_med if cf_dur_2 <= 0 & !mi(cf_dur_2_med)

	replace cf_dur_1 = dur_no * cf_dur_1
	replace cf_dur_2 = dur_no * cf_dur_2

	
	//ISSUE 12: high CF duarble goods
	/*preserve
		keep if cf_dur_2 > 10000 & !mi(cf_dur_2)
		export excel using "${path}\issue\issue_general.xlsx", sheet("cf_dura_issue") sheetmodify firstrow(variables) 
	restore*/

	* Method 2 - age based depreciation 
	* regressing average price with respect to average age
	gen lnptmk = ln(ptmk) 
	label var lnptmk "Log of rent value Birr"

	gen drate2=.
	levels asset_type if durable == 1, local(levels)
	foreach l of local levels {
		tempvar ok xb
		gen `ok' = asset_type==`l'
		qreg lnptmk k if `ok'==1 
		replace drate2 = 1 - exp(r(table)[1,1]) if `ok'==1
		summ drate2 if `ok'==1
		count if `ok'==1
		drop `ok'
	}

	gen cf_dur_3 = dur_no*ptmk*drate2/(1+drate2)
	
	tabstat cf_dur_1 cf_dur_2 cf_dur_3 if durable == 1 [aw=weight_hh], by(asset_type) s(mean median min max) format(%9.2f)
		
   	*Collapse to household
	collapse (sum) cf_dur_1 cf_dur_2 cf_dur_3 (first) weight_hh, by(hhid)
	keep hhid cf_dur_1 cf_dur_2 cf_dur_3
	*lab var cf_dur "consumption flow from durables (Birr per year)"
	qui compress
			
	gen cf_dur = cf_dur_1
	replace cf_dur = cf_dur_2 if cf_dur_1 < 0

	label var cf_dur_1 "estimated cf for durable goods (NSO)"
	label var cf_dur_2 "estimated cf for durable goods (Revised)"
	label var cf_dur_3 "estimated cf for durable goods (regression)"
	label var cf_dur_3 "estimated cf for durable goods (combine 1 and 2)"
	
	save "${out}\NISH2021_DURABLE_CONS.dta", replace 
