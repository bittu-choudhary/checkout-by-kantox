require_relative 'cart'

class Checkout
  def initialize(pricing_rules)
    @pricing_rules = pricing_rules
    @cart = Cart.new
  end

  def scan(product)
    @cart.add(product)
  end

  def total
    @cart.total
  end
end
