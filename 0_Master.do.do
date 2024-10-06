*************************************************
** Title: CPD, Ghana
** Date Created: April 2nd, 2024
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


** Setup
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
	** C. User-Written Programs
		{
		** Running dofiles with a timer
			cap program drop CPD_do
			program define CPD_do
			qui {
				** Displaying start time
					noi di " - Started at: `c(current_time)'"
				
				** Starting timer
					timer on 1
					
				** Executing dofile 
					do "${do}/`1'"
				
				** Collecting timer results
					timer off 1
					timer list 1
					noi di `r(t1)'/60 "  mins for `1'"
					
				** Clearing for next run
					timer clear
				
				} // End Quietly
			end
		}
	** D. User-Preferred Settings
		{
		** Matrix Size
			set matsize 10000
			//set maxvar 32000
		}
	}
*****

glu
** 1. Creating Profit Per Acre Panel
	CPD_do "1A_RevenuePanelCreation.do"
	CPD_do "1B_CostsPanelCreation.do"
	CPD_do "1C_ProfitPanelCreation.do"
	
** 2. Summary Statistics & Visualizations
	CPD_do "2A_SummaryStatistics.do"

** 3. Portfolio Property Creation & Analysis
	CPD_do "3A_CovarianceEstimation.do"
	
	
	*******
	* END *
	*******


