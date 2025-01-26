/*===========================================================================
| Author: Olowookere, Oluwatosin Olawale
| Purpose: Stata Code Sample for Pre-Doctoral Application in Development Economics
| The script performs three tasks: 
|                (1) Data cleaning, transformation and export of output  
|                (2) Data wrangling and panel regression analysis to undertand the impact of foreign aid on health outcome 
|                (3) Run regression and export the output to LaTeX
| Date: November 8th, 2024
============================================================================*/

clear all 
version 18 // Version control for replication 
set more off 

ssc install estout // To export regression results

/*===========================================================================
Task One: Clean the data, create a unitary value, covert the data from long to wide format using months column.
Metadata for Task 1: This is a panel containing countries export transactions. Below are the columns: 
• Exporter ID: (string) identifier of the exporter firm. Dataset contains only six unique exporters.
• Country of destination: (string) name of the country of destination.
• Value (in US dollars): (numeric) value of the export transaction, in US dollars.
• Volume (in tonnes): (numeric) volume of the export transaction, in tonnes.
• Date (dd/mm/yyyy): (string) date of the export transaction, in dd/mm/yyyy format.
• Notes: (string) remarks concerning the export transactions.
============================================================================*/

*** Set Directory ***
cd C:/Users/oluwatosin/Downloads/Olowookere_Oluwatosin_Pre-Doc_Stata_Test

***** Task One: Data Wrangling *****
// a. Load Data  
import delimited "/Users/oluwatosin/Downloads/Olowookere_Oluwatosin_Pre-Doc_Stata_Test/Input_Data/1_Data_Cleaning.csv", clear

// b. Checking Data 
describe
br
list in 1/10

// c. Rename columns for easier reference
rename exporterid exporter_id
rename countryofdestination destination_country
rename valueinusdollars export_value_US
rename volumeintonnes volume_tonnes

// d. Cleaning date column 
gen Date_cleaned = daily(dateddmmyyyy, "DMY")

replace Date_cleaned = daily(dateddmmyyyy, "MDY") if Date_cleaned == . // For date cells where date is saved as MDY
replace Date_cleaned = daily("31/12/2020", "DMY") if notes == "Total 2020" & missing(Date_cleaned) // Use note column as fallback for date missing
replace Date_cleaned = daily(dateddmmyyyy, "YDM") if Date_cleaned == .

format Date_cleaned %tdDD/NN/YYYY // Transform date format to DD/MM/YYYY

gen year = year(Date_cleaned) // Extract year from date column 
gen month = month(Date_cleaned) // Extract year from date column 

drop notes dateddmmyyyy // Drop notes and dateddmmyyyy columns 

sort countryofdestination Date_cleaned

// e. Cleaning Data ID: Exporter ID 
replace exporterid = subinstr(exporterid, "OOO", "", .) if strpos(exporterid, "OOO") > 0 // Remove tripple ooo before export ids
replace countryofdestination = "Togo" in 92 // Togo written as Tango
replace exporterid = "7745967" in 91
replace exporterid = "6324555" in 53

gen exporter_id = exporterid + string(Month, "%02.0f") // Ids are duplicated for same country, preventing it from being unique. I concatenate months number with the original id given in the data. This helps to uniquely distinguish observations

**** Cleaning missing observations
replace valueinusdollars = subinstr(valueinusdollars, "USD", "", .) // Remove USD string in the valueinusdollars 
destring valueinusdollars, replace force // Transform valueinusdollars to numeric
drop if missing(valueinusdollars) | missing(volumeintonnes) // Drop observations where either of the valueinusdollars or olumeintonnes is missing

// f. Calculate Unitary export value 
gen unitary_export_value = valueinusdollars / volumeintonnes 

// g. Transform data into wide format using months 
collapse (sum) valueinusdollars volumeintonnes unitary_export_value, by(exporter_id countryofdestination year month)
reshape wide valueinusdollars volumeintonnes unitary_export_value, i(exporter_id countryofdestination year) j(month)

sort year

**** Export Output Data
export delimited "/Users/oluwatosin/Downloads/Olowookere_Oluwatosin_Pre-Doc_Stata_Test/Output_Data/1_Data_Cleaned.csv", replace



/*===========================================================================
| Task Two: This panel data is extracted from OECD, WDI and SDG goal 2 and 3. 
| It investigates the impact of foreign aid on health outcomes. 
| I created six composite indices for health outcome convering malnutrition, reproductive fatality etc. 
| To avoid serial correlation, the panel data is aggregated from yearly data into period, aggreagted over 5 years period using mean method
| The indices served as outcome variables for pooled OLS regression
============================================================================*/
****** SubTask 1: Data Cleaning and Transformation *********
// a. Load the dataset
import delimited "https://raw.githubusercontent.com/Olowookere-O-O/R-Scripts-for-Thesis-Analysis/refs/heads/main/Thesis_Data/MisF_imp_clean_thesis_data_Indices.csv", clear


// b. Create a local macro with all variables except the ones to exclude
ds iso3c country region, not
local vars_to_destring `r(varlist)'

// c. Apply destring to the selected variables
destring `vars_to_destring', replace float dpcomma


// d. Filter out year 2022
drop if year == 2022

// e. Create the `periods` variable based on year ranges
gen periods = ""
replace periods = "2000-2004" if inrange(year, 2000, 2004)
replace periods = "2005-2009" if inrange(year, 2005, 2009)
replace periods = "2010-2013" if inrange(year, 2010, 2013)
replace periods = "2014-2017" if inrange(year, 2014, 2017)
replace periods = "2018-2021" if inrange(year, 2018, 2021)
replace periods = string(year) if missing(periods)

preserve
keep country iso3c region
duplicates drop iso3c, force 
save unique_ids.dta, replace
restore

// f. Group by iso3c and periods, calculate means of model_vars
collapse (mean) ae bci gov chs_25perc oda_disb soc_inf_oda govt_hth_spnd_1 hlth_spdng_pergdp cf_lf_ratio pop_tot cri_score pop_densty external_debt_stock trade gdp_per_cap zscore_envdeath_index zscore_infdis_index zscore_hscr_index zscore_mental_index zscore_reprd_index zscore_nutrit_index aid_per_gni unemply_rate, by(iso3c periods)

// g. Generate log-transformed variables
*gen log_remittance = log(remit + 1)
gen log_ae = log(ae + 1)
gen log_bci = log(bci + 1)
gen log_gov = log(gov + 3)
gen log_CHS = log(chs_25perc + 1)
gen log_ODA = log(oda_disb + 1)
gen log_Soc_Infra = log(soc_inf_oda + 1)
gen Log_Govt_Spend_1 = log(govt_hth_spnd_1)
gen log_hlth_Per_Cap = log(hlth_spdng_pergdp)
gen log_CF_LF_ratio = log(cf_lf_ratio + 1)
gen log_Pop = log(pop_tot)
gen log_CRI_Score = log(cri_score)
gen log_Pop_dens = log(pop_densty)
gen log_External_debt = log(external_debt_stock)
gen log_Trade = log(trade)
gen log_GDP_Cap = log(gdp_per_cap)
gen log_Env_Dth_Tr = log(zscore_envdeath_index + 2)
gen log_BID_Tr = log(zscore_infdis_index + 1)
gen log_HSCR_Tr = log(zscore_hscr_index + 2.5)
gen log_BMD_Tr = log(zscore_mental_index + 1.5)
gen log_RFTP_Tr = log(zscore_reprd_index + 1.5)
gen log_Malnutri_Tr = log(zscore_nutrit_index + 2)
gen log_ODA_per_GNI = log(aid_per_gni + 1)
gen log_unemp = log(unemply_rate + 1)

merge m:1 iso3c using unique_ids, nogenerate

// h. Convert string IDs to numeric for `iso3c` and `periods`
encode iso3c, gen(numeric_iso3c)
encode periods, gen(numeric_periods)

order country numeric_iso3c numeric_periods region iso3c  periods

// i. Declare panel data structure using numeric IDs
xtset numeric_iso3c numeric_periods

****** SubTask 2: Running Regression *******
// a. Define outcome variables
global zscore_envdeath_index zscore_hscr_index zscore_infdis_index zscore_mental_index zscore_nutrit_index zscore_reprd_index
global predictors log_ODA ae cri_score log_Pop_dens log_Pop log_GDP_Cap log_Trade log_hlth_Per_Cap gov log_External_debt


xtsum numeric_iso3c numeric_periods $outcomes $predictors

zscore_envdeath_index zscore_hscr_index zscore_infdis_index zscore_mental_index zscore_nutrit_index zscore_reprd_index


eststo: regress zscore_nutrit_index $predictors 
eststo: regress zscore_hscr_index  $predictors
eststo: regress zscore_reprd_index  $predictors

// c. Loop through each outcome variable
foreach outcome in `outcomes' {
    di "===================================================="
    di "Analyzing Outcome Variable: `outcome'"
    di "===================================================="

    // d. Run pooled OLS
    regress `outcome' log_ODA ae cri_score log_Pop_dens log_Pop log_GDP_Cap log_Trade log_hlth_Per_Cap gov log_External_debt 
    est store pooled

    // e. Run fixed effects model
    xtreg `outcome' log_ODA ae cri_score log_Pop_dens log_Pop log_GDP_Cap log_Trade log_hlth_Per_Cap gov log_External_debt, fe
    est store fixed

    // f. Run random effects model
    xtreg `outcome' log_ODA ae cri_score log_Pop_dens log_Pop log_GDP_Cap log_Trade log_hlth_Per_Cap gov log_External_debt, re
    est store random

    // g. Breusch-Pagan LM test (pooled OLS vs random effects)
    xttest0

    // h. Hausman test (fixed effects vs random effects)
    hausman fixed random, sigmamore

	// i. Compare models
    di "Model comparison results for `outcome':"
    esttab pooled fixed random, se b(%9.3f) star stats(r2 r2_a N, labels("R-squared" "Adj R-sq" "N")) 

    di "===================================================="
}


/*===========================================================================
| Task Three: In this task, I performed regression analysis and export the results in LaTeX format
============================================================================*/

// a. Load Data  
import delimited "/Users/oluwatosin/Downloads/Olowookere_Oluwatosin_Pre-Doc_Stata_Test/Input_Data/2_Formatting_Results.csv", clear

// b. Regression 1: Attendance rate
eststo: regress attendance treatment, roburst

// c. Regression 2: Grade Point Average
eststo: regress gpa treatment, roburst

// d. Regression 3: Height
eststo: regress height treatment, roburst

// e. Export the regression results to LateX
esttab pooled, tex 
