require 'spec_helper'
require_relative '../../lib/checkout'
require_relative '../../lib/product'
require_relative '../../lib/product_catalog'
require_relative '../../lib/rule_engine'
require_relative '../../lib/rules/quantity_discount_rule'

RSpec.describe 'Money Integration' do
  let(:green_tea_gbp) { create(:product) }
  let(:green_tea_usd) { create(:product, code: 'GR2', name: 'Green tea USD', price: 4.25, currency: 'USD') }
  let(:catalog) { create(:product_catalog, products: [green_tea_gbp, green_tea_usd]) }

  describe 'Money objects in products' do
    it 'creates products with Money pricing' do
      expect(green_tea_gbp.price).to be_a(Money)
      expect(green_tea_gbp.price.amount).to eq(3.11)
      expect(green_tea_gbp.price.currency).to eq('GBP')
    end

    it 'handles different currencies' do
      expect(green_tea_usd.price.currency).to eq('USD')
      expect(green_tea_usd.price.to_s).to eq('$4.25')
    end
  end

  describe 'checkout with Money' do
    let(:rule_engine) { RuleEngine.new(rules: []) }
    let(:checkout) { create(:checkout, pricing_rules: rule_engine, catalog: catalog) }

    it 'returns numeric total for backward compatibility' do
      checkout.scan('GR1')
      total = checkout.total

      expect(total).to eq(3.11)
      expect(total).to be_a(Numeric)
    end

    it 'returns Money object via total_money method' do
      checkout.scan('GR1')
      total_money = checkout.total_money

      expect(total_money).to be_a(Money)
      expect(total_money.amount).to eq(3.11)
      expect(total_money.currency).to eq('GBP')
      expect(total_money.to_s).to eq('£3.11')
    end

    it 'handles empty cart with Money' do
      expect(checkout.total).to eq(0)
      expect(checkout.total_money).to be_a(Money)
      expect(checkout.total_money.amount).to eq(0)
    end
  end

  describe 'multi-currency support' do
    it 'formats different currencies correctly' do
      gbp_money = create(:money, amount: 5.99, currency: 'GBP')
      usd_money = create(:money, amount: 7.50, currency: 'USD')
      eur_money = create(:money, amount: 8.25, currency: 'EUR')

      expect(gbp_money.to_s).to eq('£5.99')
      expect(usd_money.to_s).to eq('$7.50')
      expect(eur_money.to_s).to eq('€8.25')
    end
  end

  describe 'rule engine with Money' do
    let(:bogo_rule) { create(:quantity_discount_rule) }
    let(:rule_engine) { RuleEngine.new(rules: [bogo_rule]) }
    let(:checkout) { create(:checkout, pricing_rules: rule_engine, catalog: catalog) }

    it 'applies rules correctly with Money objects' do
      checkout.scan('GR1')
      checkout.scan('GR1')

      expect(checkout.total).to eq(3.11)  # BOGO applied

      total_money = checkout.total_money
      expect(total_money.amount).to eq(3.11)
      expect(total_money.currency).to eq('GBP')
    end
  end
end
