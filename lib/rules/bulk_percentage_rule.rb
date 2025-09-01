require_relative 'bulk_rule_base'

class BulkPercentageRule < BulkRuleBase
  def initialize(product_code:, min_quantity:, discount_percentage:)
    super(product_code, min_quantity)
    @discount_percentage = discount_percentage
  end

  protected

  def calculate_discount(items, quantity)
    original_price = items.first.price
    discount_per_item = original_price * (@discount_percentage / 100.0)

    quantity * discount_per_item
  end
end
