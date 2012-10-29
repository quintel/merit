# Merit Order

This module is used to calculate the merit order for the
[Energy Transition Model](http://et-model.com).

The **merit order** predicts which electricity generating technology will
produce electricity when the demand/load on the electricity network has a
certain value.

## How to use it

Start a new session

```Ruby
merit_order = Merit::Order.new
=> "<Merit::Order, 6 load curves, 0 participants>"
```

Add some participants to the Merit Order

```Ruby
merit_order.add_participant(:nuclear, :must_run,     0.25, 2000)

merit_order.add_participant(:wind,    :volatile,     0.21, 5000)

merit_order.add_participant(:coal,    :dispatchable, 0.22, 3000)
merit_order.add_participant(:gas,     :dispatchable, 0.23, 4000)
```

Specify with what demand you want to calculate the merit order

```Ruby
merit_order.load_curve('total').demand = 1_000
merit_order.load_curve('industry_chps').demand = 100
merit_order.load_curve('agriculture_chps').demand = 0
merit_order.load_curve('building_chps').demand = 50
merit_order.load_curve('solar_pv').demand = 10
merit_order.load_curve('offshore_wind').demand = 200
merit_order.load_curve('coastal_wind').demand = 90
merit_order.load_curve('inland_wind').demand = 90
```

## Input

The Merit Order needs to know about **which technologies participate** in the
merit order, and about the **total energy demand** of **8 types** of
**different demands**.

#### Participants

This module has to be supplied with the participants of the Merit Order.

#### Load curves

There are eight types of load curves:

1. **total demand**
2. **industry chps**
3. **agriculural chps**
4. **buildings chps**
5. **solar pv panels**
6. **offshore wind turbines**
7. **coastal wind turbines**
8. **inland wind turbines**

This shape/distribution of the load curves are defined [here](TODO: add
location of CSV file).

The user has to supply the 'height' of these load curves, e.g.:

```Ruby
merit_order.load_curve('total').demand = 1_000
```

## Output

Merit order can supply the user with the **full load hours** and the
**profitability** of the *participants*.

```Ruby
merit_order.participants['coal'].full_load_hours
=> 8_760 # it runs all the time!
merit_order.participants['coal'].profitability
=> 1_000_000_000 # it makes a billion euros!
```

#### Full load hours

Return the full load hours or a participating electricity generating
technology.

#### Profitability

Returns the profit this type of power generator makes in Euros per year.

## Road Map

* Currently, the load curve is expected to consists of 8_760 data points for
  the `full_load_hours` to work correctly.
* More outputs will be added, especially for **partipants**.
* This module will import [ETSource](http://github.com/quintel/etsource) data.

## Issues

Please add any issues to the list of
[issues](http://github.com/quintel/merit/issues).
