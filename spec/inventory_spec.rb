require 'spec_helper'
require_relative '../lib/inventory'

RSpec.describe Inventory do
  let(:inventory) { Inventory.new }

  describe '#initialize' do
    it 'creates empty inventory system' do
      expect(inventory).to be_a(Inventory)
    end
  end

  describe '#add_product' do
    it 'adds product with initial stock level' do
      inventory.add_product('GR1', units: 50)
      expect(inventory.stock_level('GR1')[:total]).to eq(50)
    end

    it 'initializes available stock equal to total units' do
      inventory.add_product('SR1', units: 25)
      stock = inventory.stock_level('SR1')
      expect(stock[:available]).to eq(25)
      expect(stock[:reserved]).to eq(0)
    end
  end

  describe '#stock_level' do
    context 'for unknown product' do
      it 'returns zero stock levels' do
        stock = inventory.stock_level('UNKNOWN')
        expect(stock[:total]).to eq(0)
        expect(stock[:reserved]).to eq(0)
        expect(stock[:available]).to eq(0)
      end
    end

    context 'for known product' do
      before do
        inventory.add_product('CF1', units: 30)
      end

      it 'returns correct stock information' do
        stock = inventory.stock_level('CF1')
        expect(stock).to have_key(:total)
        expect(stock).to have_key(:reserved)
        expect(stock).to have_key(:available)
      end
    end
  end

  describe '#available?' do
    before do
      inventory.add_product('GR1', units: 10)
    end

    it 'returns true when sufficient stock available' do
      expect(inventory.available?('GR1', 5)).to be true
    end

    it 'returns true when requesting exact available stock' do
      expect(inventory.available?('GR1', 10)).to be true
    end

    it 'returns false when insufficient stock' do
      expect(inventory.available?('GR1', 15)).to be false
    end

    it 'returns false for unknown product' do
      expect(inventory.available?('XX1', 1)).to be false
    end

    it 'returns true when requesting zero quantity' do
      expect(inventory.available?('GR1', 0)).to be true
    end

    context 'with edge cases' do
      it 'handles negative quantity requests' do
        expect(inventory.available?('GR1', -1)).to be true
      end

      it 'handles very large quantity requests' do
        expect(inventory.available?('GR1', 999999)).to be false
      end
    end
  end

  describe '#reserve' do
    let(:cart_id) { 'cart_123' }

    before do
      inventory.add_product('GR1', units: 10)
    end

    context 'successful reservations' do
      it 'reserves stock successfully when available' do
        result = inventory.reserve('GR1', 3, cart_id)
        expect(result).to be true
        expect(inventory.stock_level('GR1')[:available]).to eq(7)
        expect(inventory.stock_level('GR1')[:reserved]).to eq(3)
      end

      it 'reserves exact available stock' do
        result = inventory.reserve('GR1', 10, cart_id)
        expect(result).to be true
        expect(inventory.stock_level('GR1')[:available]).to eq(0)
        expect(inventory.stock_level('GR1')[:reserved]).to eq(10)
      end

      it 'handles multiple reservations for same cart' do
        inventory.reserve('GR1', 2, cart_id)
        inventory.reserve('GR1', 1, cart_id)

        expect(inventory.stock_level('GR1')[:reserved]).to eq(3)
        expect(inventory.stock_level('GR1')[:available]).to eq(7)
      end

      it 'handles reservations from different carts' do
        cart_id_2 = 'cart_456'

        inventory.reserve('GR1', 3, cart_id)
        inventory.reserve('GR1', 2, cart_id_2)

        expect(inventory.stock_level('GR1')[:reserved]).to eq(5)
        expect(inventory.stock_level('GR1')[:available]).to eq(5)
      end
    end

    context 'failed reservations' do
      it 'fails to reserve when insufficient stock' do
        result = inventory.reserve('GR1', 15, cart_id)
        expect(result).to be false
        expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
        expect(inventory.stock_level('GR1')[:available]).to eq(10)
      end

      it 'fails to reserve unknown product' do
        result = inventory.reserve('XX1', 1, cart_id)
        expect(result).to be false
      end

      it 'fails reservation when stock becomes insufficient due to other reservations' do
        inventory.reserve('GR1', 8, 'cart_other')
        result = inventory.reserve('GR1', 5, cart_id)

        expect(result).to be false
        expect(inventory.stock_level('GR1')[:reserved]).to eq(8)
        expect(inventory.stock_level('GR1')[:available]).to eq(2)
      end
    end

    context 'edge cases' do
      it 'handles zero quantity reservations' do
        result = inventory.reserve('GR1', 0, cart_id)
        expect(result).to be true
        expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
      end

      it 'handles negative quantity reservations' do
        result = inventory.reserve('GR1', -1, cart_id)
        expect(result).to be true
        expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
      end
    end
  end

  describe '#release' do
    let(:cart_id) { 'cart_123' }

    before do
      inventory.add_product('GR1', units: 10)
      inventory.reserve('GR1', 3, cart_id)
    end

    context 'successful releases' do
      it 'releases reserved stock back to available' do
        inventory.release('GR1', 2, cart_id)

        expect(inventory.stock_level('GR1')[:available]).to eq(9)
        expect(inventory.stock_level('GR1')[:reserved]).to eq(1)
      end

      it 'releases all reserved stock for a product' do
        inventory.release('GR1', 3, cart_id)

        expect(inventory.stock_level('GR1')[:available]).to eq(10)
        expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
      end

      it 'handles partial releases correctly' do
        inventory.reserve('GR1', 2, cart_id) # Total: 5 reserved
        inventory.release('GR1', 1, cart_id)  # Release 1, leaving 4

        expect(inventory.stock_level('GR1')[:reserved]).to eq(4)
        expect(inventory.stock_level('GR1')[:available]).to eq(6)
      end

      it 'handles releases across multiple products' do
        inventory.add_product('SR1', units: 5)
        inventory.reserve('SR1', 2, cart_id)

        inventory.release('GR1', 1, cart_id)
        inventory.release('SR1', 1, cart_id)

        expect(inventory.stock_level('GR1')[:reserved]).to eq(2)
        expect(inventory.stock_level('SR1')[:reserved]).to eq(1)
      end
    end

    context 'edge case releases' do
      it 'handles releasing more than reserved gracefully' do
        inventory.release('GR1', 5, cart_id)

        expect(inventory.stock_level('GR1')[:available]).to eq(10)
        expect(inventory.stock_level('GR1')[:reserved]).to eq(0)
      end

      it 'handles releases for non-existent reservations' do
        result = inventory.release('SR1', 1, cart_id)

        expect(result).to be true
        expect(inventory.stock_level('GR1')[:reserved]).to eq(3) # unchanged
      end

      it 'handles releases for unknown carts' do
        result = inventory.release('GR1', 1, 'unknown_cart')

        expect(result).to be true
        expect(inventory.stock_level('GR1')[:reserved]).to eq(3) # unchanged
      end

      it 'handles zero quantity releases' do
        result = inventory.release('GR1', 0, cart_id)

        expect(result).to be true
        expect(inventory.stock_level('GR1')[:reserved]).to eq(3) # unchanged
      end

      it 'handles negative quantity releases' do
        result = inventory.release('GR1', -1, cart_id)

        expect(result).to be true
        expect(inventory.stock_level('GR1')[:reserved]).to eq(3) # unchanged
      end
    end

    context 'reservation cleanup' do
      it 'cleans up empty product reservations' do
        inventory.release('GR1', 3, cart_id)

        # Should not cause errors on subsequent operations
        result = inventory.release('GR1', 1, cart_id)
        expect(result).to be true
      end

      it 'maintains other cart reservations when releasing' do
        other_cart = 'cart_456'
        inventory.reserve('GR1', 2, other_cart)

        inventory.release('GR1', 3, cart_id)

        expect(inventory.stock_level('GR1')[:reserved]).to eq(2)
        expect(inventory.stock_level('GR1')[:available]).to eq(8)
      end
    end
  end
end
