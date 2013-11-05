module Merit

  DEFAULT_AREA = :nl

  # Allows you to run the Merit Order with a different area
  #
  # Example:
  # Merit.with_area :uk do
  #   o = Merit::Order.new
  #   o.calculate
  # end
  def self.within_area(area)
    @area = area

    yield

    @area = nil
  end

  def self.area
    @area || DEFAULT_AREA
  end

end
