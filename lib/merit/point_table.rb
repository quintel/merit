module Merit
  # Given a Merit::Order, produces a table containing load and pricing
  # information about a single point in the order.
  #
  # For example:
  #
  #   debug = PointTable.new(order)
  #
  #   # Produce a table for the first hour in the year.
  #   debug.table_for(0)
  #
  #   # Produce a table for the 2000th hour in the year.
  #   debug.table_for(2000)
  class PointTable
    def initialize(order)
      @order = order
    end

    def table_for(point)
      headings = ['', 'Key', '% Used', 'MWh Load', 'M.Cost']

      Terminal::Table.new(headings: headings) do |table|
        users(point).each(&table.method(:add_row))
        table.add_separator

        always_on(point).each(&table.method(:add_row))
        table.add_separator

        transients(point).each(&table.method(:add_row))

        table.align_column(2, :right)
        table.align_column(3, :right)
        table.align_column(4, :right)
      end
    end

    private

    def users(point)
      @order.participants.users.map do |user|
        ['U', user.key, '-', format('%.02f', user.load_at(point)), '-']
      end
    end

    def always_on(point)
      producer_rows(:always_on, point)
    end

    def transients(point)
      producer_rows(:transients, point)
    end

    def producer_rows(type, point)
      producers = @order.participants.public_send(type).sort_by do |producer|
        [ producer.max_load_curve.get(point).zero? ? 1 : 0,
          producer.cost_strategy.sortable_cost(point),
          -producer.load_curve.get(point) ]
      end

      producers.map { |producer| row(producer, point) }.compact
    end

    def row(producer, point)
      prod = producer.load_curve.get(point)
      max  = producer.max_load_curve.get(point)

      cost =
        if producer.cost_strategy.respond_to?(:cost_at_load)
          demand = producer.load_curve.get(point)
          producer.cost_strategy.cost_at_load(demand)
        else
          producer.cost_strategy.sortable_cost(point)
        end

      cap_used = max.zero? ? '-' : format('%.01f', (prod / max) * 100)

      price_setting =
        @order.price_setting_producers[point] == producer ? '* ' : ''

      [ (producer.always_on? ? 'A' : 'T'),
        producer.key,
        prod.zero? && ! max.zero? ? '0.0 %' : "#{ cap_used } %",
        format('%.02f', prod),
        format('%s%.02f', price_setting, cost) ]
    end
  end # PointTable
end # Merit
