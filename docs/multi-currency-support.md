# Multi-Currency Support Design

## Context
The checkout system needs to support multiple currencies for international operations:
- Products priced in different base currencies (GBP, EUR, USD, etc.)
- Real-time currency conversion for checkout
- Supporting currency-specific pricing rules

Main challenges include:
- Floating-point precision issues in financial calculations
- Currency conversion rate management
- Rounding behavior differences between currencies
- Price display formatting requirements
- Exchange rate volatility handling

## Implementation Details
The checkout system implements a multi-currency system with:

1. **Money Value Object**: Immutable money representation with currency
2. **Currency Converter**: Real-time exchange rate handling
3. **Precision Management**: Decimal-based calculations to avoid float errors
4. **Localized Formatting**: Currency-appropriate display formatting

### Core Components
- `Money` class with currency and amount
- `CurrencyConverter` for real-time rate fetching
- Decimal arithmetic throughout the system
- Currency formatting utilities

### Money Value Object
```ruby
class Money
  include Comparable

  attr_reader :amount, :currency

  def initialize(amount, currency)
    @amount = BigDecimal(amount.to_s)
    @currency = currency.to_s.upcase
  end

  def +(other)
    ensure_same_currency(other)
    Money.new(@amount + other.amount, @currency)
  end

  def to_s
    CurrencyFormatter.format(@amount, @currency)
  end
end
```

### Currency Conversion Strategy
```ruby
class CurrencyConverter
  def convert(money, target_currency)
    return money if money.currency == target_currency

    rate = get_exchange_rate(money.currency, target_currency)
    converted_amount = money.amount * rate

    Money.new(converted_amount, target_currency)
  end

  private

  def get_rate(from_currency, to_currency)
    # Invalid case handling
    @rates[from_currency][to_currency]
  end
end
```

## +ives And -ives

### Positive
- Accurate financial calculations without precision loss
- Support for international markets and currencies
- Flexible currency-specific pricing strategies
- Easy addition of new currencies

### Negative
- Increased complexity in arithmetic operations
- Need for exchange rate management
- More complex testing scenarios
