FactoryBot.define do
  factory :product_catalog do
    transient do
      products { [] }
    end

    initialize_with { new(products: products) }
    to_create { |instance| instance }

    trait :with_products do
      products { [build(:product)] }
    end

    trait :with_multiple_products do
      products { [build(:product, code: "GR1"), build(:product, code: "SR1", name: "Strawberries", price: 5.00)] }
    end
  end
end
