require 'spec_helper'
require_relative '../../lib/rules/bulk_fixed_price_rule'
require_relative '../../lib/product'

RSpec.describe BulkFixedPriceRule do
  let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00) }

  describe 'SR1 bulk fixed price rule' do
    let(:rule) { create(:bulk_fixed_price_rule) }

    context 'below minimum threshold' do
      context 'with single item' do
        let(:cart_items) { { 'SR1' => [strawberries] } }

        it 'applies no discount for single item' do
          discount = rule.apply(cart_items)
          expect(discount).to eq(0)
        end

        it 'is applicable when SR1 items present' do
          expect(rule.applicable?(cart_items)).to be true
        end
      end

      context 'with two items' do
        let(:cart_items) { { 'SR1' => [strawberries, strawberries] } }

        it 'applies no discount for two items' do
          discount = rule.apply(cart_items)
          expect(discount).to eq(0)
        end

        it 'is applicable when SR1 items present' do
          expect(rule.applicable?(cart_items)).to be true
        end
      end
    end

    context 'with no items' do
      let(:empty_cart) { {} }

      it 'is not applicable when no items' do
        expect(rule.applicable?(empty_cart)).to be false
      end

      it 'applies no discount when no items' do
        discount = rule.apply(empty_cart)
        expect(discount).to eq(0)
      end
    end

    context 'with different product' do
      let(:green_tea) { create(:product) }
      let(:cart_items) { { 'GR1' => [green_tea] } }

      it 'is not applicable for different product' do
        expect(rule.applicable?(cart_items)).to be false
      end

      it 'applies no discount for different product' do
        discount = rule.apply(cart_items)
        expect(discount).to eq(0)
      end
    end

    context 'at minimum threshold' do
      let(:cart_items) { { 'SR1' => [strawberries, strawberries, strawberries] } }

      it 'applies bulk discount for 3 items' do
        discount = rule.apply(cart_items)
        expected_discount = (5.00 - 4.50) * 3  # 0.50 * 3 = 1.50
        expect(discount).to be_within(0.01).of(expected_discount)
      end

      it 'calculates correct savings per item' do
        discount = rule.apply(cart_items)
        expect(discount).to eq(1.50)
      end
    end

    context 'above minimum threshold' do
      context 'with 4 items' do
        let(:cart_items) { { 'SR1' => Array.new(4, strawberries) } }

        it 'applies bulk discount for 4 items' do
          discount = rule.apply(cart_items)
          expected_discount = (5.00 - 4.50) * 4  # 0.50 * 4 = 2.00
          expect(discount).to eq(2.00)
        end
      end

      context 'with 5 items' do
        let(:cart_items) { { 'SR1' => Array.new(5, strawberries) } }

        it 'applies bulk discount for 5 items' do
          discount = rule.apply(cart_items)
          expected_discount = (5.00 - 4.50) * 5  # 0.50 * 5 = 2.50
          expect(discount).to eq(2.50)
        end

        it 'discount scales linearly with quantity' do
          discount = rule.apply(cart_items)
          expect(discount).to eq(2.50)
        end
      end

      context 'with 10 items' do
        let(:cart_items) { { 'SR1' => Array.new(10, strawberries) } }

        it 'applies bulk discount for all 10 items' do
          discount = rule.apply(cart_items)
          expected_discount = (5.00 - 4.50) * 10  # 0.50 * 10 = 5.00
          expect(discount).to eq(5.00)
        end
      end
    end
  end
end
