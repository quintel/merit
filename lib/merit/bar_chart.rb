module Merit

  class BarChart

    attr_reader :values

    WIDTH  = 72
    HEIGHT = 16
    EMPTY  = '-'
    MARKER = 'o'

    def initialize(values)
      @values = values
    end

    # Outputs a String with line breaks that represents a Chart
    def draw
      puts matrix.transpose.reverse.map(&:join).join("\n")
      nil
    end

    # Holds the X and Y values for the Plot...
    def matrix
      # initialize a matrix to hold x and y values, all empty to start with
      matrix = Array.new(WIDTH+1).map { Array.new(HEIGHT, EMPTY) }

      # calculated max y value
      max_y_value = reduced_values.max

      # puts a marker on the place where the value is
      reduced_values.each_with_index do |value, index|
        x_value = index
        y_value = value / max_y_value * HEIGHT - 1
        matrix[x_value][y_value] = MARKER unless matrix[x_value].nil?
      end

      # append each row with a tick value
      HEIGHT.times do |index|
        matrix[WIDTH][index] = " #{(max_y_value/(HEIGHT-index)).round(2)}"
      end

      matrix
    end

    # how many values do I need to average over the WIDTH?
    def step_size
      values.size / WIDTH
    end

    # scale values horizontally (take averages)
    def reduced_values
      reduced_values = []

      values.each_slice(step_size) do |slice|
        reduced_values << slice.inject(:+).to_f / slice.size
      end

      reduced_values
    end

  end

end
