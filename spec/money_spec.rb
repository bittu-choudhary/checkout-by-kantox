require 'spec_helper'
require_relative '../lib/money'

RSpec.describe Money do
  describe '#initialize' do
    it 'creates money with amount and currency' do
      money = create(:money)

      expect(money.amount).to eq(10.50)
      expect(money.currency).to eq('GBP')
    end

    it 'defaults to GBP currency' do
      money = create(:money, amount: 5.00)

      expect(money.currency).to eq('GBP')
    end

    it 'handles integer amounts' do
      money = create(:money, amount: 15, currency: 'USD')

      expect(money.amount).to eq(15.0)
    end
  end

  describe '#to_s' do
    it 'formats GBP correctly' do
      money = create(:money, amount: 3.11, currency: 'GBP')

      expect(money.to_s).to eq('£3.11')
    end

    it 'formats USD correctly' do
      money = create(:money, amount: 5.99, currency: 'USD')

      expect(money.to_s).to eq('$5.99')
    end

    it 'formats EUR correctly' do
      money = create(:money, amount: 7.50, currency: 'EUR')

      expect(money.to_s).to eq('€7.50')
    end

    it 'handles zero amounts' do
      money = create(:money, amount: 0.00, currency: 'GBP')

      expect(money.to_s).to eq('£0.00')
    end
  end

  describe 'arithmetic operations' do
    let(:gbp_five) { create(:money, amount: 5.00, currency: 'GBP') }
    let(:gbp_three) { create(:money, amount: 3.00, currency: 'GBP') }
    let(:usd_five) { create(:money, amount: 5.00, currency: 'USD') }

    describe '#add' do
      it 'adds money of same currency' do
        result = gbp_five.add(gbp_three)

        expect(result.amount).to eq(8.00)
        expect(result.currency).to eq('GBP')
      end

      it 'raises error for different currencies' do
        expect { gbp_five.add(usd_five) }.to raise_error(ArgumentError, 'Cannot add different currencies: GBP and USD')
      end
    end

    describe '#subtract' do
      it 'subtracts money of same currency' do
        result = gbp_five.subtract(gbp_three)

        expect(result.amount).to eq(2.00)
        expect(result.currency).to eq('GBP')
      end

      it 'raises error for different currencies' do
        expect { gbp_five.subtract(usd_five) }.to raise_error(ArgumentError, 'Cannot subtract different currencies: GBP and USD')
      end
    end

    describe '#multiply' do
      it 'multiplies by scalar' do
        result = gbp_five.multiply(3)

        expect(result.amount).to eq(15.00)
        expect(result.currency).to eq('GBP')
      end

      it 'handles decimal multipliers' do
        result = gbp_three.multiply(1.5)

        expect(result.amount).to eq(4.50)
      end
    end
  end

  describe 'comparison' do
    let(:gbp_five) { create(:money, amount: 5.00, currency: 'GBP') }
    let(:gbp_three) { create(:money, amount: 3.00, currency: 'GBP') }
    let(:gbp_five_copy) { create(:money, amount: 5.00, currency: 'GBP') }

    it 'compares equal amounts' do
      expect(gbp_five == gbp_five_copy).to be true
    end

    it 'compares different amounts' do
      expect(gbp_five == gbp_three).to be false
    end

    it 'handles greater than comparison' do
      expect(gbp_five > gbp_three).to be true
    end

    it 'handles less than comparison' do
      expect(gbp_three < gbp_five).to be true
    end
  end
end
