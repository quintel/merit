# Merit

The Merit module is used to calculate the merit order for the [Energy
Transition Model](http://et-model.com).

The **merit order** predicts/calculates which electricity generating
**producers** are producing the power to meet the demand/load of the
different **users** of electricity.

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
| agriculture_chp_engine_gas_power_fuelmix             | Merit::MustRunProducer      | 78.31972973    | 3980.424144        |
| buildings_collective_chp_wood_pellets                | Merit::MustRunProducer      | 154.16507      | 6097.777778        |
| buildings_collective_chp_gas_power_fuelmix           | Merit::MustRunProducer      | 94.03660242    | 3942               |
| households_collective_chp_wood_pellets               | Merit::MustRunProducer      | 119.9789346    | 6097.777778        |
| households_collective_chp_network_gas                | Merit::MustRunProducer      | 13.2815786     | 3942               |
| households_water_heater_fuel_cell_chp_network_gas    | Merit::MustRunProducer      | 0.0            | 0                  |
| other_chp_engine_gas_power_fuelmix                   | Merit::MustRunProducer      | 78.38201622    | 4000               |
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
| energy_power_combined_cycle_gas_power_fuelmix        | Merit::DispatchableProducer | 44.24374451    | 6671.774693261107  |
| energy_power_combined_cycle_ccs_gas_power_fuelmix    | Merit::DispatchableProducer | 57.28270883    | NaN                |
| energy_chp_combined_cycle_gas_power_fuelmix          | Merit::DispatchableProducer | 60.33237888    | 2692.5290921503865 |
| energy_power_ultra_supercritical_gas_power_fuelmix   | Merit::DispatchableProducer | 65.90324432    | 519.7911394222648  |
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
> merit_order.participant(:energy_chp_combined_cycle_gas_power_fuelmix).info
=================================================================================
Key:   energy_chp_combined_cycle_gas_power_fuelmix
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
Effective_output_capacity: 574.9333333 (MW)
Availability:              0.9 (fraction)
```

# Participants

Producers and users of electricity are both called **participants** of the
merit order.

## Users

Users are those 'things' that use electricity. This can be one 'thing', such
as the total demand for a particilar county, but Merit is also capable of
adding different demand together, such as the sector demands, or certain
demand shifting technologies, such as, or intensive electricity demands with
load curves such as 'loading strategies' for electric cars.

For each demand, a **demand profile** has to be defined, and the **total
consumption has to be given.

### Total consumption

Total consumption must be supplied in **MJ**. It is the sum of all electricity
consumption of converters in the final demand converter group **plus** losses
of the electricity network.

## Load Curve/Profile of demand

The total demand is used to scale up the **load profile** for the total demand
(i.e. the demand profile) to produce the correct demand curve (which is a load
curve).

## Producers

A producer is an electricity producing technology, such as a nuclear power
plant, or a local chp.

The following input has to be supplied to Merit in order for it to calculate
properly:

* key (Symbol)
* load_profile (Symbol)
* marginal_costs (EUR/MWh/year) 
* effective_output_capacity (MW electric/plant)
* number_of_units
* availability (%)
* fixed_costs (EUR/plant/year)
* fixed_operation_and_maintenance_costs_per_year (EUR/plant/year)

Have a look at [the stub](/blob/master/examples/stub.rb) for some examples.

### Different types of Producers:

This module has to be supplied with the participants of the Merit Order, which
has to be of one of the following three classes:

* Volatile (e.g. wind turbine, solar panel)
* MustRun (e.g. heat driven CHP)
* Dispatchable (e.g. coal or gas power plant)

#### Key [Symbol]

The **key** is used to identify the participant.

#### Effective output capacity [Float]

The *effective output capacity* is the maximum output capacity of a single
plant. That means it describes how much electricity the technology produces
per second when running at maximum load.

For definitions of available and nominal capacities see the **definitions**
section below.

#### Marginal costs [Float]

The marginal_costs (EUR/MWh/year) are calculated by dividing the variable costs
(EUR/plant/year) of the participant by one plant's annual electricity
production (in MWh/plant). The marginal costs can be queried from the
ETEngine's GQL with the following query:

TODO: Adjust to concrete Query to get the marginal costs (divide by...)

    V(converter_key, variable_costs_per(:mwh_electricity))

#### Fixed costs [Float]

TODO: insert definition...

The fixed costs (EUR/plant/year) can be queried from the ETM with the
fixed_costs function:

    V(converter_key, fixed_costs)

#### Number of units [Float]

A number that specifies how many of a technology are present. **This can be
fractional.**

TODO: Insert Query!

#### Availability [Float]

The availability describes which fraction of the time a technology is available
for electricity production. The full load hours of a technology cannot exceed
its availability multiplied by 8760.  For example, if the availability is 0.95,
the full_load_hours can never exceed 0.95 * 8760 = 8322 hours.

TODO: Insert Query!

#### Fixed operations & maintenance costs per year [Float]

The fixed_operation_and_maintenance_costs_per_year (EUR/plant/year) are used as
an input for calculating the operational_expenses per participant. The
operational_expenses will be used as an output to indicate the extent of
profitability of a participant.

TODO: Insert Query!

#### Additional parameters for must_run and volatile participants

* load_profile_key
* full_load_hours

#### Load profile key

Gives the name of the profile.

#### Full load hours

The full load hours are defined as:

    production / (effective_output_capacity * number_of_units * 3600 )

#### Must Runs and Volatiles

The full load hours of a **must run** or **volatile** participant are
determined by outside factors, and have to be supplied when this participant is
added.

The full load hours of **volatile** and **must-run** technologies already take
the availability of these technologies into account.

#### Dispatchables

The full load hours of a **dispatchable** participant are determined by this
module (so they are 'output').

```Ruby merit_order.participant[:coal].full_load_hours => 2000.0 #hours ```

In full load hours, 'full load' means that the plant runs at its **effective**
capacity. A plant that runs every second of the year at half load, therefore
has full load hours = 8760 * 50% = 4380 hours.

# Output

There are two main areas of output for the Merit Order: *full load hours* (how
much does a plant run?) and *profitability* (is it profitable?).

## For each hour per year:

### Electricity price [Unit EUR/MWh]

For **each hour in a year**, the price is equal to the `marginal_costs` of the
participant that is **one higher** in the merit order than the price-setting
participant. This reflects the assumption that a producer will try to sell his
electricity for a price that is as high as possible but still smaller than the
cost of the participant that is next in the merit order.

**N.B. It is to be determined what the margin is for the most expensive plant
in the merit order (i.e.  when there is no 'one higher').**


## For each Participant

You can get a summary of the participant, but

```Ruby
mo.dispatchables.first.info
```

Furthermore, you can get the following details from a participant:

* full_load_hours
* total income
* total costs
* total variable costs
* operational_expenses
* profit
* profitability

Of course, you can also get the input back which is known, such as
fixed_costs, key, etc.)

### Full load hours

The full load hours of a participant can be calculated by integrating the area
under the load curve and dividing the resulting total production (in MWh)
through the effective capacity.  In practice the integration amounts to summing
up the loads for each data point. Each data point represents 1 hour (so 8760
data points per year).

    full_load_hours = load_profile.sum / effective_output_capacity

For the participants that are cheaper than the price setting participant, the
load is equal to the **available output capacity**.  For the price setting
participant the load is generally lower than the available capacity, since only
a fraction of its available capacity is needed to meet the demand.  For the
participants that are more expensive than the price setting participant, the
load is equal to 0.

### Profitability

**PLEASE NOTE** The cost, revenue and profit methods are not yet implemented, 
but will be added soon.

#### Total income [Float, EUR/plant/year]

The `income` (in EUR/plant/year) of a participant is calculated by summing up
the `load * electricity price` for each data point and dividing the result by
the `number_of_units`.

#### Total costs [Float, EUR/plant/year]

The `total_costs` (EUR/plant/year) of a power participant is calculated by
summing up the `fixed_costs` (which is input) and the `variable_costs`:

    total_costs = fixed_costs + variable_costs

#### Variable costs [Float, EUR/plant/year]

The `variable_costs` (EUR/plant/year) of a participant is calculated by
multiplying the (input parameter) `marginal_costs` (EUR/MWh/year) by the
`electricity production` per plant of the participant.

    variable_costs = marginal_costs * effective_output_capacity * number_of_units * full_load_hours / number_of_units

#### Operational expenses [Float, EUR/plant/year]

The `operational_expenses` (EUR/plant/year) of a participant is calculated by
adding the (input parameter) `fixed_operation_and_maintenance_costs_per_year`
(EUR/plant/year) to the `variable costs`.

    operational_expenses = fixed_operation_and_maintenance_costs_per_year + variable_costs

#### Profit [Float

The `profit` of a participant (EUR/plant/year) is calculated by subtracting the
`total_costs` from the `income` of the participant.

    profit = income - total_costs

#### Profitability

Returns one of three states:

1. `:profitable` (if `income >= total costs`)
2. `:conditionally_profitable` (if `operational_expenses =< income < total costs`)
3. `:unprofitable` (if `income < operational_expenses`)

P.S. These three states are communicated to the user by coloring the
participants **green**, **orange** and **red** respectively in the Merit Order
table.

## Load Profile

For each **must_run** and **volatile** participant a **normalized** load
profile has to be defined in the merit order module. Also, the **demand**
needs to have a load profile defined.

#### Definition

A load profile has **8760** datapoints, one for every hour in a year. Profiles
are normalized such that multiplying them with the total produced electricity
(in **MJ**) yields the load at every point in time in units of **MW**.

This normalization effectively implies that the surface area under the load
profiles is equal to 1 MJ.  This can be checked:

``` Ruby
Merit::LoadProfile.load(:total_demand).valid?
=> true #
```

#### Current Load Profiles

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

## Definitions

### Capacity

##### Nominal capacity

What's in the brochure? (e.g. 800 MW)

##### Effective capacity

What's the effective output of a technology over its lifetime? (e.g. 790 MW)

##### Available capacity

What's available if you take maintenance, down time, and volatility into
account? (e.g. 650 MW)

     available_capacity = effective_capacity * availability

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
* marginal_costs: **EUR/MWh/year** 
* effective_output_capacity: **MW electric/plant**
* number_of_units: **#**
* availability: **fraction** (between 0 and 1)
* fixed_costs: **EUR** (per plant per year)
* fixed_operation_and_maintenance_costs_per_year: **EUR** (per plant per year)
* total_demand: **MJ** (per year)
* full_load_hours: **hours** (per year)
* profitability: **:symbol**
* income: **EUR** (per plant per year)
* profit: **EUR** (per plant per year)
* electricity price: **EUR/MWh**

## Issues

Please add any issues to the list of
[issues](http://github.com/quintel/merit/issues).
