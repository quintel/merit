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
The marginal costs per plant are calculated by normalizing the variable costs of the plant by the amount of MWh it has produced.

```Ruby
merit_order.add_dispatchable(:nuclear_gen3,             50.0, 800, 0.95)
merit_order.add_dispatchable(:ultra_supercritical_coal, 48.0, 2000, 0.90)
merit_order.add_dispatchable(:combined_cycle_gas,       60.0, 3000, 0.85)
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
=> 10.0 # EUR (annual)
merit_order.participant[:ultra_supercritical_coal].profitability
=> "profitable"
```

The electricity price is an outcome of the merit order calculation, and is determined to be:
Marginal costs of the plant that comes next to the price setting plant (EUR/MWh)

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
2. income
3. total costs (fixed costs + variable costs)
4. fixed costs (cost of capital + depreciation costs + fixed O&M costs)
5. variable costs (fuel costs + CO2-emissions costs + variable O&M costs)
6. profitability (green, orange or red)
7. profit (EUR)
8. load fraction

```Ruby
merit_order.participants[:coal].full_load_hours
=> 8_760 # it runs all the time!
merit_order.participants[:coal].profit
=> 1_000_000_000 EUR (annual) # it makes a billion euros!
merit_order.participants[:coal].profitability
=> "profitable" # hurray, it is profitable!
```
This information is shown in a table. 

#### Full load hours

Return the full load hours of a participating electricity generating
technology in **hours**.

#### Income and load fraction

The income of a plant is calculated by summing up the (load fraction * electricity price) for each data point.
Each data point represents 1 hour (so 8760 data points per year).
The load fraction is the fraction of capacity of a plant that is used for matching the total electricity demand, so:

load fraction = Capacity used (MW) / maximum capacity (MW)

For the price setting plant this load fraction is probably lower than 1.

#### Total costs, fixed costs and variable costs

The calculation of these costs per plant (annually) is done in ETEngine
[ETEngine](https://github.com/quintel/etengine/blob/master/app/models/qernel/converter_api/cost.rb) .

Needed input for these calculations:
* WACC
* construction time
* technical lifetime 
* depreciation costs
* total investment over lifetime
* residual value
* fixed O&M costs (EUR/FLH) (annual)
* variable O&M costs (EUR/FLH)
* fuel used (MJ)
* fuel price (EUR/MJ)
* CO2 emissions costs
* % free CO2 credits
* % ETS (which part of the plant is restricted by the ETS)
* % CO2 emissions with no costs

#### Profitability

Returns one of three states:

1. Profitable (if income >= total costs)
2. Conditionally profitable (if variable costs =< income < total costs)
3. Unprofitable (if income < variable costs)

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
7. CO2-emissions_costs
8. variable_O&M_costs
9. fixed_costs
10. income
11. type (dispatchable, volatile or must_run)
12. total production (redundant but easy)

## Load profile

For each **must_run** and **volatile** participant a **normalized** load profile has to be
defined in the merit order module.

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
* profitability: not profitable (red), conditionally profitable (orange), profitable (green)
* variable costs: EUR (annual)
* fixed costs: EUR (annual)
* income: EUR (annual)
* profit: EUR (annual)
* electricity price: EUR/MWh
* 

## Issues

Please add any issues to the list of
[issues](http://github.com/quintel/merit/issues).
