require 'spec_helper'
require_relative '../lib/checkout'

RSpec.describe Checkout do
  describe "#initialize" do

    it "accepts pricing rules" do
      pricing_rules = []
      checkout = Checkout.new(pricing_rules)

      expect(checkout).to be_a(Checkout)
    end

    it "has an initial total of 0" do
      pricing_rules = []
      checkout = Checkout.new(pricing_rules)

      expect(checkout.total).to eq(0)
    end

  end

  describe "#scan" do
    let(:pricing_rules) { [] }
    let(:checkout) { Checkout.new(pricing_rules) }
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
    let(:pricing_rules) { [] }
    let(:checkout) { Checkout.new(pricing_rules) }
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
end
