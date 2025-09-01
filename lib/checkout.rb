require_relative 'cart'

class Checkout
  def initialize(pricing_rules:, catalog: nil, currency_converter: nil, base_currency: 'GBP')
    @pricing_rules = pricing_rules
    @catalog = catalog
    @currency_converter = currency_converter
    @base_currency = base_currency
    @cart = Cart.new(rule_engine: pricing_rules, currency_converter: @currency_converter, base_currency: @base_currency)
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
    base_total = @cart.total
    return base_total unless @currency_converter

    # Convert total to base currency if it's not already
    if base_total.currency != @base_currency
      @currency_converter.convert(base_total, @base_currency)
    else
      base_total
    end
  end

  def total_in_currency(target_currency)
    raise ArgumentError, "Currency converter not available" unless @currency_converter

    base_total = @cart.total
    @currency_converter.convert(base_total, target_currency)
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
