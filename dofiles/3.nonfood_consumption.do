  
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
*==============================================================================	
	use "${temp}\NISH2021_NONFOOD_CONS.dta", clear
	
	* Items/major items to exclude from the final consumption aggregates per the M&V (2022) guidelines
	*gen items_toexclude = (major==960) 
	
	replace major = 26 if itemc==1608 | itemc==1607  // Chat and hopes to Narcotics/Tobacco major group 
	
	gen ann_quant_st = ann_quant/STUNIT //standard unit is kg/l or items
	gen price = ann_value/ann_quant_st
	 
	sum price STPRICE //identical
	
	//outlisers (winsorize)
	gen logprice = log(price) 
	
	flagout logprice [pw=weight_hh], item(itemc) z(${z}) //winsorize upper and lower outlier
	
	gen p = price
	replace p = exp(_max) if _flag == 1
	replace p = exp(_min) if _flag == -1
	
	gen ann_value_fix = p * ann_quant_st
	lab var ann_value_fix "annual expenditure value (fix)"
	
	* Nonfood expenditure including/excluding SFP 	
	gen nfood_sfp      = ann_value_fix if sfp_any==1
	gen nfood_wotrs    = ann_value_fix if trans_allow_gov==0 
	lab var nfood_sfp      "nonfood consumption from SFP"
	lab var nfood_wotrs    "nonfood consumption excluding transport allowance"
	
* 1. collapse to hhid - item level 
	preserve 
		collapse (sum) ann_quant_st ann_value_fix netcal* nfood_*  ///
		(mean) price, by(itemc major hhid)
		tempfile collapse1
		save `collapse1'
	restore 
	
	* Create nonfood expenditure categories of interest first  
 	 recode itemc                                                               ///
	    (2301/2398 2501/2698            	=1 "alcohol & tobacco")             ///
		(10301/10398            			=2 "household supplies")            ///
		(10101/10198            			=3 "water")                         ///
		(10201/10298            			=4 "fuel and power")                ///
		(20101/21398            			=5 "clothing & footwear")           ///
		(30101/30198                        =6 "rent")                          ///
		(30201/41198 51101101/55301101     	=7 "house furnishing & equipment")  ///
		(10701/10898 60101/60198     		=8 "transport & communication")     ///
		(10901/11098 70101/70398   			=9 "recreation & culture")          ///   
		(11101/11198 80101/80198  			=10 "personal care")                ///
		(10401/10698 50101/50398        	=11 "health")                       ///
		(70401/71198 71201/78198  			=12 "education")                    ///
		(90101/90298                   		=13 "finance & insurance")          ///
		(80201/80298 41201/41298		    =14 "other nonfood")                ///
		                     , gen(nfood_group) 
		ta nfood_group

	  *Should we exclude furniture and household appliances/utensils (40101/41198s) as well? 
	  
	 * See TABLE 4.1. The COICOP System as a Checklist for the Construction of the Consumption Aggregate (page 36 of M&V, 2022)
	 recode itemc (60101/60105 ///                                            
	              60113/60115 ///
				  60119/60122 ///
				  70101/70109 ///
				  70113/70121 ///
				  30101/30198 /// 
	              40101/40198 ///
				  40301/40398    =0 "excluded") ///
	              (nonmissing    =1 "included"), gen(eligible_nonfood)

	* Items to be excluded include durables (their value will enter as cf), produtive assets, taxes, and large (unusual) expenditrures 
	* The list of durables is restricted to the list of assets from the WMS 

	 recode itemc (40101/40198 ///
				  40301/40311 ///
				  40313/40398 ///
				  60101/60105 ///           
				  60113/60115 ///
				  70101/70108 ///
				  70113/70115 ///
				  70116/70117 ///
				  70119/70121 = 1 "durable") ///
				  (nonmissing = 0 "nondurable"), gen(durable)	
				  
	save "${temp}\NISH2021_NONFOOD_CONS_LONG.dta", replace									 	 	  
      
	* Calculate values by each food type or group/category 

	forvalues i=1(1)14 {
		 gen exp_`i'      = 0
		replace exp_`i'   = ann_value_fix if nfood_group==`i' 
	  }
					
	* Rent by tenancy type 
	gen exp_rent_all        = ann_value_fix if inrange(itemc,30101,30198)
	gen exp_rent_kebele 	= ann_value_fix if itemc==30101
	gen exp_rent_agency 	= ann_value_fix if itemc==30102
    gen exp_rent_privindiv 	= ann_value_fix if itemc==30103
    gen exp_rent_owner 		= ann_value_fix if itemc==30104
    gen exp_rent_privorg 	= ann_value_fix if itemc==30105
    gen exp_rent_subsidiz 	= ann_value_fix if itemc==30106
    gen exp_rent_free 		= ann_value_fix if itemc==30107
    gen exp_rent_other      = ann_value_fix if itemc==30198
				
	* Utilities and energy expenditures
	gen exp_supplies          = ann_value_fix if major==103
	gen exp_water_all         = ann_value_fix if major==101
	gen exp_fuel_any      	  = ann_value_fix if major==102
	gen exp_fuel_elec         = ann_value_fix if itemc==10207  // electricity 
	gen exp_fuel_elec2        = ann_value_fix if itemc==10207 | itemc==10211  // electricity, dry cell? 
	gen exp_fuel_solar        = ann_value_fix if itemc==10221 
    gen exp_fuel_gas          = ann_value_fix if itemc==10206 | itemc==10210 | itemc==10219 // kerosene, butane gas, lighter gas  
	gen exp_fuel_keros        = ann_value_fix if itemc==10206 // kerosene 
	gen exp_fuel_wood         = ann_value_fix if itemc==10201 | itemc==10202 // firewood only   
	gen exp_fuel_liquid       = ann_value_fix if itemc==10206 | itemc==10210 // kerosene, butane gas   
	gen exp_fuel_biomass      = ann_value_fix if inrange(itemc,10201,10205) | inrange(itemc,10213,10216) | itemc==10222 // firewood, crop residues, chibo 
	gen exp_fuel_solid        = ann_value_fix if inrange(itemc,10201,10205) | inrange(itemc,10213,10218) | inrange(itemc,10208,10209) | itemc==10222
	gen exp_fuel_charcoal     = ann_value_fix if itemc==10203 | itemc==10214 // charcoal and mixed charcoal 
	gen exp_fuel_other        = ann_value_fix if itemc==10212 | itemc==10220 | itemc==10298 // other sources, and service 
	
	* Non-food expenditures (government approach)  
	gen nfood_nondur         = ann_value_fix          
	replace nfood_nondur     = . if durable==1                 // exclude durables 
	replace nfood_nondur     = . if inrange(itemc,30101,30198) // exclude rent 
	gen exp_durable          = ann_value_fix if durable==1         // durable expenditure 

	* Nonfood nondurables expenditure including/excluding SFP 	
	gen nfood_nondur_sfp      = nfood_sfp 
	replace nfood_nondur_sfp   = . if durable==1                 // excldue durables  
	replace nfood_nondur_sfp   = . if inrange(itemc,30101,30198) // exclude rent 
	gen nfood_nondur_wosfp    = nfood_wosfp 
	replace nfood_nondur_wosfp = . if durable==1  
	replace nfood_nondur_wosfp = . if inrange(itemc,30101,30198) 

	 gen nfood_nondur_wotrs = nfood_wotrs
	replace nfood_nondur_wotrs  = . if durable==1  
	replace nfood_nondur_wotrs  = . if inrange(itemc,30101,30198) 
	
	* Collapse nonfood expenditures to household 
	collapse (sum) ann_value_fix nfood_nondur* exp_* , by(hhid)

	ren (ann_value_fix    exp_1 exp_2 exp_3 exp_4  exp_5  exp_6  exp_7  exp_8  exp_9  exp_10  exp_11 exp_12 exp_13 exp_14)     ///
	    (nonfoodexp_2 exp_alctob exp_sup exp_water exp_fuel exp_cloth exp_rent exp_furnsh exp_trncom exp_recul exp_perscar ///
		exp_health exp_educ exp_fin exp_onfood)
	
	lab var nfood_nondur      "nonfood nondurable expenditure"
	lab var nonfoodexp_2      "nonfood expenditure"
	lab var exp_alctob        "alcohol and tobacco expenditure"
	lab var exp_sup           "house supplies expenditure"
	lab var exp_water         "water expenditure"
	lab var exp_fuel          "fuel expenditure"
	lab var exp_cloth         "clothing and footwear expenditure"
	lab var exp_furnsh        "furnishing and equipment expenditure"
	lab var exp_trncom        "transport and communication expenditure"
	lab var exp_recul         "recreation and culture expenditure"
	lab var exp_perscar       "personal care expenditure"
	lab var exp_health        "health expenditure"
	lab var exp_educ          "education expenditure"
	lab var exp_rent          "rent expenditure"
	lab var exp_fin           "finance and insurance expenditure"
	lab var exp_onfood        "other nonfood expenditure"
	lab var exp_durable       "durables expenditure"

	lab var exp_rent_kebele    "Rent: Kebele owned housing unit"
	lab var exp_rent_agency    "Rent: Housing agency owned"
	lab var exp_rent_privindiv "Rent: Privately owned (household/person)"
	lab var exp_rent_owner     "Rent: Imputed rent of owner occupied housing units"
	lab var exp_rent_privorg   "Rent: Private organization"
	lab var exp_rent_subsidiz  "Rent: Subsidized housing unit"
	lab var exp_rent_free      "Rent: Imputed rent of free housing units"
	lab var exp_rent_other     "Rent: others"
		  						
	lab var exp_supplies       "expenditure on supplies"
	lab var exp_water_all      "expenditure on water"
	lab var exp_fuel_any       "expenditure on any fuel/energy"
	lab var exp_fuel_elec	   "expenditure on electricity"
	lab var exp_fuel_elec2     "expenditure on electricity and dry cells"
	lab var exp_fuel_gas	   "expenditure on gas/liquid fuels"  
	lab var exp_fuel_solar	   "expenditure on solar energy"
	lab var exp_fuel_biomass   "expenditure on biomass fuels" 
	lab var exp_fuel_solid	   "expenditure on all solid fuels " 
	lab var exp_fuel_keros	   "expenditure on kerosene"
	lab var exp_fuel_liquid	   "expenditure on all liquid fuels"
	lab var exp_fuel_wood	   "expenditure on firewood"  
	lab var exp_fuel_charcoal  "expenditure on charcoal" 
	lab var exp_fuel_other	   "expenditure on all other fuels/services"
				
	 * Identify tenancy from the rent expenditure data 
	gen renter_kebel  = exp_rent_kebele > 0
	gen renter_agenc  = exp_rent_agency > 0
	gen renter_privhh = exp_rent_privindiv > 0
	gen renter_owner  = exp_rent_owner > 0
	gen renter_prvorg = exp_rent_privorg > 0
	gen renter_subsid = exp_rent_subsidiz > 0
	gen renter_free   = exp_rent_free > 0
	gen renter_other  = exp_rent_other > 0
	
	gen tenancy_1 = . 
	replace tenancy_1 = 1 if renter_kebel==1
	replace tenancy_1 = 2 if renter_agenc==1
	replace tenancy_1 = 3 if renter_privhh==1
	replace tenancy_1 = 4 if renter_owner==1
	replace tenancy_1 = 5 if renter_prvorg==1
	replace tenancy_1 = 6 if renter_subsid==1
	replace tenancy_1 = 7 if renter_free==1
	replace tenancy_1 = 8 if renter_other==1
    
	lab define tenancy_1 1 "rent from kebele" 2 "rent from agency" 3 "rent from priv hh/person"    ///
						 4 "owner" 5 "rent from priv organ" 6 "subsidies hs unit" 7 "free hs unit" ///
						 8 "other"
	lab values tenancy_1 tenancy_1
	ta tenancy_1
	lab var tenancy_1 "tenancy by rent type"

		
	compress
	save "${out}\NISH2021_NONFOOD_CONS.dta", replace
   
	
	