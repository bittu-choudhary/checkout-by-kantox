class Cart
  attr_accessor :items

  def initialize(rule_engine: nil, currency_converter: nil, base_currency: 'GBP')
    @items = []
    @rule_engine = rule_engine
    @currency_converter = currency_converter
    @base_currency = base_currency
  end

  def total
    if @items.empty?
      return Money.new(amount: 0, currency: @base_currency)
    end

    subtotal = calculate_subtotal_in_base_currency
    discount_amount = @rule_engine && @rule_engine.respond_to?(:apply_rules) ? @rule_engine.apply_rules(grouped_items) : 0
    discount = Money.new(amount: discount_amount, currency: @base_currency)

    result = subtotal.subtract(discount)
    result.amount < 0 ? Money.new(amount: 0, currency: @base_currency) : result
  end

  def add(product)
    @items << product
  end

  def items
    @items.dup
  end

  def grouped_items
    @items.group_by(&:code)
  end

  private

  def calculate_subtotal_in_base_currency
    return Money.new(amount: 0, currency: @base_currency) if @items.empty?

    converted_prices = @items.map do |item|
      price = item.price
      if @currency_converter && price.currency != @base_currency
        @currency_converter.convert(price, @base_currency)
      else
        price
      end
    end

    # Now all prices should be in the same currency, so we can safely reduce
    if converted_prices.first.currency == @base_currency
      converted_prices.reduce(&:add)
    else
      # Fallback: convert all to base currency amounts and sum
      total_amount = converted_prices.sum(&:amount)
      Money.new(amount: total_amount, currency: @base_currency)
    end
  end
end
