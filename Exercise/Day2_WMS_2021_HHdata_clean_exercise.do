
	*=============================================================================
	*Project:       Ethiopia Poverty Measurement Training 2025
	*Author: 	    Haoyu Wu
	*Create Date:   8/8/2025
	*Modify Date:   8/24/2025
	*Subject:       Day 2: Data Cleaning - Household level
	*=============================================================================

	*Note: Data source
	*Welfare Monitoring Survey (WMS) 2020/21
	*for Ethiopia were collected by the Ethiopia Central Statistical Agency (CSA) 
	*Throughout the do-file, we sometimes use the shorthand WMS to refer to Welfare Monitoring Survey

	// =========================================================
	// A. Demographics            
	// =========================================================

	use "$raw\WMS 2021\WMS 2022 HH Level Data.dta", clear	


	*A1. Generate unique household ID  
	//hint: Region + zone + wereda + town + subcity + kebele + EA + Housing serial Number + Hh Sample Selection Sr.No.

	lab var hhid "Household identifier"

	*A2. rural/urban
	//hint: rural/urban variable from HCES data "$rawdata/HCES_rawdata_final.dta"

	lab define rur 1 "Urban"  2 "Rural", replace
	lab val ur rur
	lab var ur "Rural/urban identifier"

	*A3. weight
	// hint1: check the total and consider rescale or not 
	//A3.1 household weight


	//A3.2 population weight


	*A4. location variables
	//hint: Rename variables to get what you need

	

	* A4.1 Population distribution by region and location
	// hint: table (region), statistic()

	*===================================================
	*B. Housing
	*===================================================

	*B1. Number of years lived in current dwelling 
	//hint: q5102_years/wq5102_months 
	//      months should list between 1 to 12
	//      year should be not missing, 0? 99?
	//      outliers? winsorize?


	*B2. Ownership type of dwelling
	//hint: wq5103	
	//		Maybe recode to make it more readable
	//      Maybe can distiguish rent or own?


	*B3. Number of rooms/bedroom
	//hint: wq5104a, wq5104b
	//      not zero
	//      watch out carzy numbers
	//      bedroom < nooms
	


	*B4. Dwelling construction materials
	*B4.1 Wall
	//hint: wq5105
	//      can generate improved wall: wall made up of stone and cement, blocks-plastered with cement, and bricks

	*B4.2 roof
	//hint: wq5106
	//     improved roof -  corrugated iron sheet or concrete/cement

	*B4.2 roof
	//hint: wq5107
	//      improved floor- floor made of materials except mud/dung, bamboo/reed or other


	*******************************************
	*C.	WATER
	******************************************

	* C1. Drinking water

	//hint: wq5302(Source of drinking water during rainy season)
	// improved sources of water: piped water (dwelling, compound yard/plot, neighbor, public tap/standpipe, kiosk/retailer), tube well/borehole, protected dug well, protected spring, rainwater, bottled, tanker


	* C2. Time to get water (in minutes) if source of water is neighbour's yard, compound or elsewhere (including waiting time)
	//hint:  wq5304 wq5305
	//       waiting time is greater than total time  

	
	********************************************
	*D. Sanitation
	*********************************************

	*D1. Type of toilet facility
	// hint: wq5402
    //       Improved toilet facility: : flush to piped sewer system/septic tank/pit latrine, pit latrine with slab, twin pit with slab, other composting toilet	


	*D2. Type of waste disposal facility

	//hint: wq5411
	//      Improved waste disposal method - all except throw in the field/yard, into the river, or other

	
	**********************************************
	*E.Energy and lighting
	***********************************************

	*E1. Source of lighting
	//hint: wq5202
	//      electricity source


			  
	*E2. Source of cooking fuel
	//hint: wq5214
	//      improved cooking fuel : kerosene, Butane gas, electricity, solar, bio-gas 
	//      use to update the electricity source


	***************************************
	*F. Number of durables
	***************************************
	// hint: wq8201_01 - wq8207_49
	//       need to reshape the data

