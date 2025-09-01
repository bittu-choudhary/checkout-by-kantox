require 'spec_helper'
require_relative '../../lib/checkout'
require_relative '../../lib/product'
require_relative '../../lib/product_catalog'
require_relative '../../lib/rule_engine'
require_relative '../../lib/rules/quantity_discount_rule'
require_relative '../../lib/rules/bulk_fixed_price_rule'
require_relative '../../lib/rules/bulk_percentage_rule'

RSpec.describe 'Multiple Rules Integration' do
  let(:green_tea) { create(:product) }
  let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00) }
  let(:coffee) { create(:product, code: 'CF1', name: 'Coffee', price: 11.23) }
  let(:catalog) { create(:product_catalog, products: [green_tea, strawberries, coffee]) }
  let(:bogo_rule) { create(:quantity_discount_rule) }  # Buy-one-get-one-free
  let(:bulk_fixed_rule) { create(:bulk_fixed_price_rule) }  # £4.50 when buying 3+
  let(:bulk_percentage_rule) { create(:bulk_percentage_rule) }
  let(:checkout) { create(:checkout, pricing_rules: rule_engine, catalog: catalog) }

  describe 'multiple rules on different products' do
    let(:rule_engine) { RuleEngine.new(rules: [bogo_rule, bulk_fixed_rule, bulk_percentage_rule]) }

    context 'complex cart scenarios' do
      it 'applies GR1 BOGO and SR1 bulk pricing together' do
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('SR1')

        # 2 GR1 with BOGO = £3.11 + 3 SR1 with bulk = £13.50 = £16.61
        expected_total = 3.11 + (3 * 4.50)
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end

      it 'applies GR1 BOGO and CF1 bulk percentage together' do
        checkout.scan('GR1')
        checkout.scan('CF1')
        checkout.scan('GR1')
        checkout.scan('CF1')
        checkout.scan('CF1')

        # 2 GR1 with BOGO = £3.11 + 3 CF1 with percentage = £22.46 = £25.57
        expected_total = 3.11 + (3 * 7.49)
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end

      it 'applies SR1 bulk and CF1 percentage together' do
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('SR1')
        checkout.scan('CF1')

        # 3 SR1 with bulk = £13.50 + 3 CF1 with percentage = £22.46 = £35.96
        expected_total = (3 * 4.50) + (3 * 7.49)
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end

      it 'applies all three rules together' do
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('SR1')
        checkout.scan('CF1')

        # 2 GR1 BOGO = £3.11 + 3 SR1 bulk = £13.50 + 3 CF1 percentage = £22.46 = £39.07
        expected_total = 3.11 + (3 * 4.50) + (3 * 7.49)
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end
    end

    context 'partial rule activation' do
      it 'applies only applicable rules when thresholds not met' do
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('GR1')

        # 2 GR1 BOGO = £3.11 + 1 SR1 full = £5.00 + 1 CF1 full = £11.23 = £19.34
        expected_total = 3.11 + 5.00 + 11.23
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end

      it 'applies GR1 BOGO only when other rules inactive' do
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('GR1')
        checkout.scan('SR1')

        # 2 GR1 BOGO = £3.11 + 2 SR1 full = £10.00 + 1 CF1 full = £11.23 = £24.34
        expected_total = 3.11 + (2 * 5.00) + 11.23
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end
    end

    context 'rules with different quantities' do
      it 'handles odd quantities with multiple active rules' do
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('CF1')

        # 3 GR1: 1 BOGO set + 1 full = £6.22 + 3 SR1 bulk = £13.50 + 3 CF1 percentage = £22.46 = £42.18
        expected_total = 6.22 + (3 * 4.50) + (3 * 7.49)
        expect(checkout.total).to be_within(0.01).of(expected_total)
      end
    end
  end

  describe 'rule independence' do
    let(:rule_engine) { RuleEngine.new(rules: [bogo_rule, bulk_fixed_rule]) }

    it 'GR1 rule does not affect SR1 pricing' do
      checkout.scan('GR1')
      checkout.scan('SR1')
      checkout.scan('GR1')
      checkout.scan('SR1')
      checkout.scan('SR1')

      # GR1 discount should not affect SR1 bulk pricing
      expected_total = 3.11 + (3 * 4.50)
      expect(checkout.total).to be_within(0.01).of(expected_total)
    end

    it 'SR1 rule does not affect GR1 pricing' do
      checkout.scan('SR1')
      checkout.scan('GR1')
      checkout.scan('SR1')
      checkout.scan('GR1')
      checkout.scan('SR1')

      # SR1 discount should not affect GR1 BOGO pricing
      expected_total = (3 * 4.50) + 3.11
      expect(checkout.total).to be_within(0.01).of(expected_total)
    end
  end


  describe 'Original Test Cases' do
    let(:rule_engine) { RuleEngine.new(rules: [bogo_rule, bulk_fixed_rule, bulk_percentage_rule]) }

    context 'Test Case 1: GR1,SR1,GR1,GR1,CF1 → £22.45' do
      it 'matches expected total exactly' do
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('GR1')
        checkout.scan('GR1')
        checkout.scan('CF1')

        total = checkout.total
        expect(total).to be_within(0.01).of(22.45)
      end
    end

    context 'Test Case 2: GR1,GR1 → £3.11' do
      it 'matches expected total exactly' do
        checkout.scan('GR1')
        checkout.scan('GR1')

        total = checkout.total
        expect(total).to eq(3.11)
      end

      it 'applies BOGO correctly' do
        checkout.scan('GR1')
        checkout.scan('GR1')

        # 2 GR1: 1 BOGO set = £3.11
        total = checkout.total
        expect(total).to eq(3.11)
      end
    end

    context 'Test Case 3: SR1,SR1,GR1,SR1 → £16.61' do
      it 'matches expected total exactly' do
        checkout.scan('SR1')
        checkout.scan('SR1')
        checkout.scan('GR1')
        checkout.scan('SR1')

        total = checkout.total
        expect(total).to be_within(0.01).of(16.61)
      end

      it 'applies SR1 bulk discount correctly' do
        checkout.scan('SR1')
        checkout.scan('SR1')
        checkout.scan('GR1')
        checkout.scan('SR1')

        # 3 SR1: bulk price = £13.50
        # 1 GR1: full price = £3.11
        # Total = £16.61

        total = checkout.total
        expect(total).to be_within(0.01).of(16.61)
      end
    end

    context 'Test Case 4: GR1,CF1,SR1,CF1,CF1 → £30.57' do
      it 'matches expected total exactly' do
        checkout.scan('GR1')
        checkout.scan('CF1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('CF1')

        total = checkout.total
        expect(total).to be_within(0.01).of(30.57)
      end

      it 'applies CF1 percentage discount correctly' do
        checkout.scan('GR1')
        checkout.scan('CF1')
        checkout.scan('SR1')
        checkout.scan('CF1')
        checkout.scan('CF1')

        # 1 GR1: full price = £3.11
        # 1 SR1: full price = £5.00
        # 3 CF1: 2/3 price = £22.46
        # Total = £30.57

        total = checkout.total
        expect(total).to be_within(0.01).of(30.57)
      end
    end
  end
end
