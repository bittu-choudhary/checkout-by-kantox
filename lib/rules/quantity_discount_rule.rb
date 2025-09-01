require_relative 'base_rule'

class QuantityDiscountRule < BaseRule
  def initialize(product_code:, buy_quantity:, free_quantity:)
    @product_code = product_code
    @buy_quantity = buy_quantity
    @free_quantity = free_quantity
  end

  def applicable?(cart_items)
    cart_items.key?(@product_code) && !cart_items[@product_code].empty?
  end

  def apply(cart_items)
    return 0 unless applicable?(cart_items)

    items = cart_items[@product_code]
    quantity = items.length

    return 0 if quantity < (@buy_quantity + @free_quantity)

    sets = quantity / (@buy_quantity + @free_quantity)
    discount_per_set = items.first.price * @free_quantity

    sets * discount_per_set
  end
end
