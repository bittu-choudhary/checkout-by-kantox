require 'spec_helper'
require_relative '../../lib/rules/quantity_discount_rule'
require_relative '../../lib/product'

RSpec.describe QuantityDiscountRule do
  let(:green_tea) { create(:product) }

  describe 'BOGO rule for GR1' do
    let(:rule) { create(:quantity_discount_rule) }

    context 'with single item' do
      let(:cart_items) { { 'GR1' => [green_tea] } }

      it 'applies no discount for single item' do
        discount = rule.apply(cart_items)
        expect(discount).to eq(0)
      end

      it 'is applicable when GR1 items present' do
        expect(rule.applicable?(cart_items)).to be true
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
      let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00) }
      let(:cart_items) { { 'SR1' => [strawberries] } }

      it 'is not applicable for different product' do
        expect(rule.applicable?(cart_items)).to be false
      end
    end

    context 'with insufficient items for discount' do
      let(:rule) { create(:quantity_discount_rule, buy_quantity: 2, free_quantity: 1) }
      let(:cart_items) { { 'GR1' => [green_tea, green_tea] } }

      it 'applies no discount when insufficient items' do
        discount = rule.apply(cart_items)
        expect(discount).to eq(0)
      end
    end

    context 'with items for discount' do
      let(:rule) { create(:quantity_discount_rule) }
      let(:cart_items) { { 'GR1' => [green_tea, green_tea] } }

      it 'calculates discount correctly' do
        discount = rule.apply(cart_items)
        expect(discount).to eq(3.11)
      end
    end
  end

  describe 'BOGO with 2 items' do
    let(:rule) { create(:quantity_discount_rule) }

    context 'exactly 2 items' do
      let(:cart_items) { { 'GR1' => [green_tea, green_tea] } }

      it 'applies discount for one free item' do
        discount = rule.apply(cart_items)
        expect(discount).to eq(3.11)
      end

      it 'discount equals price of one item' do
        discount = rule.apply(cart_items)
        expect(discount).to eq(green_tea.price.amount)
      end
    end

    context 'with 4 items' do
      let(:cart_items) { { 'GR1' => [green_tea, green_tea, green_tea, green_tea] } }

      it 'applies discount for two free items' do
        discount = rule.apply(cart_items)
        expect(discount).to eq(6.22)
      end

      it 'discount equals price of two items' do
        discount = rule.apply(cart_items)
        expect(discount).to be_within(0.01).of(green_tea.price.amount * 2)
      end
    end
  end

  describe 'BOGO with odd quantities' do
    let(:rule) { create(:quantity_discount_rule) }

    context 'with 3 items' do
      let(:cart_items) { { 'GR1' => [green_tea, green_tea, green_tea] } }

      it 'applies discount for one set only' do
        discount = rule.apply(cart_items)
        expect(discount).to eq(3.11)
      end

      it 'leaves one item at full price' do
        discount = rule.apply(cart_items)
        expected_discount = green_tea.price.amount * 1
        expect(discount).to eq(expected_discount)
      end
    end

    context 'with 5 items' do
      let(:cart_items) { { 'GR1' => Array.new(5, green_tea) } }

      it 'applies discount for two complete sets' do
        discount = rule.apply(cart_items)
        expect(discount).to be_within(0.01).of(6.22)
      end

      it 'leaves one item at full price' do
        discount = rule.apply(cart_items)
        expected_discount = green_tea.price.amount * 2
        expect(discount).to be_within(0.01).of(expected_discount)
      end
    end

    context 'with 7 items' do
      let(:cart_items) { { 'GR1' => Array.new(7, green_tea) } }

      it 'applies discount for three complete sets' do
        discount = rule.apply(cart_items)
        expect(discount).to be_within(0.01).of(9.33)
      end
    end
  end
end
