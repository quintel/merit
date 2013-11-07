This eu folder containts load profiles for the EU27 model (base year 2011). 

Documentation on how profiles are made in general can be found on https://github.com/quintel/documentation/blob/master/modules/merit_order/must-run%20Profile%20specifications.markdown
Specifically: The 'intrinsic' full load hours of any profile (defined as `Full Load Hours (profile) = Total(profile) / Max(profile)`) should never surpass the full load hours that are assigned to the respective technology. This avoids that merit order will operate a technology at a higher capacity than the installed capacity allows. 


agriculture_chp.csv
	identical to NL profile

buildings_chp.csv
	identical to NL profile

industry_chp.csv
	always on

river.csv
	identical to NL profile

solar_pv.csv
	tbd

total_demand.csv

	The original curves (per country and per month) have been downloaded from ENTSO-E, see https://www.entsoe.eu/db-query/consumption/mhlv-all-countries-for-a-specific-month 
	We consider 26 out of the 27 EU countries, only Malta is missing.

	We add all EU load curves together, unit: MW.

	It turns out that there is one datapoint missing in the database, we deal with that by interpolating from the one value left and right (datapoint 2042).

	See Dropbox/Quintel/Projects/Restructure Research Dataset/EU27 project/source analyses/12_merit_order/ENTSO-E/demand_curves/plot_average_loadcurves.py (Thanks to @jorisberkhout )

	It turns out that the sum of the EU_load curve equals 3.33701 GWh. 
	The "merit_order_total_electricity_demand" in a default EU scenario is 
	3.25069 GWh, so we are doing pretty well.

	We normalised the EU_total_demand curve to 1/3600 and saved it in windows-formatted CSV file, 15 digits, scientific writing :sunglasses:


wind_coastal.csv
	tbd

wind_inland.csv
	tbd

wind_offshore.csv
	tbd

