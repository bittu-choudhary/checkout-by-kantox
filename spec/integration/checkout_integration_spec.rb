require 'spec_helper'
require_relative '../../lib/checkout'
require_relative '../../lib/product'
require_relative '../../lib/product_catalog'
require_relative '../../lib/rule_engine'
require_relative '../../lib/rules/quantity_discount_rule'
require_relative '../../lib/rules/bulk_fixed_price_rule'
require_relative '../../lib/rules/bulk_percentage_rule'

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

  describe 'SR1 bulk pricing integration' do
    let(:bulk_rule) { create(:bulk_fixed_price_rule) }
    let(:rule_engine) { RuleEngine.new(rules: [bulk_rule]) }
    let(:checkout) { create(:checkout, pricing_rules: rule_engine, catalog: catalog) }

    context 'test case: SR1,SR1,GR1,SR1 → £16.61' do
      it 'applies bulk discount to SR1 items only' do
        checkout.scan('SR1')
        checkout.scan('SR1')
        checkout.scan('GR1')
        checkout.scan('SR1')

        # 3 SR1 at £4.50 each = £13.50 + 1 GR1 at £3.11 = £16.61
        expect(checkout.total).to be_within(0.01).of(16.61)
      end

      it 'matches expected test case exactly' do
        checkout.scan('SR1')
        checkout.scan('SR1')
        checkout.scan('GR1')
        checkout.scan('SR1')

        total = checkout.total
        expect(total).to be_within(0.01).of(16.61)
      end
    end

    context 'below threshold' do
      it 'charges full price for 1 SR1' do
        checkout.scan('SR1')

        expect(checkout.total).to eq(5.00)
      end

      it 'charges full price for 2 SR1' do
        checkout.scan('SR1')
        checkout.scan('SR1')

        expect(checkout.total).to eq(10.00)
      end
    end

    context 'at threshold' do
      it 'applies bulk discount for 3 SR1' do
        checkout.scan('SR1')
        checkout.scan('SR1')
        checkout.scan('SR1')

        expected_total = 4.50 * 3  # £13.50
        expect(checkout.total).to eq(expected_total)
      end
    end

    context 'above threshold' do
      it 'applies bulk discount for 4 SR1' do
        checkout.scan('SR1')
        checkout.scan('SR1')
        checkout.scan('SR1')
        checkout.scan('SR1')

        expected_total = 4.50 * 4  # £18.00
        expect(checkout.total).to eq(expected_total)
      end
    end

    context 'mixed with other products' do
      it 'applies bulk discount only to SR1 items' do
        checkout.scan('SR1')
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('SR1')

        # 3 SR1 at £4.50 + 1 GR1 at £3.11 + 1 CF1 at £11.23
        expected_total = (4.50 * 3) + 3.11 + 11.23  # £27.84
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end
    end
  end

  describe 'CF1 bulk percentage discount integration' do
    let(:percentage_rule) { create(:bulk_percentage_rule) }
    let(:rule_engine) { RuleEngine.new(rules: [percentage_rule]) }
    let(:checkout) { create(:checkout, pricing_rules: rule_engine, catalog: catalog) }

    context 'test case: GR1,CF1,SR1,CF1,CF1 → £30.57' do
      it 'applies percentage discount to CF1 items only' do
        checkout.scan('GR1')
        checkout.scan('CF1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('CF1')

        # 1 GR1 at £3.11 + 1 SR1 at £5.00 + 3 CF1 at 2/3 price (£7.49 each) = £30.57
        expected_total = 3.11 + 5.00 + (3 * 7.49)  # £30.57
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end

      it 'matches expected test case exactly' do
        checkout.scan('GR1')
        checkout.scan('CF1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('CF1')

        total = checkout.total
        expect(total).to be_within(0.01).of(30.57)
      end
    end

    context 'below threshold' do
      it 'charges full price for 1 CF1' do
        checkout.scan('CF1')

        expect(checkout.total).to eq(11.23)
      end

      it 'charges full price for 2 CF1' do
        checkout.scan('CF1')
        checkout.scan('CF1')

        expected_total = 11.23 * 2
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end
    end

    context 'at threshold' do
      it 'applies percentage discount for 3 CF1' do
        checkout.scan('CF1')
        checkout.scan('CF1')
        checkout.scan('CF1')

        # 3 CF1 at 2/3 price: £11.23 * 2/3 = £7.49 each
        expected_total = 3 * 7.49  # £22.46 (with rounding)
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end

      it 'calculates 2/3 price correctly' do
        checkout.scan('CF1')
        checkout.scan('CF1')
        checkout.scan('CF1')

        # Each coffee should cost £7.49 (2/3 of £11.23)
        total = checkout.total
        price_per_coffee = total / 3
        expect(price_per_coffee).to be_within(0.01).of(7.49)
      end
    end

    context 'above threshold' do
      it 'applies percentage discount for 4 CF1' do
        checkout.scan('CF1')
        checkout.scan('CF1')
        checkout.scan('CF1')
        checkout.scan('CF1')

        expected_total = 4 * 7.49
        expect(checkout.total).to be_within(0.02).of(expected_total)
      end
    end

    context 'mixed with other products' do
      it 'applies percentage discount only to CF1 items' do
        checkout.scan('CF1')
        checkout.scan('GR1')
        checkout.scan('CF1')
        checkout.scan('SR1')
        checkout.scan('CF1')

        # 3 CF1 at £7.49 + 1 GR1 at £3.11 + 1 SR1 at £5.00
        expected_total = (3 * 7.49) + 3.11 + 5.00
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end
    end
  end
end
