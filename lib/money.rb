class Money
  attr_reader :amount, :currency

  CURRENCY_SYMBOLS = {
    'GBP' => '£',
    'USD' => '$',
    'EUR' => '€'
  }.freeze

  def initialize(amount:, currency: 'GBP')
    @amount = amount.to_f
    @currency = currency
  end

  def to_s
    symbol = CURRENCY_SYMBOLS[@currency] || @currency
    "#{symbol}#{'%.2f' % @amount}"
  end

  def add(other)
    validate_same_currency(other)
    Money.new(amount: @amount + other.amount, currency: @currency)
  end

  def subtract(other)
    validate_same_currency(other)
    Money.new(amount: @amount - other.amount, currency: @currency)
  end

  def multiply(scalar)
    Money.new(amount: @amount * scalar, currency: @currency)
  end

  def ==(other)
    return false unless other.is_a?(Money)
    @amount == other.amount && @currency == other.currency
  end

  def >(other)
    validate_same_currency(other)
    @amount > other.amount
  end

  def <(other)
    validate_same_currency(other)
    @amount < other.amount
  end

  private

  def validate_same_currency(other)
    unless @currency == other.currency
      raise ArgumentError, "Cannot #{caller_locations(1,1)[0].label.gsub('_', ' ')} different currencies: #{@currency} and #{other.currency}"
    end
  end
end
