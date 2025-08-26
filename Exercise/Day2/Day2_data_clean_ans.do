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
	glo raw "C:\Users\wb545671\OneDrive - WBG\AFE_work\Mission\3.ETH_Aug2025\NISH2021\training\Data\in"
	glo clean 
	glo report "C:\Users\wb545671\OneDrive - WBG\AFE_work\Mission\3.ETH_Aug2025\NISH2021\training\Data\in"

	*********************************************
	** (1) LOGFILE SET-UP					   **
	*********************************************
	cap log close _all
	*log using "$report/log_report"


	*********************************************
	** (2) MODULE PROPERTIES				   **
	*********************************************
	/// Load raw data
	use "${raw}\HH_Roster.dta", clear	
	

	*********************************************
	** (2) MODULE PROPERTIES				   **
	*********************************************
	des CQ11- CQ1101 
	sum CQ11- CQ1101 //issue if we spot zero or missing
	//hhid
	cap ren hhid hhid_orig
	tostring CQ11, gen(hid_1) format(%02.0f)  //region
	tostring CQ12, gen(hid_2) format(%02.0f)  //zone
	tostring CQ13, gen(hid_3) format(%02.0f)  //Wereda
	tostring CQ14, gen(hid_4) format(%01.0f)  //town
	tostring CQ15, gen(hid_5) format(%02.0f)  //sub-city
	tostring CQ16, gen(hid_6) format(%03.0f)  //kebele
	tostring CQ17, gen(hid_7) format(%02.0f)  //EA
	tostring CQ18, gen(hid_8) format(%02.0f) //housing serial number
	egen hhid = concat(hid_1 hid_2 hid_3 hid_4 hid_5 hid_6 hid_7 hid_8)
	drop hid_1 hid_2 hid_3 hid_4 hid_5 hid_6 hid_7 hid_8
	replace hhid = "1" + hhid 
	lab var hhid "Household identifier"
	order hhid
	//checking the admin level data
	cap assert inrange(CQ11,1,15)
	
	//pid
	ren CQ1101 pid

	isid hhid pid
	order hhid pid
	
	/// Drop Duplicate Households
	duplicates tag, gen(tag)
	tab tag
	drop tag

	*********************************************
	** (3) MODULE FORMATTING	   			   **
	*********************************************

	/// CONVERT NON-CONFORMING VALUES TO MISSING 
	ds ur - RATE, has(type numeric)
	foreach var in `r(varlist)' {
		display "VARIABLE NAME: `var'"
		replace `var' = . if `var' >.
	}

	ds ur - RATE, has(type string)
	foreach var in `r(varlist)' {
	display "VARIABLE NAME: `var'"
	replace `var' = "" if `var' == ".a" | `var'=="##N/A##"
	}

	/// VARIABLE CASE (MAKE STRINGS UPPERCASE)
	ds ur - RATE, has(type string)
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
	
	gen issue_missing  = "" //missing
	gen	issue_outrange = "" //out of range 
	gen issue_skip     = "" //skipping pattern issue
	
	*********************************************
	** CQ1103   Relationship to Head of the HH **
	*********************************************
	* Tab Variable *
	tab CQ1103, m
	tab CQ1103, m nol
	
	* value label
	label def CQ1103 ///                                       
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
          19 "Non Relatives", replace                                       
	label value CQ1103 CQ1103 
	
	* variable label
	label variable CQ1103 "Relationship to Head of the HH"
	
	* Check that Field is Not Missing *
	count if  missing(CQ1103)
	replace issue_missing = "CQ1103" if missing(CQ1103)

	* Check that Field is in Range
	count if !inrange(CQ1103, 0,19) & !mi(CQ1103)
	replace issue_outrange = "CQ1103" if !inrange(CQ1103, 0,19) & !mi(CQ1103)
		
	**********************************************************************
	** CQ1104   sex                                                     **
	**********************************************************************
	* Tab Variable *
	tab CQ1104, m
	tab CQ1104, m nol 

	* value label
	label def gender                                                         ///
			1 "Male"                                                         ///
			2 "Female" , replace                                        
	label value CQ1104 gender
	
	* variable label
	label variable CQ1104 "gender"
	
	* Check that Field is Not Missing *
	count if missing(CQ1104)
	replace issue_missing =  issue_missing+",CQ1104" if missing(CQ1104)
	
	* Check that Field is in Range
	count if !inrange(CQ1104, 1,2) & !mi(CQ1104)
	replace issue_outrange = issue_missing+",CQ1104" if !inrange(CQ1104, 1,2) & !mi(CQ1104)

	
	**********************************************************************
	** CQ1105   age                                                     **
	**********************************************************************
	* Tab Variable *
	* numberic variables

	* value label
	
	* variable label
	label variable CQ1105 "age"
	
	* Check that Field is Not Missing *
	count if missing(CQ1105)
	replace issue_missing =  issue_missing+",CQ1105" if missing(CQ1105)
	
	* Check that Field is in Range
	count if !inrange(CQ1105, 0,97) & !mi(CQ1105)
	replace issue_outrange = issue_missing+",CQ1105" if !inrange(CQ1105, 0,97) & !mi(CQ1105)
	
	**********************************************************************
	** CQ1106   RELEGION                                                    **
	**********************************************************************
	* Tab Variable *
	tab CQ1106, m
	tab CQ1106, m nol 

	* value label
	label def relegion                                                       ///
			1 "Orthodox"                                                     ///
			2 "Catholic"                                                     ///
			3 "Protestant"                                                   ///
			4 "Islam"                                                        ///
			5 "Waqi-Feta"                                                    ///
			6 "Traditional"                                                  ///
			7 "No religion/Atheist"                                          ///
			8 "Other", replace                                        
	label value CQ1106 relegion
	
	* variable label
	label variable CQ1106 "Relegion"
	
	* Check that Field is Not Missing *
	count if missing(CQ1106)
	replace issue_missing =  issue_missing+",CQ1106" if missing(CQ1106)
	
	* Check that Field is in Range
	count if !inrange(CQ1106, 1,8) & !mi(CQ1106)
	replace issue_outrange = issue_missing+",CQ1106" if !inrange(CQ1106, 1,8) & !mi(CQ1106)

	
	**********************************************************************
	** CQ1107   Does [NAME] has any disability problem?                 **
	**********************************************************************
	tab CQ1107, m
	tab CQ1107, m nol 

	* value label
	label def yesorno ///
			1 "Yes"                                                          ///
			2 "No" , replace                                        
	label value CQ1107 yesorno
	
	* variable label
	label variable CQ1107 "Does [NAME] has any disability problem?"
	
	* Check that Field is Not Missing *
	count if missing(CQ1107)
	replace issue_missing =  issue_missing+",CQ1107" if missing(CQ1107)
	
	* Check that Field is in Range
	count if !inrange(CQ1107, 1,2) & !mi(CQ1107)
	replace issue_outrange = issue_missing+",CQ1107" if !inrange(CQ1107, 1,2) & !mi(CQ1107)
	
	**********************************************************************
	** CQ1108  What type of Disability does [Name] has?                 **
	**********************************************************************
	tab CQ1108, m
	tab CQ1108, m nol 

	* value label
	* omission *
	
	* variable label
	label variable CQ1108 "What type of Disability does [Name] has?"
	
	* Check that Field is Not Missing *
	count if (missing(CQ1108) & CQ1107 == 1) | (!missing(CQ1108) & CQ1107 == 2)
	replace issue_skip =  issue_skip+",CQ1108" if (missing(CQ1108) & CQ1107 == 1) | (!missing(CQ1108) & CQ1107 == 2)
	
	* Check that Field is in Range
	count if !inrange(CQ1108, 1,14) & !mi(CQ1108)
	replace issue_outrange = issue_missing+",CQ1108" if !inrange(CQ1108, 1,14) & !mi(CQ1108)
	
	
	**********************************************************************
	** CQ1109  What is [NAME]'s CURRENT MARITAL STATUS                  **
	**********************************************************************
	tab CQ1109, m
	tab CQ1109, m nol 

	* value label
	* omission *
	
	* variable label
	label variable CQ1109 "What is [NAME]'s CURRENT MARITAL STATUS?"
	
	* Check that Field is Not Missing *
	count if missing(CQ1109) & CQ1105 >= 10 & CQ1105 < .
	count if !missing(CQ1109) & CQ1105 < 10
	
	replace issue_skip =  issue_skip+",CQ1109" if (missing(CQ1109) & CQ1105 >= 10) | (!missing(CQ1109) & CQ1105 < 10)
	
	* Check that Field is in Range
	count if !inrange(CQ1109, 1,6) & !mi(CQ1109)
	replace issue_outrange = issue_missing+",CQ1109" if !inrange(CQ1109, 1,6) & !mi(CQ1109)
	

	**********************************************************************
	** CQ1110   Can [NAME] read and write ?                             **
	**********************************************************************
	tab CQ1110, m
	tab CQ1110, m nol 

	* value label
	*label def yesorno
	*		1 "Yes"                                                          ///
	*		2 "No" , replace                                        
	label value CQ1110 yesorno
	
	* variable label
	label variable CQ1110 "Can [NAME] read and write?"
	
	* Check that Field is Not Missing *
	count if missing(CQ1110) & CQ1105 >= 5 & CQ1105 < .
	count if !missing(CQ1110) & CQ1105 < 5
	
	replace issue_skip =  issue_skip+",CQ1110" if (missing(CQ1110) & CQ1105 >= 5) | ( !missing(CQ1110) & CQ1105 < 5)
	
	* Check that Field is in Range
	count if !inrange(CQ1110, 1,2) & !mi(CQ1110)
	replace issue_outrange = issue_missing+",CQ1110" if !inrange(CQ1110, 1,2) & !mi(CQ1110)

	
	**********************************************************************
	** CQ1111  Has [NAME] ever attended school?                             **
	**********************************************************************
	tab CQ1111, m
	tab CQ1111, m nol 

	* value label                                    
	label value CQ1111 yesorno
	
	* variable label
	label variable CQ1111 "Has [NAME] ever attended school?"
	
	* Check that Field is Not Missing *
	count if missing(CQ1111) & CQ1105 >= 5 & CQ1105 < .
	count if !missing(CQ1111) & CQ1105 < 5
		
	replace issue_skip =  issue_skip+",CQ1111" if(missing(CQ1111) & CQ1105 >= 5) | (!missing(CQ1111) & CQ1105 < 5)
	
	* Check that Field is in Range
	count if !inrange(CQ1111, 1,2) & !mi(CQ1111)
	replace issue_outrange = issue_missing+",CQ1111" if !inrange(CQ1111, 1,2) & !mi(CQ1111)

	**********************************************************************
	** CQ1112  what is the higher school/grade that [NAME] has complete **
	**********************************************************************
	tab CQ1112, m
	tab CQ1112, m nol 

	* value label                                    
	* omission 
	
	* variable label
	label variable CQ1112 "what is the higher school/grade that [NAME] has complete"
	
	* Check that Field is Not Missing *
	count if missing(CQ1112) & CQ1105 >= 5 & CQ1111 == 1 & CQ1105 < .
	count if !missing(CQ1112) & CQ1105 < 5
	
	replace issue_skip =  issue_skip+",CQ1112" if (missing(CQ1112) & CQ1105 >= 5 & CQ1111 == 1) | (!missing(CQ1112) & CQ1105 < 5)
	
	* Check that Field is in Range
	count if !inrange(CQ1112, 0,40) & !inrange(CQ1112, 93,98) & !mi(CQ1112)
	replace issue_outrange = issue_missing+",CQ1112" if !inrange(CQ1112, 0,40) & !inrange(CQ1112, 93,98) & !mi(CQ1112)

	**********************************************************************
	** CQ1113 During the last 12 months, did (NAME) earn/has got any income/remittance?               **
	**********************************************************************
	tab CQ1113, m
	tab CQ1113, m nol 

	* value label                                    
	label value CQ1113 yesorno
	
	* variable label
	label variable CQ1113 "During the last 12 months, did (NAME) earn/has got any income/remittance? "
	
	* Check that Field is Not Missing *
	count if  missing(CQ1113)
	replace issue_missing =  issue_missing+",CQ1113" if missing(CQ1113)
	
	* Check that Field is in Range
	count if !inrange(CQ1113, 1,2) & !mi(CQ1113)
	replace issue_outrange = issue_missing+",CQ1113" if !inrange(CQ1113, 1,2) & !mi(CQ1113)
	
	**********************************************************************
	** CQ1115   age  (10 and above)                                                    **
	**********************************************************************
	* Tab Variable *
	* numberic variables

	* value label
	
	* variable label
	label variable CQ1105 "age (10 and above)"
	
	* Check that Field is Not Missing *
	count if missing(CQ1115) & CQ1105 >= 10 & CQ1105 < .
	count if !missing(CQ1115) & CQ1105 < 10
	replace issue_skip =  issue_skip + ",CQ1115" if (missing(CQ1115) & CQ1105 >= 10) | (!missing(CQ1115) & CQ1105 <  10)
	
	* Check that Field is in Range
	count if !inrange(CQ1115, 10,97) & !mi(CQ1115)
	replace issue_outrange = issue_missing+",CQ1115" if !inrange(CQ1115, 10,97) & !mi(CQ1115)


	*************************************************************************
	** CQ1116 Did [name] most of the time worked during the past 12 months **
	*************************************************************************
	tab CQ1116, m
	tab CQ1116, m nol 

	* value label                                    
	label value CQ1116 yesorno
	
	* variable label
	label variable CQ1116 "Did [name] most of the time worked during the past 12 months "
	
	* Check that Field is Not Missing *
	count if missing(CQ1116) & CQ1105 >= 10 & CQ1105 < .
	count if !missing(CQ1116) & CQ1105 < 10
	if _rc replace issue_skip =  issue_skip + ",CQ1116" if (missing(CQ1116) & CQ1105 >= 10) | (!missing(CQ1116) & CQ1105 < 10)
	
	* Check that Field is in Range
	count if !inrange(CQ1116, 1,2) & !mi(CQ1116)
	replace issue_outrange = issue_missing+",CQ1116" if !inrange(CQ1116, 1,2) & !mi(CQ1116)


	*************************************************************************
	** CQ1117 What was the main reason[NAME] was not working during the past 12 months? **
	*************************************************************************
	tab CQ1117, m
	tab CQ1117, m nol 

	* value label                                    
	* omission *
	
	* variable label
	label variable CQ1117 "main reason[NAME] for not working during the past 12 months?"
	
	* Check that Field is Not Missing *
	count if missing(CQ1117) & CQ1116  == 2
	count if !missing(CQ1117) & CQ1116 == 1
	replace issue_skip =  issue_skip + ",CQ1117" if (missing(CQ1117) & CQ1116  == 2) | (!missing(CQ1117) & CQ1116 == 1)
	
	
	* Check that Field is in Range
	count if !inrange(CQ1117, 1,9) & CQ1117 != 98 & !mi(CQ1117)
	replace issue_outrange = issue_missing+",CQ1117" if !inrange(CQ1117, 1,9) & CQ1117 != 98 & !mi(CQ1117)


	*************************************************************************
	** CQ1118 What was the main status in employment                       **
	*************************************************************************
	tab CQ1118, m
	tab CQ1118, m nol 

	* value label                                    
	* omission *
	
	* variable label
	label variable CQ1118 "What was the main status in employment "
	
	* Check that Field is Not Missing *
	count if missing(CQ1118) & CQ1116  == 1
	count if !missing(CQ1118) & CQ1116  == 2
	replace issue_skip =  issue_skip + ",CQ1118" if (missing(CQ1118) & CQ1116  == 1) | (!missing(CQ1118) & CQ1116  == 2)
	
	* Check that Field is in Range
	count if !inlist(CQ1118, 1,11,12,21,22,31,32,41,42,43,44,51,52,53,54,61,62,71,72,81,91,92,98) & !mi(CQ1118)
	replace issue_outrange = issue_missing+",CQ1118" if !inlist(CQ1118, 1,11,12,21,22,31,32,41,42,43,44,51,52,53,54,61,62,71,72,81,91,92,98) & !mi(CQ1118)

	
	*************************************************************************
	** CQ1119 Type of Occupation                                           **
	*************************************************************************
	tab CQ1119, m
	tab CQ1119, m nol 

	* value label                                    
	* omission *
	
	* variable label
	label variable CQ1119 "Type of Occupation "
	
	* Check that Field is Not Missing *
	count if missing(CQ1119) & CQ1116  == 1
	count if !missing(CQ1119) & CQ1116  == 2
	replace issue_skip =  issue_skip + ",CQ1119" if (missing(CQ1119) & CQ1116  == 1)| ( !missing(CQ1119) & CQ1116  == 2)
	
	
	* Check that Field is in Range
	count if !inrange(CQ1119, 1,10) & !mi(CQ1119)
	replace issue_outrange = issue_missing+",CQ1119" if !inrange(CQ1119, 1,10) & !mi(CQ1119)

	
	*************************************************************************
	** CQ1120 What kind of Business is [NAME]'s main Occupation connected with  **
	*************************************************************************
	tab CQ1120, m
	tab CQ1120, m nol 

	* value label                                    
	* omission *
	
	* variable label
	label variable CQ1120 "Type of Business "
	
	* Check that Field is Not Missing *
	count if missing(CQ1120) & CQ1116  == 1
	count if !missing(CQ1120) & CQ1116  == 2
	replace issue_skip =  issue_skip + ",CQ1120" if (missing(CQ1120) & CQ1116  == 1) | (!missing(CQ1120) & CQ1116  == 2)
	
	
	* Check that Field is in Range
	count if !inrange(CQ1120, 1,21) & !mi(CQ1120)
	replace issue_outrange = issue_missing+",CQ1120" if !inrange(CQ1120, 1,21) & !mi(CQ1120)

	* check issue
	tab issue_missing
	tab issue_outrange
	tab issue_skip
	
	capture log close
