Spree::Price.class_eval do
  has_many :sale_prices
  has_many :active_sale_prices, -> { active }, class_name: "Spree::SalePrice"

  def put_on_sale(value, params = {})
    new_sale(value, params).save
  end

  def new_sale(value, params = {})
    sale_price = sale_prices.new

    sale_price.value      = value
    sale_price.calculator = params[:calculator] ? params[:calculator].constantize.new : Spree::Calculator::AmountSalePriceCalculator.new
    sale_price.start_at   = params[:start_at] || Time.now
    sale_price.end_at     = params[:end_at]   || nil
    sale_price.enabled    = params[:enabled]  || true

    sale_price
  end

  # TODO make update_sale method

  def active_sale
    on_sale? ? first_sale(sale_prices.active) : nil
  end
  alias :current_sale :active_sale

  def next_active_sale
    sale_prices.present? ? first_sale(sale_prices) : nil
  end
  alias :next_current_sale :next_active_sale

  def sale_price
    on_sale? ? active_sale.new_amount : nil
  end

  def sale_price=(value)
    on_sale? ? active_sale.update_attribute(:value, value) : put_on_sale(value)
  end

  def discount_percent
    on_sale? ? (1 - (sale_price / original_price)) * 100 : 0.0
  end

  def on_sale?
    sale_prices.active.present? && first_sale(sale_prices.active).value != original_price
  end

  def original_price
    self[:amount]
  end

  def original_price=(value)
    self.price = value
  end

  def price
    on_sale? ? sale_price : original_price
  end

  def amount
    price
  end

  def enable_sale
    return nil unless next_active_sale.present?
    next_active_sale.enable
  end

  def disable_sale
    return nil unless active_sale.present?
    active_sale.disable
  end

  def start_sale(end_time = nil)
    return nil unless next_active_sale.present?
    next_active_sale.start(end_time)
  end

  def stop_sale
    return nil unless active_sale.present?
    active_sale.stop
  end

  private
    def first_sale(scope)
      scope.order("created_at DESC").first
    end
end
