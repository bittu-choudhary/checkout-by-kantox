require_relative 'cart'

class Checkout
  def initialize(pricing_rules:, catalog: nil)
    @pricing_rules = pricing_rules
    @catalog = catalog
    @cart = Cart.new(rule_engine: pricing_rules)
  end

  def scan(item)
    product = resolve_product(item)
    @cart.add(product)
  end

  def total
    result = @cart.total
    result.is_a?(Money) ? result.amount : result
  end

  def total_money
    @cart.total
  end

  private

  def resolve_product(item)
    return item if item.respond_to?(:price)

    if @catalog
      product = @catalog.find(item)
      raise ArgumentError, "Product not found: #{item}" unless product
      return product
    end

    item
  end
end
