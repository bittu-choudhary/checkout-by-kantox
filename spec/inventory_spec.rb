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
end
