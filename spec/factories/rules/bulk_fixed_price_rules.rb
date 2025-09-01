FactoryBot.define do
  factory :bulk_fixed_price_rule do
    product_code { "SR1" }
    min_quantity { 3 }
    fixed_price { 4.50 }

    initialize_with { new(product_code: product_code, min_quantity: min_quantity, fixed_price: fixed_price) }
    to_create { |instance| instance }
  end
end
