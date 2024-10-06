*************************************************
** Title: CostPanelCreation, Ghana
** Date Created: May 12th, 2024
** Author: Vincent Armentano
** Contact: varmenta@ucsd.edu
** Last Modified: August 27, 2024
*************************************************
{
	** A. Directory Setup
		{
		if inlist("`c(username)'","Vinny","varmentano","vja8446","wildi") {
			*gl home = "X:/Box Sync/DIRTS_Rainfall_Expectations"
			gl home = "C:\Users/`c(username)'\OneDrive - UC San Diego\A_Research\LSMSISA\9_GhanaISSER"
		}
		else {
		if inlist("`c(username)'", "ashvi") {
			*gl home = "X:/Box Sync/DIRTS_Rainfall_Expectations"
			gl home = "C:\Users/`c(username)'\UC San Diego/Vincent J Armentano - LSMSISA\9_GhanaISSER"
			}
		else {
			qui {
			** Creating Base Directory Global from user's directory
				gl home = substr("`c(pwd)'",1,strpos("`c(pwd)'","dofiles")-2)
				noi di "Base Directory set to '${home}'"	
			** Exiting if Base Directory can't be created
				if "${home}"=="" {
					noi di "Launch Stata in a directory for this project"
					exit
					}
				}
		}
		}
	** B. Setting Macros
		{
		** External Data
			gl raw_w1	"${home}/A_Data/1_Raw/Wave1"
			gl raw_w2	"${home}/A_Data/1_Raw/Wave2"
			gl raw_w3	"${home}/A_Data/1_Raw/Wave3"
			
		** Internally Created Data
			gl create	"${home}/A_Data/3_Created"
		}
		}
	**1. Chemical Cost
 {
		** A. Wave 1
		{
			**i. Wet Season Wave 1
				**Load dataset
				u "${raw_w1}/s4avi1.dta", clear
				**Renaming confusing collum names
					rename s4avi1_plotno plotid
					rename s4avi_a165ii chemcost_1
					rename s4avi_a173ii chemcost_2
					rename s4avi_a181ii chemcost_3
					rename s4avi_a189ii chemcost_4
					rename s4avi_a197ii chemcost_5
				**Changing missing values to zero
					replace chemcost_1 = 0 if mi(chemcost_1)
					replace chemcost_2 = 0 if mi(chemcost_2)
					replace chemcost_3 = 0 if mi(chemcost_3)
					replace chemcost_4 = 0 if mi(chemcost_4)
					replace chemcost_5 = 0 if mi(chemcost_5)
				**Summing chemical costs
					gen chemcost_a = chemcost_1 + chemcost_2 + chemcost_3 + chemcost_4 + 					chemcost_5
					replace chemcost_a = 0 if mi(chemcost_a)
				**Dropping duplicates
					duplicates drop FPrimary plotid chemcost_a, force
				**Dropping incomplete data
					drop if FPrimary == .| plotid == . | chemcost_a == .
				**Check for unique identifier
					isid FPrimary plotid
				**Prepare for merge
					keep FPrimary plotid chemcost_a wave
				**Save
					tempfile w1chemcost_dry
					save `w1chemcost_dry', replace
			**ii. Dry Season Wave 1
				**Load dataset
					u "${raw_w1}/s4avi2.dta", clear
				**renaming confusing collum names
					rename s4avi2_plotno plotid
					rename s4avi_206ii chemcost_1
					rename s4avi_214ii chemcost_2
					rename s4avi_222ii chemcost_3
					rename s4avi_230ii chemcost_4
					rename s4avi_238ii chemcost_5
					replace chemcost_1 = 0 if mi(chemcost_1)
					replace chemcost_2 = 0 if mi(chemcost_2)
					replace chemcost_3 = 0 if mi(chemcost_3)
					replace chemcost_4 = 0 if mi(chemcost_4)
					replace chemcost_5 = 0 if mi(chemcost_5)
				**Summarize chemical costs
					gen chemcost_b = chemcost_1 + chemcost_2 + chemcost_3 + chemcost_4 + chemcost_5
					replace chemcost_b = 0 if mi(chemcost_b)
				**Dropping duplicates
					duplicates drop FPrimary plotid chemcost_b, force
				**Dropping incomplete data
					drop if FPrimary == .| plotid == . | chemcost_b == .
				**Preparing for merge
					keep FPrimary plotid chemcost_b wave
				**Check unique identifier
					isid FPrimary plotid
				**Merge with previous data
					merge 1:1 FPrimary plotid using `w1chemcost_dry'
					keep if _merge == 3
					gen chemcost = chemcost_a + chemcost_b
					replace chemcost = 0 if mi(chemcost)
					keep FPrimary plotid chemcost wave
				**Save Chemcost_wave1
					tempfile w1chemcost
					save `w1chemcost', replace
			}
	**	B. Wave 2
		{
					**Load dataset
						u "${raw_w2}/04l_chemquestions.dta", clear
					**Assert id
						isid FPrimary InstanceNumber
					**Check unique quantity
						tab chempurchasedunit
					**Standardize each quantity purchased to grams
						gen conversion_factor = .
						*Liter
						replace conversion_factor = 1000 if chempurchasedunit == 3
						*Grams
						replace conversion_factor = 1 if chempurchasedunit == 4
						*Small bag (15kg)
						replace conversion_factor = 15000 if chempurchasedunit == 2
						*Big bag (50kg)
						replace conversion_factor = 50000 if chempurchasedunit == 1
					**Calculate quantity in grams
						gen quantity_in_grams = chempurchased * conversion_factor
					**Calculate price per gram
						gen price_per_gram = chempurchasedprice / quantity_in_grams
					**Calculate median price per gram for each chemical name
						bysort chemname chempurchased: egen median_price_per_gram = median(price_per_gram)
				**Standardize each quantity used on plots to grams
					forvalues i = 1/10 {
						*Define conversion factors for each unit
						gen conversion_factor_plot`i' = .
						* Liter
						replace conversion_factor_plot`i' = 1000 if chemperplot`i'_chemunits == 3
						*Grams
						replace conversion_factor_plot`i' = 1 if chemperplot`i'_chemunits == 4
						*Small bag (15kg)
						replace conversion_factor_plot`i' = 15000 if chemperplot`i'_chemunits == 2
						*Big bag (50kg)
						replace conversion_factor_plot`i' = 50000 if chemperplot`i'_chemunits == 1
						*Calculate the standardized quantity in grams for each plot
						gen quantity_in_grams_plot`i' = chemperplot`i'_chemquant * conversion_factor_plot`i'
						}
				**Calculate cost per each plot
					forvalues i = 1/10 {
					gen cost_perplot`i' = quantity_in_grams_plot`i' * median_price_per_gram
					}
				**Reshape data to create plotid
					reshape long cost_perplot, i(FPrimary InstanceNumber) j(plotid)
				**sum plotid by FPrimary
					collapse (sum) cost_perplot, by(FPrimary plotid InstanceNumber)
				**Drop if missing cost_perplot
					drop if cost_perplot == 0
				**Rename cost_perplot to chemcost
					rename cost_perplot chemcost
				**Destring FPrimary for merge
					destring FPrimary, replace
				**Assert id
					isid FPrimary plotid InstanceNumber
				**Save Chemcost_wave2
					gen wave = 2
					tempfile w2chemcost
					save `w2chemcost', replace
				}
	** C. Wave 3
		{
			**Wave 3 has not chemical purchase price, saving chemical purchase price per gram from wave2 to merge with wave 1
						u "${raw_w2}/04l_chemquestions.dta", clear
					**Assert id
						isid FPrimary InstanceNumber
					**Standardize each quantity purchased to grams
						gen conversion_factor = .
						*Liter
						replace conversion_factor = 1000 if chempurchasedunit == 3
						*Grams
						replace conversion_factor = 1 if chempurchasedunit == 4
						*Small bag (15kg)
						replace conversion_factor = 15000 if chempurchasedunit == 2
						*Big bag (50kg)
						replace conversion_factor = 50000 if chempurchasedunit == 1
						*Calculate quantity in grams
						gen quantity_in_grams = chempurchased * conversion_factor
						*Calculate price per gram
						gen price_per_gram = chempurchasedprice / quantity_in_grams
						*Calculate median price per gram for each chemical name
						bysort chemname chempurchased: egen median_price_per_gram = median(price_per_gram)
						*Keep only the variables you need
						keep chemname median_price_per_gram
						* Collapse the dataset to ensure one observation per chemical
						collapse (median) median_price_per_gram, by(chemname)
						* Prepare for merge
						replace chemname = lower(chemname)
						drop in 1
						duplicates drop chemname, force
						* Save the dataset
						tempfile chemcost
						save `chemcost', replace
			**Load dataset
				u "${raw_w3}/04l_chemquestions.dta", clear
			**Standardize each quantity used on plots to grams
				forvalues i = 1/9 {
					*Define conversion factors for each unit
					gen conversion_factor_plot`i' = .
					*Liter
					replace conversion_factor_plot`i' = 1000 if chemperplot_chemunits_`i' == 3
					*Grams
					replace conversion_factor_plot`i' = 1 if chemperplot_chemunits_`i' == 4
					*Small bag (15kg)
					replace conversion_factor_plot`i' = 15000 if chemperplot_chemunits_`i' == 2
					*Big bag (50kg)
					replace conversion_factor_plot`i' = 50000 if chemperplot_chemunits_`i' == 1
					*Calculate the standardized quantity in grams for each plot
					gen quantity_in_grams_plot`i' = chemperplot_chemquant_`i' * conversion_factor_plot`i'
						}
			**Merge with median price
				drop if missing(chemname)
				replace chemname = lower(chemname)
				merge m:1 chemname using `chemcost'
				drop if _merge != 3
			**Calculate cost per each plot
				forvalues i = 1/9 {
				gen cost_perplot`i' = quantity_in_grams_plot`i' * median_price_per_gram
				}
			**Collapse data by FPrimary to sum accross plots the cost per plot
				collapse (sum) cost_perplot1-cost_perplot9, by(FPrimary)
			**Reshape creating plotid
				reshape long cost_perplot, i(FPrimary) j(plotid)
			**Drop if missing cost_perplot
				drop if cost_perplot == .
			**Destring FPrimary
				destring FPrimary, replace
			**Assert id
				isid FPrimary plotid
			**Save Chemcost_wave1
				gen wave = 3
				tempfile w3chemcost
				save `w3chemcost', replace
		}
 }
	**2. Labor Cost
 {
		** A. Wave 1
		{
				**i. Stage#1
					**Load Data
						u "${raw_w1}/s4aix1.dta", clear
					**Rename to unique identifier
						rename hhno FPrimary
						rename s4aix1_plotno plotid
					**Assert ID
						drop if FPrimary == . | plotid == .
						isid FPrimary plotid
					**Men Calculation
						*Renaming confusing variables
						rename s4aix_290i causualmen_day
						rename s4aix_290ii causualmen_hourperday
						rename s4aix_290iii causualmen
						*Changing missing to 0
						replace causualmen_day = 0 if mi(causualmen_day)
						replace causualmen_hourperday = 0 if mi(causualmen_hourperday)
						replace causualmen = 0 if mi(causualmen)
						*Calculating work
						gen causualmen_workhours = causualmen_day * causualmen_hourperday * causualmen
						*Renaming confusing variables
						rename s4aix_293i permanentmen_day
						rename s4aix_293ii permanentmen_hourperday
						rename s4aix_293iii permanentmen
						*Changing missing to 0
						replace permanentmen_day = 0 if mi(permanentmen_day)
						replace permanentmen_hourperday =0 if mi(permanentmen_hourperday)
						replace permanentmen = 0 if mi(permanentmen)
						*Calculating permanent workers hourly
						gen permanentmen_workhours = permanentmen_day * permanentmen_hourperday * permanentmen
						*Renaming confusing variables
						rename s4aix_296i familymen_day
						rename s4aix_296ii familymen_hourperday
						rename s4aix_296iii familymen
						*Changing missing to 0
						replace familymen_day = 0 if mi(familymen_day)
						replace familymen_hourperday = 0 if mi(familymen_hourperday)
						replace familymen = 0 if mi(familymen)
						*Calculating hours worked by men in family
						gen familymen_workhours = familymen_day * familymen_hourperday * familymen
						*Calculating total work by men
						gen men_workhours_1 = causualmen_workhours + permanentmen_workhours + familymen_workhours
					**For Women
						*Renaming confusing variables
						rename s4aix_291i causualwomen_day
						rename s4aix_291ii causualwomen_hourperday
						rename s4aix_291iii causualwomen
						*Changing missing to 0
						replace causualwomen_day = 0 if mi(causualwomen_day)
						replace causualwomen_hourperday = 0 if mi(causualwomen_hourperday)
						replace causualwomen = 0 if mi(causualwomen)
						*Casual workers total hours
						gen causualwomen_workhours = causualwomen_day * causualwomen_hourperday * causualwomen
						*Renaming confusing variables
						rename s4aix_294i permanentwomen_day
						rename s4aix_294ii permanentwomen_hourperday
						rename s4aix_294iii permanentwomen
						*Replace missing to zero
						replace permanentwomen_day = 0 if mi(permanentwomen_day)
						replace permanentwomen_hourperday =0 if mi(permanentwomen_hourperday)
						replace permanentwomen = 0 if mi(permanentwomen)
						*Total hours permanent workers
						gen permanentwomen_workhours = permanentwomen_day * permanentwomen_hourperday * permanentwomen
						*Renaming confusing variables
						rename s4aix_297i familywomen_day
						rename s4aix_297ii familywomen_hourperday
						rename s4aix_297iii familywomen
						*Changing missing to 0
						replace familywomen_day = 0 if mi(familywomen_day)
						replace familywomen_hourperday = 0 if mi(familywomen_hourperday)
						replace familywomen = 0 if mi(familywomen)
						*Total hours worked by family
						gen familywomen_workhours = familywomen_day * familywomen_hourperday * familywomen
						*Total hours worked by women
						gen women_workhours_1 = causualwomen_workhours + permanentwomen_workhours + familywomen_workhours
						*Keeping important variables
						keep FPrimary plotid men_workhours_1 women_workhours_1
					**Saving
						tempfile Laborw1s1
						save `Laborw1s1', replace
				**Stage#2
					**Load Data
						use "${raw_w1}/s4aix2.dta", clear
					**Rename to unique identifier
						rename s4aix2_plotno plotid
					**Assert ID
						drop if FPrimary == . | plotid == .
						isid FPrimary plotid
					**Men Calculation
						*Renaming confusing variables
						rename s4aix_299i causualmen_day
						rename s4aix_299ii causualmen_hourperday
						rename s4aix_299iii causualmen
						*Changing missing to 0
						replace causualmen_day = 0 if mi(causualmen_day)
						replace causualmen_hourperday = 0 if mi(causualmen_hourperday)
						replace causualmen = 0 if mi(causualmen)
						*Calculating work
						gen causualmen_workhours = causualmen_day * causualmen_hourperday * causualmen
						*Renaming confusing variables
						rename s4aix_302i permanentmen_day
						rename s4aix_302ii permanentmen_hourperday
						rename s4aix_302iii permanentmen
						*Changing missing to 0
						replace permanentmen_day = 0 if mi(permanentmen_day)
						replace permanentmen_hourperday = 0 if mi(permanentmen_hourperday)
						replace permanentmen = 0 if mi(permanentmen)
						*Calculating permanent workers hourly
						gen permanentmen_workhours = permanentmen_day * permanentmen_hourperday * permanentmen
						*Renaming confusing variables
						rename s4aix_305i familymen_day
						rename s4aix_305ii familymen_hourperday
						rename s4aix_305iii familymen
						*Changing missing to 0
						replace familymen_day = 0 if mi(familymen_day)
						replace familymen_hourperday = 0 if mi(familymen_hourperday)
						replace familymen = 0 if mi(familymen)
						*Calculating hours worked by men in family
						gen familymen_workhours = familymen_day * familymen_hourperday * familymen
						*Calculating total work by men
						gen men_workhours_2 = causualmen_workhours + permanentmen_workhours + familymen_workhours
					**Women Calculation
						*Renaming confusing variables
						rename s4aix_300i causualwomen_day
						rename s4aix_300ii causualwomen_hourperday
						rename s4aix_300iii causualwomen
						*Changing missing to 0
						replace causualwomen_day = 0 if mi(causualwomen_day)
						replace causualwomen_hourperday = 0 if mi(causualwomen_hourperday)
						replace causualwomen = 0 if mi(causualwomen)
						*Casual workers total hours
						gen causualwomen_workhours = causualwomen_day * causualwomen_hourperday * causualwomen
						*Renaming confusing variables
						rename s4aix_303i permanentwomen_day
						rename s4aix_303ii permanentwomen_hourperday
						rename s4aix_303iii permanentwomen
						*Replace missing to zero
						replace permanentwomen_day = 0 if mi(permanentwomen_day)
						replace permanentwomen_hourperday = 0 if mi(permanentwomen_hourperday)
						replace permanentwomen = 0 if mi(permanentwomen)
						*Total hours permanent workers
						gen permanentwomen_workhours = permanentwomen_day * permanentwomen_hourperday * permanentwomen
						*Renaming confusing variables
						rename s4aix_306i familywomen_day
						rename s4aix_306ii familywomen_hourperday
						rename s4aix_306iii familywomen
						*Changing missing to 0
						replace familywomen_day = 0 if mi(familywomen_day)
						replace familywomen_hourperday = 0 if mi(familywomen_hourperday)
						replace familywomen = 0 if mi(familywomen)
						*Total hours worked by family
						gen familywomen_workhours = familywomen_day * familywomen_hourperday * familywomen
						*Total hours worked by women
						gen women_workhours_2 = causualwomen_workhours + permanentwomen_workhours + familywomen_workhours
					**Keeping important variables
						keep FPrimary plotid men_workhours_2 women_workhours_2
					**Saving
						tempfile Laborw1s2
						save `Laborw1s2', replace
				**Stage#3
					**Load Data
						use "${raw_w1}/s4aix3.dta", clear
					**Rename to unique identifier
						rename s4aix3_plotno plotid
					**Assert ID
						drop if FPrimary == . | plotid == .
						isid FPrimary plotid
					**Men Calculation
						*Renaming confusing variables
						rename s4aix_308i causualmen_day
						rename s4aix_308ii causualmen_hourperday
						rename s4aix_308iii causualmen
						*Changing missing to 0
						replace causualmen_day = 0 if mi(causualmen_day)
						replace causualmen_hourperday = 0 if mi(causualmen_hourperday)
						replace causualmen = 0 if mi(causualmen)
						*Calculating work
						gen causualmen_workhours = causualmen_day * causualmen_hourperday * causualmen
						*Renaming confusing variables
						rename s4aix_311i permanentmen_day
						rename s4aix_311ii permanentmen_hourperday
						rename s4aix_311iii permanentmen
						*Changing missing to 0
						replace permanentmen_day = 0 if mi(permanentmen_day)
						replace permanentmen_hourperday = 0 if mi(permanentmen_hourperday)
						replace permanentmen = 0 if mi(permanentmen)
						*Calculating permanent workers hourly
						gen permanentmen_workhours = permanentmen_day * permanentmen_hourperday * permanentmen
						*Renaming confusing variables
						rename s4aix_314i familymen_day
						rename s4aix_314ii familymen_hourperday
						rename s4aix_314iii familymen
						*Changing missing to 0
						replace familymen_day = 0 if mi(familymen_day)
						replace familymen_hourperday = 0 if mi(familymen_hourperday)
						replace familymen = 0 if mi(familymen)
						*Calculating hours worked by men in family
						gen familymen_workhours = familymen_day * familymen_hourperday * familymen
						*Calculating total work by men
						gen men_workhours_3 = causualmen_workhours + permanentmen_workhours + familymen_workhours
					**Women Calculation
						*Renaming confusing variables
						rename s4aix_309i causualwomen_day
						rename s4aix_309ii causualwomen_hourperday
						rename s4aix_309iii causualwomen
						*Changing missing to 0
						replace causualwomen_day = 0 if mi(causualwomen_day)
						replace causualwomen_hourperday = 0 if mi(causualwomen_hourperday)
						replace causualwomen = 0 if mi(causualwomen)
						*Casual workers total hours
						gen causualwomen_workhours = causualwomen_day * causualwomen_hourperday * causualwomen
						*Renaming confusing variables
						rename s4aix_312i permanentwomen_day
						rename s4aix_312ii permanentwomen_hourperday
						rename s4aix_312iii permanentwomen
						*Replace missing to zero
						replace permanentwomen_day = 0 if mi(permanentwomen_day)
						replace permanentwomen_hourperday = 0 if mi(permanentwomen_hourperday)
						replace permanentwomen = 0 if mi(permanentwomen)
						*Total hours permanent workers
						gen permanentwomen_workhours = permanentwomen_day * permanentwomen_hourperday * permanentwomen
						*Renaming confusing variables
						rename s4aix_315i familywomen_day
						rename s4aix_315ii familywomen_hourperday
						rename s4aix_315iii familywomen
						*Changing missing to 0
						replace familywomen_day = 0 if mi(familywomen_day)
						replace familywomen_hourperday = 0 if mi(familywomen_hourperday)
						replace familywomen = 0 if mi(familywomen)
						*Total hours worked by family
						gen familywomen_workhours = familywomen_day * familywomen_hourperday * familywomen
						*Total hours worked by women
						gen women_workhours_3 = causualwomen_workhours + permanentwomen_workhours + familywomen_workhours
					**Keeping important variables
						keep FPrimary plotid men_workhours_3 women_workhours_3
					**Saving
						tempfile Laborw1s3
						save `Laborw1s3', replace
				**Stage#4
					**Load Data
						use "${raw_w1}/s4aix4.dta", clear
					**Rename to unique identifier
						rename s4aix4_plotno plotid
					**Assert ID
						drop if FPrimary == . | plotid == .
						isid FPrimary plotid
					**Men Calculation
						*Renaming confusing variables
						rename s4aix_317i causualmen_day
						rename s4aix_317ii causualmen_hourperday
						rename s4aix_317iii causualmen
						*Changing missing to 0
						replace causualmen_day = 0 if mi(causualmen_day)
						replace causualmen_hourperday = 0 if mi(causualmen_hourperday)
						replace causualmen = 0 if mi(causualmen)
						*Calculating work
						gen causualmen_workhours = causualmen_day * causualmen_hourperday * causualmen
						*Renaming confusing variables
						rename s4aix_320i permanentmen_day
						rename s4aix_320ii permanentmen_hourperday
						rename s4aix_320iii permanentmen
						*Changing missing to 0
						replace permanentmen_day = 0 if mi(permanentmen_day)
						replace permanentmen_hourperday = 0 if mi(permanentmen_hourperday)
						replace permanentmen = 0 if mi(permanentmen)
						*Calculating permanent workers hourly
						gen permanentmen_workhours = permanentmen_day * permanentmen_hourperday * permanentmen
						*Renaming confusing variables
						rename s4aix_323i familymen_day
						rename s4aix_323ii familymen_hourperday
						rename s4aix_323iii familymen
						*Changing missing to 0
						replace familymen_day = 0 if mi(familymen_day)
						replace familymen_hourperday = 0 if mi(familymen_hourperday)
						replace familymen = 0 if mi(familymen)
						*Calculating hours worked by men in family
						gen familymen_workhours = familymen_day * familymen_hourperday * familymen
						*Calculating total work by men
						gen men_workhours_4 = causualmen_workhours + permanentmen_workhours + familymen_workhours
					**Women Calculation
						*Renaming confusing variables
						rename s4aix_318i causualwomen_day
						rename s4aix_318ii causualwomen_hourperday
						rename s4aix_318iii causualwomen
						*Changing missing to 0
						replace causualwomen_day = 0 if mi(causualwomen_day)
						replace causualwomen_hourperday = 0 if mi(causualwomen_hourperday)
						replace causualwomen = 0 if mi(causualwomen)
						*Casual workers total hours
						gen causualwomen_workhours = causualwomen_day * causualwomen_hourperday * causualwomen
						*Renaming confusing variables
						rename s4aix_321i permanentwomen_day
						rename s4aix_321ii permanentwomen_hourperday
						rename s4aix_321iii permanentwomen
						*Replace missing to zero
						replace permanentwomen_day = 0 if mi(permanentwomen_day)
						replace permanentwomen_hourperday = 0 if mi(permanentwomen_hourperday)
						replace permanentwomen = 0 if mi(permanentwomen)
						*Total hours permanent workers
						gen permanentwomen_workhours = permanentwomen_day * permanentwomen_hourperday * permanentwomen
						*Renaming confusing variables
						rename s4aix_324i familywomen_day
						rename s4aix_324ii familywomen_hourperday
						rename s4aix_324iii familywomen
						*Changing missing to 0
						replace familywomen_day = 0 if mi(familywomen_day)
						replace familywomen_hourperday = 0 if mi(familywomen_hourperday)
						replace familywomen = 0 if mi(familywomen)
						*Total hours worked by family
						gen familywomen_workhours = familywomen_day * familywomen_hourperday * familywomen
						*Total hours worked by women
						gen women_workhours_4 = causualwomen_workhours + permanentwomen_workhours + familywomen_workhours
					**Keeping important variables
						keep FPrimary plotid men_workhours_4 women_workhours_4
					**Saving
						tempfile Laborw1s4
						save `Laborw1s4', replace
				**Stage#5
					**Load Data
						use "${raw_w1}/s4aix5.dta", clear
					**Rename to unique identifier
						rename s4aix5_plotno plotid
					**Assert ID
						drop if FPrimary == . | plotid == .
						isid FPrimary plotid
					**Men Calculation
						*Renaming confusing variables
						rename s4aix_327i causualmen_day
						rename s4aix_327ii causualmen_hourperday
						rename s4aix_327iii causualmen
						*Changing missing to 0
						replace causualmen_day = 0 if mi(causualmen_day)
						replace causualmen_hourperday = 0 if mi(causualmen_hourperday)
						replace causualmen = 0 if mi(causualmen)
						*Calculating work
						gen causualmen_workhours = causualmen_day * causualmen_hourperday * causualmen
						*Renaming confusing variables
						rename s4aix_330i permanentmen_day
						rename s4aix_330ii permanentmen_hourperday
						rename s4aix_330iii permanentmen
						*Changing missing to 0
						replace permanentmen_day = 0 if mi(permanentmen_day)
						replace permanentmen_hourperday = 0 if mi(permanentmen_hourperday)
						replace permanentmen = 0 if mi(permanentmen)
						*Calculating permanent workers hourly
						gen permanentmen_workhours = permanentmen_day * permanentmen_hourperday * permanentmen
						*Renaming confusing variables
						rename s4aix_333i familymen_day
						rename s4aix_333ii familymen_hourperday
						rename s4aix_333iii familymen
						*Changing missing to 0
						replace familymen_day = 0 if mi(familymen_day)
						replace familymen_hourperday = 0 if mi(familymen_hourperday)
						replace familymen = 0 if mi(familymen)
						*Calculating hours worked by men in family
						gen familymen_workhours = familymen_day * familymen_hourperday * familymen
						*Calculating total work by men
						gen men_workhours_5 = causualmen_workhours + permanentmen_workhours + familymen_workhours
				**Women Calculation
					*Renaming confusing variables
					rename s4aix_328i causualwomen_day
					rename s4aix_328ii causualwomen_hourperday
					rename s4aix_328iii causualwomen
					*Changing missing to 0
					replace causualwomen_day = 0 if mi(causualwomen_day)
					replace causualwomen_hourperday = 0 if mi(causualwomen_hourperday)
					replace causualwomen = 0 if mi(causualwomen)
					*Casual workers total hours
					gen causualwomen_workhours = causualwomen_day * causualwomen_hourperday * causualwomen
					*Renaming confusing variables
					rename s4aix_331i permanentwomen_day
					rename s4aix_331ii permanentwomen_hourperday
					rename s4aix_331iii permanentwomen
					*Replace missing to zero
					replace permanentwomen_day = 0 if mi(permanentwomen_day)
					replace permanentwomen_hourperday = 0 if mi(permanentwomen_hourperday)
					replace permanentwomen = 0 if mi(permanentwomen)
					*Total hours permanent workers
					gen permanentwomen_workhours = permanentwomen_day * permanentwomen_hourperday * permanentwomen
					*Renaming confusing variables
					rename s4aix_334i familywomen_day
					rename s4aix_334ii familywomen_hourperday
					rename s4aix_334iii familywomen
					*Changing missing to 0
					replace familywomen_day = 0 if mi(familywomen_day)
					replace familywomen_hourperday = 0 if mi(familywomen_hourperday)
					replace familywomen = 0 if mi(familywomen)
					*Total hours worked by family
					gen familywomen_workhours = familywomen_day * familywomen_hourperday * familywomen
					*Total hours worked by women
					gen women_workhours_5 = causualwomen_workhours + permanentwomen_workhours + familywomen_workhours
				**Keeping important variables
					keep FPrimary plotid men_workhours_5 women_workhours_5
				**Saving
					tempfile Laborw1s5
					save `Laborw1s5', replace
				**Stage#6
					**Load Data
						use "${raw_w1}/s4aix6.dta", clear
					**Rename to unique identifier
						rename s4aix6_plotno plotid
					**Assert ID
						drop if FPrimary == . | plotid == .
						isid FPrimary plotid
					**Men Calculation
						*Renaming confusing variables
						rename s4aix_336i causualmen_day
						rename s4aix_336ii causualmen_hourperday
						rename s4aix_336iii causualmen
						*Changing missing to 0
						replace causualmen_day = 0 if mi(causualmen_day)
						replace causualmen_hourperday = 0 if mi(causualmen_hourperday)
						replace causualmen = 0 if mi(causualmen)
						*Calculating work
						gen causualmen_workhours = causualmen_day * causualmen_hourperday * causualmen
						*Renaming confusing variables
						rename s4aix_339i permanentmen_day
						rename s4aix_339ii permanentmen_hourperday
						rename s4aix_339iii permanentmen
						*Changing missing to 0
						replace permanentmen_day = 0 if mi(permanentmen_day)
						replace permanentmen_hourperday = 0 if mi(permanentmen_hourperday)
						replace permanentmen = 0 if mi(permanentmen)
						*Calculating permanent workers hourly
						gen permanentmen_workhours = permanentmen_day * permanentmen_hourperday * permanentmen
						*Renaming confusing variables
						rename s4aix_342i familymen_day
						rename s4aix_342ii familymen_hourperday
						rename s4aix_342iii familymen
						*Changing missing to 0
						replace familymen_day = 0 if mi(familymen_day)
						replace familymen_hourperday = 0 if mi(familymen_hourperday)
						replace familymen = 0 if mi(familymen)
						*Calculating hours worked by men in family
						gen familymen_workhours = familymen_day * familymen_hourperday * familymen
						*Calculating total work by men
						gen men_workhours_6 = causualmen_workhours + permanentmen_workhours + familymen_workhours
					**Women Calculation
						*Renaming confusing variables
						rename s4aix_337i causualwomen_day
						rename s4aix_337ii causualwomen_hourperday
						rename s4aix_337iii causualwomen
						*Changing missing to 0
						replace causualwomen_day = 0 if mi(causualwomen_day)
						replace causualwomen_hourperday = 0 if mi(causualwomen_hourperday)
						replace causualwomen = 0 if mi(causualwomen)
						*Casual workers total hours
						gen causualwomen_workhours = causualwomen_day * causualwomen_hourperday * causualwomen
						*Renaming confusing variables
						rename s4aix_340i permanentwomen_day
						rename s4aix_340ii permanentwomen_hourperday
						rename s4aix_340iii permanentwomen
						*Replace missing to zero
						replace permanentwomen_day = 0 if mi(permanentwomen_day)
						replace permanentwomen_hourperday = 0 if mi(permanentwomen_hourperday)
						replace permanentwomen = 0 if mi(permanentwomen)
						*Total hours permanent workers
						gen permanentwomen_workhours = permanentwomen_day * permanentwomen_hourperday * permanentwomen
						*Renaming confusing variables
						rename s4aix_343i familywomen_day
						rename s4aix_343ii familywomen_hourperday
						rename s4aix_343iii familywomen
						*Changing missing to 0
						replace familywomen_day = 0 if mi(familywomen_day)
						replace familywomen_hourperday = 0 if mi(familywomen_hourperday)
						replace familywomen = 0 if mi(familywomen)
						*Total hours worked by family
						gen familywomen_workhours = familywomen_day * familywomen_hourperday * familywomen
						*Total hours worked by women
						gen women_workhours_6 = causualwomen_workhours + permanentwomen_workhours + familywomen_workhours
					**Keeping important variables
						keep FPrimary plotid men_workhours_6 women_workhours_6
					**Saving
						tempfile Laborw1s6
						save `Laborw1s6', replace
				**Stage#7
					**Load Data
						use "${raw_w1}/s4aix7.dta", clear
					**Rename to unique identifier
						rename s4aix7_plotno plotid
					**Assert ID
						drop if FPrimary == . | plotid == .
						isid FPrimary plotid
					**Men Calculation
						*Renaming confusing variables
						rename s4aix_345i causualmen_day
						rename s4aix_345ii causualmen_hourperday
						rename s4aix_345iii causualmen
						*Changing missing to 0
						replace causualmen_day = 0 if mi(causualmen_day)
						replace causualmen_hourperday = 0 if mi(causualmen_hourperday)
						replace causualmen = 0 if mi(causualmen)
						*Calculating work
						gen causualmen_workhours = causualmen_day * causualmen_hourperday * causualmen
						*Renaming confusing variables
						rename s4aix_348i permanentmen_day
						rename s4aix_348ii permanentmen_hourperday
						rename s4aix_348iii permanentmen
						*Changing missing to 0
						replace permanentmen_day = 0 if mi(permanentmen_day)
						replace permanentmen_hourperday = 0 if mi(permanentmen_hourperday)
						replace permanentmen = 0 if mi(permanentmen)
						*Calculating permanent workers hourly
						gen permanentmen_workhours = permanentmen_day * permanentmen_hourperday * permanentmen
						*Renaming confusing variables
						rename s4aix_351i familymen_day
						rename s4aix_351ii familymen_hourperday
						rename s4aix_351iii familymen
						*Changing missing to 0
						replace familymen_day = 0 if mi(familymen_day)
						replace familymen_hourperday = 0 if mi(familymen_hourperday)
						replace familymen = 0 if mi(familymen)
						*Calculating hours worked by men in family
						gen familymen_workhours = familymen_day * familymen_hourperday * familymen
						*Calculating total work by men
						gen men_workhours_7 = causualmen_workhours + permanentmen_workhours + familymen_workhours
					**Women Calculation
						*Renaming confusing variables
						rename s4aix_346i causualwomen_day
						rename s4aix_346ii causualwomen_hourperday
						rename s4aix_346iii causualwomen
						*Changing missing to 0
						replace causualwomen_day = 0 if mi(causualwomen_day)
						replace causualwomen_hourperday = 0 if mi(causualwomen_hourperday)
						replace causualwomen = 0 if mi(causualwomen)
						*Casual workers total hours
						gen causualwomen_workhours = causualwomen_day * causualwomen_hourperday * causualwomen
						*Renaming confusing variables
						rename s4aix_349i permanentwomen_day
						rename s4aix_349ii permanentwomen_hourperday
						rename s4aix_349iii permanentwomen
						*Replace missing to zero
						replace permanentwomen_day = 0 if mi(permanentwomen_day)
						replace permanentwomen_hourperday = 0 if mi(permanentwomen_hourperday)
						replace permanentwomen = 0 if mi(permanentwomen)
						*Total hours permanent workers
						gen permanentwomen_workhours = permanentwomen_day * permanentwomen_hourperday * permanentwomen
						*Renaming confusing variables
						rename s4aix_352i familywomen_day
						rename s4aix_352ii familywomen_hourperday
						rename s4aix_352iii familywomen
						*Changing missing to 0
						replace familywomen_day = 0 if mi(familywomen_day)
						replace familywomen_hourperday = 0 if mi(familywomen_hourperday)
						replace familywomen = 0 if mi(familywomen)
						*Total hours worked by family
						gen familywomen_workhours = familywomen_day * familywomen_hourperday * familywomen
						*Total hours worked by women
						gen women_workhours_7 = causualwomen_workhours + permanentwomen_workhours + familywomen_workhours
					**Keeping important variables
						keep FPrimary plotid men_workhours_7 women_workhours_7
					**Saving
						tempfile Laborw1s7
						save `Laborw1s7', replace
				**Stage#8
					**Load Data
						use "${raw_w1}/s4aix8.dta", clear
					**Rename to unique identifier
						rename s4aix8_plotno plotid
					**Assert ID
						drop if FPrimary == . | plotid == .
						isid FPrimary plotid
					**Men Calculation
						*Renaming confusing variables
						rename s4aix_354i causualmen_day
						rename s4aix_354ii causualmen_hourperday
						rename s4aix_354iii causualmen
						*Changing missing to 0
						replace causualmen_day = 0 if mi(causualmen_day)
						replace causualmen_hourperday = 0 if mi(causualmen_hourperday)
						replace causualmen = 0 if mi(causualmen)
						*Calculating work
						gen causualmen_workhours = causualmen_day * causualmen_hourperday * causualmen
						*Renaming confusing variables
						rename s4aix_357i permanentmen_day
						rename s4aix_357ii permanentmen_hourperday
						rename s4aix_357iii permanentmen
						*Changing missing to 0
						replace permanentmen_day = 0 if mi(permanentmen_day)
						replace permanentmen_hourperday = 0 if mi(permanentmen_hourperday)
						replace permanentmen = 0 if mi(permanentmen)
						*Calculating permanent workers hourly
						gen permanentmen_workhours = permanentmen_day * permanentmen_hourperday * permanentmen
						*Renaming confusing variables
						rename s4aix_360i familymen_day
						rename s4aix_360ii familymen_hourperday
						rename s4aix_360iii familymen
						*Changing missing to 0
						replace familymen_day = 0 if mi(familymen_day)
						replace familymen_hourperday = 0 if mi(familymen_hourperday)
						replace familymen = 0 if mi(familymen)
						*Calculating hours worked by men in family
						gen familymen_workhours = familymen_day * familymen_hourperday * familymen
						*Calculating total work by men
						gen men_workhours_8 = causualmen_workhours + permanentmen_workhours + familymen_workhours
					**Women Calculation
						*Renaming confusing variables
						rename s4aix_355i causualwomen_day
						rename s4aix_355ii causualwomen_hourperday
						rename s4aix_355iii causualwomen
						*Changing missing to 0
						replace causualwomen_day = 0 if mi(causualwomen_day)
						replace causualwomen_hourperday = 0 if mi(causualwomen_hourperday)
						replace causualwomen = 0 if mi(causualwomen)
						*Casual workers total hours
						gen causualwomen_workhours = causualwomen_day * causualwomen_hourperday * causualwomen
					*Renaming confusing variables
					rename s4aix_358i permanentwomen_day
					rename s4aix_358ii permanentwomen_hourperday
					rename s4aix_358iii permanentwomen
					*Replace missing to zero
					replace permanentwomen_day = 0 if mi(permanentwomen_day)
					replace permanentwomen_hourperday = 0 if mi(permanentwomen_hourperday)
					replace permanentwomen = 0 if mi(permanentwomen)
					*Total hours permanent workers
					gen permanentwomen_workhours = permanentwomen_day * permanentwomen_hourperday * permanentwomen
					*Renaming confusing variables
					rename s4aix_361i familywomen_day
					rename s4aix_361ii familywomen_hourperday
					rename s4aix_361iii familywomen
					*Changing missing to 0
					replace familywomen_day = 0 if mi(familywomen_day)
					replace familywomen_hourperday = 0 if mi(familywomen_hourperday)
					replace familywomen = 0 if mi(familywomen)
					*Total hours worked by family
					gen familywomen_workhours = familywomen_day * familywomen_hourperday * familywomen
					*Total hours worked by women
					gen women_workhours_8 = causualwomen_workhours + permanentwomen_workhours + familywomen_workhours
				**Keeping important variables
					keep FPrimary plotid men_workhours_8 women_workhours_8
				**Saving
					tempfile Laborw1s8
					save `Laborw1s8', replace
				**Merging all 9 labor costs
					merge 1:1 FPrimary plotid using `Laborw1s1', nogen
					merge 1:1 FPrimary plotid using `Laborw1s2', nogen
					merge 1:1 FPrimary plotid using `Laborw1s3', nogen
					merge 1:1 FPrimary plotid using `Laborw1s4', nogen
					merge 1:1 FPrimary plotid using `Laborw1s5', nogen
					merge 1:1 FPrimary plotid using `Laborw1s6', nogen
					merge 1:1 FPrimary plotid using `Laborw1s7', nogen
				**Total hours accross all panels
					gen total_men_workhours = men_workhours_1 + men_workhours_2 + men_workhours_3 + men_workhours_4 + men_workhours_5 + men_workhours_6 + men_workhours_7 + men_workhours_8
					gen total_women_workhours = women_workhours_1 + women_workhours_2 + women_workhours_3 + women_workhours_4 + women_workhours_5 + women_workhours_6 + women_workhours_7 + women_workhours_8
				**Keeping important variables
					keep FPrimary plotid total_men_workhours total_women_workhours
				**Saving
					tempfile Laborw1hours
					save `Laborw1hours', replace
			**ii. Wage
				**Using wave 2 medium wage
					*Load data
					use  "${raw_w2}/04m_aglabour.dta", clear
					isid FPrimary InstanceNumber plotid
					*Replace missing values
					replace hiredavgpayman = 0 if mi(hiredavgpayman)
					replace hiredavgpaywoman = 0 if mi(hiredavgpaywoman)
					*Calculate average pay male
					gen MaleAveWage_Perday_1 = hiredavgpayman * 1 if hiredpayunit == 1
					gen MaleAveWage_Perday_2 = hiredavgpayman * (1/7) if hiredpayunit == 2
					gen MaleAveWage_Perday_3 = hiredavgpayman * (1/30.44) if hiredpayunit == 3
					*Per Plot
					drop if hiredpayunit == 4
					*Per Acre
					drop if hiredpayunit == 5
					*Per Pole
					drop if hiredpayunit == 6
					*Per Rope
					drop if hiredpayunit == 7
					*Other
					drop if hiredpayunit == -666
					*Calculate average pay female
					gen FemaleAveWage_Perday_1 = hiredavgpaywoman * 1 if hiredpayunit == 1
					gen FemaleAveWage_Perday_2 = hiredavgpaywoman * (1/7) if hiredpayunit == 2
					gen FemaleAveWage_Perday_3 = hiredavgpaywoman * (1/30.44) if hiredpayunit == 3
					*Per Plot
					drop if hiredpayunit == 4
					*Per Acre
					drop if hiredpayunit == 5
					*Per Pole
					drop if hiredpayunit == 6
					*Per Rope
					drop if hiredpayunit == 7
					*Other
					drop if hiredpayunit == -666
					*Median pay male and female
					egen medMLW = rowmedian(MaleAveWage_Perday_1 MaleAveWage_Perday_2 MaleAveWage_Perday_3)
					egen medFLW = rowmedian(FemaleAveWage_Perday_1 FemaleAveWage_Perday_2 FemaleAveWage_Perday_3)
					*Replace missing values
					replace medMLW = 0 if mi(medMLW)
					replace medFLW = 0 if mi(medFLW)
					*Save file
					destring FPrimary, replace
					drop if mi(hiredpayunit)
					tempfile medwagew2
					save `medwagew2', replace
				**Load hours wave1
					u `Laborw1hours', clear
				**Merge medwage
					merge 1:m FPrimary plotid using `medwagew2'
				**Massage data
					keep FPrimary plotid total_men_workhours total_women_workhours medFLW medMLW
					replace total_men_workhours = 0 if mi(total_men_workhours)
					replace total_women_workhours = 0 if mi(total_women_workhours)
					replace medMLW = medMLW / 12
					replace medFLW = medFLW / 12
					replace medMLW = 0 if mi(medMLW)
					replace medFLW = 0 if mi(medFLW)
				**Generate total labor cost
					gen total_labor_cost = medMLW * total_men_workhours + medFLW * total_women_workhours
					replace total_labor_cost = 0 if mi(total_labor_cost)
				**Create InstanceNumber
					bysort FPrimary: generate InstanceNumber = _n
				**Assert ID
					keep FPrimary plotid InstanceNumber total_labor_cost
					isid FPrimary plotid
				**Saving
					tempfile LaborCost1
					save `LaborCost1', replace
				
				
			}
		** B. Wave 2
		{
			**Load Data
				u "${raw_w2}/04m_aglabourquestions.dta", clear
			**Checking unique id
				isid FPrimary InstanceNumber plotid, m
			**Create new variables
				gen malepersonaldays = .
				gen femalepersonaldays = .
			**Change missing value to zero
				replace malepersonaldays = 0 if mi(malepersonaldays)
				replace familymendays = 0 if mi(familymendays)
				replace communalmendays = 0 if mi(communalmendays)
				replace hiredmendays = 0 if mi(hiredwomendays)
				replace othermendays = 0 if mi(othermendays)
				replace femalepersonaldays = 0 if mi(femalepersonaldays)
				replace familywomendays = 0 if mi(familywomendays)
				replace communalwomendays = 0 if mi(communalwomendays)
				replace hiredwomendays = 0 if mi(hiredwomendays)
				replace otherwomendays = 0 if mi(otherwomendays)
			**Calculate total work days
				gen MaleWorkDays = malepersonaldays + familymendays + communalmendays + hiredmendays + othermendays
				gen FemaleWorkDays = femalepersonaldays + familywomendays + communalwomendays + hiredwomendays + otherwomendays
			**Destring FPrimary
				destring FPrimary, replace
			**Merge with average wages
				merge 1:1 FPrimary InstanceNumber plotid using `medwagew2', nogen
			**Calculate total wage per plot	
				gen TotalMaleWage = medMLW * MaleWorkDays
				gen TotalFemaleWage = medFLW * FemaleWorkDays
				egen TotalWage = rowtotal(TotalMaleWage TotalFemaleWage)
			**Change missing to zero
				replace TotalMaleWage = 0 if mi(TotalMaleWage)
				replace TotalFemaleWage = 0 if mi(TotalFemaleWage)
			**The food cost for commlabor and hiredlabor
				replace commlabfoodcost = 0 if mi(commlabfoodcost)
				replace hiredfoodcost = 0 if mi(hiredfoodcost)
				gen TotalFoodCost = commlabfoodcost + hiredfoodcost
			**Calculate total costs
				egen TotalLaborCosts = rowtotal(TotalWage TotalFoodCost)
			**Drop missing data
				drop if missing(FPrimary) | missing(plotid) | missing(InstanceNumber)
			**Drop duplicates
				duplicates drop FPrimary plotid InstanceNumber, force
			**Assert ID
				isid FPrimary plotid InstanceNumber
			**Save
				keep FPrimary plotid InstanceNumber TotalMaleWage TotalFemaleWage TotalWage TotalFoodCost TotalLaborCosts
				rename TotalLaborCosts total_labor_cost
				tempfile LaborCost2
				save `LaborCost2', replace
		}
		** C. Wave 3
		{
			**Load Data
				u "${raw_w3}/04m_aglabourquestions.dta", clear
			**Checking for unique ID(does not)
				capture isid FPrimary plotid
			**Sort the data by FPrimary and plotid
				sort FPrimary plotid
			**Create new variables
				gen malepersonaldays = .
				gen femalepersonaldays = .
			**Change missing value to zero
				replace malepersonaldays = 0 if mi(malepersonaldays)
				replace familymendays = 0 if mi(familymendays)
				replace communalmendays = 0 if mi(communalmendays)
				replace hiredmendays = 0 if mi(hiredwomendays)
				replace othermendays = 0 if mi(othermendays)
				replace femalepersonaldays = 0 if mi(femalepersonaldays)
				replace familywomendays = 0 if mi(familywomendays)
				replace communalwomendays = 0 if mi(communalwomendays)
				replace hiredwomendays = 0 if mi(hiredwomendays)
				replace otherwomendays = 0 if mi(otherwomendays)
			**Calculate total work days
				gen MaleWorkDays = malepersonaldays + familymendays + communalmendays + hiredmendays + othermendays
				gen FemaleWorkDays = femalepersonaldays + familywomendays + communalwomendays + hiredwomendays + otherwomendays
			**Destring FPrimary
				destring FPrimary, replace
			**Merge with costs
				merge m:1 FPrimary plotid using `medwagew2', nogen
			**Calculate total wage per plot	
				gen TotalMaleWage = medMLW * MaleWorkDays
				gen TotalFemaleWage = medFLW * FemaleWorkDays
				egen TotalWage = rowtotal(TotalMaleWage TotalFemaleWage)
			**Change missing to zero
				replace TotalMaleWage = 0 if mi(TotalMaleWage)
				replace TotalFemaleWage = 0 if mi(TotalFemaleWage)
			**The food cost for commlabor and hiredlabor
				replace commlabfoodcost = 0 if mi(commlabfoodcost)
				replace hiredfoodcost = 0 if mi(hiredfoodcost)
				gen TotalFoodCost = commlabfoodcost + hiredfoodcost
			**Calculate total costs
				egen TotalLaborCosts = rowtotal(TotalWage TotalFoodCost)
			**Drop missing data
				drop if missing(FPrimary) | missing(plotid)
			**Drop duplicates
				duplicates drop FPrimary plotid, force
			**Assert ID
				isid FPrimary plotid
			**Save
				keep FPrimary plotid TotalMaleWage TotalFemaleWage TotalWage TotalFoodCost TotalLaborCosts
				tempfile LaborCost3
				save `LaborCost3', replace
		}
 }
	**3. Land Prep Cost
 {
		**A. Wave 1
			{
			**Load data
				u "${raw_w1}/s4avii.dta", clear
			**Renaming confusing varaibles
				rename s4avii_plotno plotid
				rename s4avii_244i landprepcost_ma
				rename s4avii_246i landprepcost_mi
			**Replace missing values
				replace landprepcost_ma = 0 if mi(landprepcost_ma)
				replace landprepcost_mi = 0 if mi(landprepcost_mi)
			**Gen total landprep cost
				gen landprepcost = landprepcost_ma + landprepcost_mi
				replace landprepcost = 0 if mi(landprepcost)
			**Drop if misisng plotid
				drop if mi(plotid)
			**Assert id
				isid FPrimary plotid
			**Keeping important variables
				keep FPrimary plotid landprepcost
			**Save
				tempfile landprepcost1
				save `landprepcost1', replace
			}
		**B. Wave 2
			{
			**Load tractor/plough use data
				u "${raw_w2}/04j_tracploughuse.dta", clear
			**Assert id
				isid FPrimary InstanceNumber plotid
			**Prepare for merge with land tenure costs
				keep FPrimary InstanceNumber plotid ploughpaymentcash
			**Merge
				merge 1:1 FPrimary InstanceNumber using "${raw_w2}/04i_landtenure.dta", keep(match)
			**Replace missing values
				replace rentcashannualvalue = 0 if mi(rentcashannualvalue)
			**Generate total land prep cost
				gen LandPrep_TotalCost = ploughpaymentcash + rentcashannualvalue
			**Keep important variables
				keep FPrimary plotid InstanceNumber LandPrep_TotalCost
			**Destring FPrimary
				destring FPrimary, replace
			**Assert ID
				isid FPrimary plotid InstanceNumber
			**Rename LandPrep_TotalCost to landprepcost
				rename LandPrep_TotalCost landprepcost
			**Save
				tempfile landprepcost2
				save `landprepcost2', replace
			}
		**C. Wave 3
			{
			**Load tractor/plough use data
				u "${raw_w3}/04j_tracploughuse.dta"
			**Assert id
				isid FPrimary  plotid
			**Prepare for merge with land tenure costs
				keep FPrimary plotid ploughpaymentcash
			**Merge
				merge 1:1 FPrimary plotid using "${raw_w2}/04i_landtenure.dta", keep(match)
			**Replace missing values
				replace rentcashannualvalue = 0 if mi(rentcashannualvalue)
			**Generate total land prep cost
				gen LandPrep_TotalCost = ploughpaymentcash + rentcashannualvalue
			**Keep important variables
				keep FPrimary plotid LandPrep_TotalCost
			**Assert ID
				isid FPrimary plotid
			**Destring for merge
				destring FPrimary, replace
			**Save
				tempfile landprepcost3
				save `landprepcost3', replace
			}
		**D. Merge
		{
			append using `landprepcost1', force
			append using `landprepcost2', force
			**Calculate rowtotal
				egen TotalLandPrepCost = rowtotal(LandPrep_TotalCost landprepcost)
				keep TotalLandPrepCost plotid FPrimary
			**Drop missing plotid FPrimary
				drop if missing(plotid) | missing(FPrimary)
			**Drop duplicates
				duplicates drop FPrimary plotid, force
			**Assert id
				isid plotid FPrimary
			**Save
				tempfile LandPrepCost
				save `LandPrepCost', replace
		}
 }
	**4. Seed Cost
 {
		**A. Wave 1
			{
			**Load Data
				u "${raw_w1}/s4aviii1.dta", clear
			**Seed value 1
				rename s4aviii_248i cropseed_1
				rename s4aviii_252i seedvalue_1_c
				rename s4aviii_252ii seedvalue_1_p
				gen seedvalue_1_c_ = seedvalue_1_p / 100
				gen seedvalue_1 = seedvalue_1_c + seedvalue_1_c_
			**Seed value 2
				rename s4aviii_253i cropseed_2
				rename s4aviii_257i seedvalue_2_c
				rename s4aviii_257ii seedvalue_2_p
				gen seedvalue_2_c_ = seedvalue_2_p / 100
				gen seedvalue_2 = seedvalue_2_c + seedvalue_2_c_
			**Seed value 3
				rename s4aviii_258i cropseed_3
				rename s4aviii_262i seedvalue_3_c
				rename s4aviii_262ii seedvalue_3_p
				gen seedvalue_3_c_ = seedvalue_3_p / 100
				gen seedvalue_3 = seedvalue_3_c + seedvalue_3_c_
			**Seed value 4
				rename s4aviii_263i cropseed_4	
				rename s4aviii_267i seedvalue_4_c
				rename s4aviii_267ii seedvalue_4_p
				gen seedvalue_4_c_ = seedvalue_4_p / 100
				gen seedvalue_4 = seedvalue_4_c + seedvalue_4_c_
			**Renaming to plotid
				rename s4aviii1_plotno plotid
				keep FPrimary hhid eacode plotid cropseed_1 seedvalue_1 cropseed_2 seedvalue_2 cropseed_3 seedvalue_3 cropseed_4 seedvalue_4
			**Dropping duplicates/missing values
				duplicates drop FPrimary plotid hhid eacode, force
				drop if missing(FPrimary) | missing(plotid) | missing(hhid) | missing(eacode)
			**Assert id
				isid FPrimary plotid hhid eacode
			**Reshaping data
				reshape long cropseed_ seedvalue_, i(FPrimary plotid hhid eacode) j(cropcode)
			**Dropping duplicates
				duplicates drop FPrimary plotid eacode hhid, force
			**Assert id
				isid FPrimary plotid hhid eacode
			**Renaming confusing variables
				rename cropseed_ cropname
				rename seedvalue_ seedcost_a
			**Keeping important variables
				keep FPrimary hhid plotid cropname seedcost_a eacode
				drop if missing(cropname)
				replace seedcost_a = 0 if mi(seedcost_a)
			**Save
				tempfile seedcost_a
				save `seedcost_a', replace
			**Load Data
				u "${raw_w1}/s4aviii2.dta", clear
			**Renaming confusing variables
				rename s4aviii2_plotno plotid
			**Drop missing values
				drop if missing(FPrimary) | missing(plotid) | missing(hhid) | missing(eacode)
			**Merge with previous dataset
				merge 1:1 FPrimary plotid hhid eacode using `seedcost_a', keep(match)
			**Seed value 1
				rename s4aviii_269i cropseed_1
				rename s4aviii_273i seedvalue_1_c
				rename s4aviii_273ii seedvalue_1_p
				gen seedvalue_1_c_ = seedvalue_1_p / 100
				gen seedvalue_1 = seedvalue_1_c + seedvalue_1_c_
			**Seed value 2
				rename s4aviii_274i cropseed_2
				rename s4aviii_278i seedvalue_2_c
				rename s4aviii_278ii seedvalue_2_p
				gen seedvalue_2_c_ = seedvalue_2_p / 100
				gen seedvalue_2 = seedvalue_2_c + seedvalue_2_c_
			**Seed value 3
				rename s4aviii_279i cropseed_3
				rename s4aviii_283i seedvalue_3_c
				rename s4aviii_283ii seedvalue_3_p
				gen seedvalue_3_c_ = seedvalue_3_p / 100
				gen seedvalue_3 = seedvalue_3_c + seedvalue_3_c_
			**Seed value 4
				rename s4aviii_284i cropseed_4	
				rename s4aviii_288i seedvalue_4_c
				rename s4aviii_288ii seedvalue_4_p
				gen seedvalue_4_c_ = seedvalue_4_p / 100
				gen seedvalue_4 = seedvalue_4_c + seedvalue_4_c_
			**Replace missing values with 0
				replace seedvalue_1 = 0 if mi(seedvalue_1)
				replace seedvalue_2 = 0 if mi(seedvalue_2)
				replace seedvalue_3 = 0 if mi(seedvalue_3)
				replace seedvalue_4 = 0 if mi(seedvalue_4)
			**Dropping duplicates
				duplicates drop FPrimary plotid, force
				reshape long cropseed_ seedvalue_, i(FPrimary plotid) j(cropcode)
				rename seedvalue_ seedcost_b
			**Replacing missing values
				replace seedcost_a = 0 if mi(seedcost_a)
				replace seedcost_b = 0 if mi(seedcost_b)
				gen seedcost = seedcost_a + seedcost_b
				keep FPrimary plotid cropname seedcost
				drop if mi(cropname)
				drop if mi(FPrimary)
				duplicates drop FPrimary plotid cropname,force
			**Assert id
				isid FPrimary plotid cropname
			**Save
				tempfile seedcost1
				save `seedcost1', replace
			}
		**B. Wave 2
			{
			**Load data
				u "${raw_w2}/04k_seedquestions.dta", clear
			**Assert id
				isid FPrimary InstanceNumber plotid cropname, m
			**Keeping important variables
				keep FPrimary InstanceNumber plotid cropname seedpaid
				replace seedpaid = 0 if missing(seedpaid)
				drop if missing(cropname) | missing(plotid)
			**Dropping duplicates
				duplicates drop FPrimary InstanceNumber plotid cropname, force
			**Destring FPrimary
				destring FPrimary, replace
			**Rename seedpaid to seedcost
				rename seedpaid seedcost
			**Assert id
				isid FPrimary plotid InstanceNumber
			**Save
				tempfile seedcost2
				save `seedcost2', replace
			}
		**C. Wave 3
			{
			**Load data
				u "${raw_w3}/04k_seedquestions.dta", clear
			**Assert id
				isid FPrimary plotid cropname, m
			**Keeping important variables
				keep FPrimary plotid cropname seedpaid
				replace seedpaid = 0 if missing(seedpaid)
				drop if missing(cropname) | missing(plotid)
			**Collapse for total seed cost per plot
				collapse (sum) seedpaid, by(FPrimary plotid)
			**Destring FPrimary for merge
				destring FPrimary, replace
			**Save
				tempfile seedcost3
				save `seedcost3', replace
			}
		**D. Merge
			append using `seedcost2', force
			append using `seedcost1', force
			**Massage data
				egen seedcosts = rowmax(seedpaid seedcost)
			**Keep important variables
				keep cropname FPrimary plotid seedcosts
			**Save
				tempfile seedcosts
				save `seedcosts', replace
 }
	**5. Merge Costs
 {
		**A. Wave 1
			**Merge Data
				use `w1chemcost', clear
				merge 1:1 FPrimary plotid using `LaborCost1', nogenerate
				merge 1:1 FPrimary plotid using `landprepcost1', nogenerate
				merge 1:1 FPrimary plotid using `seedcost1', nogenerate
			**Fix label of wave
				replace wave = 1 if missing(wave)
				foreach var in chemcost total_labor_cost landprepcost seedcost {
					replace `var' = 0 if missing(`var')
					}
			**Create total_costs
				gen totalcosts = chemcost + total_labor_cost + landprepcost + seedcost
				keep chemcost total_labor_cost landprepcost seedcost totalcosts FPrimary plotid wave
			**Rename variables
				rename total_labor_cost laborcost
			**Assert id
				isid FPrimary plotid
			**Save data
				save "Wave1_Costs.dta", replace
		**B. Wave 2
			**Merge Data
				use `w2chemcost', clear
				merge 1:1 FPrimary plotid InstanceNumber using `LaborCost2', nogenerate
				merge 1:1 FPrimary plotid InstanceNumber using `landprepcost2', nogenerate
				merge 1:1 FPrimary plotid InstanceNumber using `seedcost2', nogenerate
			**Fix label of wave
				replace wave = 2 if missing(wave)
			**Replace missing cost values with zeros
				foreach var in chemcost total_labor_cost landprepcost seedcost {
					replace `var' = 0 if missing(`var')
				}
			**Create total_costs
				gen totalcosts = chemcost + total_labor_cost + landprepcost + seedcost
			**Collapse total costs per plot
				collapse (sum) chemcost total_labor_cost landprepcost seedcost totalcosts, by(FPrimary plotid wave)
				keep chemcost total_labor_cost landprepcost seedcost totalcosts FPrimary plotid wave
			**Check ID
				isid FPrimary plotid
			**Renaming variables
				rename total_labor_cost laborcost
			**Save data
				save "Wave2_Costs.dta", replace
		**C. Wave 3
			**Merge Data
				use `w3chemcost', clear
				merge 1:1 FPrimary plotid using `LaborCost3', nogenerate
				merge 1:1 FPrimary plotid using `landprepcost3', nogenerate
				merge 1:1 FPrimary plotid using `seedcost3', nogenerate
			**Fix label of wave
				replace wave = 3 if missing(wave)
			**Rename variables
				rename cost_perplot chemcost
				rename TotalLaborCosts laborcost
				rename seedpaid seedcost
				rename LandPrep_TotalCost landprepcost
			**Replace missing cost values with zeros
				foreach var in chemcost laborcost landprepcost seedcost {
					replace `var' = 0 if missing(`var')
				}
			**Create total_costs
				gen totalcosts = chemcost + laborcost + landprepcost + seedcost
				keep totalcosts chemcost laborcost landprepcost seedcost FPrimary plotid wave
			**Assert id
				isid FPrimary plotid
			**Save data
				save "Wave3_Costs.dta", replace
		**D. Merge datasets
			**Append Wave 1
				append using "${create}/Wave1_Costs.dta" 
			**Append Wave 2	
				append using "${create}/Wave2_Costs.dta" 
			**Restring FPrimary
				tostring FPrimary, replace
			**Check if uniquely identified data
				isid FPrimary plotid wave
				save "${home}/A_Data/3_Created/Cost_Panel.dta", replace
			}
}