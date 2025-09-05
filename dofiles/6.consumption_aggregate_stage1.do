  
*=============================================================================
*Project:       Ethiopia Poverty Measurement Training 2025
*Author: 	    Haoyu Wu
*Create Date:   8/15/2025
*Modify Date:   8/18/2025
*Data source:   HoWStat combines HCES and WMS (2021) and conducted by the        
*		        Ethiopian Statistics Services (ESS)  
*=============================================================================
	
*================================================================ ==============
*   1. unit/ measurement data checking
*==============================================================================	

	******************************************************
	* [4] <<<< MERGE ALL DATA INTO HOUSEHOLD LEVEL >>>>  *
	******************************************************
	
	* Household level identifiers 
	use "$temp/hces_hh_data_2021.dta", clear  
	merge 1:1 hhid using "${temp}/hces_survey_date_2021.dta", nogen keep(1 3) keepusing(int*) //interview date
	
	* Food and nonfood aggregates 
	merge 1:1 hhid using "${out}\NISH2021_FOOD_CONS.dta", nogen keep(1 3)
	merge 1:1 hhid using "${out}\NISH2021_NONFOOD_CONS.dta", nogen keep(1 3)  
	merge 1:1 hhid using "${out}\NISH2021_DURABLE_CONS.dta", nogen keep(1 3)			

	* Survey month 
	clonevar month = int_month 
	
	******************************************************************
	* Calculating the consumption aggregate (and components) at the  
	* household level. We also calculate nominal expenditures here 
	*****************************************************************
	
	* Fod consumption
	gen food_exp_nom = foodexp  // food aggregates 
	
	* nonfood consumption
	** nonfood nondurables 
	gen nonfood_nondur = nfood_nondur_wotrs // nonfood nondurables, excl. transportation allowance 
	gen rent = exp_rent        // rent
	*gen durable = exp_durable  // durables, based on purchase values
	gen durable = cf_dur_2      //durables, from default model and complete model (check durables.do)
	egen nonfood_exp_nom = rowtotal(nonfood_nondur rent durable)
	
	*Total consumption aggregate as sum of food and non-food aggregates 
	egen cons_agg = rowtotal(food_exp_nom nonfood_exp_nom)
	
	gen logfood = log10(food_exp_nom/hh_size)
	tw histogram logfood [fw = round(weight_hh)], lalign(inside) width(0.05) ///
    || normal logfood [fw = round(weight_hh)], legend(off) ///
       ysca(off) title("Food consumption NISH2021")
	   
	gen lognonfood = log10(nonfood_exp_nom/hh_size)
	tw histogram lognonfood [fw = round(weight_hh)], lalign(inside) width(0.05) ///
    || normal lognonfood [fw = round(weight_hh)], legend(off) ///
       ysca(off) title("NonFood consumption NISH2021")
		
	******************************************************************
	* Adjusting food and nonfood expenditures for household size 
	* and composition 
	* We are using adult equivalence scales for the adjustment 
	*****************************************************************

   * Compute per adult equialent and per capita consumption expenditures  
	foreach var of varlist cons_agg food_exp_nom nonfood_exp_nom nonfood_nondur rent durable {
		gen `var'_pa = `var'/adulteq
		gen `var'_pc = `var'/hh_size
	}

	save "${out}\NISH2021_TOTAL_CONS.dta", replace
