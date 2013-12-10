### Profile specifications - how to make a 'good' profile for volatile participants

#### Purpose 
Collecting and documenting knowledge on how to build profiles for wind, solar, hydro etc. 
#### How to make a profile

**Research Data**. A profile should be based on actual measurement data. For volatile participants, this is usually the energy carrier that is exploited by the converter, e.g. wind speeds, light intensities, water flow. 
If possible, data from different locations (but the same year) is combined. The wind profiles that we use in the ETM are based on about 4 measurement curves. Combining more curves leads to more smooth and less peaked profiles. A smoother profile will also be characterized by more full load hours. 
(Note: do not average that data yet). 

**Convert primary energy into el. output**. For each dataset, calculate the electricity output of the converter. This is done by applying conversion laws and efficiencies  (including for example, cut-in, cut-out speeds in case of wind, or peak-power in case of solar cells). 

**Average power output**: Now, the electricity output can be averaged. (We average over distributed power generation output, not over distributed wind speeds or river flow). 

**Normalize**: The averaged profile is normalized vertically so that the area under the profile is equal to 1/3600. Normalization is a hard constraint, it should be double-checked before a profile is included in the model. 
Normalization ensures that the participant will produce the correct amount of MWh/year in merit order. This annual energy output is given by research data (effective capacity/unit and full load hours) and the user choices (number of units). 

**Save as Windows-CSV**: If the profile should be readable for the et-engine, it has to be saved in a CSV file that has windows-style newline commands. In Excel, you need to save the profile as "Windows Comma Separated (.csv)". 


##### A profile should not cause a conflict in installed capacities 

Profiles are used to convert an annual energy production to an hourly load in the merit order calculation: 

```
L(i) = profile(i) * P             < 1 >
```
with: 
; L: Load or demand in MW
; i: hour
; P: total production in MJ

It should never happen that merit order calculates an hourly electricity production capacity that exceeds the installed capacity. In other words: If wind turbines with a nameplate capacity of 3 GW are installed, it should not happen that  merit order will run them at 5 GW in certain hours of the year. In technical terms, this means: 

The load curve L(i) [MW] can never exceed the installed capacity (spec. capacity * number of units):

	L(i) =< spec_capacity * #_units             < 2 >

Combining the two equations, yields:

	profile(i) * P =< spec_capacity * #_units             < 3 >

In the merit order module, total annual production is defined as 

	P [MJ] = spec_capacity [MW] * #_units * availability [%] * full_load_hours [h] * 3600 s/h             < 4 >

Substituting P in < 3 >: 

	profile(i) * full load hours * availability * 3600 <= 1

If `MAX(profile(i) ) * full load hours * availability * 3600 exceeds 1, merit order will calculate with exaggerated capacities for certain hours of the year. 

Please test if your profiles fulfil the above constraint. It may also be interesting to see for how many hours of the year `profile(i) * full load hours * availability * 3600 = 1` is fulfilled. This is equivalent to the number of hours that a technology is running at full capacity. Is that number realistic? How often does it happen that *all* wind turbines are running at nameplate capacity throughout the country?

* * * *

**Addition:**

The issue with peaking production capacity can also be expressed with regard to full load hours: 
A profile has a 'intrinsic' full load hour characteristic that is described by 
*Full Load Hours (profile) = Total(profile) / Max(profile)* (Assuming that the peak of the profile is equivalent to the total installed capacity, which is most likely not the case)


###### Reasoning of why any profile should reflect the Full Load Hours of the participant
*Full Load Hours (ETM)* is a figure defined in the ETM dataset
*Full Load Hours (profile)* is determined only by the shape of the profile: 
*Full Load Hours (profile) = Total(profile) / max(profile)*.        **[1]**

####### Claim: The hourly power output can never surpass the installed nameplate capacity!
This translates into: 

*Number of Units * Effective Capacity ≧ Max(profile) * 3600 * Number of Units * Effective Capacity * Full Load Hours (ETM)*.         **[2]**

The left side of the equation is the installed nameplate capacity. The right side of the equation is the maximum power output that can occur in the merit order 'load calculation'. Both sides equate to the unit of MW. 

[2]--> *1 ≧ Max(profile) * 3600 * Full Load Hours (ETM)*

with [1] and Total(profile) = 1/3600, this becomes

[2]--> *Full Load Hours (profile) * 3600 * max(profile) ≧ Max(profile) * 3600 * Full Load Hours (ETM)*

--> *Full Load Hours (profile) ≧ Full Load Hours (ETM)*

This means that the Full Load Hours specified in ETM may never exceed the Full Load Hours of the profile (can easily happen for wind and even buildings_CHP). Of course, *Full Load Hours (profile) > Full Load Hours (ETM)* is possible. It just means that the participant always runs below nameplate capacity (e.g. solar PV in the Netherlands).
