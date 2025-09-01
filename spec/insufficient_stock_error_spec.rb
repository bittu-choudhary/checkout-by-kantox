require 'spec_helper'
require_relative '../lib/insufficient_stock_error'

RSpec.describe InsufficientStockError do
  describe '#initialize' do
    it 'creates error with product code, requested and available quantities' do
      error = InsufficientStockError.new('GR1', 5, 2)

      expect(error).to be_a(StandardError)
      expect(error.product_code).to eq('GR1')
      expect(error.requested).to eq(5)
      expect(error.available).to eq(2)
    end

    it 'creates error with zero available stock' do
      error = InsufficientStockError.new('SR1', 3, 0)

      expect(error.product_code).to eq('SR1')
      expect(error.requested).to eq(3)
      expect(error.available).to eq(0)
    end

    it 'has readable attributes' do
      error = InsufficientStockError.new('CF1', 10, 4)

      expect(error).to respond_to(:product_code)
      expect(error).to respond_to(:requested)
      expect(error).to respond_to(:available)
    end
  end

  describe '#message' do
    it 'provides descriptive error message' do
      error = InsufficientStockError.new('GR1', 5, 2)

      expect(error.message).to include('Insufficient stock')
      expect(error.message).to include('GR1')
      expect(error.message).to include('requested: 5')
      expect(error.message).to include('available: 2')
    end

    it 'handles zero available stock in message' do
      error = InsufficientStockError.new('SR1', 1, 0)

      expect(error.message).to include('Insufficient stock')
      expect(error.message).to include('SR1')
      expect(error.message).to include('available: 0')
    end

    it 'provides clear shortage information' do
      error = InsufficientStockError.new('CF1', 8, 3)

      message = error.message
      expect(message).to match(/shortage.*5/)  # 8 - 3 = 5 short
    end
  end

  describe 'exception behavior' do
    it 'can be raised and caught as StandardError' do
      expect {
        raise InsufficientStockError.new('GR1', 5, 2)
      }.to raise_error(StandardError)
    end

    it 'can be raised and caught as InsufficientStockError' do
      expect {
        raise InsufficientStockError.new('SR1', 3, 1)
      }.to raise_error(InsufficientStockError)
    end

    it 'provides error details when caught' do
      begin
        raise InsufficientStockError.new('CF1', 7, 2)
      rescue InsufficientStockError => e
        expect(e.product_code).to eq('CF1')
        expect(e.requested).to eq(7)
        expect(e.available).to eq(2)
      end
    end
  end

  describe 'edge cases' do
    it 'handles very large quantity requests' do
      error = InsufficientStockError.new('GR1', 999999, 50)

      expect(error.requested).to eq(999999)
      expect(error.available).to eq(50)
      expect(error.message).to include('999999')
    end

    it 'handles zero requested with zero available' do
      error = InsufficientStockError.new('SR1', 0, 0)

      expect(error.requested).to eq(0)
      expect(error.available).to eq(0)
    end

    it 'handles string product codes' do
      error = InsufficientStockError.new('PRODUCT_123', 5, 1)

      expect(error.product_code).to eq('PRODUCT_123')
      expect(error.message).to include('PRODUCT_123')
    end
  end
end
