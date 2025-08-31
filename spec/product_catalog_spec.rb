require 'spec_helper'
require_relative '../lib/product_catalog'
require_relative '../lib/product'

RSpec.describe ProductCatalog do
  let(:green_tea) { create(:product) }
  let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00) }
  let(:coffee) { create(:product, code: 'CF1', name: 'Coffee', price: 11.23) }

  describe '#initialize' do
    it 'creates an empty catalog' do
      catalog = create(:product_catalog)
      expect(catalog).to be_a(ProductCatalog)
    end

    it 'accepts a list of products' do
      catalog = create(:product_catalog, :with_multiple_products)
      expect(catalog).to be_a(ProductCatalog)
    end
  end

  describe '#find' do
    let(:catalog) { create(:product_catalog, products: [green_tea, strawberries, coffee]) }

    it 'finds product by code' do
      product = catalog.find('GR1')
      expect(product).to eq(green_tea)
    end

    it 'returns nil for unknown product code' do
      product = catalog.find('UNKNOWN')
      expect(product).to be_nil
    end
  end

  describe '#add' do
    let(:catalog) { create(:product_catalog) }

    it 'adds product to catalog' do
      catalog.add(green_tea)
      expect(catalog.find('GR1')).to eq(green_tea)
    end
  end
end
