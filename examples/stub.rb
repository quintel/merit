module Merit

  def self.stub
    require 'pathname'

    profile_dir = Pathname.new(__FILE__).dirname.dirname.join('../etsource/datasets/nl/load_profiles')
    merit_order = Merit::Order.new

    profiles = ->(name) do
      LoadProfile.load(profile_dir.join("#{ name }.csv"))
    end

    # Add 46 Converters which are examples taken from ETENgine
    merit_order.add(
      MustRunProducer.new(
        key: :agriculture_chp_engine_network_gas,
        marginal_costs: 81.34086561,
        output_capacity_per_unit: 1.01369863,
        number_of_units: 3023.581081,
        availability: 0.97,
        fixed_costs_per_unit: 116478.4738,
        fixed_om_costs_per_unit: 13062.47379,
        load_profile: profiles['agriculture_chp'],
        full_load_hours: 3980.424144
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :buildings_collective_chp_network_gas,
        marginal_costs: 97.4239366,
        output_capacity_per_unit: 0.465581395,
        number_of_units: 871.7816937,
        availability: 0.97,
        fixed_costs_per_unit: 49847.77778,
        fixed_om_costs_per_unit: 0,
        load_profile: profiles['buildings_chp'],
        full_load_hours: 3942
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :buildings_collective_chp_wood_pellets,
        marginal_costs: 155.6064849,
        output_capacity_per_unit: 47.91666667,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 18359173.13,
        fixed_om_costs_per_unit: 0,
        load_profile: profiles['buildings_chp'],
        full_load_hours: 6097.777778
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
        fixed_om_costs_per_unit: 357.75,
        load_profile: profiles['solar_pv'],
        full_load_hours: 1050
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_combined_cycle_network_gas,
        marginal_costs: 62.6637382,
        output_capacity_per_unit: 574.9333333,
        number_of_units: 5.749536178,
        availability: 0.9,
        fixed_costs_per_unit: 61526416,
        fixed_om_costs_per_unit: 9066666.667,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_ultra_supercritical_coal,
        marginal_costs: 30.67091373,
        output_capacity_per_unit: 705.9130435,
        number_of_units: 2.365705626,
        availability: 0.88,
        fixed_costs_per_unit: 111231290.8,
        fixed_om_costs_per_unit: 16000000,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_chp_ultra_supercritical_crude_oil,
        marginal_costs: 120.47066,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs_per_unit: 49359621.7,
        fixed_om_costs_per_unit: 15059622.37,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_ccs_coal,
        marginal_costs: 26.48919339,
        output_capacity_per_unit: 645.5452539,
        number_of_units: 0.0,
        availability: 0.87,
        fixed_costs_per_unit: 178999174,
        fixed_om_costs_per_unit: 21373442.62,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_ccs_network_gas,
        marginal_costs: 59.53580465,
        output_capacity_per_unit: 651.1186441,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs_per_unit: 76566794.3,
        fixed_om_costs_per_unit: 13063555.56,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_coal,
        marginal_costs: 21.36945197,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.322704082,
        availability: 0.9,
        fixed_costs_per_unit: 157393563.3,
        fixed_om_costs_per_unit: 16000000,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_combined_cycle_network_gas,
        marginal_costs: 45.95340801,
        output_capacity_per_unit: 784.0,
        number_of_units: 5.104591837,
        availability: 0.9,
        fixed_costs_per_unit: 61526416,
        fixed_om_costs_per_unit: 9066666.667,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_engine_diesel,
        marginal_costs: 102.1810615,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs_per_unit: 49359621.7,
        fixed_om_costs_per_unit: 15059622.37,
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_hydro_river,
        marginal_costs: 0.0,
        output_capacity_per_unit: 10.0,
        number_of_units: 3.7,
        availability: 0.98,
        fixed_costs_per_unit: 3000000,
        fixed_om_costs_per_unit: 320000,
        load_profile: profiles['river'],
        full_load_hours: 2702.702703
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_nuclear_gen2_uranium_oxide,
        marginal_costs: 5.803047404,
        output_capacity_per_unit: 1600.0,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs_per_unit: 317248000,
        fixed_om_costs_per_unit: 42048000,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_nuclear_gen3_uranium_oxide,
        marginal_costs: 5.532708804,
        output_capacity_per_unit: 1600.0,
        number_of_units: 0.31875,
        availability: 0.9,
        fixed_costs_per_unit: 577551594.8,
        fixed_om_costs_per_unit: 80901594.77,
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_solar_pv_solar_radiation,
        marginal_costs: 0.0,
        output_capacity_per_unit: 16.6,
        number_of_units: 0.0,
        availability: 0.98,
        fixed_costs_per_unit: 4236515.36,
        fixed_om_costs_per_unit: 477000,
        load_profile: profiles['solar_pv'],
        full_load_hours: 1050
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_supercritical_coal,
        marginal_costs: 27.59882655,
        output_capacity_per_unit: 792.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs_per_unit: 79981066.11,
        fixed_om_costs_per_unit: 19414400,
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :energy_power_supercritical_waste_mix,
        marginal_costs: 1.20608908,
        output_capacity_per_unit: 53.8932,
        number_of_units: 11.68978647,
        availability: 0.9,
        fixed_costs_per_unit: 26877150,
        fixed_om_costs_per_unit: 0,
        load_profile: profiles['industry_chp'],
        full_load_hours: 6190.47619
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_turbine_network_gas,
        marginal_costs: 81.03045942,
        output_capacity_per_unit: 147.0,
        number_of_units: 1.442176871,
        availability: 0.89,
        fixed_costs_per_unit: 6634766.741,
        fixed_om_costs_per_unit: 927202.5,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_ccs_coal,
        marginal_costs: 33.02961202,
        output_capacity_per_unit: 625.0,
        number_of_units: 0.0,
        availability: 0.85,
        fixed_costs_per_unit: 137557916.7,
        fixed_om_costs_per_unit: 15872786.89,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_coal,
        marginal_costs: 27.34719703,
        output_capacity_per_unit: 792.0,
        number_of_units: 3.391901654,
        availability: 0.88,
        fixed_costs_per_unit: 111231290.8,
        fixed_om_costs_per_unit: 16000000,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_crude_oil,
        marginal_costs: 102.1810615,
        output_capacity_per_unit: 784.0,
        number_of_units: 0.0,
        availability: 0.89,
        fixed_costs_per_unit: 49359621.7,
        fixed_om_costs_per_unit: 15059622.37,
      )
    )

    merit_order.add(
      DispatchableProducer.new(
        key: :energy_power_ultra_supercritical_network_gas,
        marginal_costs: 68.46773957,
        output_capacity_per_unit: 792.0,
        number_of_units: 4.828282828,
        availability: 0.89,
        fixed_costs_per_unit: 29085600,
        fixed_om_costs_per_unit: 1365600,
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_wind_turbine_coastal,
        marginal_costs: 0.0,
        output_capacity_per_unit: 3.0,
        number_of_units: 66.66666667,
        availability: 0.95,
        fixed_costs_per_unit: 531768.45,
        fixed_om_costs_per_unit: 147579.9,
        load_profile: profiles['wind_coastal'],
        full_load_hours: 3000
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_wind_turbine_inland,
        marginal_costs: 0.0,
        output_capacity_per_unit: 3.0,
        number_of_units: 360.0,
        availability: 0.95,
        fixed_costs_per_unit: 531768.45,
        fixed_om_costs_per_unit: 147579.9,
        load_profile: profiles['wind_inland'],
        full_load_hours: 2500
      )
    )

    merit_order.add(
      VolatileProducer.new(
        key: :energy_power_wind_turbine_offshore,
        marginal_costs: 0.0,
        output_capacity_per_unit: 3.0,
        number_of_units: 64.76190476,
        availability: 0.92,
        fixed_costs_per_unit: 1643536.011,
        fixed_om_costs_per_unit: 428882.8856,
        load_profile: profiles['wind_offshore'],
        full_load_hours: 3500
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_collective_chp_network_gas,
        marginal_costs: 88.82106511,
        output_capacity_per_unit: 0.606666667,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 49847.77778,
        fixed_om_costs_per_unit: 0,
        load_profile: profiles['buildings_chp'],
        full_load_hours: 3942
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_collective_chp_wood_pellets,
        marginal_costs: 121.0840194,
        output_capacity_per_unit: 58.33333333,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 18359173.13,
        fixed_om_costs_per_unit: 0,
        load_profile: profiles['buildings_chp'],
        full_load_hours: 6097.777778
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
        fixed_om_costs_per_unit: 35.775,
        load_profile: profiles['solar_pv'],
        full_load_hours: 1050
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_space_heater_micro_chp_network_gas,
        marginal_costs: 155.5224722,
        output_capacity_per_unit: 0.001,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 933,
        fixed_om_costs_per_unit: 110,
        load_profile: profiles['buildings_chp'],
        full_load_hours: 0
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_water_heater_fuel_cell_chp_network_gas,
        marginal_costs: 44.06470046,
        output_capacity_per_unit: 0.0015,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 2453,
        fixed_om_costs_per_unit: 200,
        load_profile: profiles['buildings_chp'],
        full_load_hours: 0
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :households_water_heater_micro_chp_network_gas,
        marginal_costs: 155.5224722,
        output_capacity_per_unit: 0.001,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 933,
        fixed_om_costs_per_unit: 110,
        load_profile: profiles['buildings_chp'],
        full_load_hours: 0
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :industry_chp_combined_cycle_gas_power_fuelmix,
        marginal_costs: 114.9119535,
        output_capacity_per_unit: 25.43252595,
        number_of_units: 122.0877551,
        availability: 0.97,
        fixed_costs_per_unit: 2543878.235,
        fixed_om_costs_per_unit: 0,
        load_profile: profiles['industry_chp'],
        full_load_hours: 5442.834138
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :industry_chp_supercritical_wood_pellets,
        marginal_costs: 141.4474576,
        output_capacity_per_unit: 32.5203252,
        number_of_units: 10.54725,
        availability: 0.97,
        fixed_costs_per_unit: 9479267.598,
        fixed_om_costs_per_unit: 2913267.598,
        load_profile: profiles['industry_chp'],
        full_load_hours: 5247.813411
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :industry_chp_ultra_supercritical_coal,
        marginal_costs: 29.89556251,
        output_capacity_per_unit: 11.57407407,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 4974342.555,
        fixed_om_costs_per_unit: 1301009.555,
        load_profile: profiles['industry_chp'],
        full_load_hours: 4204.8
      )
    )

    merit_order.add(
      MustRunProducer.new(
        key: :other_chp_engine_network_gas,
        marginal_costs: 81.4031521,
        output_capacity_per_unit: 0.467669373,
        number_of_units: 0.0,
        availability: 0.97,
        fixed_costs_per_unit: 54068.71357,
        fixed_om_costs_per_unit: 6056.838239,
        load_profile: profiles['buildings_chp'],
        full_load_hours: 4000
      )
    )

    merit_order.add(
      User.create(
        key: :total_demand,
        load_profile: profiles['total_demand'],
        total_consumption: 417946498897.5582
      )
    )

    merit_order

  end

end
