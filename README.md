# Merit Order

This module is used to calculate the merit order for the
[Energy Transition Model](http://et-model.com).

The **merit order** predicts/calculates which electricity generating
technologies are switched on or off to meet the demand/load on the electricity
network.

## Quick Demonstration

First, you have to initialize a new Merit Order 'session'

```Ruby
merit_order = Merit::Order.new
=> "<Merit::Order, 0 participants, demand: not set>"
```

Add the dispatchable participants to the Merit Order, with their *marginal
costs* in EUR / MWh, the (installed) *capacity* (in MW electric) and the
**availability**.

The marginal costs per plant are calculated by normalizing the variable costs of the plant 
by the amount of MWh it has produced. The marginal costs are calculated in ETEngine and are called
merit_order_variable_costs_per(:mwh_electricity)

Furthermore the following attributes per plant are necessary for themerit order and profitability calculation:
* WACC
* construction_time (years)
* technical_lifetime (years)
* total_investment_over_lifetime (EUR)
* residual_value (EUR)
* fixed_operation_and_maintenance_costs_per_year (EUR/FLH)
* variable O&M costs (EUR/FLH)
* typical_fuel_input (MJ)
* weighted_carrier_cost_per_mj (EUR/MJ)
* weighted_carrier_co2_per_mj (
* area.co2_percentage_free (how much co2 is given away for free)
* part_ets (which part of the plant is restricted by the ETS)
* co2_free (CO2-emissions with no costs)

```Ruby
merit_order.add_dispatchable(key: nuclear_gen3,             50.0, 800, 0.95)
merit_order.add_dispatchable(key: ultra_supercritical_coal, 48.0, 2000, 0.90)
merit_order.add_dispatchable(key: combined_cycle_gas,       60.0, 3000, 0.85)
```

Add the `must_run` and `volatile` participants with the **load_profile_key**, its
**marginal costs**, the (installed) **capacity** and it's **full load hours** 

```Ruby
merit_order.add_must_run(:industry_chp_combined_cycle_gas, :industry_chp,  110.0, 1200, 8000)
merit_order.add_volatile(:wind_offshore,                   :wind_offshore, 120.0, 1400, 7500)
```

Specify with what demand you want to calculate the merit order

```Ruby
merit_order.total_demand = 300 * 10**9 #MJ
```

Now you have supplied the minimal amount of information to calculate output
for this situation, and you can start to ask for this output, e.g.

```Ruby
merit_order.participant[:ultra_supercritical_coal].full_load_hours
=> 2000 # hours
merit_order.participant[:ultra_supercritical_coal].profit
=> 10.0 # EUR/plant/year
merit_order.participant[:ultra_supercritical_coal].profitability
=> :profitable
```

The electricity price is an outcome of the merit order calculation, and is
determined to be: Marginal costs of the plant that comes next to the price
setting plant (EUR/MWh)

## Input

The Merit Order needs to know about **which technologies participate** in the
merit order, and about the **total energy demand**.

#### Participants

This module has to be supplied with the participants of the Merit Order, which
has to be either:

* must run
* volatile
* dispatchable

The full load hours of a **must run** or **volatile** participant are determined
by outside factors, and have to be supplied when this participant is added.

For example, 8000 hours for the industry chps:

```Ruby
merit_order.add_must_run(:industry_chp_combined_cycle_gas, :industry_chp, 110.0, 1200, 8000)
```

The full load hours of a **dispatchable** participant are determined by this
module.

```Ruby
merit_order.participant[:coal].full_load_hours
=> 2000 #hours
```

#### Total demand

Total demand must be supplied in **MJ**. It is the sum of all electricity consumption 
of converters in the final demand converter group **plus** losses of the electricity network. 

The total demand is used to scale up the **normalized** demand curve to it produce the correct
demand curve.

## Output

Merit order can supply the user with the following information of the *participants*:

1. full load hours 
2. load fraction
3. income
4. total costs
5. fixed costs
6. variable costs
7. profitability
8. profit


```Ruby
merit_order.participants[:coal].full_load_hours
=> 8_760 # it runs all the time!
merit_order.participants[:coal].profit
=> 1_000_000_000 EUR (annual) # it makes a billion euros!
merit_order.participants[:coal].profitability
=> "profitable" # hurray, it is profitable!
```
This information is shown in a table. 

#### Full load hours and load fraction

Return the full load hours of a participating electricity generating
technology in **hours**. The number of full load hours is calculated by summing up the load fraction for each data point.
Each data point represents 1 hour (so 8760 data points per year).
The load fraction is the fraction of capacity of a plant that is used for matching the electricity demand in 
the merit order, so:

load fraction (%) = Capacity used (MW) / maximum capacity (MW)

For the plants that are cheaper than the price setting plant, the load fraction is equal to 1.
For the price setting plant this load fraction is generally lower than 1, 
since only a fraction of its maximum capacity is needed to meet the demand.
For the plants that are more expensive than the price setting plant, the load fraction is equal to 0.

#### Income

The income in EUR of a plant is calculated by summing up the (load fraction * electricity price) for each data point.

#### Total costs 

The total_costs (EUR/plant/year) of a power plant is calculated by summing up the fixed_costs and 
the variable_costs.

The calculation of these costs per plant is done in 
[ETEngine](https://github.com/quintel/etengine/blob/master/app/models/qernel/converter_api/cost.rb).

#### Fixed costs 

The fixed_costs (EUR/plant/year) of a power plant is calculated by summing up cost_of_capital, depreciation_costs and 
fixed_operation_and_maintenance_costs_per_year

The calculation of these costs per plant is done in 
[ETEngine](https://github.com/quintel/etengine/blob/master/app/models/qernel/converter_api/cost.rb).

#### Variable costs

The variable_costs (EUR/plant/year) of a power plant is calculated by summing up fuel_costs, co2_emissions_costs and 
variable_operation_and_maintenance_costs

The calculation of these costs per plant is done in 
[ETEngine](https://github.com/quintel/etengine/blob/master/app/models/qernel/converter_api/cost.rb).

#### Profit

The profit of a plant (EUR/plant/year) is calculated by subtracting the total_costs from the income of the plant.

#### Profitability

Returns one of three states:

1. Profitable (if income >= total costs)
2. Conditionally profitable (if variable costs =< income < total costs)
3. Unprofitable (if income < variable costs)

These three states are communicated to ETEngine with the terms **profitable**, 
**conditionally profitable** and **unprofitable**.
These three states are communicated to the user by coloring the participants **green**, 
**orange** and **red** respectively in the Merit Order table.

#### Diagnostic output

Developers of the ETM (not users) have the possibility to extract extra information
 from the Merit Order calculations. In particular, the following quantities are
 written to file (CSV) **for every datapoint**:

1. total demand
2. price of electricity
3. load of **each** participant

In addition, for **each participant**, the following quantities are written to (CSV) file:

1. key
2. production_capacity (MWe)
3. number_of_units
4. full_load_hours
5. availability
6. fuel_costs
7. co2_emissions_costs
8. variable_operation_and_maintenance_costs
9. fixed_operation_and_maintenance_costs_per_year
10. income
11. type (dispatchable, volatile or must_run)
12. total production (redundant but easy)

## Load profile

For each **must_run** and **volatile** participant a **normalized** load profile has to be
defined in the merit order module.

#### Definition

**CHAEL, please define it here**

#### Current Load Profiles

Currently, the following load profiles are supported

1. industry chps
2. agriculural chps
3. buildings chps
4. solar pv panels
5. offshore wind turbines
6. coastal wind turbines
7. inland wind turbines

These load profile are defined in the
[load_profiles](https://github.com/quintel/merit/tree/master/load_profiles) directory.
These curves are normalized such that the surface area underneath each curve equals unity.
This means that the load of a must_run or volatile participant at every point in time can
be found by multiplying its load profile with its **electricity production** (note that this
is not equal to its demand). 

## Assumptions

* This module just calculates yearly averages. No seasons, months, or days

## Road Map

* Currently, the load profile is expected to consist of 8_760 data points for
  the `full_load_hours` to work correctly.
* Additional features will (probably) be added, including:
  - number of times switched on/off
  - duration of on/off periods
  - ramp speeds
  - seasonal output
  - cost differentiation of plants of the same type
  - ...much more..
  - [add your ideas!](http://github.com/quintel/merit/issues/new)
* This module can import from [ETSource](http://github.com/quintel/etsource)
* User can define his own load profile, or change an existing one

## Units used

* total_demand: MJ (per year)
* full_load_hours: hours per year
* installed_capacity: MW(electric output)
* marginal_costs: EUR/MWh
* profitability: unprofitable (red), conditionally profitable (orange), profitable (green)
* variable_costs: (EUR/plant/year)
* fixed_costs: (EUR/plant/year)
* income: (EUR/plant/year)
* profit: (EUR/plant/year)
* electricity price: EUR/MWh

## Issues

Please add any issues to the list of
[issues](http://github.com/quintel/merit/issues).
