FactoryBot.define do
  factory :quantity_discount_rule do
    product_code { "GR1" }
    buy_quantity { 1 }
    free_quantity { 1 }

    initialize_with { new(product_code: product_code, buy_quantity: buy_quantity, free_quantity: free_quantity) }
    to_create { |instance| instance }
  end
end