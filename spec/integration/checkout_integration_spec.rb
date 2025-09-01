require 'spec_helper'
require_relative '../../lib/checkout'
require_relative '../../lib/product'
require_relative '../../lib/product_catalog'
require_relative '../../lib/rule_engine'
require_relative '../../lib/rules/quantity_discount_rule'

RSpec.describe 'Checkout Integration' do
  let(:green_tea) { create(:product) }
  let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00) }
  let(:coffee) { create(:product, code: 'CF1', name: 'Coffee', price: 11.23) }
  let(:catalog) { create(:product_catalog, products: [green_tea, strawberries, coffee]) }

  describe 'GR1 BOGO integration' do
    let(:bogo_rule) { create(:quantity_discount_rule) }
    let(:rule_engine) { RuleEngine.new(rules: [bogo_rule]) }
    let(:checkout) { create(:checkout, pricing_rules: rule_engine, catalog: catalog) }

    context 'test case: GR1,GR1 → £3.11' do
      it 'applies BOGO discount correctly' do
        checkout.scan('GR1')
        checkout.scan('GR1')

        expect(checkout.total).to eq(3.11)
      end

      it 'matches expected test case exactly' do
        checkout.scan('GR1')
        checkout.scan('GR1')

        total = checkout.total
        expect(total).to eq(3.11)
      end
    end

    context 'single GR1 item' do
      it 'charges full price for single item' do
        checkout.scan('GR1')

        expect(checkout.total).to eq(3.11)
      end
    end

    context 'three GR1 items' do
      it 'applies BOGO to pairs only' do
        checkout.scan('GR1')
        checkout.scan('GR1')
        checkout.scan('GR1')

        expected_total = 3.11 * 2  # 2 items charged (1 free)
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end
    end

    context 'mixed with other products' do
      it 'applies BOGO only to GR1 items' do
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('GR1')

        expected_total = 3.11 + 5.00  # GR1 BOGO + SR1 full price
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end
    end
  end
end
