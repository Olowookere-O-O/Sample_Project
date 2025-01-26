/*===========================================================================
| Purpose: Stata Test for Pre-Doctoral Researcher in Development Economics
| PI: Prof. Dr. Dina Pomeranz
| Author: Olowookere, Oluwatosin Olawale
| Date: November 8th, 2024 (12pm - 5:00pm)
============================================================================*/

clear all 
version 18 // Version control for replication 
set more off 

ssc install estout // To export regression results

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


****** Cleaning date column
gen Date_cleaned = daily(dateddmmyyyy, "DMY")

replace Date_cleaned = daily(dateddmmyyyy, "MDY") if Date_cleaned == . // For date cells where date is saved as MDY
replace Date_cleaned = daily("31/12/2020", "DMY") if notes == "Total 2020" & missing(Date_cleaned) // Use note column as fallback for date missing
replace Date_cleaned = daily(dateddmmyyyy, "YDM") if Date_cleaned == .

format Date_cleaned %tdDD/NN/YYYY // Transform date format to DD/MM/YYYY

gen year = year(Date_cleaned) // Extract year from date column 
gen month = month(Date_cleaned) // Extract year from date column 

drop notes dateddmmyyyy // Drop notes and dateddmmyyyy columns 

sort countryofdestination Date_cleaned

**** Cleaning Exporter ID 
replace exporterid = subinstr(exporterid, "OOO", "", .) if strpos(exporterid, "OOO") > 0 // Remove tripple ooo before export ids
replace countryofdestination = "Togo" in 92 // Togo written as Tango
replace exporterid = "7745967" in 91
replace exporterid = "6324555" in 53

gen exporter_id = exporterid + string(Month, "%02.0f") // Ids are duplicated for same country, preventing it from being unique. I concatenate months number with the original id given in the data. This helps to uniquely distinguish observations

**** Cleaning missing observations
replace valueinusdollars = subinstr(valueinusdollars, "USD", "", .) // Remove USD string in the valueinusdollars 
destring valueinusdollars, replace force // Transform valueinusdollars to numeric
drop if missing(valueinusdollars) | missing(volumeintonnes) // Drop observations where either of the valueinusdollars or olumeintonnes is missing

**** Calculate Unitary export value 
gen unitary_export_value = valueinusdollars / volumeintonnes 

***** Transform data into wide format using months 
collapse (sum) valueinusdollars volumeintonnes unitary_export_value, by(exporter_id countryofdestination year month)
reshape wide valueinusdollars volumeintonnes unitary_export_value, i(exporter_id countryofdestination year) j(month)

sort year

**** Export Output Data
export delimited "/Users/oluwatosin/Downloads/Olowookere_Oluwatosin_Pre-Doc_Stata_Test/Output_Data/1_Data_Cleaned.csv", replace







/*===========================================================================
Please Note: Task one could not be completed due to time
============================================================================*/




***** Task Two: Formatting Results Task ******

// Load Data  
import delimited "/Users/oluwatosin/Downloads/Olowookere_Oluwatosin_Pre-Doc_Stata_Test/Input_Data/2_Formatting_Results.csv", clear

// Regression 1: Attendance rate
eststo: regress attendance treatment, roburst

// Regression 2: Grade Point Average
eststo: regress gpa treatment, roburst

// Regression 3: Height
eststo: regress height treatment, roburst

// Export the regression results to LateX
esttab pooled, tex 
