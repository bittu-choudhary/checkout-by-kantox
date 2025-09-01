FactoryBot.define do
  factory :checkout do
    transient do
      pricing_rules { [] }
      catalog { nil }
      currency_converter { nil }
      base_currency { 'GBP' }
      inventory { Inventory.new }
      metrics_collector { MetricsCollector.new }
    end

    initialize_with { new(pricing_rules: pricing_rules, catalog: catalog, currency_converter: currency_converter, base_currency: base_currency, inventory: inventory, metrics_collector: metrics_collector) }
    to_create { |instance| instance }

    trait :with_catalog do
      catalog { build(:product_catalog, :with_products) }
    end

    trait :with_multiple_products_catalog do
      catalog { build(:product_catalog, :with_multiple_products) }
    end

    trait :with_pricing_rules do
      pricing_rules { [{ type: 'buy_one_get_one', product_code: 'GR1' }] }
    end
  end
end
