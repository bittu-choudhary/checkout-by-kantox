require 'spec_helper'
require_relative '../../lib/checkout'
require_relative '../../lib/product'
require_relative '../../lib/inventory'
require_relative '../../lib/insufficient_stock_error'
require_relative '../../lib/product_catalog'

RSpec.describe 'Checkout Inventory Integration' do
  let(:inventory) { Inventory.new }
  let(:green_tea) { create(:product) }
  let(:strawberries) { create(:product, code: 'SR1', name: 'Strawberries', price: 5.00, units: 5) }
  let(:coffee) { create(:product, code: 'CF1', name: 'Coffee', price: 11.23, units: 3) }

  let(:catalog) { create(:product_catalog, products: [green_tea, strawberries, coffee]) }
  let(:checkout) { create(:checkout, catalog: catalog, inventory: inventory) }

  before do
    inventory.add_product('GR1', units: 10)
    inventory.add_product('SR1', units: 5)
    inventory.add_product('CF1', units: 3)
  end

  describe 'Checkout with inventory integration' do
    it 'initializes with inventory parameter' do
      expect(checkout).to be_a(Checkout)
      expect(checkout.inventory).to eq(inventory)
    end

    it 'provides cart_id for inventory tracking' do
      expect(checkout.cart_id).to be_a(String)
      expect(checkout.cart_id.length).to be > 0
    end

    it 'passes inventory to cart during initialization' do
      expect(checkout.cart.inventory).to eq(inventory)
      expect(checkout.cart.cart_id).to eq(checkout.cart_id)
    end
  end

  describe '#scan with inventory checking' do
    context 'when sufficient stock available' do
      it 'scans items and reserves inventory' do
        checkout.scan('GR1')
        checkout.scan('SR1')

        expect(inventory.stock_level('GR1')[:reserved]).to eq(1)
        expect(inventory.stock_level('SR1')[:reserved]).to eq(1)
        expect(inventory.stock_level('GR1')[:available]).to eq(9)
        expect(inventory.stock_level('SR1')[:available]).to eq(4)
      end

      it 'handles multiple scans of same product' do
        3.times { checkout.scan('GR1') }

        expect(inventory.stock_level('GR1')[:reserved]).to eq(3)
        expect(inventory.stock_level('GR1')[:available]).to eq(7)
      end

      it 'reserves maximum available stock' do
        5.times { checkout.scan('SR1') }

        expect(inventory.stock_level('SR1')[:reserved]).to eq(5)
        expect(inventory.stock_level('SR1')[:available]).to eq(0)
      end
    end

    context 'when insufficient stock' do
      it 'raises InsufficientStockError for unavailable stock' do
        3.times { checkout.scan('CF1') }  # Use up all coffee

        expect {
          checkout.scan('CF1')  # This should fail
        }.to raise_error(InsufficientStockError) do |error|
          expect(error.product_code).to eq('CF1')
          expect(error.requested).to eq(1)
          expect(error.available).to eq(0)
        end
      end

      it 'prevents overselling when stock is exhausted' do
        10.times { checkout.scan('GR1') }  # Use up all green tea

        expect {
          checkout.scan('GR1')
        }.to raise_error(InsufficientStockError)

        expect(inventory.stock_level('GR1')[:reserved]).to eq(10)
        expect(inventory.stock_level('GR1')[:available]).to eq(0)
      end

      it 'maintains checkout state when scan fails' do
        checkout.scan('GR1')
        3.times { checkout.scan('CF1') }  # Use up all coffee

        original_total = checkout.total

        expect {
          checkout.scan('CF1')
        }.to raise_error(InsufficientStockError)

        # Checkout state should remain unchanged
        expect(checkout.total).to eq(original_total)
        expect(inventory.stock_level('CF1')[:reserved]).to eq(3)  # No additional reservation
      end
    end
  end

  describe '#process method for inventory commitment' do
    before do
      checkout.scan('GR1')
      checkout.scan('SR1')
      checkout.scan('CF1')
    end

    it 'commits all reserved inventory to sold when processing' do
      checkout.process

      expect(inventory.stock_level('GR1')[:sold]).to eq(1)
      expect(inventory.stock_level('SR1')[:sold]).to eq(1)
      expect(inventory.stock_level('CF1')[:sold]).to eq(1)

      expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
      expect(inventory.stock_level('SR1')[:reserved]).to eq(0)
      expect(inventory.stock_level('CF1')[:reserved]).to eq(0)
    end

    it 'updates available stock correctly after processing' do
      checkout.process

      expect(inventory.stock_level('GR1')[:available]).to eq(9)  # 10 - 1 sold
      expect(inventory.stock_level('SR1')[:available]).to eq(4)  # 5 - 1 sold
      expect(inventory.stock_level('CF1')[:available]).to eq(2)  # 3 - 1 sold
    end

    it 'returns success indicator when processing completes' do
      result = checkout.process
      expect(result).to be_truthy
    end

    it 'handles empty checkout processing gracefully' do
      empty_checkout = create(:checkout, catalog: catalog, inventory: inventory)

      result = empty_checkout.process
      expect(result).to be_truthy

      # No inventory changes should occur
      expect(inventory.stock_level('GR1')[:sold]).to eq(0)
      expect(inventory.stock_level('SR1')[:sold]).to eq(0)
      expect(inventory.stock_level('CF1')[:sold]).to eq(0)
    end

    it 'allows processing only once per checkout' do
      checkout.process

      expect {
        checkout.process
      }.to raise_error(RuntimeError, /already processed/)
    end
  end

  describe '#cancel method for inventory release' do
    before do
      checkout.scan('GR1')
      checkout.scan('SR1')
      checkout.scan('CF1')
    end

    it 'releases all reserved inventory when cancelling' do
      checkout.cancel

      expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
      expect(inventory.stock_level('SR1')[:reserved]).to eq(0)
      expect(inventory.stock_level('CF1')[:reserved]).to eq(0)

      expect(inventory.stock_level('GR1')[:available]).to eq(10)
      expect(inventory.stock_level('SR1')[:available]).to eq(5)
      expect(inventory.stock_level('CF1')[:available]).to eq(3)
    end

    it 'does not affect sold inventory' do
      # Simulate some previous sales
      inventory.reserve('GR1', 2, 'other_cart')
      inventory.commit('other_cart')

      checkout.cancel

      expect(inventory.stock_level('GR1')[:sold]).to eq(2)  # Should remain unchanged
    end

    it 'returns success indicator when cancellation completes' do
      result = checkout.cancel
      expect(result).to be_truthy
    end

    it 'handles empty checkout cancellation gracefully' do
      empty_checkout = create(:checkout, catalog: catalog, inventory: inventory)

      result = empty_checkout.cancel
      expect(result).to be_truthy

      # No inventory changes should occur
      expect(inventory.stock_level('GR1')[:reserved]).to eq(1)  # From main checkout setup
    end

    it 'allows cancellation only once per checkout' do
      checkout.cancel

      expect {
        checkout.cancel
      }.to raise_error(RuntimeError, /already cancelled/)
    end

    it 'prevents processing after cancellation' do
      checkout.cancel

      expect {
        checkout.process
      }.to raise_error(RuntimeError, /Cannot process.*cancelled/)
    end
  end

  describe 'checkout lifecycle with inventory' do
    it 'handles complete scan-to-process workflow' do
      # Scan items (reserves stock)
      checkout.scan('GR1')
      checkout.scan('SR1')

      expect(inventory.stock_level('GR1')[:reserved]).to eq(1)
      expect(inventory.stock_level('SR1')[:reserved]).to eq(1)

      # Calculate total (no inventory impact)
      total = checkout.total
      expect(total).to be > 0

      # Process (commits reservations to sold)
      checkout.process

      expect(inventory.stock_level('GR1')[:sold]).to eq(1)
      expect(inventory.stock_level('SR1')[:sold]).to eq(1)
      expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
      expect(inventory.stock_level('SR1')[:reserved]).to eq(0)
    end

    it 'handles scan-to-cancel workflow' do
      # Scan items
      checkout.scan('GR1')
      checkout.scan('CF1')

      expect(inventory.stock_level('GR1')[:reserved]).to eq(1)
      expect(inventory.stock_level('CF1')[:reserved]).to eq(1)

      # Cancel (releases all reservations)
      checkout.cancel

      expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
      expect(inventory.stock_level('CF1')[:reserved]).to eq(0)
      expect(inventory.stock_level('GR1')[:available]).to eq(10)
      expect(inventory.stock_level('CF1')[:available]).to eq(3)
    end

    it 'handles multiple competing checkouts' do
      checkout2 = create(:checkout, catalog: catalog, inventory: inventory)

      # Both checkouts scan items
      2.times { checkout.scan('GR1') }    # Checkout 1: 2 GR1
      3.times { checkout2.scan('GR1') }   # Checkout 2: 3 GR1

      expect(inventory.stock_level('GR1')[:reserved]).to eq(5)
      expect(inventory.stock_level('GR1')[:available]).to eq(5)

      # First checkout processes
      checkout.process
      expect(inventory.stock_level('GR1')[:sold]).to eq(2)
      expect(inventory.stock_level('GR1')[:reserved]).to eq(3)  # Second checkout still reserved

      # Second checkout cancels
      checkout2.cancel
      expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
      expect(inventory.stock_level('GR1')[:available]).to eq(8)  # 10 - 2 sold
    end

    it 'prevents double-processing and double-cancelling' do
      checkout.scan('GR1')

      # Process first
      checkout.process

      expect {
        checkout.process  # Second process should fail
      }.to raise_error(RuntimeError)

      # New checkout for cancel test
      checkout2 = create(:checkout, catalog: catalog, inventory: inventory)
      checkout2.scan('SR1')

      # Cancel first
      checkout2.cancel

      expect {
        checkout2.cancel  # Second cancel should fail
      }.to raise_error(RuntimeError)
    end
  end

  describe 'error handling with inventory' do
    it 'handles inventory errors during scanning gracefully' do
      # Mock inventory failure
      allow(inventory).to receive(:reserve).and_return(false)

      expect {
        checkout.scan('GR1')
      }.to raise_error(InsufficientStockError)
    end

    it 'maintains inventory consistency during errors' do
      checkout.scan('GR1')
      original_reserved = inventory.stock_level('GR1')[:reserved]

      # Cause a scan error
      expect {
        checkout.scan('INVALID_PRODUCT')
      }.to raise_error(ArgumentError)

      # Inventory state should remain unchanged
      expect(inventory.stock_level('GR1')[:reserved]).to eq(original_reserved)
    end
  end
end
