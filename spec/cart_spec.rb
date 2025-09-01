require 'spec_helper'
require_relative '../lib/cart'
require_relative '../lib/product'

RSpec.describe Cart do
  let(:cart) { Cart.new }
  let(:product) { create(:product) }

  describe '#add' do
    it 'adds product to cart' do
      cart.add(product)
      expect(cart.items).to include(product)
    end
  end

  describe '#total' do
    it 'calculates total of all items' do
      cart.add(product)
      total = cart.total
      expect(total).to be_a(Money)
      expect(total.amount).to eq(3.11)
    end
  end

  describe '#items' do
    it 'returns copy of items array' do
      cart.add(product)
      items = cart.items
      items.clear

      expect(cart.items).to include(product)
    end
  end

  describe '#grouped_items' do
    let(:green_tea) { create(:product) }
    let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00) }

    it 'groups items by product code' do
      cart.add(green_tea)
      cart.add(strawberries)
      cart.add(green_tea)

      grouped = cart.grouped_items
      expect(grouped['GR1']).to eq([green_tea, green_tea])
      expect(grouped['SR1']).to eq([strawberries])
    end

    it 'returns empty hash for empty cart' do
      expect(cart.grouped_items).to eq({})
    end
  end

  describe 'rule integration' do
    let(:green_tea) { create(:product) }
    let(:rule_engine) { RuleEngine.new }
    let(:cart_with_rules) { Cart.new(rule_engine: rule_engine) }

    it 'accepts rule engine in constructor' do
      expect(cart_with_rules).to be_a(Cart)
    end

    it 'calculates total with rule discounts' do
      mock_rule = double('MockRule')
      allow(mock_rule).to receive(:applicable?).and_return(true)
      allow(mock_rule).to receive(:apply).and_return(1.0)

      rule_engine.add_rule(mock_rule)
      cart_with_rules.add(green_tea)

      total = cart_with_rules.total
      expect(total).to be_a(Money)
      expect(total.amount).to eq(2.11)
    end
  end
end
