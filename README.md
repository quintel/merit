# Merit Order

This module is used to calculate the merit order for the
[Energy Transition Model](http://et-model.com).

The **merit order** predicts/calculates which electricity generating
technologies will produce electricity when the demand/load on the electricity
network has a certain value.

## Quick Demonstration

First, you have to initialize a new Merit Order 'session'

```Ruby
merit_order = Merit::Order.new
=> "<Merit::Order, 0 participants>"
```

Add the dispatchable participants to the Merit Order, with its *marginal costs*
in EUR / KWh and *the installed capacity* (in MW electric)

```Ruby
merit_order.add_participant(:nuclear, :dispatchable, 0.05, 800)
merit_order.add_participant(:coal,    :dispatchable, 0.12, 2000)
merit_order.add_participant(:gas,     :dispatchable, 0.15, 3000)
```

Add the `must_run` and `volatile` participants with their full load
hours (8000 in this case) to the Merit Order

```Ruby
merit_order.add_participant(:industry_chp:, :must_run, 1.23, 1200, 8000)
```

Specify with what demand you want to calculate the merit order

```Ruby
merit_order.total_demand = 300 * 10**9 #MJ
```

Now you have supplied the minimal amount of information to calculate output
for this situation, and you can start to ask for this output, e.g.

```Ruby
merit_order.participant[:coal].full_load_hours
=> 2000 # hours
merit_order.participant[:coal].profitability
=> 0.30 # EUR/kWh
```

## Input

The Merit Order needs to know about **which technologies participate** in the
merit order, and about the **total energy demand**.

#### Participants

This module has to be supplied with the participants of the Merit Order, which
has to be either:

* must run
* volatile
* dispatchable

The full load hours of a **must run** or **volatile** participant is determined
by outside factors, and thus has to be supplied when this participant is added.

For example, 8000 hours for the industry chps:

```Ruby
merit_order.add_participant(:industry_chp:, :must_run    , 1.23, 1200, 8000)
```

The full load hours of a **dispatchable** participant is determined by this
module.

```Ruby
merit_order.participant[:coal].full_load_hours
=> 2000 #hours
```

#### Total demand

Total demand must be supplied in **MJ**.

## Output

Merit order can supply the user with the **full load hours** and the
**profitability** of the *participants*:

```Ruby
merit_order.participants[:coal].full_load_hours
=> 8_760 # it runs all the time!
merit_order.participants[:coal].profitability
=> 1_000_000_000 # it makes a billion euros!
```

#### Full load hours

Return the full load hours or a participating electricity generating
technology in **hours**.

#### Profitability

Returns the profit this type of power generator makes in EUROS per **kWh**

## Load curves

For each **must_run** and **volatile** participant a load curve has to be
defined in the merit order.

Currently, the following load curves are supported

1. industry chps
2. agriculural chps
3. buildings chps
4. solar pv panels
5. offshore wind turbines
6. coastal wind turbines
7. inland wind turbines

These load curves are defined in
[merit_order.csv](http://github.com/merit/data/merit_order.csv).

## Road Map

* Currently, the load curve is expected to consists of 8_760 data points for
  the `full_load_hours` to work correctly.
* Additional features will (probably) be added, including:
  - number of times switched on/off
  - duration of intermittence
  - ramp speeds
  - ...much more..
  - [add your ideas!](http://github.com/quintel/merit/issues/new)
* Seasonal output
* This module can import from [ETSource](http://github.com/quintel/etsource)
* User can define its own load curve, or change an existing one

## Units used

* full_load_hours: hours per year
* installed_capacity: MW(electric output)
* marginal_costs: EUR/kWh
* profitability: EUR/kWh

## Issues

Please add any issues to the list of
[issues](http://github.com/quintel/merit/issues).
