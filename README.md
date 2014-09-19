# Merit

The Merit module is used to calculate the
[merit order](http://en.wikipedia.org/wiki/Merit_order) for the
[Energy Transition Model](http://et-model.com).

### Build Status

**Master**: ![Master branch](https://semaphoreapp.com/api/v1/projects/2ae041ef26ece32798c70411422544b8f43a5919/14150/badge.png)

### Introduction

The **merit order** predicts/calculates which electricity generating
**producers** are producing the power to meet the demand/load of the
different **users** of electricity. 
It does this for each of the 8760 hours in a year and computes several
yearly averaged quantities for each producer such as

* merit order position
* full load hours
* total revenue
* total costs
* total variable costs
* operating expenses
* profit
* profitability

The above quantities are defined and explained in the main text below.

Both **users** and **producers** are participants in the Merit Order 
calculation. Examples of users include the transport sector, the household
sector, electric heating devices, etc. Producers may be nuclear reactors, wind
turbines or solar panels.  Producers can be one of three types 

* dispatchable (can be switched on and off at will) 
* volatile (can be switched off but not on at will)
* must-run (produces electricity as a by-product and is insensitive to changes
  in electricity demand)

Every user has a demand for electricity (which can be zero) at every 
point in time , which we call its **load**. The description of the load of a 
user is described by a **load profile**.

Also, every must-run- or volatile producer has a load profile, but instead of
demand it describes its production at each point in time.

Let's get more familiar with the terms mentioned above by looking at a quick
demonstration of the Merit Order moule. 

## Quick Demonstration

Load the library from the command line along with the example stub:

    $>rake console:stub

This will load the examples in a global variable `merit_order`, calculate it
and take you into an irb or pry session (that is an interactive Ruby session).

Then you can start to request output, e.g. a summary of the 'Merit Order':

```
>merit_order.info
+------------------------------------------------------+-----------------------------+----------------+--------------------+
| key                                                  | class                       | marginal costs | full load hours    |
+------------------------------------------------------+-----------------------------+----------------+--------------------+
| energy_power_solar_pv_solar_radiation                | Merit::VolatileProducer     | 0.0            | 1050               |
| energy_power_solar_csp_solar_radiation               | Merit::VolatileProducer     | 1.0            | 500                |
| energy_power_wind_turbine_inland                     | Merit::VolatileProducer     | 0.0            | 2500               |
| energy_power_wind_turbine_coastal                    | Merit::VolatileProducer     | 0.0            | 3000               |
| energy_power_wind_turbine_offshore                   | Merit::VolatileProducer     | 0.0            | 3500               |
| buildings_solar_pv_solar_radiation                   | Merit::VolatileProducer     | 0.0            | 1050               |
| households_solar_pv_solar_radiation                  | Merit::VolatileProducer     | 0.0            | 1050               |
| industry_chp_combined_cycle_gas_power_fuelmix        | Merit::MustRunProducer      | 109.5210516    | 5442.834138        |
| industry_chp_supercritical_wood_pellets              | Merit::MustRunProducer      | 139.7898305    | 5247.813411        |
| industry_chp_ultra_supercritical_coal                | Merit::MustRunProducer      | 32.15521115    | 4204.8             |
| energy_power_supercritical_waste_mix                 | Merit::MustRunProducer      | 1.20608908     | 6190.47619         |
| agriculture_chp_engine_network_gas                   | Merit::MustRunProducer      | 78.31972973    | 3980.424144        |
| buildings_collective_chp_wood_pellets                | Merit::MustRunProducer      | 154.16507      | 6097.777778        |
| buildings_collective_chp_network_gas                 | Merit::MustRunProducer      | 94.03660242    | 3942               |
| households_collective_chp_wood_pellets               | Merit::MustRunProducer      | 119.9789346    | 6097.777778        |
| households_collective_chp_network_gas                | Merit::MustRunProducer      | 13.2815786     | 3942               |
| households_water_heater_fuel_cell_chp_network_gas    | Merit::MustRunProducer      | 0.0            | 0                  |
| other_chp_engine_network_gas                         | Merit::MustRunProducer      | 78.38201622    | 4000               |
| households_space_heater_micro_chp_network_gas        | Merit::MustRunProducer      | 0.0            | 0                  |
| households_water_heater_micro_chp_network_gas        | Merit::MustRunProducer      | 0.0            | 0                  |
| energy_power_nuclear_gen3_uranium_oxide              | Merit::DispatchableProducer | 5.826162528    | 7884.0             |
| energy_power_nuclear_gen2_uranium_oxide              | Merit::DispatchableProducer | 6.133182844    | NaN                |
| energy_power_ultra_supercritical_lignite             | Merit::DispatchableProducer | 13.999791      | NaN                |
| energy_chp_ultra_supercritical_lignite               | Merit::DispatchableProducer | 16.60280222    | NaN                |
| energy_power_ultra_supercritical_oxyfuel_ccs_lignite | Merit::DispatchableProducer | 19.58755889    | NaN                |
| energy_power_combined_cycle_coal                     | Merit::DispatchableProducer | 23.20617439    | 7883.999999998419  |
| energy_power_combined_cycle_ccs_coal                 | Merit::DispatchableProducer | 28.36859203    | NaN                |
| energy_power_ultra_supercritical_coal                | Merit::DispatchableProducer | 28.88180898    | 7708.800000001613  |
| energy_power_supercritical_coal                      | Merit::DispatchableProducer | 29.9100356     | NaN                |
| energy_chp_ultra_supercritical_coal                  | Merit::DispatchableProducer | 32.39199569    | 7695.570154910887  |
| energy_power_ultra_supercritical_ccs_coal            | Merit::DispatchableProducer | 34.97148374    | NaN                |
| energy_power_combined_cycle_network_gas              | Merit::DispatchableProducer | 44.24374451    | 6671.774693261107  |
| energy_power_combined_cycle_ccs_network_gas          | Merit::DispatchableProducer | 57.28270883    | NaN                |
| energy_chp_combined_cycle_network_gas                | Merit::DispatchableProducer | 60.33237888    | 2692.5290921503865 |
| energy_power_ultra_supercritical_network_gas         | Merit::DispatchableProducer | 65.90324432    | 519.7911394222648  |
| energy_power_turbine_network_gas                     | Merit::DispatchableProducer | 78.01340618    | 65.0114838600931   |
| energy_power_ultra_supercritical_crude_oil           | Merit::DispatchableProducer | 93.09320787    | NaN                |
| energy_chp_ultra_supercritical_crude_oil             | Merit::DispatchableProducer | 109.3782764    | NaN                |
| energy_chp_ultra_supercritical_wood_pellets          | Merit::DispatchableProducer | 139.7898305    | NaN                |
| energy_power_engine_diesel                           | Merit::DispatchableProducer | 160.0982801    | NaN                |
+------------------------------------------------------+-----------------------------+----------------+--------------------+
```

This table shows the order of the *producers* for meeting electricity demand.
*Volatile* producers come first, then *must run* producers, and finally, the
*dispatchable* producers can serve electricty demand. The *dispatchable*
producers are **ordered** by their **marginal costs**.

If you want to get more detail on one of the producers, you can query its
details. You will see a summary of the information, with a chart of the *load
curve*.

```
> merit_order.participant(:energy_chp_combined_cycle_network_gas).info
=================================================================================
Key:   energy_chp_combined_cycle_network_gas
Class: Merit::DispatchableProducer

-o---------------------------------------------------------------------- 2.13e+03
-o---------------------------------------------------------------------- 1.07e+03
-o---o---------------------------------------------------------------o-- 7.11e+02
-o---o--o------------------------------------------------------------o-- 5.33e+02
-o---o-oo---------------------------------------------------------o--o-- 4.26e+02
-oo--o-ooo----------------------------------------------------o---o-ooo- 3.55e+02
-oo-oooooo----------------------------------------------------o---o-ooo- 3.05e+02
oooooooooo-oo-------------------------------------------------o-ooo-ooo- 2.66e+02
oooooooooo-oo---o---------o----------------------------o--oo-oo-ooooooo- 2.37e+02
ooooooooooooo--oo--o--o---o---o---oooo----------o-----oo--oo-oooooooooo- 2.13e+02
ooooooooooooo-ooo-oo--oo-oo--oo-oooooo------oo-oo-oo--oo-oooooooooooooo- 1.94e+02
ooooooooooooooooo-oooooo-oo--oo-oooooo-----oooooooooo-oo-ooooooooooooooo 1.78e+02
ooooooooooooooooo-oooooo-oo--oo-oooooo-ooo-ooooooooooooooooooooooooooooo 1.64e+02
oooooooooooooooooooooooooooooooooooooooooo-ooooooooooooooooooooooooooooo 1.52e+02
oooooooooooooooooooooooooooooooooooooooooo-ooooooooooooooooooooooooooooo 1.42e+02
oooooooooooooooooooooooooooooooooooooooooo-ooooooooooooooooooooooooooooo 1.33e+02
                       LOAD CURVE (x = time, y = MW)
                       Min: 0.0, Max: 2975.0399997718337
                       SD: 1172.0370051181014

Summary:
--------
Full load hours:           2692.5290921503865 hours

Production:                32.04152699878696 PJ
Max Production:            93.82086143280453 PJ

Average load:              1016.0301559737114 MW
Available_output_capacity: 2975.0399997718337 MW

Number of units:           5.749536178 number of (typical) plants
output_capacity_per_unit: 574.9333333 (MW)
Availability:              0.9 (fraction)
```

In production environments, for optimal performance enable caching of the load
profile data:

```ruby
Merit::LoadProfile.reader = Merit::LoadProfile::CachingReader.new
```

# Participants

Producers and users of electricity are both called **participants** of the
merit order.

## Users

Users are those 'things' that use electricity. This can be one 'thing', such
as the total demand for a particular country, but Merit is also capable of
adding different demands together, such as the demand of the household sector 
and the transport sector, or certain demand shifting technologies, such as 
pumped storage, or intensive electricity demands with load curves such as 
'loading strategies' for electric cars.

For each demand, a **demand profile** has to be defined, and the **total
consumption** has to be given to properly scale the demand profile with.

### Total consumption

Total consumption must be supplied in **MJ**. It is the sum of all electricity
consumption of the users **plus** losses of the electricity network. Note that
 the losses only need to be taken into account once.

For the demand of **all** the converters in the ETM, the electricity consumption 
of the final demand converter group can be used ( **plus** losses of the 
electricity network).

### Demand profile

The **demand profile** describes the **variation** of the demand of a user as a 
function of time. The demand profile is normalized to **1 MJ** surface area. 
It has to be scaled to its proper dimensions of **MW** by multiplying it with
the total conumption. The demand profile is equivalent to the load profiles 
defined for must-run and dispatchable producers.

## Producers

A producer is an electricity producing technology, such as a nuclear power
plant, or a local chp.

The following input has to be supplied to Merit in order for it to calculate
properly:

* key (Symbol)
* load_profile_key (Symbol)
* marginal_costs (EUR/MWh) 
* output_capacity_per_unit (MW electric/unit)
* number_of_units (float)
* availability (%)
* fixed_costs_per_unit (EUR/unit/year)
* fixed_om_costs_per_unit (EUR/unit/year)

Have a look at 
[the stub](https://github.com/quintel/merit/blob/master/examples/stub.rb) for 
some examples.

### Different types of Producers:

This module has to be supplied with the participants of the Merit Order, which
has to be of one of the following three classes:

* Volatile (e.g. wind turbine, solar panel)
* MustRun (e.g. CHPs that fulfill a heat demand)
* Dispatchable (e.g. coal or gas power plant)

#### Key [Symbol]

The **key** is used to identify the participant.

The key costs can be queried from the ETEngine's GQL with the following query:

    V(converter_key, key)

However, this is hardly useful, as the 'converter_key' is identical to the 'key'.

#### Effective output capacity [Float]

The *effective output capacity* is the maximum output capacity of a single
plant. That means it describes how much electricity the technology produces
per second when running at maximum load.

The effective output capacity can be queried from the ETEngine's GQL with the following
query:

    V(converter_key, "electricity_output_conversion * effective_input_capacity")

For definitions of available and nominal capacities see the **definitions**
section below.

#### Marginal costs [Float]

The marginal_costs (EUR/MWh) are calculated by dividing the variable costs
(EUR/plant/year) of the participant by the annual electricity production.

The marginal costs can be queried from the ETEngine's GQL with the following
query:

    V(converter_key, variable_costs_per(:mwh_electricity))

#### Fixed costs per unit [Float]

The *fixed costs* of a plant are costs that do not change with producting,
and consists of its 'cost_of_capital', 'depreciation_costs' and
'fixed_operating_and_maintenance_costs_per_year'.

The *fixed costs per unit* can be queried from the ETEngine's GQL with the following
query:

    V(converter_key, fixed_costs)

#### Number of units [Float]

A number that specifies how many of a technology are present. **This can be
fractional.**

The number of units can be queried from the ETM with the following query:

    V(converter_key, number_of_units)

#### Availability [Float]

The availability describes which fraction of the time a technology is available
for electricity production. The full load hours of a technology cannot exceed
its availability multiplied by 8760.  For example, if the availability is 0.95,
the full_load_hours can never exceed 0.95 * 8760 = 8322 hours.

The availability can be queried from the ETM with the following query:

    V(converter_key, availability)

#### Fixed operations & maintenance costs per unit per year [Float]

The **fixed_om_costs_per_unit** (EUR/unit/year) are used as
an input for calculating the operational_expenses per participant. The
operational_expenses will be used as an output to indicate the extent of
profitability of a participant (see also the list of outputs).

The fixed_om_costs_per_unit can be queried from the 
ETEngine's GQL with the following query:

    V(converter_key, fixed_operation_and_maintenance_costs_per_year)

#### Additional parameters for must_run and volatile participants

* load_profile_key
* full_load_hours

#### Load profile key

Gives the name of the load profile. 

##### Current Load Profiles

Currently, the following load profiles are supported

0. demand
1. industry chps
2. agriculural chps
3. buildings chps
4. solar pv panels
5. offshore wind turbines
6. coastal wind turbines
7. inland wind turbines

These load profile are defined in the
[load_profiles](https://github.com/quintel/merit/tree/master/load_profiles)
directory.  These curves are normalized such that the surface area underneath
each curve equals unity.  This means that the load of a must_run or volatile
participant at every point in time can be found by multiplying its load profile
with its **electricity production** (note that this is not equal to its
demand).

**NOTE: The scaling of MO load_profiles can result in loads (MW) larger 
then the available efficiency**

This happens because the area under the profiles needs to be scaled to the 
total produced electricity but the shape of the profiles does not always 
include all information.

For example, the profiles for wind may not describe every gush of wind that 
has been converted into electricity and therefore 'misses' features, i.e., it 
has a trough where it should have a peak. This is inevitable as we do not have 
measurement of every location in the Netherlands where a turbine is situated 
and we do not know the exact relation between the wind speeds (measured) and 
the production of a turbine.

This means that to reproduce the total production, the profile has to be 
scaled vertically (to make up for the lost peaks) and peaks in the load may 
become unphysically high. This is not a fundamental problem, as the curve is 
only indicative of the variability of the technology, but it might confuse 
the user.

For a guideline on how to generate merit order profiles, please check out the 
[profile_generation_guidelines.md](https://github.com/quintel/merit/blob/master/profile_generation_guidelines.md). 

#### Full load hours

The full load hours are defined as:

    production / (output_capacity_per_unit * number_of_units * 3600 )

##### Must Runs and Volatiles

The full load hours of a **must run** or **volatile** participant are
determined by outside factors, and have to be supplied when this participant is
added.

The full load hours of **volatile** and **must-run** technologies already take
the availability of these technologies into account.

The full load hours can be queried from the ETM with the following query:

    V(converter_key, full_load_hours)

##### Dispatchables

The full load hours of a **dispatchable** participant are determined by this
module (so they are 'output').

````ruby
merit_order.participant(:coal).full_load_hours
=> 2000.0 #hours
```

In full load hours, 'full load' means that the plant runs at its **effective**
capacity. A plant that runs every second of the year at half load, therefore
has full load hours = 8760 * 50% = 4380 hours.

# Output

There are two main areas of output for the Merit Order: *full load hours* (how
much does a plant run?) and *profitability* (is it profitable?).

## For each hour per year

### Electricity price Curve

You can get the electricity price in EUR/MWh for each hour in the year by
running:

    Merit::PriceCurves::FirstUnloaded.new(merit_order)

The price is equal to the `marginal_costs` of the participant that is **the
first one that is not running at all**. This reflects the assumption that a
producer will try to sell his electricity for a price that is as high as
possible but still (infinite) smaller than the cost of the participant that is
the first one *not* producing.

If all the dispatchables are producing, and hence there is none *not-running*,
the *highest* `:marginal_costs` of a **runnning** dispatchable plant multiplied
with a factor 7.22 is taken to be the price in that market.

If there are no dispatchable running plants defined, the fall back price is 600
Euros.

Alternatively, you can determine the pricing according to the most expensive
running plant:

    Merit::PriceCurves::LastLoaded.new(merit_order)

## For each Participant

You can get a summary of the participant by running:

    participant.info

Furthermore, you can get the following details from a participant:

* merit order position
* full load hours
* total revenue
* total costs
* total variable costs
* operational expenses
* profit
* profitability

Of course, you can also get the given input values, such as
`fixed_costs`, `key`, etc.

### Full load hours

The full load hours of a participant can be calculated by integrating the area
under the load curve and dividing the resulting total production (in MWh)
through the effective capacity.  In practice the integration amounts to summing
up the loads for each data point. Each data point represents 1 hour (so 8760
data points per year).

    full_load_hours = load_profile.sum / output_capacity_per_unit

For the participants that are cheaper than the price setting participant, the
load is equal to the **available output capacity**.  For the price setting
participant, the load is generally lower than the available capacity, since only
a fraction of its available capacity is needed to meet the demand.  For the
participants that are more expensive than the price setting participant, the
load is equal to 0.

### Financial output

Financial ouptut is calculated **per participant**. To obtain the output **per
 unit**, the output must be divided through the number of units of the 
 participant.

#### Total revenue [EUR/year]

The `revenue` (in EUR/year) of a participant is calculated by summing up
the `load * electricity_price` for each data point.

#### Total costs [EUR/year]

The `total_costs` (EUR/year) of a participant is calculated by
summing up the `fixed_costs` (which is input) and the `variable_costs`:

    total_costs = fixed_costs + variable_costs

#### Fixed costs [EUR/year]

The fixed_costs 

    fixed_costs = fixed_costs_per_unit * number_of_units

#### Variable costs [EUR/year]

The `variable_costs` (EUR/year) of a participant is calculated by
the (input parameter) `marginal_costs` (EUR/MWh) by the `production` of the
participant (in MWh).

    variable_costs = marginal_costs * production(:mwh)

#### Operating costs (OPEX) [EUR/year]

The `operating_costs` (also called OPEX) (EUR/year) of a participant is
calculated by:

    operating_costs = fixed_om_costs + variable_costs

#### Fixed Operating And Maintenance Costs [EUR/year]

The `fixed_om_costs` are calculated by taking the
 `fixed_om_costs_per_unit` and multiplying it
with the `number_of_units`.

    fixed_om_costs = fixed_om_costs_per_unit * number_of_units

#### Profit [EUR/year]

The `profit` of a participant (EUR/year) is calculated by subtracting the
`total_costs` from the `revenue` of the participant.

    profit = revenue - total_costs

#### Profitability

Returns one of three states:

1. `:profitable` (if `revenue >= total costs`)
2. `:conditionally_profitable` (if `operating_costs =< revenue < total costs`)
3. `:unprofitable` (if `revenue < operating_costs`)

P.S. These three states are communicated to the end user in the ETM by coloring
the participants **green**, **orange** and **red** respectively.

## Definitions

### Capacity

##### Nominal capacity

What's in the brochure? (e.g. 800 MW)

##### Effective capacity

What's the effective output of a technology over its lifetime? (e.g. 790 MW)

##### Available capacity

What's available if you take maintenance, down time, and volatility into
account? (e.g. 650 MW)

     available_capacity = output_capacity_per_unit * availability

### Load profile

A load profile has **8760** datapoints, one for every hour in a year. Profiles
are normalized such that multiplying them with the total produced electricity
(in **MJ**) yields the load at every point in time in units of **MW**.

This normalization effectively implies that the surface area under the load
profiles is equal to 1 MJ.  This can be checked:

``` Ruby
Merit::LoadProfile.load(:total_demand).valid?
=> true #
```

## Assumptions

* This module just calculates yearly averages. No seasons, months, or days
* The electricity price is marginal costs of the participant that comes next to
  the price setting participant (EUR/MWh)

## Road Map

* Currently, the load profile is expected to consist of 8_760 data points for
  the `full_load_hours` to work correctly. More flexibility may be supported
  later.
* Additional features will (probably) be added, including:
  - number of times switched on/off
  - duration of on/off periods
  - ramp speeds
  - seasonal output
  - cost differentiation of participants of the same type
  - ...much more..
  - [add your ideas!](http://github.com/quintel/merit/issues/new)
* This module can import from [ETSource](http://github.com/quintel/etsource)
* User can define his own load profile, or change an existing one

## Units used

#### Principles

* All *energies/demands/productions* are quoted in **MJ**
* All *loads/capacity/powers* are quoted in **MW**

#### List

* load: **MW**
* marginal_costs: **EUR/MWh** 
* output_capacity_per_unit: **MW electric/unit**
* number_of_units: **#**
* availability: **fraction** (between 0 and 1)
* fixed_costs_per_unit: **EUR** (per unit per year)
* fixed_om_costs_per_unit: **EUR** (per unit per year)
* total_demand: **MJ** (per year)
* full_load_hours: **hours** (per year)
* profitability: **:symbol**
* revenue: **EUR** (per year)
* profit: **EUR** (per year)
* electricity price: **EUR/MWh**

## Issues

Please add any issues to the list of
[issues](http://github.com/quintel/merit/issues).
