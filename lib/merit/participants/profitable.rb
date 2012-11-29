# This module includes all the 
module Merit::Profitable

  # Public: Returns the absolute amount of revenue.
  def revenue
    revenue_curve.reduce(:+)
  end

  # Public: Returns a Curve with the revenue per point in time.
  def revenue_curve
    load_curve * order.price_curve
  end

end
