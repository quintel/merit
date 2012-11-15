# Merit Order

This module is used to calculate the merit order for the
[Energy Transition Model](http://et-model.com).

The **merit order** predicts/calculates which electricity generating
technologies are switched on or off to meet the demand/load on the electricity
network at every **hour** in the year.

## Quick Demonstration

First, you have to initialize a new Merit Order 'session'

```Ruby
merit_order = Merit::Order.new
=> "<Merit::Order, 0 participants, demand: not set>"
```

Add the dispatchable participants to the Merit Order, by using the following 
parameters as input:
* key (string)
* marginal_costs (EUR/MWh/year) 
* effective_output_capacity (MW electric/plant)
* number_of_units (# FLOAT, not integer!)
* availability (%)
* fixed_costs (EUR/plant/year)

For example, we could add the following participant:

```Ruby
merit_order.add(
  DispatchableParticipant.new(
    key:                       :ultra_supercritical_coal,
    marginal_costs:            20.02
    effective_output_capacity: 792.0,
    number_of_units:           3.0,
    availability:              0.90,
    fixed_costs:               3_000_000
  )
)
```

Add the `must_run` and `volatile` participants. They have two additional
parameters: 

* load_profile_key
* full_load_hours

for instance:

```Ruby
merit_order.add(
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

merit_order.add(
  VolatileParticipant.new(
    key:                       :wind_offshore,
    marginal_costs:            0.0,
    effective_output_capacity: 1400,
    availability:              0.95,
    fixed_costs:               400_000,
    number_of_units:           30,
    load_profile_key:          :offshore_wind_profile,
    full_load_hours:           7_000
  )
)
```

Specify what total demand you want to calculate the merit order with (in **MJ**):

```Ruby
merit_order.total_demand = 300 * 10**9 #MJ
```

Now you have supplied the minimal amount of information to calculate output
for this situation, and you can start to ask for output, e.g.

```Ruby
merit_order.participant[:ultra_supercritical_coal].full_load_hours
=> 2000 # hours
merit_order.participant[:ultra_supercritical_coal].profit
=> 10.0 # EUR/year
merit_order.participant[:ultra_supercritical_coal].profitability
=> :profitable
```

## Input

The Merit Order needs to know about **which technologies participate** in the
merit order, what **parameters** these participants have, 
and about the **total energy demand**.

#### Total demand

Total demand must be supplied in **MJ**. It is the sum of all electricity
consumption of converters in the final demand converter group **plus** losses
of the electricity network. 

The total demand is used to scale up the **normalized** demand curve 
(i.e. the demand profile) to
produce the correct demand curve (which is a load curve).

#### Participants

This module has to be supplied with the participants of the Merit Order, which
has to be either:

* must run
* volatile
* dispatchable

#### Parameters for all participants (dispatchable, must-run and volatile)

* key (string)
* marginal_costs (EUR/MWh/year) 
* effective_output_capacity (MW electric/plant)
* number_of_units (# float)
* availability (%)
* fixed_costs (EUR/plant/year)


##### Key

With **key** the name of the participant is meant.

##### Effective output capacity

The effective output capacity is the maximum output capacity of a single plant.
That means it describes how much electricity the technology produces per second
when running at maximum load. 

For definitions of available and nominal capacities see the **Definitions** section below.

##### Marginal costs

The marginal_costs (EUR/MWh/year) are calculated by dividing the variable costs
(EUR/plant/year) of the participant by one plant's annual electricity production (in
MWh/plant). The marginal costs can be queried from the ETEngine's GQL with the
following query:

    V(converter_key, variable_costs_per(:mwh_electricity))

##### Fixed costs

The fixed costs (EUR/plant/year) can be queried from the ETM with the fixed_costs
function:

    V(converter_key, fixed_costs)

##### Number of units

A number that specifies how many of a technology are present. **This can be fractional.**

##### Availability

The availability describes which fraction of the time a technology is available for electricity
 production. The full load hours of a technology cannot exceed its availability multiplied by 8760. 
For example, if the availability is 0.95, the full_load_hours can never exceed 
0.95 * 8760 = 8322 hours.

#### Additional parameters for must_run and volatile participants

* load_profile_key
* full_load_hours

##### Load profile key

Gives the name of the profile.

##### Full load hours

The full load hours are defined as:
participant production / (effective_output_capacity * number_of_units * 3600 )

The full load hours of a **must run** or **volatile** participant are determined
by outside factors, and have to be supplied when this participant is added.

The full load hours of volatile and must-run technologies already take the 
availability of these technologies into account. 

The full load hours of a **dispatchable** participant are determined by this
module (so they are 'output').

```Ruby
merit_order.participant[:coal].full_load_hours
=> 2000.0 #hours
```

In full load hours, 'full load' means that the plant runs at its **effective** 
capacity. A plant that runs every second of the year at half load, therefore has 
full load hours = 8760 * 50% = 4380 hours (if we assume a year has exactly 8760 hours).

## Output

### For each LoadCurvePoint and Participant

* load

#### Load

Return the load (in MW) of a participating electricity generating technology. 

### For each LoadCurvePoint

* price
* demand load

#### Price

The price is equal to the `marginal_costs` of the participant that is **one higher** in the 
merit order than the price-setting participant. This reflects the assumption that a producer
will try to sell his electricity for a price that is as high as possible but still smaller 
than the cost of the participant that is next in the merit order.

This is the price of electricity at that point in time. Unit EUR/MWh

**N.B. It is to be determined what the margin is for the most expensive plant in the merit order (i.e. 
when there is no 'one higher').**

#### Demand load

The demand load is defined by the load curve for the total_demand, and is
the value of this curve at this particular point in time. Unit: MW.

### For each Participant

* full_load_hours
* total income
* total costs
* total variable cost
* profit
* profitability
* (all the input which is known, such as fixed_costs, key, etc.)

```Ruby
merit_order.participants[:coal].full_load_hours
=> 8_760 # it runs all the time!
merit_order.participants[:coal].profit
=> 1_000_000_000 EUR (annual) # it makes a billion euros!
merit_order.participants[:coal].profitability
=> :profitable # hurray, it is profitable!
```

#### Full load hours

The full load hours of a participant can be calculated by integrating the 
area under the load curve and dividing the resulting total production (in MWh)
through the effective capacity.
In practice the integration amounts to summing up the loads for each data point. 
Each data point represents 1 hour (so 8760 data points per year).

    full_load_hours = load_profile.sum / effective_output_capacity

For the participants that are cheaper than the price setting participant, the
load is equal to the **available output capacity**.  
For the price setting participant the load is generally lower than the available capacity, 
since only a fraction of its available capacity is needed to meet the demand.  
For the participants that are more expensive than the price setting participant, the load 
is equal to 0.

#### Total income

The `income` (in EUR/plant/year) of a participant is calculated by summing up the 
`load * electricity price` for each data point and dividing the result by the
`number_of_units`.

#### Total costs 

The `total_costs` (EUR/plant/year) of a power participant is calculated by
summing up the `fixed_costs` (which is input) and the `variable_costs`:

    total_costs = fixed_costs + variable_costs

#### Variable costs

The `variable_costs` (EUR/plant/year) of a participant is calculated by
multiplying the (input parameter) `marginal_costs` (EUR/MWh/year) by the
`electricity production` per plant of the participant.

    variable_costs = marginal_costs * effective_output_capacity * number_of_units * full_load_hours / number_of_units

#### Profit

The `profit` of a participant (EUR/plant/year) is calculated by subtracting the
`total_costs` from the `income` of the participant.

    profit = income - total_costs

#### Profitability

Returns one of three states:  ** THIS IS WRONG USE OPEX AND CAPEX **

1. `:profitable` (if `income >= total costs`)
2. `:conditionally_profitable` (if `variable costs =< income < total costs`)
3. `:unprofitable` (if `income < variable costs`)

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
