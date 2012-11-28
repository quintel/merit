module Merit::Profitable

  def revenue
    revenue_curve.reduce(:+)
  end

  # Public: Returns the amount of profit in Euros that
  # this plant is making at point in time

  def revenue_curve
    load_curve * order.price_curve
  end

end
