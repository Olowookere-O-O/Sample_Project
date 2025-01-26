* Load the dataset
import delimited "https://raw.githubusercontent.com/Olowookere-O-O/R-Scripts-for-Thesis-Analysis/refs/heads/main/Thesis_Data/MisF_imp_clean_thesis_data_Indices.csv", clear


* Create a local macro with all variables except the ones to exclude
ds iso3c country region, not
local vars_to_destring `r(varlist)'

* Apply destring to the selected variables
destring `vars_to_destring', replace float dpcomma


* Filter out year 2022
drop if year == 2022

* Create the `periods` variable based on year ranges
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

* Group by iso3c and periods, calculate means of model_vars
collapse (mean) ae bci gov chs_25perc oda_disb soc_inf_oda govt_hth_spnd_1 hlth_spdng_pergdp cf_lf_ratio pop_tot cri_score pop_densty external_debt_stock trade gdp_per_cap zscore_envdeath_index zscore_infdis_index zscore_hscr_index zscore_mental_index zscore_reprd_index zscore_nutrit_index aid_per_gni unemply_rate, by(iso3c periods)



* Generate log-transformed variables
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

* Convert string IDs to numeric for `iso3c` and `periods`
encode iso3c, gen(numeric_iso3c)
encode periods, gen(numeric_periods)

order country numeric_iso3c numeric_periods region iso3c  periods

* Declare panel data structure using numeric IDs
xtset numeric_iso3c numeric_periods

* Step 2: Define outcome variables
global zscore_envdeath_index zscore_hscr_index zscore_infdis_index zscore_mental_index zscore_nutrit_index zscore_reprd_index
global predictors log_ODA ae cri_score log_Pop_dens log_Pop log_GDP_Cap log_Trade log_hlth_Per_Cap gov log_External_debt


xtsum numeric_iso3c numeric_periods $outcomes $predictors




zscore_envdeath_index zscore_hscr_index zscore_infdis_index zscore_mental_index zscore_nutrit_index zscore_reprd_index


eststo: regress zscore_nutrit_index $predictors 
eststo: regress zscore_hscr_index  $predictors
eststo: regress zscore_reprd_index  $predictors


* Step 3: Loop through each outcome variable
foreach outcome in `outcomes' {
    di "===================================================="
    di "Analyzing Outcome Variable: `outcome'"
    di "===================================================="

    * Step 4: Run pooled OLS
    regress `outcome' log_ODA ae cri_score log_Pop_dens log_Pop log_GDP_Cap log_Trade log_hlth_Per_Cap gov log_External_debt 
    est store pooled

    * Step 5: Run fixed effects model
    xtreg `outcome' log_ODA ae cri_score log_Pop_dens log_Pop log_GDP_Cap log_Trade log_hlth_Per_Cap gov log_External_debt, fe
    est store fixed

    * Step 6: Run random effects model
    xtreg `outcome' log_ODA ae cri_score log_Pop_dens log_Pop log_GDP_Cap log_Trade log_hlth_Per_Cap gov log_External_debt, re
    est store random

    * Step 7: Breusch-Pagan LM test (pooled OLS vs random effects)
    xttest0

    * Step 8: Hausman test (fixed effects vs random effects)
    hausman fixed random, sigmamore

	* Optional: Compare models
    di "Model comparison results for `outcome':"
    esttab pooled fixed random, se b(%9.3f) star stats(r2 r2_a N, labels("R-squared" "Adj R-sq" "N")) 

    di "===================================================="
}



* Step 3: Loop through each outcome variable
foreach outcome in `outcomes' {
    * Step 4: Run pooled OLS and display results
    di "Running Pooled OLS for `outcome'..."
    reg $outcomes $predictors
}
