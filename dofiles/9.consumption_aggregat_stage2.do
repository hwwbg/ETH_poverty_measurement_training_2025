  
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
	gen durable = cf_dur      //durables, from default model and complete model (check durables.do)
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

	***********************************************************
	* Adjusting food and nonfood expenditures to price variations
	* Temporal and spatial price variations
	*************************************************
	
	*************************************
	* SPATIAL PRICE DEFLATORS 	
	*************************************	
	merge m:1 REP using "${temp}\sptial_def.dta", assert(3) nogen
  					
	**************************************
	* WITHIN SURVEY AND TEMPORAL DEFLATORS 	
	**************************************			
	merge m:1 month using "${temp}\temporal_def.dta", assert(3) nogen

	******************************************************************
	* Calculating different welfare aggregates wrt spatial and  
	* temporal deflators  
	*****************************************************************
	
	* Generate aggregate deflators (spatial X temporal)
	gen fd_spat  = fd_def*fd_temp
	gen nfd_spat = nfd_def*nfd_temp	

	* Consumption aggregates with temporal deflator only 
	gen food_pc_temp   = food_exp_nom_pc/fd_temp
	gen nfood_pc_temp  = nonfood_exp_nom_pc/nfd_temp
	egen total_pc_temp = rowtotal(food_pc_temp nfood_pc_temp)

	* Consumption aggregates with SPATIAL deflator only
	gen food_pa_sp   = food_exp_nom_pa/fd_def
	gen nfood_pa_sp  = nonfood_exp_nom_pa/nfd_def
	egen total_pa_sp = rowtotal(food_pa_sp nfood_pa_sp)

	* Real consumption aggregates (with SPATIAL and TEMPORAL deflator) 
	gen food_pa_r      = food_exp_nom_pa/fd_spat
	gen nfood_pa_r     = nonfood_exp_nom_pa/nfd_spat
	gen nfood_nondur_r = nonfood_nondur_pa/nfd_spat
	gen rent_r         = rent_pa/nfd_spat
	gen durable_r      = durable_pa/nfd_spat	
	egen total_pa_r    = rowtotal(food_pa_r nfood_pa_r)
	gen food_pc_r      = food_exp_nom_pc/fd_spat
	gen nfood_pc_r     = nonfood_exp_nom_pc/nfd_spat
	egen total_pc_r    = rowtotal(food_pc_r nfood_pc_r)
	egen total_pa_nom  = rowtotal(food_exp_nom_pa nonfood_exp_nom_pa) 

	* Harmonized welfare/consumption aggregate variables. This is created 
	* to share with the D4G group for international poverty rate calculation 

	clonevar welfarenom  = total_pa_nom
	clonevar welfare     = total_pc_temp 
	clonevar welfaredef  = total_pa_sp 
	clonevar welfarereal = total_pa_r 

	lab var welfare        "Welfare aggregate (per capita) for estimating international poverty"
	lab var welfarenom     "Welfare aggregate in nominal terms"
	lab var welfaredef     "Welfare aggregate spatially deflated"
	lab var welfarereal    "Welfare aggregate spatially and temporally deflated"

	* Consumption expenditure per capita per day 
	gen cons_pc_day  = welfare/365

	******************************************************************
	* Alternative poverty line, national and international, and poverty 
	* rate calculations 
	*****************************************************************	

	* Two poverty lines are constructed by inflating the December 2015 line using (i) CPI deflator and (ii) GDP deflator
	* But the one based on GDP deflator is not going to be used (only for checking)
	g fpline_2021    = 10903     // based on Dec 2021 food CPI deflators 
	g pline_2021     = 18964     // based on Dec 2021 CPI deflators 
	* the 2021 poverty line should be the 2016 line (updated from 2011 using CPI deflator) inflated to Dec 2021 
	g pline_gdp_def = 16103     // based on GDP deflator (2021) 2.24137931 using 2015 as reference 
	g fpline_2021_2    = 11060     // based on Dec 2021 food CPI deflators 
	g pline_2021_2     = 17753     // based on Dec 2021 CPI deflators 
	
	lab var fpline_2021   "Food poverty line, 2021, Birr/adult/year (Food CPI deflator)"
	lab var pline_2021    "National poverty line, Birr/adult/year (CPI deflator)"
	lab var pline_gdp_def "National poverty line, 2021, Birr/adult/year (GDP deflator)"
	lab var fpline_2021_2 "Food poverty line, 2021, Birr/adult/year (Poverty basket recosted)"
	lab var pline_2021_2  "National poverty line, 2021, Birr/adult/year (Poverty basket recosted)"

	* Poverty headcounts   
	gen poor_nat_1 = total_pa_r < pline_2021
	gen poor_nat_2 = total_pa_r < pline_gdp_def
	gen poor_food_1 = food_pa_r < fpline_2021 
	gen fbshare = food_pa_r/total_pa_r
	gen poor_food_2 = food_pa_r < fpline_2021_2
	gen poor_nat_3 = total_pa_r < pline_2021_2  // original pov basket valued at weighted mean survey prices 

	lab var poor_nat_1     "poor (national poverty line, CPI based deflator)"
	lab var poor_nat_2 	   "poor (national poverty line, GDP deflator)"
	lab var poor_nat_3     "poor (national poverty line, pov basket recosted)"	
	lab var poor_food_1    "food poor (food poverty line, CPI based deflator)"	
	lab var poor_food_2    "food poor (food poverty line, pov basket recosted)"	
	lab var fbshare        "food budget share"

	* Extreme poverty (national line)
	gen poor_ext = (total_pa_r < fpline_2021)
    lab var poor_ext "Extreme poor (national line)"
	

	* International poverty rates  	
	*(3) International poverty lines 
	//2017PPP
	gen lipl_2017 = 2.15*8.50*2.2525252 
	gen lmicpl_2017 = 3.65*8.50*2.2525252 
	gen umicpl_2017 = 6.85*8.50*2.2525252 
	
	//2021PPP
	gen lipl_2021 = 3*13.436761*1.1192654 
	gen lmicpl_2021 = 4.2*13.436761*1.1192654 
	gen umicpl_2021 = 8.3*13.436761*1.1192654
		
	gen poor_lipl_1 = (cons_pc_day < lipl_2017)
	gen poor_lmicpl_1 = (cons_pc_day < lmicpl_2017)
	gen poor_umicpl_1 = (cons_pc_day < umicpl_2017)
	
	lab var poor_lipl_1 "poor: international poverty line ($2.15 2017PPP)"
	lab var poor_lmicpl_1 "poor: lower middle income line ($3.65 2017PPP)"
	lab var poor_umicpl_1 "poor: upper middle income line ($6.85 2017PPP)"
	
	gen poor_lipl_2 = (cons_pc_day < lipl_2021)
	gen poor_lmicpl_2 = (cons_pc_day < lmicpl_2021)
	gen poor_umicpl_2 = (cons_pc_day < umicpl_2021)
	
	lab var poor_lipl_2 "poor: international poverty line ($3 2021PPP)"
	lab var poor_lmicpl_2 "poor: lower middle income line ($4.2 2021PPP)"
	lab var poor_umicpl_2 "poor: upper middle income line ($8.3 2021PPP)"
	
	* food poverty line
	gen kcal_day_pa = netcal/adulteq/365
	lab var kcal_day_pa "kcalories per adult per day"
	gen poor_cal = (kcal_day_pa < 2200)
	lab define poor_cal 0 "non poor" 1 "poor"
	lab values poor_cal poor_cal 
	lab var poor_cal "poor: based on calories"
		
	sum poor_* [aw=weight_pop]

	* Survey identifier 
	gen survey_year = 2021 
	
	compress 
	save "${out}/hces_household_2021_final.dta", replace 	
	