require 'spec_helper'
require_relative '../lib/product'

RSpec.describe Product do
  describe '#initialize' do
    it 'creates a product with code, name, and price' do
      product = create(:product)

      expect(product).to be_a(Product)
    end
  end

  describe 'attributes' do
    let(:product) { create(:product) }

    it 'returns the product code' do
      expect(product.code).to eq('GR1')
    end

    it 'returns the product name' do
      expect(product.name).to eq('Green tea')
    end

    it 'returns the product price' do
      expect(product.price).to eq(3.11)
    end
  end

  describe 'equality' do
    let(:product1) {create(:product) }
    let(:product2) { create(:product) }
    let(:different_product) {create(:product, code: 'SR1', name: 'Strawberries', price: 5.00) }

    it 'is equal when product codes match' do
      expect(product1).to eq(product2)
    end

    it 'is not equal when product codes differ' do
      expect(product1).not_to eq(different_product)
    end

    it 'has the same hash when product codes match' do
      expect(product1.hash).to eq(product2.hash)
    end
  end
end
