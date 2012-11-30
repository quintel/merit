module Merit

  def self.stub

    merit_order = Merit::Order.new
    # Add 45 Converters which are examples taken from ETENgine
    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_solar_pv_solar_radiation,
        marginal_costs: 0.0,
        output_capacity_per_unit: 16.6,
        number_of_units: 0.0,
        availability: 0.98,
        fixed_costs: 4236515.36,
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
        fixed_costs: 15129166.33,
        load_profile_key: :solar_pv,
        full_load_hours: 500
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_wind_turbine_inland,
        marginal_costs: 0.0,
        output_capacity_per_unit: 3.0,
        number_of_units: 360.0,
        availability: 0.95,
        fixed_costs: 531768.45,
        load_profile_key: :wind_inland,
        full_load_hours: 2500
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_wind_turbine_coastal,
        marginal_costs: 0.0,
        output_capacity_per_unit: 3.0,
        number_of_units: 66.66666667,
        availability: 0.95,
        fixed_costs: 531768.45,
        load_profile_key: :wind_coastal,
        full_load_hours: 3000
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_wind_turbine_offshore,
        marginal_costs: 0.0,
        output_capacity_per_unit: 3.0,
        number_of_units: 64.76190476,
        availability: 0.92,
        fixed_costs: 1643536.011,
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
        fixed_costs: 2545.292412,
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
        fixed_costs: 222.9245208,
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
        fixed_costs: 2543878.235,
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
        fixed_costs: 9479267.598,
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
        fixed_costs: 4974342.555,
        load_profile_key: :industry_chp,
        full_load_hours: 4204.8
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :energy_power_supercritical_waste_mix,
        marginal_costs: 1.20608908,
        output_capacity_per_unit: 53.8932,
        number_of_units: 11.68978647,
        availability: 0.9,
        fixed_costs: 26877150,
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
        fixed_costs: 116478.4738,
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
        fixed_costs: 18359173.13,
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
        fixed_costs: 49847.77778,
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
        fixed_costs: 18359173.13,
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
        fixed_costs: 49847.77778,
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
        fixed_costs: 2453,
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
        fixed_costs: 54068.71357,
        load_profile_key: :buildings_chp,
        full_load_hours: 4000
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_space_heater_micro_chp_network_gas,
        marginal_costs: 0.0,
        output_capacity_per_unit: 0.001,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs: 933,
        load_profile_key: :buildings_chp,
        full_load_hours: 0
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_water_heater_micro_chp_network_gas,
        marginal_costs: 0.0,
        output_capacity_per_unit: 0.001,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs: 933,
        load_profile_key: :buildings_chp,
        full_load_hours: 0
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_combined_cycle_gas_power_fuelmix,
        marginal_costs: 60.33237888,
        output_capacity_per_unit: 574.9333333,
        number_of_units: 5.749536178,
        availability: 0.9,
        fixed_costs: 61526416,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_ultra_supercritical_coal,
        marginal_costs: 32.39199569,
        output_capacity_per_unit: 705.9130435,
        number_of_units: 2.365705626,
        availability: 0.88,
        fixed_costs: 111231290.8,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_ultra_supercritical_crude_oil,
        marginal_costs: 109.3782764,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs: 49359621.7,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_ultra_supercritical_lignite,
        marginal_costs: 16.60280222,
        output_capacity_per_unit: 613.8,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs: 92837254.57,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_ultra_supercritical_wood_pellets,
        marginal_costs: 139.7898305,
        output_capacity_per_unit: 66.96428571,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs: 27886950.9,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_ccs_coal,
        marginal_costs: 28.36859203,
        output_capacity_per_unit: 645.5452539,
        number_of_units: 0.0,
        availability: 0.87,
        fixed_costs: 178999174,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_ccs_gas_power_fuelmix,
        marginal_costs: 57.28270883,
        output_capacity_per_unit: 651.1186441,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs: 76566794.3,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_coal,
        marginal_costs: 23.20617439,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.322704082,
        availability: 0.9,
        fixed_costs: 157393563.3,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_gas_power_fuelmix,
        marginal_costs: 44.24374451,
        output_capacity_per_unit: 784.0,
        number_of_units: 5.104591837,
        availability: 0.9,
        fixed_costs: 61526416,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_engine_diesel,
        marginal_costs: 160.0982801,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs: 49359621.7,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_nuclear_gen2_uranium_oxide,
        marginal_costs: 6.133182844,
        output_capacity_per_unit: 1600.0,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs: 317248000,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_nuclear_gen3_uranium_oxide,
        marginal_costs: 5.826162528,
        output_capacity_per_unit: 1600.0,
        number_of_units: 0.31875,
        availability: 0.9,
        fixed_costs: 577551594.8,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_supercritical_coal,
        marginal_costs: 29.9100356,
        output_capacity_per_unit: 792.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs: 79981066.11,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_turbine_network_gas,
        marginal_costs: 78.01340618,
        output_capacity_per_unit: 147.0,
        number_of_units: 1.442176871,
        availability: 0.89,
        fixed_costs: 6634766.741,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_ccs_coal,
        marginal_costs: 34.97148374,
        output_capacity_per_unit: 625.0,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs: 137557916.7,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_coal,
        marginal_costs: 28.88180898,
        output_capacity_per_unit: 792.0,
        number_of_units: 3.391901654,
        availability: 0.88,
        fixed_costs: 111231290.8,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_crude_oil,
        marginal_costs: 93.09320787,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs: 49359621.7,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_gas_power_fuelmix,
        marginal_costs: 65.90324432,
        output_capacity_per_unit: 792.0,
        number_of_units: 4.828282828,
        availability: 0.89,
        fixed_costs: 29085600,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_lignite,
        marginal_costs: 13.999791,
        output_capacity_per_unit: 790.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs: 112037799.7,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_oxyfuel_ccs_lignite,
        marginal_costs: 19.58755889,
        output_capacity_per_unit: 640.0,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs: 240498185.1,
      )
    )

    merit_order.add(
      User.new(
        key: :total_demand,
        total_consumption: 417946498897.5582
      )
    )

    merit_order

  end

end
