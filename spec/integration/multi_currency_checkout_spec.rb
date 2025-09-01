require 'spec_helper'
require_relative '../../lib/checkout'
require_relative '../../lib/product'
require_relative '../../lib/product_catalog'
require_relative '../../lib/rule_engine'
require_relative '../../lib/rules/quantity_discount_rule'
require_relative '../../lib/currency_converter'

RSpec.describe 'Multi-Currency Checkout' do
  let(:green_tea_gbp) { create(:product) }
  let(:green_tea_usd) { create(:product, code: 'GR2', name: 'Green tea USD', price: 4.25, currency: 'USD') }
  let(:green_tea_eur) { create(:product, code: 'GR3', name: 'Green tea EUR', price: 3.75, currency: 'EUR') }
  let(:catalog) { create(:product_catalog, products: [green_tea_gbp, green_tea_usd, green_tea_eur]) }
  let(:rule_engine) { RuleEngine.new(rules: []) }
  let(:converter) { CurrencyConverter.new }

  describe 'checkout with currency conversion' do
    let(:checkout) { create(:checkout, pricing_rules: rule_engine, catalog: catalog, currency_converter: converter) }

    it 'accepts currency converter in constructor' do
      expect(checkout).to be_a(Checkout)
    end

    it 'calculates total in checkout base currency' do
      checkout.scan('GR1') # GBP product
      checkout.scan('GR2') # USD product

      total_gbp = checkout.total_in_currency('GBP')
      expect(total_gbp).to be_a(Money)
      expect(total_gbp.currency).to eq('GBP')
    end

    it 'allows total calculation in different currencies' do
      checkout.scan('GR1') # £3.11 GBP

      total_usd = checkout.total_in_currency('USD')
      total_eur = checkout.total_in_currency('EUR')

      expect(total_usd.currency).to eq('USD')
      expect(total_eur.currency).to eq('EUR')
      expect(total_usd.amount).to be > 3.11 # USD worth less than GBP
      expect(total_eur.amount).to be > 3.11 # EUR worth less than GBP
    end

    it 'maintains backward compatibility with original total method' do
      checkout.scan('GR1')

      # Original total method should still work and return base currency
      original_total = checkout.total
      expect(original_total).to be_a(Numeric)
      expect(original_total).to eq(3.11)
    end
  end

  describe 'mixed currency cart handling' do
    let(:checkout) { create(:checkout, pricing_rules: rule_engine, catalog: catalog, currency_converter: converter, base_currency: 'GBP') }

    it 'handles products in different currencies' do
      checkout.scan('GR1') # GBP £3.11
      checkout.scan('GR2') # USD $4.25
      checkout.scan('GR3') # EUR €3.75

      total_gbp = checkout.total_in_currency('GBP')

      # Should convert all currencies to GBP and sum
      expect(total_gbp.currency).to eq('GBP')
      expect(total_gbp.amount).to be > 3.11 # Sum of converted amounts
    end

    it 'converts each product price to base currency during calculation' do
      checkout.scan('GR2') # USD $4.25

      total_gbp = checkout.total_in_currency('GBP')

      # $4.25 should convert to less than £4.25 (USD weaker than GBP)
      expect(total_gbp.amount).to be < 4.25
      expect(total_gbp.amount).to be > 2.50 # But still substantial
    end
  end

  describe 'currency-aware pricing rules' do
    let(:bogo_rule) { create(:quantity_discount_rule) }
    let(:multi_currency_engine) { RuleEngine.new(rules: [bogo_rule]) }
    let(:checkout) { create(:checkout, pricing_rules: multi_currency_engine, catalog: catalog, currency_converter: converter, base_currency: 'GBP') }

    it 'applies rules correctly across different currencies' do
      checkout.scan('GR1') # GBP £3.11
      checkout.scan('GR1') # GBP £3.11 - should trigger BOGO
      checkout.scan('GR2') # USD $4.25

      total_gbp = checkout.total_in_currency('GBP')

      # Should have: 1x GR1 (one free from BOGO) + converted USD product
      # Total should be £3.11 + converted $4.25 (about $4.25 * 0.8 = £3.40)
      expected_min = 3.11 + 2.50 # Conservative estimate for USD conversion
      expect(total_gbp.amount).to be > expected_min
    end
  end

  describe 'error handling' do
    let(:checkout) { create(:checkout, pricing_rules: rule_engine, catalog: catalog, currency_converter: converter) }

    it 'raises error for unsupported currency' do
      checkout.scan('GR1')

      expect { checkout.total_in_currency('XXX') }.to raise_error(CurrencyConverter::UnsupportedCurrencyError)
    end

    it 'handles checkout without converter gracefully' do
      no_converter_checkout = create(:checkout, pricing_rules: rule_engine, catalog: catalog)
      no_converter_checkout.scan('GR1')

      expect { no_converter_checkout.total_in_currency('USD') }.to raise_error(ArgumentError, /Currency converter not available/)
    end
  end

  describe 'currency preference inheritance' do
    let(:checkout_with_base) { create(:checkout, pricing_rules: rule_engine, catalog: catalog, currency_converter: converter, base_currency: 'EUR') }

    it 'uses specified base currency for calculations' do
      checkout_with_base.scan('GR1') # GBP product

      # Default total should be in EUR (specified base currency)
      total_money = checkout_with_base.total_money
      expect(total_money.currency).to eq('EUR')
    end

    it 'allows overriding base currency for specific calculations' do
      checkout_with_base.scan('GR1') # GBP product

      total_usd = checkout_with_base.total_in_currency('USD')
      expect(total_usd.currency).to eq('USD')
    end
  end

  describe 'currency conversion precision' do
    let(:checkout) { create(:checkout, pricing_rules: rule_engine, catalog: catalog, currency_converter: converter) }

    it 'maintains reasonable precision in currency conversions' do
      checkout.scan('GR1') # £3.11

      total_usd = checkout.total_in_currency('USD')
      total_back_to_gbp = converter.convert(total_usd, 'GBP')

      # Should be close to original after round-trip conversion
      expect(total_back_to_gbp.amount).to be_within(0.01).of(3.11)
    end
  end
end
