  
*=============================================================================
*Project:       Ethiopia Poverty Measurement Training 2025
*Author: 	    Haoyu Wu
*Create Date:   8/8/2025
*Modify Date:   8/26/2025
*Data source:   HoWStat combines HCES and WMS (2021) and conducted by the        
*		        Ethiopian Statistics Services (ESS)  
*=============================================================================

*==============================================================================
*   1. DATA CLEAN - geographic and demographic  
*==============================================================================	
	use "$raw/HCES_rawdata_final.dta", clear

	//1.1 BROWSE THE DATA
	des
	sum
	
	//1.2 Generate unique household identifier
	cap ren hhid hhid_orig
	tostring RWQ11, gen(hid_1) format(%02.0f) 
	tostring RWQ12, gen(hid_2) format(%02.0f) 
	tostring RWQ13, gen(hid_3) format(%02.0f) 
	tostring RWQ14, gen(hid_4) format(%01.0f) 
	tostring RWQ15, gen(hid_5) format(%02.0f) 
	tostring RWQ16, gen(hid_6) format(%02.0f) 
	tostring RWQ17, gen(hid_7) format(%02.0f) 
	tostring RID202, gen(hid_8) format(%03.0f) 
	tostring RWQ18, gen(hid_9) format(%06.0f)
	egen hhid = concat(hid_1 hid_2 hid_3 hid_4 hid_5 hid_6 hid_7 hid_8 hid_9)
	drop hid_1 hid_2 hid_3 hid_4 hid_5 hid_6 hid_7 hid_8 hid_9
	replace hhid = "1" + hhid 
	lab var hhid "Household identifier"
	order hhid
			
	//1.3 Rename variables of interest 
	ren RWQ11 region 
	ren RWQ12 zone
	ren RWQ13 woreda
	ren RWQ14 town
	ren RWQ15 subcity
	ren RWQ16 kebele
	ren RWQ17 EA
	ren WQ19  hh_size
	ren ADEQ  adulteq
	
	//1.4 FIX THE DESCRIPTION
	label var REP           "reporting level/strata"
	label var region        "Region/admin1"
	label var zone          "Zone/admin2"
	label var woreda        "Wereda Code/admin3"
	label var town          "Town Code"
	label var subcity       "Sub-city/Wereda Code"
	label var kebele        "Kebele Code/admin4"
	label var EA            "Enumeration Area Code"
	label var hh_size       "household size"
	label var adulteq       "Adult Equivalent factor"
	label var NETCAL        "total net calories per household"
	label var FOOD          "food nonfood dummy"
	label var ANNUAL_QUANT   "annual quantity"
	label var ITEMC			"item code"
	label var ANNUAL_VALUE  "annual expenditure value"
	
	//1.5 Sampling and population weights
	total WGT_WEIGHT
	//WGT_WEIGHT is 100 times larger than it should be
	gen weight_hh = WGT_WEIGHT/100
	lab var weight_hh "sampling houshold weights" 
	gen weight_pop = weight_hh*hh_size
	lab var weight_pop "population weight"
	drop WGT_WEIGHT 
	clonevar rate = RATE_RATE
	
	//1.6 Save HH level data
	preserve 
		keep  weight_hh REP - EA hh_size adulteq rate hhid
		duplicates drop hhid, force 
		save "$temp/hces_hh_data_2021.dta", replace  
	restore  
	
*==============================================================================
*   2. Basic information about the data/confirmed
*==============================================================================				
								
	*2.1 Basic information
	cap unique hhid
	di in g "# of household: " in y r(unique)

	cap unique MAJOR
	di in g "# of major items: " in y r(unique)

	cap unique ITEMC
	di in g "# of detailed items: " in y r(unique)

	*2.2 First round checking (missing/negative/zeros)
	 *2.2.1 Quantity (ANNUAL_QUANT) and value (ANNUAL_VALUE)
	 foreach v of varlist ANNUAL_QUANT ANNUAL_VALUE{
		di in y "checking `v'"
		qui count if `v' < 0
		di in g "# of negative: " in y r(N)
		qui count if mi(`v')
		di in g "# of missing: " in y r(N)
		qui count if `v' == 0
		di in g "# of zeros: " in y r(N)
		replace `v' = . if `v' == 0  //Zero2Miss: 3 ANNUAL_QUANT, 1 ANNUAL_VALUE
	 }
	 qui count if mi(ANNUAL_QUANT) & mi(ANNUAL_VALUE)
	 di in g "# of missing quantity and missing value: " in y r(N) //should be dropped
	 drop if mi(ANNUAL_QUANT) & mi(ANNUAL_VALUE)
	 *!!!!!!!DROP 1: 977 obs drop (missing ANNUAL_QUANT and ANNUAL_VALUE)!!!!!!!
	 drop if mi(ANNUAL_QUANT)
	 *!!!!!!!DROP 2: xxx obs drop (missing ANNUAL_QUANT)                 !!!!!!!
	 
	 qui count if mi(ANNUAL_QUANT) & !mi(ANNUAL_VALUE)
	 di in g "# of missing quantity, but NOT missing/zero value: " in y r(N)
	 qui count if mi(ANNUAL_VALUE) & !mi(ANNUAL_QUANT)
	 di in g "# of missing value, but NOT missing/zero quantity: " in y r(N)

	 *2.2.2 Prices (STPRICE) in the data are standard unit prices 
	 qui count if STPRICE==. 
	 di in g "# of missing standard price: " in y r(N)
	 qui count if STPRICE==0 
	 di in g "# of zero standard price: " in y r(N)
	 replace STPRICE = . if STPRICE==0   //Zero2Miss: 3 STPRICE
*==============================================================================
*   3. Special treatment
*==============================================================================	
	* 3.1 Food and nonfood dummy adjustment
	 replace FOOD = 2 if MAJOR==23     // Alcoholic drinks to non-food 
	 replace FOOD = 1 if MAJOR==24     // food preparation services to food, part of food agg in 2015/16  
	 replace FOOD = 2 if ITEMC==1608   // Chat 
	 replace FOOD = 2 if ITEMC==1607   // buck-thorn leaves/hope 
	 replace MAJOR = 26 if ITEMC==1608 | ITEMC==1607  // Chat and hopes to Narcotics/Tobacco major group  

	*3.2 variable name adjustment
	ren (ANNUAL_VALUE ANNUAL_QUANT FOOD ITEMC MAJOR NETCAL)  ///
		 (ann_value ann_quant food_dummy itemc major netcal)

	*3.3 Check data duplicates ! 
	duplicates tag hhid itemc FID TYPE SOURCE ann_quant, gen(dup_tag)
	
	//ISSUE 1: DUPLICATES
	/*preserve
		keep if dup_tag ! = 0
		export excel using "${path}\issue\issue_general.xlsx", sheet("duplicates_all") sheetmodify firstrow(variables) 
	restore*/
	
	duplicates drop hhid itemc FID TYPE SOURCE ann_quant , force 
	//before the data checked, we need to drop the duplicates
	*!!!!!!!DROP 3: xxx obs drop (duplicates)                 !!!!!!!
	
	*3.4 School Feeding Program (SFP) Operated in AA (1170 households, 25.6% of the HHs in AA) - check how significant that was 
	*3.4.1 Captured in the data: ENUM_CODE 999 and SOURCE 62 
	ta itemc if ENUM_CODE==999 & TYPE==2 & SOURCE==62 & food_dummy==1 & region==14 // 56,100
	gen school_feed_sfp = (ENUM_CODE==999 & TYPE==2 & SOURCE==62 & food_dummy==1 & region==14)
	lab var school_feed_sfp "SFP: food"

	*3.4.2 Transport allowance of 2837.51 Birr per person per year (Bus fare (within town)): made for 829 HHs in AA 
	gen trans_allow_gov = (itemc==10702 & SOURCE==62 & TYPE==2 & ENUM_CODE==999 & region==14) 
	lab var trans_allow_gov "transport allowance"
	
	*3.4.3 School Uniform 
	gen school_unif_sfp = (itemc==77101 & SOURCE==62 & TYPE==2 & ENUM_CODE==999 & region==14) 
	lab var school_unif_sfp "SFP: school uniform"
	
	*3.4.4 Walking shoes (imported)
	gen walk_shoes_sfp = (itemc==20810 & SOURCE==62 & TYPE==2 & ENUM_CODE==999 & region==14) 
	lab var walk_shoes_sfp "SFP: shoes"

	*3.4.5 Exercise books 
	gen exbook_sfp = (itemc==70402 & SOURCE==62 & TYPE==2 & ENUM_CODE==999 & region==14) 
	lab var exbook_sfp "SFP: exercise books"

	*3.4.6 Any SFP (food or nonfood)
	gen sfp_any = (ENUM_CODE==999 & SOURCE==62 & TYPE==2 & region==14)

*==============================================================================
*   4. Split data into food and nonfood
*==============================================================================
	preserve 
		keep if food_dummy == 1
		drop NONFOODEXP 
		drop food_dummy dup_tag
		save "${temp}\NISH2021_FOOD_CONS.dta", replace
	restore
	
	preserve
		keep if food_dummy != 1 
		drop food*
		drop Foodexp
		drop dup_tag
		save "${temp}\NISH2021_NONFOOD_CONS.dta", replace
	restore
	