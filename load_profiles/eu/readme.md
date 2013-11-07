#### This eu folder containts load profiles for the EU27 model (base year 2011). 

Documentation on how profiles are made in general can be found on https://github.com/quintel/documentation/blob/master/modules/merit_order/must-run%20Profile%20specifications.markdown
Specifically: The 'intrinsic' full load hours of any profile (defined as `Full Load Hours (profile) = Total(profile) / Max(profile)`) should never surpass the full load hours that are assigned to the respective technology. This avoids that merit order will operate a technology at a higher capacity than the installed capacity allows. 

##### agriculture_chp.csv
	identical to NL profile

##### buildings_chp.csv
	identical to NL profile

##### industry_chp.csv
	always on

##### river.csv
	identical to NL profile

##### solar_pv.csv
	tbd

##### total_demand.csv

	The original curves (per country and per month) have been downloaded from ENTSO-E, see https://www.entsoe.eu/db-query/consumption/mhlv-all-countries-for-a-specific-month 
	We consider 26 out of the 27 EU countries, only Malta is missing. (Be aware that the original data considers dailight savings, which means that we needed to correct two non-continuous hours in March and October)
	We add all EU load curves together, unit: MW. 

##### wind_coastal.csv
	tbd

##### wind_inland.csv
	tbd

##### wind_offshore.csv
	tbd

