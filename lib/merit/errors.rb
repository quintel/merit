module Merit
  # Error class which serves as a base for all errors which occur in Merit.
  MeritError = Class.new(StandardError)

  # Internal: Creates a new error class which inherits from MeritError,
  # whose message is created by evaluating the block you give.
  #
  # For example
  #
  #   MyError = error_class do |weight, limit|
  #     "#{ weight } exceeds #{ limit }"
  #   end
  #
  #   raise MyError.new(5000, 2500)
  #   # => #<Merit::MyError: 5000 exceeds 2500>
  #
  # Returns an exception class.
  def self.error_class(superclass = MeritError, &block)
    Class.new(superclass) do
      def initialize(*args) ; super(make_message(*args)) ; end
      define_method(:make_message, &block)
    end
  end

  # Added a node to a graph, when one already exists with the same key.
  UnknownDemandError = error_class do
    "Cannot calculate if Demand is not (yet known)"
  end

  MissingLoadProfileError = error_class do |key|
    "#{key} is not known. Please add."
  end

  IncorrectLoadProfileError = error_class do |key|
    "#{key} is malformatted. It needs to contain 2190, 4380 or 8760 points."
  end

end # Merit
