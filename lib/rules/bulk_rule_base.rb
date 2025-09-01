require_relative 'base_rule'

class BulkRuleBase < BaseRule
  def initialize(product_code, min_quantity)
    @product_code = product_code
    @min_quantity = min_quantity
  end

  def applicable?(cart_items)
    cart_items.key?(@product_code) && !cart_items[@product_code].empty?
  end

  def apply(cart_items)
    return 0 unless applicable?(cart_items)

    items = cart_items[@product_code]
    quantity = items.length

    return 0 if quantity < @min_quantity

    calculate_discount(items, quantity)
  end

  protected

  def calculate_discount(items, quantity)
    raise NotImplementedError, "#{self.class} must implement #calculate_discount"
  end
end
