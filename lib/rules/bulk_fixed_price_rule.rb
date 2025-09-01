require_relative 'base_rule'

class BulkFixedPriceRule < BaseRule
  def initialize(product_code:, min_quantity:, fixed_price:)
    @product_code = product_code
    @min_quantity = min_quantity
    @fixed_price = fixed_price
  end

  def applicable?(cart_items)
    cart_items.key?(@product_code) && !cart_items[@product_code].empty?
  end

  def apply(cart_items)
    return 0 unless applicable?(cart_items)

    items = cart_items[@product_code]
    quantity = items.length

    return 0 if quantity < @min_quantity

    original_price = items.first.price
    savings_per_item = original_price - @fixed_price

    quantity * savings_per_item
  end
end
