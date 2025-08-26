	/**********************************************************************
	*WMS 2022 - INDIVIDUAL LEVEL CLEAN

	*Created:		Haoyu Wu  - Aug 20, 2025 - (hwu4@worldbank.org)
	*Last modified: Haoyu Wu  - Aug 20, 2025 - (hwu4@worldbank.org)

	Development Note:  
	This syntax file is intended to check for errors, report error details, clean and recheck.
	There are four sections:
	** 	(1) MODULE SET-UP: Transfering data from RAW >> CLEAN
	**	(2) MODULE PROPERTIES: Case count, duplicates check, remove refusals (not from Module 1)
	** 	(3) MODULE FORMATTING: Order variables, format/storage type, variable labels, valuesets
	** 	(4) MODULE CHECKS/CLEANING: Quality checks and data cleaning
	***********************************************************************/

	version 13.1
	set more off
	pause off
	*********************************************
	** (0) GLOBALE SET-UP 					   **
	*********************************************
	glo raw "C:\Users\wb545671\OneDrive - WBG\AFE_work\Mission\3.ETH_Aug2025\NISH2021\Poverty Measurement\Data\rawdata\WMS 2021"
	glo clean 
	glo report "C:\Users\wb545671\OneDrive - WBG\AFE_work\Mission\3.ETH_Aug2025\NISH2021\Poverty Measurement\Data\rawdata\WMS 2021"

	*********************************************
	** (1) LOGFILE SET-UP					   **
	*********************************************
	cap log close _all
	log using "$report/log_report"


	*********************************************
	** (2) MODULE PROPERTIES				   **
	*********************************************
	/// Load raw data
	use "${raw}\WMS 2022 Members Level Data.dta", clear	
	
	sum wq11 - wq18 //issue if we spot zero or missing
	//hhid
	cap ren hhid hhid_orig
	tostring wq11, gen(hid_1) format(%02.0f)  //region
	tostring wq12, gen(hid_2) format(%02.0f)  //zone
	tostring wq13, gen(hid_3) format(%02.0f)  //Wereda
	tostring wq14, gen(hid_4) format(%01.0f)  //town
	tostring wq15, gen(hid_5) format(%02.0f)  //sub-city
	tostring wq16, gen(hid_6) format(%03.0f)  //kebele
	tostring wq17, gen(hid_7) format(%02.0f)  //EA
	tostring id202, gen(hid_8) format(%03.0f) //housing serial number
	tostring wq18, gen(hid_9) format(%06.0f)  //Hh sample selection sr. no
	egen hhid1 = concat(hid_1 hid_2 hid_3 hid_4 hid_5 hid_6 hid_7 hid_8 hid_9)
	drop hid_1 hid_2 hid_3 hid_4 hid_5 hid_6 hid_7 hid_8 hid_9
	replace hhid = "1" + hhid 
	lab var hhid "Household identifier"
	order hhid
	//checking the admin level data
	assert inrange(wq11,2,15)
	
	
	//pid
	ren wq1101 pid

	isid hhid pid
	order hhid pid
	/// Drop Duplicate Households
	duplicates tag, gen(tag)

	
	/// Count Cases in Module
	di "CASE COUNT"
	count

	*********************************************
	** (3) MODULE FORMATTING	   			   **
	*********************************************

	/// CONVERT NON-CONFORMING VALUES TO MISSING 
	ds wq11 - wq9204, has(type numeric)
	foreach var in `r(varlist)' {
		display "VARIABLE NAME: `var'"
		replace `var' = . if `var' >.
	}

	ds wq11 - wq9204, has(type string)
	foreach var in `r(varlist)' {
	display "VARIABLE NAME: `var'"
	replace `var' = "" if `var' == ".a" | `var'=="##N/A##"
	}

	/// VARIABLE CASE (MAKE STRINGS UPPERCASE)
	ds wq11 - wq9204, has(type string)
	foreach var in `r(varlist)' {
	replace `var' = upsper(`var')
	}	

	/// DESTRING, TOSTRING VARIABLES
	* If needed *

	/// RECODE VARIABLES
	* If needed *


	/// FORMAT TYPE
	* If needed *

	*********************************************
	** (4) MODULE CHECKS / CLEANING		       **
	*********************************************
	
	gen issue_missing  = . //missing
	gen	issue_outrange = . //out of range 
	gen issue_skip     = . //skipping pattern issue
	
	*********************************************
	** wq1103   Relationship to Head of the HH **
	*********************************************
	* Tab Variable *
	tab wq1103, m
	tab wq1103, m nol
	
	* value label
	label def WQ1103 
           0 "Household Head (HhH)"                                          ///
           1 "Spouse/Live as a spouse"                                       ///
           2 "Son/Daughter  of Household &  Spouse"                          ///
           3 "Son/Daughter of Head of Household"                             ///
           4 "Son/Daughter of Spouse"                                        ///
           5 "Mother/Father of Head of Household"                            ///
           6 "Mother/Father of Spouse"                                       ///
           7 "Brother/Sister of Head of Household"                           ///
           8 "Brother/Sister of Spouse"                                      ///
           9 "Grand child of Head of Household  & Spouse"                    ///
          10 "Grand child of Head of Household"                              ///
          11 "Grand child of Spouse"                                         ///
          12 "Son/Daughter  of Brother/Sister of Head  Household"            ///
          13 "Son/Daughter  of  Brother/Sister of spouse"                    ///
          14 "Adopted child"                                                 ///
          15 "Employed Domestic Servant"                                     ///
          16 "Employed Person to Serve the Hh"                               ///
          17 "Employee of the Family Economic Organization"                  ///
          18 "Other Relatives"                                               ///
          19 "Non Relatives", replace                                        ///
	label value wq1103 WQ1103 
	
	* variable label
	label variable wq1103 "Relationship to Head of the HH"
	
	* Check that Field is Not Missing *
	assert !missing(wq1103)
	replace issue_missing = 1 if missing(wq1103)

	* Check that Field is in Range
	assert inrange(wq1103, 0,19)
	replace issue_range = 1 if !inrange(wq1103, 0,19)
	
	**********************************************************************
	** wq1108   Does [NAME]'s biological father live in this household? **
	**********************************************************************
	* Tab Variable *
	tab wq1108, m
	tab wq1108, m nol 

	* value label
	label def yesno
			1 "Yes"                                                          ///
			2 "No" , replace                                        
	label value wq1108 yesno
	
	* variable label
	label variable wq1108 "Does [NAME]'s biological father live in this household?"
	
	* Check that Field is Not Missing *
	assert !missing(wq1108)
	replace issue_missing = 1 if missing(wq1108)
	
	* Check that Field is in Range
	assert inrange(wq1108, 1,2)
	replace issue_outrange = 1 if !inrange(wq1108, 1,2)

	**********************************************************************
	** wq1109   Record line number of   [NAME]'S  bilogical  father     **
	**********************************************************************
	* Tab Variable *
	tab wq1109, m
	tab wq1109, m nol

	* value label (no need)

	* variable label
	label variable wq1109 "line number of [NAME]'s bilogical father"
	
	* Check that Field is Not Missing *
	assert !missing(wq1109) if wq1108 == 1 //should NOT be missing, but missing
	replace issue_skip = 1 if missing(wq1109) & wq1108 == 1
	
	assert missing(wq1109) if wq1108 == 2 //should be missing, but NOT missing
	replace issue_skip = 1 if !missing(wq1109) & wq1108 == 2
	
	* Check that Field is in Range 
	assert inrange(wq1108, 1,2) 
	replace issue_outrange = 1 if !inrange(wq1108, 1,2)

	**********************************************************************
	** wq1109   Record line number of   [NAME]'S  bilogical  father     **
	**********************************************************************
	* Tab Variable *
	tab wq1109, m
	tab wq1109, m nol

	* value label (no need)

	* variable label
	label variable wq1109 "line number of [NAME]'s bilogical father"
	
	* Check that Field is Not Missing *
	assert !missing(wq1109) if wq1108 == 1 //should NOT be missing, but missing
	replace issue_skip = 1 if missing(wq1109) & wq1108 == 1
	
	assert missing(wq1109) if wq1108 == 2 //should be missing, but NOT missing
	replace issue_skip = 1 if !missing(wq1109) & wq1108 == 2
	
	* Check that Field is in Range 
	assert inrange(wq1108, 1,2) 
	replace issue_outrange = 1 if !inrange(wq1108, 1,2)
	
	////////////////////////////////////////////////////////////////////////////
	//                                 Exercise                               //
	//clear questions for wq1110 to wq1216
	

	
	
	***********************************************************************
	capture log close
