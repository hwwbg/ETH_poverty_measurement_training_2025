  
*=============================================================================
*Project:       Ethiopia Poverty Measurement Training 2025
*Author: 	    Haoyu Wu
*Create Date:   8/8/2025
*Modify Date:   8/13/2025
*Data source:   HoWStat combines HCES and WMS (2021) and conducted by the        
*		        Ethiopian Statistics Services (ESS)  
*=============================================================================
	
*==============================================================================
*   0. GLOBAL SETTING
*==============================================================================		
	//0.1 general clearence
	clear
	clear matrix
	clear mata
	set more off
	set maxvar 10000
	//0.2 key parameters
	global z 3       //zscore for outliers detection
	global nmin 20   //minimum number of observations to construct the effective statistical summary
	
	global inf 0.3517  //nonfood inflation rate
	global int 0.07    //nominal interest rate
	
	** calories per capita to use to set food poverty line
	global calories_pc 2200

	** reference population for food poverty line
	global d_min = 3
	global d_max = 7
	
	global rav_perc = 15 // take population with x% of the food poverty line

	** f. exclude hhs with extreme alpha 
	* or exclude bottom p_alpha and top p_alpha percent
	global p_alpha = 10
	
	//0.2 data path setting
*	global path "C:\Users\wb545671\OneDrive - WBG\AFE_work\Mission\3.ETH_Aug2025\NISH2021\training"
	global path "C:\Users\wb416046\WBG\Christina Wieser - Ethiopia\ESS\Training August 2025"
	
	global temp "${path}\Data\temp"  
	global out 	"${path}\Data\output"
	global log  "${path}\log"
*	global raw  "C:\Users\wb545671\OneDrive - WBG\AFE_work\Mission\3.ETH_Aug2025\NISH2021\Poverty Measurement\Data\rawdata"
	global raw  "C:\Users\wb416046\WBG\Christina Wieser - Ethiopia\ESS\Training August 2025\Data"

	///0.2.1 create the folder if there are not exsit
	cap mkdir   "${path}\Data"
	cap mkdir   "${path}\Data\temp"  
	cap mkdir   "${path}\Data\output"
	cap mkdir   "${path}\log"	

	//0.3 call the specific adofile
	///0.3.1 Method 1 add the adopath
	adopath ++ "${path}\dofiles\adofile"
	///0.3.2 Method 2 call the adofile directly
	*do "${path}\dofile\adofile\dlw_primus1.ado"
