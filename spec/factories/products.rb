FactoryBot.define do
  factory :product do
    code { "GR1" }
    name { "Green tea" }
    price { 3.11 }
    currency { "GBP" }
    units { 50 }


    initialize_with { new(code: code, name: name, price: price, currency: currency, units: units) }
    to_create { |instance| instance }
  end
end
