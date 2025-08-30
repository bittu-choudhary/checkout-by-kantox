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
      expect(cart.total).to eq(3.11)
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
end
