require 'csv'

class CSVWriter

  attr_reader :values

  def initialize(values)
    @values = values
  end

  def write!(file_name = 'output.csv')
    file_path = File.join(Merit.root, 'output', file_name)

    CSV.open(file_path, 'w') do |csv|
      values.each{ |value| csv << value }
    end
  end

end
