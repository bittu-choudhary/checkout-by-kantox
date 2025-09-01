FactoryBot.define do
  factory :bulk_percentage_rule do
    product_code { "CF1" }
    min_quantity { 3 }
    discount_percentage { 33.33 }

    initialize_with { new(product_code: product_code, min_quantity: min_quantity, discount_percentage: discount_percentage) }
    to_create { |instance| instance }
  end
end
