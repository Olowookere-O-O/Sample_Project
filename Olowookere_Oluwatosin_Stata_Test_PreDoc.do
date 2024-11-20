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


// d. Handle missing values: drop rows where both exporter_id or export_value are missing, as they are essential
drop if missing(exporter_id) | missing(export_value_US)

// e. Remove non-numeric characters from export value and converting to numeric
// Remove commas and other symbols from export_value, then convert to numeric
gen export_value_cleaned = subinstr(export_value_US, ",", "", .)

// f. Drop the old `export_value` column and rename cleaned version
drop export_value_US
gen export_value_dollars = real(export_value_cleaned)



// g. Standardize date format and filter for the year 2020
gen date_cleaned = date(dateddmmyyyy, "DMY")
format date_cleaned %td
drop dateddmmyyyy
rename date_cleaned date


keep if year(date) == 2020 // Filter to keep only data from 2020

// h. Calculate total unitary exports (export_value / volume)
gen unitary_exports = export_value_dollars  / volume_tonnes
drop if missing(unitary_exports)  // drop if calculation fails due to missing data


* i. Reshape the dataset to have one column per month (Jan-Dec) for each exporter-country pair
gen month = month(date) //Extract month and year for reshaping
gen year = year(date)
keep exporter_id destination_country year month unitary_exports //  drop any non-relevant columns and keep only required data

reshape wide unitary_exports, i(exporter_id destination_country) j(month) // Reshape from long to wide format

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
esttab, tex 
