# This module includes all the 
module Merit::Profitable

  # Returns the absolute amount of profit that is made
  # for the whole period.
  def revenue
    revenue_curve.reduce(:+)
  end

  # Public: Returns the amount of profit in Euros that
  # this plant is making.
  def revenue_curve
    load_curve * order.price_curve
  end

end
