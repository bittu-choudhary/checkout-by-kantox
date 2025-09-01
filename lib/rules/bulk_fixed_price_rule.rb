require_relative 'bulk_rule_base'

class BulkFixedPriceRule < BulkRuleBase
  def initialize(product_code:, min_quantity:, fixed_price:)
    super(product_code, min_quantity)
    @fixed_price = fixed_price
  end

  protected

  def calculate_discount(items, quantity)
    original_price = items.first.price
    savings_per_item = original_price - @fixed_price

    quantity * savings_per_item
  end
end
