require 'spec_helper'
require_relative '../lib/checkout'
require_relative '../lib/product_catalog'

RSpec.describe Checkout do
  describe "#initialize" do

    it "accepts pricing rules" do
      checkout = create(:checkout)

      expect(checkout).to be_a(Checkout)
    end

    it "has an initial total of 0" do
      checkout =  create(:checkout)

      expect(checkout.total).to eq(0)
    end

  end

  describe "#scan" do
    let(:checkout) {  create(:checkout) }
    let(:green_tea) { create(:product) }
    let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00) }

    it "adds item to checkout" do
      expect { checkout.scan(green_tea) }.not_to raise_error
    end

    it "reflects item price in total" do
      checkout.scan(green_tea)
      expect(checkout.total).to eq(green_tea.price)
    end

    context "with multiple items" do
      it "adds different product correctly" do
        checkout.scan(green_tea)
        checkout.scan(strawberries)
        expect(checkout.total).to eq(green_tea.price + strawberries.price)
      end
    end

    context "with multiple quantities of same item" do
      it "adds same product correctly" do
        checkout.scan(green_tea)
        checkout.scan(green_tea)
        expect(checkout.total).to eq(green_tea.price * 2)
      end

      it "handles mixed scanning" do
        checkout.scan(green_tea)
        checkout.scan(strawberries)
        checkout.scan(green_tea)
        expect(checkout.total).to eq(green_tea.price * 2 + strawberries.price)
      end
    end
  end

  describe "integration" do
    let(:checkout) { create(:checkout)}
    let(:green_tea) { create(:product) }
    let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00) }
    let(:coffee) { create(:product, code: 'CF1', name: 'Coffee', price: 11.23) }

    context "complete checkout flow without discounts" do
      it "calculates total for mixed products without pricing rules" do
        checkout.scan(green_tea)
        checkout.scan(strawberries)
        checkout.scan(green_tea)
        checkout.scan(coffee)
        expect(checkout.total).to eq(green_tea.price * 2 + strawberries.price + coffee.price)
      end

      it "handles empty basket" do
        expect(checkout.total).to eq(0)
      end

      it "maintains running total as items are scanned" do
        checkout.scan(green_tea)
        expect(checkout.total).to eq(green_tea.price)

        checkout.scan(strawberries)
        expect(checkout.total).to eq(green_tea.price + strawberries.price)

        checkout.scan(green_tea)
        expect(checkout.total).to eq(green_tea.price * 2 + strawberries.price)

        checkout.scan(coffee)
        expect(checkout.total).to eq(green_tea.price * 2 + strawberries.price + coffee.price)
      end
    end
  end

  describe 'catalog integration' do
    let(:green_tea) { create(:product) }
    let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00) }
    let(:catalog) { create(:product_catalog, products: [green_tea, strawberries]) }
    let(:checkout) { create(:checkout, catalog: catalog) }

    context 'scanning with product codes' do
      it 'scans product by code using catalog' do
        checkout.scan('GR1')
        expect(checkout.total).to eq(3.11)
      end

      it 'handles multiple product codes' do
        checkout.scan('GR1')
        checkout.scan('SR1')
        checkout.scan('GR1')

        expect(checkout.total).to be_within(0.01).of(11.22)
      end

      it 'raises error for unknown product code' do
        expect { checkout.scan('UNKNOWN') }.to raise_error(ArgumentError, 'Product not found: UNKNOWN')
      end
    end

    context 'mixed scanning modes' do
      it 'accepts both product objects and codes' do
        checkout.scan(green_tea)
        checkout.scan('SR1')

        expect(checkout.total).to be_within(0.01).of(8.11)
      end
    end

    context 'without catalog' do
      let(:checkout_no_catalog) { create(:checkout) }

      it 'scans product objects directly' do
        checkout_no_catalog.scan(green_tea)
        expect(checkout_no_catalog.total).to eq(3.11)
      end

      it 'passes through string when no catalog provided' do
        expect { checkout_no_catalog.scan('GR1') }.not_to raise_error
      end
    end
  end
end
