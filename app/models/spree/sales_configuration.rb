class Spree::SalesConfiguration < Spree::Preferences::Configuration
  attr_accessor :calculators

  def initialize
    @calculators = []
  end
end
