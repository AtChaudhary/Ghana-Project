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
{
	**Load Revenue panel
	u "${home}/A_Data/3_Created/RevenuePanel", clear
	**Merge with Cost Panel
	merge 1:1 FPrimary wave plotid using "${home}/A_Data/3_Created/Cost_Panel", nogen
	**Create profit column
	gen profit = revenue - totalcosts
	**keep importnat variables
	keep FPrimary wave plotid cropname profit
	**reshape
	reshape wide profit cropname, i(FPrimary plotid) j(wave)
	**Drop empty entries
	replace profit1 = 0 if missing(profit1)
	replace profit2 = 0 if missing(profit2)
	replace profit3 = 0 if missing(profit3)
	**Replace missing values cropname
	replace cropname1 = "no crop" if missing(cropname1)
	replace cropname2 = "no crop" if missing(cropname2)
	replace cropname3 = "no crop" if missing(cropname3)
	**Delete missing values
	drop if cropname1 == "no crop" & profit1 == 0 & cropname2 == "no crop" & profit2 == 0 & cropname3 == "no crop" & profit3 == 0
	**Save
	save "${home}/A_Data/3_Created/Profit_Panel.dta", replace
}
}