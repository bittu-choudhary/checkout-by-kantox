FactoryBot.define do
  factory :money do
    amount { 10.50 }
    currency { "GBP" }

    initialize_with { new(amount: amount, currency: currency) }
    to_create { |instance| instance }

    trait :usd do
      currency { "USD" }
    end

    trait :eur do
      currency { "EUR" }
    end
  end
end
