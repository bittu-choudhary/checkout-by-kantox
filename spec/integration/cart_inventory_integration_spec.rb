require 'spec_helper'
require_relative '../../lib/cart'
require_relative '../../lib/product'
require_relative '../../lib/inventory'
require_relative '../../lib/insufficient_stock_error'

RSpec.describe 'Cart Inventory Integration' do
  let(:inventory) { Inventory.new }
  let(:cart_id) { SecureRandom.uuid }
  let(:cart) { Cart.new(base_currency: 'GBP', inventory: inventory, cart_id: cart_id) }

  let(:green_tea) { create(:product) }
  let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00, units: 5) }
  let(:coffee) { create(:product, code: 'CF1', name: 'Coffee', price: 11.23, units: 0) }

  before do
    inventory.add_product('GR1', units: 10)
    inventory.add_product('SR1', units: 5)
    inventory.add_product('CF1', units: 0)
  end

  describe 'Cart with inventory integration' do
    it 'initializes with inventory and cart_id parameters' do
      expect(cart).to be_a(Cart)
    end

    it 'provides cart_id accessor' do
      expect(cart.cart_id).to eq(cart_id)
    end

    it 'provides inventory accessor' do
      expect(cart.inventory).to eq(inventory)
    end
  end

  describe '#add with inventory checking' do
    context 'when sufficient stock available' do
      it 'adds product and reserves stock in inventory' do
        cart.add(green_tea)

        expect(cart.items).to include(green_tea)
        expect(inventory.stock_level('GR1')[:reserved]).to eq(1)
        expect(inventory.stock_level('GR1')[:available]).to eq(9)
      end

      it 'handles multiple additions of same product' do
        cart.add(green_tea)
        cart.add(green_tea)

        expect(cart.items.count).to eq(2)
        expect(inventory.stock_level('GR1')[:reserved]).to eq(2)
        expect(inventory.stock_level('GR1')[:available]).to eq(8)
      end

      it 'handles additions of different products' do
        cart.add(green_tea)
        cart.add(strawberries)

        expect(cart.items.count).to eq(2)
        expect(inventory.stock_level('GR1')[:reserved]).to eq(1)
        expect(inventory.stock_level('SR1')[:reserved]).to eq(1)
        expect(inventory.stock_level('GR1')[:available]).to eq(9)
        expect(inventory.stock_level('SR1')[:available]).to eq(4)
      end

      it 'reserves exact available stock' do
        5.times { cart.add(strawberries) }

        expect(cart.items.count).to eq(5)
        expect(inventory.stock_level('SR1')[:reserved]).to eq(5)
        expect(inventory.stock_level('SR1')[:available]).to eq(0)
      end
    end

    context 'when insufficient stock' do
      it 'raises InsufficientStockError when adding to empty stock' do
        expect {
          cart.add(coffee)
        }.to raise_error(InsufficientStockError) do |error|
          expect(error.product_code).to eq('CF1')
          expect(error.requested).to eq(1)
          expect(error.available).to eq(0)
        end
      end

      it 'raises InsufficientStockError when exceeding available stock' do
        10.times { cart.add(green_tea) }

        expect {
          cart.add(green_tea)  # This should fail - asking for 11th item
        }.to raise_error(InsufficientStockError) do |error|
          expect(error.product_code).to eq('GR1')
          expect(error.requested).to eq(1)
          expect(error.available).to eq(0)
        end
      end

      it 'does not add item when stock insufficient' do
        original_count = cart.items.count
        original_reserved = inventory.stock_level('CF1')[:reserved]

        expect {
          cart.add(coffee)
        }.to raise_error(InsufficientStockError)

        expect(cart.items.count).to eq(original_count)
        expect(inventory.stock_level('CF1')[:reserved]).to eq(original_reserved)
      end

      it 'handles insufficient stock with partial reservations' do
        3.times { cart.add(strawberries) }  # Reserve 3, leaving 2

        expect {
          cart.add(strawberries)  # This should work - 4th item
          cart.add(strawberries)  # This should work - 5th item
          cart.add(strawberries)  # This should fail - 6th item
        }.to raise_error(InsufficientStockError)

        expect(cart.items.count).to eq(5)  # 3 + 2 successful additions
        expect(inventory.stock_level('SR1')[:reserved]).to eq(5)
        expect(inventory.stock_level('SR1')[:available]).to eq(0)
      end
    end

    context 'edge cases' do
      it 'maintains cart state when inventory operations fail' do
        cart.add(green_tea)
        original_items = cart.items.dup

        expect {
          cart.add(coffee)  # This should fail
        }.to raise_error(InsufficientStockError)

        # Cart should maintain its previous state
        expect(cart.items).to eq(original_items)
        expect(inventory.stock_level('GR1')[:reserved]).to eq(1)
      end
    end
  end

  describe '#remove with inventory integration' do
    before do
      cart.add(green_tea)
      cart.add(strawberries)
    end

    it 'removes item and releases stock reservation' do
      cart.remove(green_tea)

      expect(cart.items).not_to include(green_tea)
      expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
      expect(inventory.stock_level('GR1')[:available]).to eq(10)
    end

    it 'handles partial removal of multiple same items' do
      cart.add(green_tea)  # Now have 2 green teas

      cart.remove(green_tea)  # Remove one

      expect(cart.items.count { |item| item.code == 'GR1' }).to eq(1)
      expect(inventory.stock_level('GR1')[:reserved]).to eq(1)
      expect(inventory.stock_level('GR1')[:available]).to eq(9)
    end

    it 'maintains reservations for other products' do
      cart.remove(green_tea)

      expect(inventory.stock_level('SR1')[:reserved]).to eq(1)
      expect(inventory.stock_level('SR1')[:available]).to eq(4)
    end
  end

  describe 'cart lifecycle with inventory' do
    it 'handles complete cart-to-inventory workflow' do
      # Add items (reserves stock)
      cart.add(green_tea)
      cart.add(strawberries)

      expect(inventory.stock_level('GR1')[:reserved]).to eq(1)
      expect(inventory.stock_level('SR1')[:reserved]).to eq(1)

      # Remove one item (releases stock)
      cart.remove(strawberries)

      expect(inventory.stock_level('SR1')[:reserved]).to eq(0)
      expect(inventory.stock_level('SR1')[:available]).to eq(5)

      # Check final state
      expect(cart.items.count).to eq(1)
      expect(inventory.stock_level('GR1')[:reserved]).to eq(1)
    end

    it 'handles competing carts for same inventory' do
      cart2_id = 'cart_456'
      cart2 = Cart.new(base_currency: 'GBP', inventory: inventory, cart_id: cart2_id)

      # Both carts add items
      5.times { cart.add(green_tea) }    # Cart 1: 5 items
      3.times { cart2.add(green_tea) }   # Cart 2: 3 items

      expect(inventory.stock_level('GR1')[:reserved]).to eq(8)
      expect(inventory.stock_level('GR1')[:available]).to eq(2)

      # Cart 1 tries to add more - should work for 2 more
      2.times { cart.add(green_tea) }
      expect(inventory.stock_level('GR1')[:available]).to eq(0)

      # Either cart tries to add one more - should fail
      expect {
        cart.add(green_tea)
      }.to raise_error(InsufficientStockError)

      expect {
        cart2.add(green_tea)
      }.to raise_error(InsufficientStockError)
    end
  end
end
