module Merit

  def self.stub

    merit_order = Merit::Order.new
    # Add 45 Converters which are examples taken from ETENgine
    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_solar_pv_solar_radiation,
        marginal_costs: 0.0,
        output_capacity_per_unit: 16.6,
        number_of_units: 2163.2,
        availability: 0.98,
        fixed_costs_per_unit: 4236515.36,
        load_profile_key: :solar_pv,
        full_load_hours: 1050
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_solar_csp_solar_radiation,
        marginal_costs: 1.0,
        output_capacity_per_unit: 50.0,
        number_of_units: 0.0,
        availability: 0.99,
        fixed_costs_per_unit: 15129166.33,
        load_profile_key: :solar_pv,
        full_load_hours: 500
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_wind_turbine_inland,
        marginal_costs: 0.0,
        output_capacity_per_unit: 3.0,
        number_of_units: 6321.7,
        availability: 0.95,
        fixed_costs_per_unit: 531768.45,
        load_profile_key: :wind_inland,
        full_load_hours: 2500
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_wind_turbine_coastal,
        marginal_costs: 0.0,
        output_capacity_per_unit: 3.0,
        number_of_units: 313.2,
        availability: 0.95,
        fixed_costs_per_unit: 531768.45,
        load_profile_key: :wind_coastal,
        full_load_hours: 3000
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_wind_turbine_offshore,
        marginal_costs: 0.0,
        output_capacity_per_unit: 3.0,
        number_of_units: 3555.6,
        availability: 0.92,
        fixed_costs_per_unit: 1643536.011,
        load_profile_key: :wind_offshore,
        full_load_hours: 3500
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :buildings_solar_pv_solar_radiation,
        marginal_costs: 0.0,
        output_capacity_per_unit: 0.01245,
        number_of_units: 2547.332186,
        availability: 0.98,
        fixed_costs_per_unit: 2545.292412,
        load_profile_key: :solar_pv,
        full_load_hours: 1050
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :households_solar_pv_solar_radiation,
        marginal_costs: 0.0,
        output_capacity_per_unit: 0.001245,
        number_of_units: 51023.14018,
        availability: 0.98,
        fixed_costs_per_unit: 222.9245208,
        load_profile_key: :solar_pv,
        full_load_hours: 1050
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :industry_chp_combined_cycle_gas_power_fuelmix,
        marginal_costs: 109.5210516,
        output_capacity_per_unit: 25.43252595,
        number_of_units: 122.0877551,
        availability: 0.97,
        fixed_costs_per_unit: 2543878.235,
        load_profile_key: :industry_chp,
        full_load_hours: 5442.834138
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :industry_chp_supercritical_wood_pellets,
        marginal_costs: 139.7898305,
        output_capacity_per_unit: 32.5203252,
        number_of_units: 10.54725,
        availability: 0.97,
        fixed_costs_per_unit: 9479267.598,
        load_profile_key: :industry_chp,
        full_load_hours: 5247.813411
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :industry_chp_ultra_supercritical_coal,
        marginal_costs: 32.15521115,
        output_capacity_per_unit: 11.57407407,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 4974342.555,
        load_profile_key: :industry_chp,
        full_load_hours: 4204.8
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :energy_power_supercritical_waste_mix,
        marginal_costs: 1.20608908,
        output_capacity_per_unit: 53.8932,
        number_of_units: 15.3,
        availability: 0.9,
        fixed_costs_per_unit: 26877150,
        load_profile_key: :industry_chp,
        full_load_hours: 6190.47619
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :agriculture_chp_engine_gas_power_fuelmix,
        marginal_costs: 78.31972973,
        output_capacity_per_unit: 1.01369863,
        number_of_units: 3023.581081,
        availability: 0.97,
        fixed_costs_per_unit: 116478.4738,
        load_profile_key: :agriculture_chp,
        full_load_hours: 3980.424144
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :buildings_collective_chp_wood_pellets,
        marginal_costs: 154.16507,
        output_capacity_per_unit: 47.91666667,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 18359173.13,
        load_profile_key: :buildings_chp,
        full_load_hours: 6097.777778
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :buildings_collective_chp_gas_power_fuelmix,
        marginal_costs: 94.03660242,
        output_capacity_per_unit: 0.465581395,
        number_of_units: 871.7816937,
        availability: 0.97,
        fixed_costs_per_unit: 49847.77778,
        load_profile_key: :buildings_chp,
        full_load_hours: 3942
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_collective_chp_wood_pellets,
        marginal_costs: 119.9789346,
        output_capacity_per_unit: 58.33333333,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 18359173.13,
        load_profile_key: :buildings_chp,
        full_load_hours: 6097.777778
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_collective_chp_network_gas,
        marginal_costs: 13.2815786,
        output_capacity_per_unit: 0.606666667,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 49847.77778,
        load_profile_key: :buildings_chp,
        full_load_hours: 3942
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_water_heater_fuel_cell_chp_network_gas,
        marginal_costs: 0.0,
        output_capacity_per_unit: 0.0015,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 2453,
        load_profile_key: :buildings_chp,
        full_load_hours: 0
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :other_chp_engine_gas_power_fuelmix,
        marginal_costs: 78.38201622,
        output_capacity_per_unit: 0.467669373,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 54068.71357,
        load_profile_key: :buildings_chp,
        full_load_hours: 4000
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_space_heater_micro_chp_network_gas,
        marginal_costs: 0.0,
        output_capacity_per_unit: 0.001,
        number_of_units: 2653986.11,
        availability: 0.97,
        fixed_costs_per_unit: 933,
        load_profile_key: :buildings_chp,
        full_load_hours: 2172.843281
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_water_heater_micro_chp_network_gas,
        marginal_costs: 0.0,
        output_capacity_per_unit: 0.001,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 933,
        load_profile_key: :buildings_chp,
        full_load_hours: 0
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_combined_cycle_gas_power_fuelmix,
        marginal_costs: 60.33237907,
        output_capacity_per_unit: 574.9333333,
        number_of_units: 5.749536178,
        availability: 0.9,
        fixed_costs_per_unit: 61526416,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_ultra_supercritical_coal,
        marginal_costs: 32.39205592,
        output_capacity_per_unit: 705.9130435,
        number_of_units: 2.365705626,
        availability: 0.88,
        fixed_costs_per_unit: 111231290.8,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_ultra_supercritical_crude_oil,
        marginal_costs: 109.3782764,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs_per_unit: 49359621.7,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_ultra_supercritical_lignite,
        marginal_costs: 16.60280222,
        output_capacity_per_unit: 613.8,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 92837254.57,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_ccs_coal,
        marginal_costs: 28.36860309,
        output_capacity_per_unit: 645.5452539,
        number_of_units: 0.0,
        availability: 0.87,
        fixed_costs_per_unit: 178999174,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_ccs_gas_power_fuelmix,
        marginal_costs: 57.28270885,
        output_capacity_per_unit: 651.1186441,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs_per_unit: 76566794.3,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_coal,
        marginal_costs: 23.20623514,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.322704082,
        availability: 0.9,
        fixed_costs_per_unit: 157393563.3,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_gas_power_fuelmix,
        marginal_costs: 44.24374465,
        output_capacity_per_unit: 784.0,
        number_of_units: 5.104591837,
        availability: 0.9,
        fixed_costs_per_unit: 61526416,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_engine_diesel,
        marginal_costs: 160.0982801,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs_per_unit: 49359621.7,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_nuclear_gen2_uranium_oxide,
        marginal_costs: 6.133182844,
        output_capacity_per_unit: 1600.0,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs_per_unit: 317248000,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_nuclear_gen3_uranium_oxide,
        marginal_costs: 5.826162528,
        output_capacity_per_unit: 1600.0,
        number_of_units: 0.31875,
        availability: 0.9,
        fixed_costs_per_unit: 577551594.8,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_supercritical_coal,
        marginal_costs: 29.91011205,
        output_capacity_per_unit: 792.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs_per_unit: 79981066.11,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_turbine_network_gas,
        marginal_costs: 78.01340644,
        output_capacity_per_unit: 147.0,
        number_of_units: 1.442176871,
        availability: 0.89,
        fixed_costs_per_unit: 6634766.741,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_ccs_coal,
        marginal_costs: 34.97149518,
        output_capacity_per_unit: 625.0,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs_per_unit: 137557916.7,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_coal,
        marginal_costs: 28.88186268,
        output_capacity_per_unit: 792.0,
        number_of_units: 3.391901654,
        availability: 0.88,
        fixed_costs_per_unit: 111231290.8,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_crude_oil,
        marginal_costs: 93.09320787,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs_per_unit: 49359621.7,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_gas_power_fuelmix,
        marginal_costs: 65.90324453,
        output_capacity_per_unit: 792.0,
        number_of_units: 4.828282828,
        availability: 0.89,
        fixed_costs_per_unit: 29085600,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_lignite,
        marginal_costs: 13.999791,
        output_capacity_per_unit: 790.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs_per_unit: 112037799.7,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_oxyfuel_ccs_lignite,
        marginal_costs: 19.58755889,
        output_capacity_per_unit: 640.0,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs_per_unit: 240498185.1,
      )
    )



    merit_order.add(
      User.new(
        key: :total_demand,
        total_consumption: 416825986429.6511
      )
    )

    merit_order

  end

end

# for easy console access
@s = Merit.stub

# calculate the merit order right away (use @s.recalculate! when you want to to
# recalculate later)
@s.calculate
