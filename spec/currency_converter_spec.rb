require 'spec_helper'
require_relative '../lib/currency_converter'
require_relative '../lib/money'

RSpec.describe CurrencyConverter do
  let(:converter) { CurrencyConverter.new }

  describe '#initialize' do
    it 'creates converter with default exchange rates' do
      expect(converter).to be_a(CurrencyConverter)
    end

    it 'accepts custom exchange rates' do
      custom_rates = { 'USD' => { 'GBP' => 0.80 } }
      custom_converter = CurrencyConverter.new(rates: custom_rates)
      expect(custom_converter).to be_a(CurrencyConverter)
    end
  end

  describe '#convert' do
    context 'with same currency' do
      it 'returns original amount for same currency' do
        gbp_money = create(:money, amount: 10.00)
        result = converter.convert(gbp_money, 'GBP')

        expect(result).to be_a(Money)
        expect(result.amount).to eq(10.00)
        expect(result.currency).to eq('GBP')
      end
    end

    context 'with different currencies' do
      it 'converts GBP to USD' do
        gbp_money = create(:money, amount: 10.00)
        result = converter.convert(gbp_money, 'USD')

        expect(result).to be_a(Money)
        expect(result.currency).to eq('USD')
        expect(result.amount).to be > 10.00 # GBP should be worth more than USD
      end

      it 'converts USD to GBP' do
        usd_money =create(:money, amount: 10.00, currency: 'USD')
        result = converter.convert(usd_money, 'GBP')

        expect(result).to be_a(Money)
        expect(result.currency).to eq('GBP')
        expect(result.amount).to be < 10.00 # USD should be worth less than GBP
      end

      it 'converts GBP to EUR' do
        gbp_money = create(:money, amount: 10.00)
        result = converter.convert(gbp_money, 'EUR')

        expect(result).to be_a(Money)
        expect(result.currency).to eq('EUR')
        expect(result.amount).to be > 10.00 # GBP should be worth more than EUR
      end

      it 'handles decimal precision correctly' do
        gbp_money =create(:money, amount: 3.11)
        result = converter.convert(gbp_money, 'USD')

        expect(result.amount).to be_within(0.01).of(3.11 * 1.25) # Approximate USD rate
      end
    end

    context 'with unsupported currencies' do
      it 'raises error for unknown source currency' do
        fake_money = create(:money, amount: 10.00, currency: 'XXX')

        expect { converter.convert(fake_money, 'GBP') }.to raise_error(CurrencyConverter::UnsupportedCurrencyError)
      end

      it 'raises error for unknown target currency' do
        gbp_money = create(:money, amount: 10.00)

        expect { converter.convert(gbp_money, 'YYY') }.to raise_error(CurrencyConverter::UnsupportedCurrencyError)
      end
    end
  end

  describe '#supported_currencies' do
    it 'returns array of supported currency codes' do
      currencies = converter.supported_currencies

      expect(currencies).to be_an(Array)
      expect(currencies).to include('GBP', 'USD', 'EUR')
    end
  end

  describe '#get_rate' do
    it 'returns exchange rate between currencies' do
      rate = converter.get_rate('GBP', 'USD')

      expect(rate).to be_a(Numeric)
      expect(rate).to be > 1.0 # GBP should be worth more than 1 USD
    end

    it 'returns 1.0 for same currency' do
      rate = converter.get_rate('GBP', 'GBP')
      expect(rate).to eq(1.0)
    end

    it 'calculates inverse rates correctly' do
      gbp_to_usd = converter.get_rate('GBP', 'USD')
      usd_to_gbp = converter.get_rate('USD', 'GBP')

      expect(usd_to_gbp).to be_within(0.001).of(1.0 / gbp_to_usd)
    end
  end

  describe '#update_rates' do
    it 'updates exchange rates' do
      old_rate = converter.get_rate('GBP', 'USD')

      converter.update_rates({ 'GBP' => { 'USD' => 2.0 } })
      new_rate = converter.get_rate('GBP', 'USD')

      expect(new_rate).to eq(2.0)
      expect(new_rate).not_to eq(old_rate)
    end

    it 'maintains bidirectional rate consistency' do
      converter.update_rates({ 'GBP' => { 'USD' => 1.5 } })

      gbp_to_usd = converter.get_rate('GBP', 'USD')
      usd_to_gbp = converter.get_rate('USD', 'GBP')

      expect(gbp_to_usd).to eq(1.5)
      expect(usd_to_gbp).to be_within(0.001).of(1.0 / 1.5)
    end
  end
end
