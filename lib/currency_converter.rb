require_relative 'money'

class CurrencyConverter
  class UnsupportedCurrencyError < StandardError; end

  DEFAULT_RATES = {
    'GBP' => {
      'USD' => 1.25,
      'EUR' => 1.15
    },
    'USD' => {
      'GBP' => 0.80,
      'EUR' => 0.92
    },
    'EUR' => {
      'GBP' => 0.87,
      'USD' => 1.09
    }
  }.freeze

  def initialize(rates: nil)
    @rates = rates || DEFAULT_RATES.dup
    ensure_bidirectional_rates
  end

  def convert(money, target_currency)
    return money if money.currency == target_currency

    rate = get_rate(money.currency, target_currency)
    converted_amount = money.amount * rate
    Money.new(amount: converted_amount, currency: target_currency)
  end

  def supported_currencies
    @rates.keys.sort
  end

  def get_rate(from_currency, to_currency)
    return 1.0 if from_currency == to_currency

    unless @rates.key?(from_currency)
      raise UnsupportedCurrencyError, "Unsupported source currency: #{from_currency}"
    end

    unless @rates[from_currency].key?(to_currency)
      raise UnsupportedCurrencyError, "No exchange rate available from #{from_currency} to #{to_currency}"
    end

    @rates[from_currency][to_currency]
  end

  def update_rates(new_rates)
    new_rates.each do |from_currency, rates_hash|
      @rates[from_currency] ||= {}
      rates_hash.each do |to_currency, rate|
        @rates[from_currency][to_currency] = rate

        # Ensure bidirectional rates
        @rates[to_currency] ||= {}
        @rates[to_currency][from_currency] = 1.0 / rate
      end
    end
  end

  private

  def ensure_bidirectional_rates
    # Create a copy to avoid modifying hash during iteration
    original_rates = @rates.dup

    original_rates.each do |from_currency, rates_hash|
      rates_hash.each do |to_currency, rate|
        @rates[to_currency] ||= {}
        @rates[to_currency][from_currency] ||= 1.0 / rate
      end
    end

    # Ensure self-referential rates are 1.0
    @rates.keys.each do |currency|
      @rates[currency] ||= {}
      @rates[currency][currency] = 1.0
    end
  end
end
