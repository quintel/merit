module Merit

  class BarChart

    attr_reader :values, :height, :width

    WIDTH  = 72
    HEIGHT = 16
    EMPTY  = '-'
    MARKER = 'o'

    def initialize(values, height = HEIGHT, width = WIDTH)
      @height, @width = height, width
      @values = values
    end

    # Outputs a String with line breaks that represents a Chart
    def draw
      $stdout.puts drawing; nil
    end

    def drawing
      matrix.transpose.reverse.map(&:join).join("\n")
    end

    # Holds the X and Y values for the Plot...
    def matrix
      # initialize a matrix to hold x and y values, all empty to start with
      matrix = Array.new(width+1).map { Array.new(height, EMPTY) }

      # calculated max y value
      max_y_value = reduced_values.max

      # puts a marker on the place where the value is
      reduced_values.each_with_index do |value, index|
        x_value = index

        if max_y_value.zero?
          y_value = 0
        else
          y_value = (value / max_y_value * height-1)
        end

        0.upto(y_value) do |value|
          matrix[x_value][value] = MARKER unless matrix[x_value].nil?
        end
      end

      # append each row with a tick value
      height.times do |index|
        tick_value = max_y_value / ( height - index )
        matrix[width][index] = " #{sprintf("%8.2e", tick_value)}"
      end

      matrix
    end

    # how many values do I need to average over the WIDTH?
    def step_size
      values.size / width
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
