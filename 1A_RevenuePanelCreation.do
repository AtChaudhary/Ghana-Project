*************************************************
** Title: Revenue Creation
** Date Created: August 27, 2024
** Author: Vincent Armentano
** Contact: varmenta@ucsd.edu
** Last Modified:
*************************************************

** Purpose:
	{
/*
	This dofile aggregates & arranges sections of dofiles
	all pertaining to the anlaysis of crop portfolio
	diversification.
*/
	}
*****

** 1. Wave 1
	{
	** i. Wet Season
		{
		** A. Load Base File & create season id
			u "${raw_w1}/s4av1.dta", clear
			duplicates drop
			isid FPrimary s4av1_plotno,m
			gen season = "Wet"
		
		** B. Slight Cleaning
			{		
			** Variables that are confusing, but at most are 80 pesewas
				drop s4v_a99ii s4v_a91ii s4v_a115ii s4v_a107ii
				
			** Value is cedis + pessawas
				qui forval c = 1/5 { 
					loc v = word("82 90 98 106 114", `c')
					gen marketvalue_harvested_`c' = s4v_a`v'i + s4v_a`v'ii/100
					}
			
			** Rename
				ren (s4v_a78i s4v_a78ii	///
					s4v_a78iii s4v_a78iv s4v_a78v 	///
					s4v_a78vi s4v_a78vii s4v_a78viii	///
					s4v_a78ix s4v_a78x)				///
					(s4v_a78_1 s4v_a78_2 			///
					s4v_a78_3 s4v_a78_4 s4v_a78_5 	///
					s4v_a78_6 s4v_a78_7 s4v_a78_8	///
					s4v_a78_9 s4v_a78_10)
		
			** Copying Variables
				forval c = 1/10 {
					decode(s4v_a78_`c'), gen(cropname_`c')
					}
					
			** Truncating to relevant Variables
				keep season FPrimary wave cropname_* s4v_a78_*	///
					marketvalue_harvested_* s4av1_plotno
			}
		*****
		
		** C. Reshaping Long to HH-Plot-Crop Level
			reshape long cropname_ s4v_a78_ marketvalue_harvested_,	///
						i(FPrimary s4av1_plotno) j(cindex)
			count if cropname_==""
				assert `r(N)'==46718
				drop if cropname_==""
			count if mi(marketvalue_harvested_)
				assert `r(N)'==8408
				drop if mi(marketvalue_harvested_)
			drop cindex
			ren	(cropname_ s4v_a78_ s4av1_plotno)	///
				(cropname  cropcode Plot_WetID)
			la val cropcode 
		
		** D. Preparing Revenue Figures
			replace marketvalue_harvested_ = 0 if mi(marketvalue_harvested_)
		
		** E. Consolidating Different harvests of same crop on same plot
			keep season FPrimary wave Plot_WetID marketvalue_harvested_ cropcode cropname
			collapse (sum) marketvalue_harvested_, by(season FPrimary wave Plot_WetID cropcode cropname)
		** F. Holding progress
			isid FPrimary Plot_WetID cropcode
			tempfile w1wet 
				save `w1wet', replace
		}
	*****
	
	** ii. Dry Season
		{
		** A. Load Base File & create season id
			u "${raw_w1}/s4av2.dta", clear
			duplicates drop 
			isid FPrimary s4av2_plotno,m
			gen season = "Dry"
		
		** B. Slight Cleaning
			{
			** Variables that are confusing, but at most are 80 pesewas
				drop s4v_a124ii s4v_a132ii s4v_a140ii s4v_a148ii s4v_a156ii
				
			** Value is cedis + pessawas
				qui forval c = 1/5 { 
					loc v = word("123 131 139 147 155", `c')
					gen marketvalue_harvested_`c' = s4v_a`v'i + s4v_a`v'ii/100
					}
			
			** Rename
				ren (s4v_a120i s4v_a120ii s4v_a120iii s4v_a120iv s4v_a120v s4v_a120vi s4v_a120vii s4v_a120viii s4v_a120ix s4v_a120x)				///
					(s4v_a120_1 s4v_a120_2 s4v_a120_3 s4v_a120_4 s4v_a120_5 s4v_a120_6 s4v_a120_7 s4v_a120_8 s4v_a120_9 s4v_a120_10)
		
			** Copying Variables
				forval c = 1/10 {
					decode(s4v_a120_`c'), gen(cropname_`c')
					}
					
			** Truncating to relevant Variables
				keep season FPrimary wave cropname_* s4v_a120_*	///
					marketvalue_harvested_* s4av2_plotno
			}
		*****
		
		** C. Reshaping Long to Season-HH-Plot-Crop Level
			reshape long cropname_ s4v_a120_ marketvalue_harvested_,	///
					i(FPrimary s4av2_plotno) j(cindex)
			count if cropname_==""
				assert `r(N)'==53774
				drop if cropname_==""
			count if mi(marketvalue_harvested_)
				assert `r(N)'==2849
				drop if mi(marketvalue_harvested_)
			drop cindex
			ren	(cropname_ s4v_a120_ s4av2_plotno)	///
				(cropname  cropcode Plot_DryID)
			la val cropcode
		
		** D. Preparing Revenue Figures
			replace marketvalue_harvested_ = 0 if mi(marketvalue_harvested_)
			
		** E. Consolidating Different harvests of same crop on same plot
			keep season FPrimary wave Plot_DryID marketvalue_harvested_ cropcode cropname
			collapse (sum) marketvalue_harvested_, by(season FPrimary wave Plot_DryID cropcode cropname)
		
		** F. Checking ID
			isid FPrimary Plot_DryID cropcode
		}
	*****
	
	** iii. Appending Wet & Dry, then holding progress
		append using `w1wet'
		tostring FPrimary, replace
		isid season FPrimary Plot_DryID Plot_WetID cropcode,m
		tempfile wave1
			save `wave1', replace
	}
*****

** 2. Wave 2
	{	
	** i. Load & Prepare Quantity Information
		{
		** A. Loading Quantity Data and Asserting ID
			u "${raw_w2}/04n_harvestquestions.dta", clear	
			isid FPrimary InstanceNumber plotid cropcode, m
			
		** B. Slight Cleaning
			{
			** . Names
				rename cropname cropname_harvest
				replace harvestquantity = 0 if mi(harvestquantity)
			** ii. Unit standardizing for harvestquantity into kg
				{
				** [Known]
				** Kilogram ............14
					gen harvestquantity_14 = harvestquantity * 1 if harvestunit == 14
				** Maxi bag ............18
					gen harvestquantity_18 = harvestquantity * 100 if harvestunit == 18
				** Mini bag ............19
					gen harvestquantity_19 = harvestquantity * 15 if harvestunit == 19
						
				** [Unknown]
				** Assuming equivalent to kilograms
					gen harvestquantity_99 = harvestquantity if !inlist(harvestunit,14,18,19)
					/*
					** American tin...... 02
					drop if harvestunit == 2
					** Basket ................04
					drop if harvestunit == 4
					** Bowl ...................06
					drop if harvestunit == 6
					** Box .....................07
					drop if harvestunit == 7
					** Bucket ................29
					drop if harvestunit ==29
					** Bundle ...............09
					drop if harvestunit == 9
					** Crate ..................30
					drop if harvestunit == 30
					** Calabash ............40
					drop if harvestunit == 40
					** Fingers ...............11
					drop if harvestunit == 11
					** Margarine tin.....17
					drop if harvestunit == 17
					** Single ...............37
					drop if harvestunit == 37
					** Stick ..................23
					drop if harvestunit == 23
					** Tonne ...............24
					drop if harvestunit == 24
					** Set ....................36
					drop if harvestunit == 36
					** 100 pieces of crop--91
					drop if harvestunit == 91
					** Fruits ....................12
					drop if harvestunit == 12
					** Bunches ....................08
					drop if harvestunit == 8
					** Tuber ....................26
					drop if harvestunit == 26
					** Yards/metres ....................38
					drop if harvestunit == 38
					** Calabash ....................40
					drop if harvestunit == 40
					** Tie ....................40
				
					** Other specify----------99/140
					drop if harvestunit == 99
					drop if harvestunit == 140
				*/
				
				** New Harvest Quantity in KG
					egen harvestquantity_t = rowtotal(harvestquantity_14 harvestquantity_18 harvestquantity_19 harvestquantity_99)
				}
			*****
			
			** iii. Truncate
				keep FPrimary InstanceNumber plotid cropcode	///
					cropname_harvest harvestquantity_t harvestunit
				drop if mi(harvestunit)
			}
		*****
			
		** C. Preparing for Merge with Prices
			tempfile w2_quantities
				save `w2_quantities', replace
		}
	*****
	
	** ii. Load & Prepare Price Information
		{
		** A. Execute
			u "${raw_w2}/04o_cropsalesstoresquestions.dta", clear
			
		** B. Understand ID	
			gen Respondent = 1 if InstanceNumber<20
			replace Respondent = 2 if InstanceNumber>20
			assert !mi(Respondent)
			isid FPrimary InstanceNumber
			isid FPrimary Respondent cropcode
		
		** C. Truncate
			keep FPrimary InstanceNumber cropcode cropname wave	///
				samecommsoldprice samecommsoldunit othercommsoldprice	///
				othercommsoldunit
			ren cropname cropname_sale
			
		** D. Find each crops median sold price
			{
			** a. Assert No missing Prices
				assert !mi(cropcode)
				
			** 	
				replace samecommsoldprice = 0 if mi(samecommsoldprice)
				replace othercommsoldprice = 0 if mi(othercommsoldprice)
				
			** Unit standardizing for samecommsoldprice into /kg
				{	
					** American tin...... 02
					drop if samecommsoldunit == 2
					** Basket ................04
					drop if samecommsoldunit == 4
					** Bowl ...................06
					drop if samecommsoldunit == 6
					** Box .....................07
					drop if samecommsoldunit == 7
					** Bucket ................29
					drop if samecommsoldunit ==29
					** Bundle ...............09
					drop if samecommsoldunit == 9
					** Crate ..................30
					drop if samecommsoldunit == 30
					** Calabash ............40
					drop if samecommsoldunit == 40
					** Fingers ...............11
					drop if samecommsoldunit == 11
					** Kilogram ............14
					gen samecommsoldprice_14 = samecommsoldprice / 1 if samecommsoldunit == 14
					** Margarine tin.....17
					drop if samecommsoldunit == 17
					** Maxi bag ............18
					gen samecommsoldprice_18 = samecommsoldprice / 100 if samecommsoldunit == 18
					** Mini bag ............19
					gen samecommsoldprice_19 = samecommsoldprice / 15 if samecommsoldunit == 19
					** Single ...............37
					drop if samecommsoldunit == 37
					** Stick ..................23
					drop if samecommsoldunit == 23
					** Tonne ...............24
					drop if samecommsoldunit == 24
					** Set ....................36
					drop if samecommsoldunit == 36
					** 100 pieces of crop--91
					drop if samecommsoldunit == 91
					** Fruits ....................12
					drop if samecommsoldunit == 12
					** Bunches ....................08
					drop if samecommsoldunit == 8
					** Pounds ....................21
					gen samecommsoldprice_21 = samecommsoldprice * 0.9 if samecommsoldunit == 21
					** Tuber ....................26
					drop if samecommsoldunit == 26
					** Bunches ....................08
					drop if samecommsoldunit == 8
					** Yards/metres ....................38
					drop if samecommsoldunit == 38
					** Calabash ....................40
					drop if samecommsoldunit == 40
					** Tie ....................40
				
					** Other specify----------99/140
					drop if samecommsoldunit == 99
					drop if samecommsoldunit == 140
					
				}
			*****

			** Unit standardizing for othercommsoldprice into /kg
				{	
					** American tin...... 02
					drop if othercommsoldunit == 2
					** Basket ................04
					drop if othercommsoldunit == 4
					** Bowl ...................06
					drop if othercommsoldunit == 6
					** Box .....................07
					drop if othercommsoldunit == 7
					** Bucket ................29
					drop if othercommsoldunit ==29
					** Bundle ...............09
					drop if othercommsoldunit == 9
					** Crate ..................30
					drop if othercommsoldunit == 30
					** Calabash ............40
					drop if othercommsoldunit == 40
					** Fingers ...............11
					drop if othercommsoldunit == 11
					** Kilogram ............14
					gen othercommsoldprice_14 = othercommsoldprice / 1 if othercommsoldunit == 14
					** Margarine tin.....17
					drop if othercommsoldunit == 17
					** Maxi bag ............18
					gen othercommsoldprice_18 = othercommsoldprice / 100 if othercommsoldunit == 18
					** Mini bag ............19
					gen othercommsoldprice_19 = othercommsoldprice / 15 if othercommsoldunit == 19
					** Single ...............37
					drop if othercommsoldunit == 37
					** Stick ..................23
					drop if othercommsoldunit == 23
					** Tonne ...............24
					drop if othercommsoldunit == 24
					** Set ....................36
					drop if othercommsoldunit == 36
					** 100 pieces of crop--91
					drop if othercommsoldunit == 91
					
					** Fruits ....................12
					drop if othercommsoldunit == 12
					** Bunches ....................08
					drop if othercommsoldunit == 8
					** Tuber ....................26
					drop if othercommsoldunit == 26
					** Bunches ....................08
					drop if othercommsoldunit == 8
					** Calabash ....................40
					drop if othercommsoldunit == 40
					** Tie ....................40
				
					** Other specify----------99/140
					drop if othercommsoldunit == 99
					drop if othercommsoldunit == 140
				
				}
			*****

			**Find median sold price
				drop if mi(samecommsoldunit) & mi(othercommsoldunit)
				
				
				egen medsame_14 = median(samecommsoldprice_14), by(cropcode)
				egen medsame_18 = median(samecommsoldprice_18), by(cropcode)
				egen medsame_19 = median(samecommsoldprice_19), by(cropcode)
				egen medsame_21 = median(samecommsoldprice_21), by(cropcode)

				egen medother_14 = median(othercommsoldprice_14), by(cropcode)
				egen medother_18 = median(othercommsoldprice_18), by(cropcode)
				egen medother_19 = median(othercommsoldprice_19), by(cropcode)
				
				egen medsame_row = rowmedian(medsame_14 medsame_18 medsame_19 medsame_21)
				egen medother_row = rowmedian(medother_14 medother_18 medother_19)

				egen medTSP = rowmedian(medsame_row medother_row)

					replace medTSP = 0 if mi(medTSP)
					replace medsame_14 = 0 if mi(medsame_14)
					replace medsame_18 = 0 if mi(medsame_18)
					replace medsame_19 = 0 if mi(medsame_19)
					replace medsame_21 = 0 if mi(medsame_21)
					replace medother_14 = 0 if mi(medother_14)
					replace medother_18 = 0 if mi(medother_18)
					replace medother_19 = 0 if mi(medother_19)
			}
		*****
		
		** v. Assert ID
			isid FPrimary InstanceNumber cropcode, m
		}
	*****
	
	** iii. Merge Prices and Quantities to get Revenue
		{
			merge 1:1 FPrimary InstanceNumber cropcode using `w2_quantities'
		drop if _merge !=3
		** Calculate revenue
			gen revenue = medTSP * harvestquantity_t
			replace revenue = 0 if mi(revenue)
		}
	*****
	
	** iv. Save Revenue of wave 2
		keep InstanceNumber FPrimary cropcode cropname_sale plotid harvestquantity revenue wave
		isid FPrimary plotid cropcode
		tempfile wave2
		save `wave2', replace
		
	}
*****

** 3. Wave 3
	{	
	** i. Load & Prepare Quantity Information
		{
		** A. Loading Quantity Data and Asserting ID
			u "${raw_w3}/04n_harvestquestions", clear	
			isid FPrimary plotid cropcode, m
			** B. Slight Cleaning
			{
			** . Names
				rename cropname cropname_harvest
				replace harvestquantity = 0 if mi(harvestquantity)
			** ii. Unit standardizing for harvestquantity into kg
				{
				** [Known]
				** Kilogram ............14
					gen harvestquantity_14 = harvestquantity * 1 if harvestunit == 14
				** Maxi bag ............18
					gen harvestquantity_18 = harvestquantity * 100 if harvestunit == 18
				** Mini bag ............19
					gen harvestquantity_19 = harvestquantity * 15 if harvestunit == 19
						
				** [Unknown]
				** Assuming equivalent to kilograms
					gen harvestquantity_99 = harvestquantity if !inlist(harvestunit,14,18,19)
				/*
					** American tin...... 02
					drop if harvestunit == 2
					** Basket ................04
					drop if harvestunit == 4
					** Bowl ...................06
					drop if harvestunit == 6
					** Box .....................07
					drop if harvestunit == 7
					** Bucket ................29
					drop if harvestunit ==29
					** Bundle ...............09
					drop if harvestunit == 9
					** Crate ..................30
					drop if harvestunit == 30
					** Calabash ............40
					drop if harvestunit == 40
					** Fingers ...............11
					drop if harvestunit == 11
					** Margarine tin.....17
					drop if harvestunit == 17
					** Single ...............37
					drop if harvestunit == 37
					** Stick ..................23
					drop if harvestunit == 23
					** Tonne ...............24
					drop if harvestunit == 24
					** Set ....................36
					drop if harvestunit == 36
					** 100 pieces of crop--91
					drop if harvestunit == 91
					** Fruits ....................12
					drop if harvestunit == 12
					** Bunches ....................08
					drop if harvestunit == 8
					** Tuber ....................26
					drop if harvestunit == 26
					** Yards/metres ....................38
					drop if harvestunit == 38
					** Calabash ....................40
					drop if harvestunit == 40
					** Tie ....................40
				
					** Other specify----------99/140
					drop if harvestunit == 99
					drop if harvestunit == 140
				*/
				
				** New Harvest Quantity in KG
					egen harvestquantity_t = rowtotal(harvestquantity_14 harvestquantity_18 harvestquantity_19 harvestquantity_99)
				}
			*****
			
			** iii. Truncate
				keep FPrimary plotid cropcode	///
					cropname_harvest harvestquantity_t harvestunit
				drop if mi(harvestunit)
			}
		** C. Preparing for Merge with Prices
				tempfile w3_quantities
				save `w3_quantities', replace
		}
	*****
	
	** ii. Load & Prepare Price Information
	{
		u "${raw_w3}/04o_cropsalesstoresquestions.dta", clear
			
		** B. Understand ID	
			list if missing(FPrimary, plotid, cropcode, cropname)
			drop if missing(FPrimary, plotid, cropcode, cropname)
			isid FPrimary plotid cropcode cropname 
		
		** C. Truncate
			keep FPrimary cropcode cropname plotid	///
				samecommsoldprice samecommsoldunit othercommsoldprice	///
				othercommsoldunit
			ren cropname cropname_sale
			
		** D. Find each crops median sold price
			{
			** a. Assert No missing Prices
				assert !mi(cropcode)
				
			** 	
				replace samecommsoldprice = 0 if mi(samecommsoldprice)
				replace othercommsoldprice = 0 if mi(othercommsoldprice)
				
			** Unit standardizing for samecommsoldprice into /kg
				{	
					** American tin...... 02
					drop if samecommsoldunit == 2
					** Basket ................04
					drop if samecommsoldunit == 4
					** Bowl ...................06
					drop if samecommsoldunit == 6
					** Box .....................07
					drop if samecommsoldunit == 7
					** Bucket ................29
					drop if samecommsoldunit ==29
					** Bundle ...............09
					drop if samecommsoldunit == 9
					** Crate ..................30
					drop if samecommsoldunit == 30
					** Calabash ............40
					drop if samecommsoldunit == 40
					** Fingers ...............11
					drop if samecommsoldunit == 11
					** Kilogram ............14
					gen samecommsoldprice_14 = samecommsoldprice / 1 if samecommsoldunit == 14
					** Margarine tin.....17
					drop if samecommsoldunit == 17
					** Maxi bag ............18
					gen samecommsoldprice_18 = samecommsoldprice / 100 if samecommsoldunit == 18
					** Mini bag ............19
					gen samecommsoldprice_19 = samecommsoldprice / 15 if samecommsoldunit == 19
					** Single ...............37
					drop if samecommsoldunit == 37
					** Stick ..................23
					drop if samecommsoldunit == 23
					** Tonne ...............24
					drop if samecommsoldunit == 24
					** Set ....................36
					drop if samecommsoldunit == 36
					** 100 pieces of crop--91
					drop if samecommsoldunit == 91
					** Fruits ....................12
					drop if samecommsoldunit == 12
					** Bunches ....................08
					drop if samecommsoldunit == 8
					** Pounds ....................21
					gen samecommsoldprice_21 = samecommsoldprice * 0.9 if samecommsoldunit == 21
					** Tuber ....................26
					drop if samecommsoldunit == 26
					** Bunches ....................08
					drop if samecommsoldunit == 8
					** Yards/metres ....................38
					drop if samecommsoldunit == 38
					** Calabash ....................40
					drop if samecommsoldunit == 40
					** Tie ....................40
				
					** Other specify----------99/140
					drop if samecommsoldunit == 99
					drop if samecommsoldunit == 140
					
				}
			*****

			** Unit standardizing for othercommsoldprice into /kg
				{	
					** American tin...... 02
					drop if othercommsoldunit == 2
					** Basket ................04
					drop if othercommsoldunit == 4
					** Bowl ...................06
					drop if othercommsoldunit == 6
					** Box .....................07
					drop if othercommsoldunit == 7
					** Bucket ................29
					drop if othercommsoldunit ==29
					** Bundle ...............09
					drop if othercommsoldunit == 9
					** Crate ..................30
					drop if othercommsoldunit == 30
					** Calabash ............40
					drop if othercommsoldunit == 40
					** Fingers ...............11
					drop if othercommsoldunit == 11
					** Kilogram ............14
					gen othercommsoldprice_14 = othercommsoldprice / 1 if othercommsoldunit == 14
					** Margarine tin.....17
					drop if othercommsoldunit == 17
					** Maxi bag ............18
					gen othercommsoldprice_18 = othercommsoldprice / 100 if othercommsoldunit == 18
					** Mini bag ............19
					gen othercommsoldprice_19 = othercommsoldprice / 15 if othercommsoldunit == 19
					** Single ...............37
					drop if othercommsoldunit == 37
					** Stick ..................23
					drop if othercommsoldunit == 23
					** Tonne ...............24
					drop if othercommsoldunit == 24
					** Set ....................36
					drop if othercommsoldunit == 36
					** 100 pieces of crop--91
					drop if othercommsoldunit == 91
					
					** Fruits ....................12
					drop if othercommsoldunit == 12
					** Bunches ....................08
					drop if othercommsoldunit == 8
					** Tuber ....................26
					drop if othercommsoldunit == 26
					** Bunches ....................08
					drop if othercommsoldunit == 8
					** Calabash ....................40
					drop if othercommsoldunit == 40
					** Tie ....................40
				
					** Other specify----------99/140
					drop if othercommsoldunit == 99
					drop if othercommsoldunit == 140
				
				}
			*****

			**Find median sold price
				drop if mi(samecommsoldunit) & mi(othercommsoldunit)
				
				
				egen medsame_14 = median(samecommsoldprice_14), by(cropcode)
				egen medsame_18 = median(samecommsoldprice_18), by(cropcode)
				egen medsame_19 = median(samecommsoldprice_19), by(cropcode)
				egen medsame_21 = median(samecommsoldprice_21), by(cropcode)

				egen medother_14 = median(othercommsoldprice_14), by(cropcode)
				egen medother_18 = median(othercommsoldprice_18), by(cropcode)
				egen medother_19 = median(othercommsoldprice_19), by(cropcode)
				
				egen medsame_row = rowmedian(medsame_14 medsame_18 medsame_19 medsame_21)
				egen medother_row = rowmedian(medother_14 medother_18 medother_19)

				egen medTSP = rowmedian(medsame_row medother_row)

					replace medTSP = 0 if mi(medTSP)
					replace medsame_14 = 0 if mi(medsame_14)
					replace medsame_18 = 0 if mi(medsame_18)
					replace medsame_19 = 0 if mi(medsame_19)
					replace medsame_21 = 0 if mi(medsame_21)
					replace medother_14 = 0 if mi(medother_14)
					replace medother_18 = 0 if mi(medother_18)
					replace medother_19 = 0 if mi(medother_19)
					}
		*****
		
		** v. Assert ID
			isid FPrimary plotid cropcode, m
 	** vi. Merge with quantity
			merge 1:1 FPrimary cropcode plotid using `w3_quantities'
			drop if _merge !=3
		** Calculate revenue
			gen revenue = medTSP * harvestquantity_t
		**Add collum identifying wave
		gen wave = 3
	*****
 }
		
	
	** iv. Save Revenue of wave 3
	{
		
		keep FPrimary cropcode cropname_sale plotid harvestquantity revenue wave
		drop if revenue==0
		isid FPrimary plotid cropcode
		tempfile wave3
		save `wave3', replace
		}

	}
*****

** 4. Aggregating into Panel
	{
		append using `wave1', force
		append using `wave2', force
	}
	** Reshapping
	{
		gen new_cropname = cropname_sale
		replace new_cropname = cropname if missing(cropname_sale)
		gen new_revenue = revenue
		replace new_revenue = marketvalue_harvested_ if missing(revenue)
		gen new_plotid = plotid
		replace new_plotid = Plot_DryID if missing(new_plotid)
		replace new_plotid = Plot_WetID if missing(new_plotid)
		keep new_cropname new_revenue wave new_plotid FPrimary
		rename new_revenue revenue
		rename new_cropname cropname
		rename new_plotid plotid
		destring FPrimary
		sort wave
		duplicates drop
	**Create plot crop level data
		*Sum revenues for the same crop on the same plot
		collapse (sum) revenue, by(FPrimary wave plotid cropname)
		*Check if collapse work
		duplicates list FPrimary plotid wave cropname
		*Sum the revenue for each plotid and combine crop names
		bysort FPrimary wave plotid (cropname): gen crop_combined = cropname[1]
		bysort FPrimary wave plotid (cropname): replace crop_combined = crop_combined[_n-1] + "/" + cropname if _n > 1
		*Collapse the dataset to sum revenue and keep the combined crop names
		collapse (sum) revenue (first) crop_combined, by(FPrimary wave plotid)
		*Renaming
		rename crop_combined cropname
		*Check ID
		isid FPrimary plotid wave
	** Saving created data
		save "${home}/A_Data/3_Created/RevenuePanel.dta", replace
	}
*****



	*******
	* END *
	*******