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

Add the dispatchable participants to the Merit Order, by using the following 
parameters as input:
* marginal_costs (EUR/MWh/year) 
* effective_output_capacity (MW electric/plant)
* number_of_units (#)
* availability (%)
* fixed_costs (EUR/plant/year)

Now the (dispatchable) participants have certain attributes, e.g.

```Ruby
Merit::Order.add(
  DispatchableParticipant.new(
    key:                       :ultra_supercritical_coal,
    marginal_costs:            20.02
    effective_output_capacity: 792.0,
    number_of_units:           3.0,
    availability:              0.90,
    fixed_costs:               3_000_000
  )
)

Merit::Order.add(
  DispatchableParticipant.new(
    key:                       :combined_cycle_gas,
    marginal_costs:            23.00,
    effective_output_capacity: 3_000.0,
    number_of_units:           3.0,
    availability:              0.85,
    fixed_costs:               5_000_000
  )
)
```

Add the `must_run` and `volatile` participants. They have two additional
parameters: 

1. load_profile_key
2. full_load_hours

```Ruby
Merit::Order.add(
  MustRunParticipant.new(
    key:                       :industry_chp_combined_cycle_gas,
    marginal_costs:            1.00,
    effective_output_capacity: 1240.0,
    number_of_units:           2.0
    availability:              0.95,
    fixed_costs:               400_000,
    load_profile_key:          :industry_chps_profile,
    full_load_hours:           8_000
  )
)

Merit::Order.add(
  VolatileParticipant.new(
    key:                       :wind_offshore,
    marginal_costs:            0.0,
    effective_output_capacity: 1400,
    availability:              0.95,
    fixed_costs:               400000,
    number_of_units:           30,
    load_profile_key:          :offshore_wind_profile,
    full_load_hours:           7_000
  )
)
```

Specify what demand you want to calculate the merit order with (in **MJ**):

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

## Input

The Merit Order needs to know about **which technologies participate** in the
merit order, what **parameters** these participants have, 
and about the **total energy demand**.

#### Participants

This module has to be supplied with the participants of the Merit Order, which
has to be either:

* must run
* volatile
* dispatchable

#### Full load hours

The full load hours of a **must run** or **volatile** participant are determined
by outside factors, and have to be supplied when this participant is added.

The full load hours of a **dispatchable** participant are determined by this
module (so they are 'output').

```Ruby
merit_order.participant[:coal].full_load_hours
=> 2000.0 #hours
```

#### Total demand

Total demand must be supplied in **MJ**. It is the sum of all electricity
consumption of converters in the final demand converter group **plus** losses
of the electricity network. 

The total demand is used to scale up the **normalized** demand curve to it
produce the correct demand curve.

#### Marginal costs

The marginal_costs (EUR/MWh/year) are calculated by dividing the variable costs
(EUR/plant/year) of the participant by its (yearly) electricity production (in
MWh). The marginal costs can be queried from the ETEngine's GQL with the
following query:

    V(:converter_key, variable_costs_per(:mwh_electricity))

#### Fixed costs

The fixed costs (EUR/plant) can be queried from the ETM with the fixed_costs
function:

    V(:converter_key, fixed_costs)

## Output

Merit order can supply the user with the following information of the
*participants*:

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
=> :profitable # hurray, it is profitable!
```

#### Full load hours and load fraction

Return the full_load_hours of a participating electricity generating technology
in **hours**. The number of full load hours is calculated by summing up the
load_fraction for each data point.  Each data point represents 1 hour (so 8760
data points per year).  The load_fraction is the fraction of capacity of a
participant that is used for matching the electricity demand in the merit
order, so:

    load_fraction = capacity used / maximum capacity

For the participants that are cheaper than the price setting participant, the
load fraction is equal to 1.  For the price setting participant this load
fraction is generally lower than 1, since only a fraction of its maximum
capacity is needed to meet the demand.  For the participants that are more
expensive than the price setting participant, the load_fraction is equal to 0.

#### Income

The `income` (in EUR) of a participant is calculated by summing up the `load
fraction * electricity price` for each data point.

#### Total costs 

The `total_costs` (EUR/plant/year) of a power participant is calculated by
summing up the `fixed_costs` (which is input) and the `variable_costs`:

    total_costs = fixed_costs + variable_costs

#### Variable costs

The `variable_costs` (EUR/plant/year) of a participant is calculated by
multiplying the (input parameter) `marginal_costs` (EUR/MWh/year) by the
`electricity production` of the participant.

    variable_costs = marginal_costs * effective_output_capacity * number_of_units * full_load_hours

#### Profit

The `profit` of a participant (EUR/plant/year) is calculated by subtracting the
`total_costs` from the `income` of the participant.

    profit = income - total_costs

#### Profitability

Returns one of three states:

1. `:profitable` (if `income >= total costs`)
2. `:conditionally_profitable` (if `variable costs =< income < total costs`)
3. `:unprofitable` (if `income < variable costs`)

P.S. These three states are communicated to the user by coloring the
participants **green**, **orange** and **red** respectively in the Merit Order
table.

## Diagnostic output

Admin users of this module have the possibility to extract extra information
from the Merit Order calculations.

#### For every LoadCurvePoint

In particular, the following quantities are outputted **for every datapoint**:

1. total demand
2. price of electricity
3. load of **each** participant

#### For each Participant

In addition, for **each participant**, the following quantities are outputted:

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
11. type (`:dispatchable`, `:volatile` or `:must_run`)
12. total production (redundant but easy)

## Load Profile

For each **must_run** and **volatile** participant a **normalized** load
profile has to be defined in the merit order module. Also, the **total demand**
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

* marginal_costs: **EUR/MWh/year** 
* effective_output_capacity: **MW electric/plant**
* number_of_units: **#**
* availability: **fraction** (between 0 and 1)
* fixed_costs: **EUR** (per plant per year)**
* total_demand: **MJ** (per year)
* full_load_hours: **hours** (per year)
* profitability: **:symbol**
* income: **EUR** (per plant per year)
* profit: **EUR** (per plant per year)
* electricity price: **EUR/MWh**

## Issues

Please add any issues to the list of
[issues](http://github.com/quintel/merit/issues).
