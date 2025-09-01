require 'spec_helper'
require_relative '../../lib/rules/bulk_percentage_rule'
require_relative '../../lib/product'

RSpec.describe BulkPercentageRule do
  let(:coffee) { create(:product, code: 'CF1', name: 'Coffee', price: 11.23) }

  describe 'CF1 bulk percentage rule' do
    let(:rule) { create(:bulk_percentage_rule) }

    context 'below minimum threshold' do
      context 'with single item' do
        let(:cart_items) { { 'CF1' => [coffee] } }

        it 'applies no discount for single item' do
          discount = rule.apply(cart_items)
          expect(discount).to eq(0)
        end

        it 'is applicable when CF1 items present' do
          expect(rule.applicable?(cart_items)).to be true
        end
      end

      context 'with two items' do
        let(:cart_items) { { 'CF1' => [coffee, coffee] } }

        it 'applies no discount for two items' do
          discount = rule.apply(cart_items)
          expect(discount).to eq(0)
        end

        it 'is applicable when CF1 items present' do
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
      let(:cart_items) { { 'CF1' => [coffee, coffee, coffee] } }

      it 'applies percentage discount for 3 items' do
        discount = rule.apply(cart_items)
        # 33.33% of £11.23 = £3.74, for 3 items = £11.23
        expected_discount = (11.23 * 0.3333) * 3
        expect(discount).to be_within(0.01).of(expected_discount)
      end

      it 'calculates correct percentage savings' do
        discount = rule.apply(cart_items)
        expect(discount).to be_within(0.01).of(11.23)
      end
    end

    context 'above minimum threshold' do
      context 'with 4 items' do
        let(:cart_items) { { 'CF1' => Array.new(4, coffee) } }

        it 'applies percentage discount for 4 items' do
          discount = rule.apply(cart_items)
          expected_discount = (11.23 * 0.3333) * 4
          expect(discount).to be_within(0.01).of(expected_discount)
        end
      end

      context 'with 5 items' do
        let(:cart_items) { { 'CF1' => Array.new(5, coffee) } }

        it 'applies percentage discount for 5 items' do
          discount = rule.apply(cart_items)
          expected_discount = (11.23 * 0.3333) * 5
          expect(discount).to be_within(0.01).of(expected_discount)
        end

        it 'discount scales linearly with quantity' do
          discount = rule.apply(cart_items)
          expect(discount).to be_within(0.01).of(18.72)
        end
      end
    end
  end
end
