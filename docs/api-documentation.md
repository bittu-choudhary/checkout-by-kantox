# API Documentation

## Core Classes

### Checkout

The main entry point for scanning items and calculating totals.

```ruby
checkout = Checkout.new(pricing_rules: pricing_rules, product_catalog: product_catalog, currency_converter: currency_converter, base_currency: base_currency, inventory: inventory)
```

**Parameters:**
- `pricing_rules`: Array of rule objects (QuantityDiscountRule, BulkFixedPriceRule, etc.)
- `product_catalog`: ProductCatalog instance for product lookup
- `currency_converter`: CurrencyConverter instance for multi-currency support (optional)
- `inventory`: Inventory instance for stock management (optional, keyword parameter)

**Methods:**

#### `scan(item)`
Scans a product by code or product object.
```ruby
checkout.scan('GR1')  # By product code
checkout.scan(product)  # By product object
```

#### `total`
Returns the total amount.
```ruby
total = checkout.total
puts total  # => £22.45
```

#### `total_in_currency(currency_code)`
Returns total converted to specified currency.
```ruby
usd_total = checkout.total_in_currency('USD')
```

#### `process()`
Commits all reserved inventory to sold state.
```ruby
checkout.process  # Returns true on success
```

#### `cancel()`
Releases all reserved inventory back to available state.
```ruby
checkout.cancel  # Returns true on success
```

### Product

Represents a product with code, name, and price.

```ruby
product = Product.new(code: 'GR1', name: 'Green Tea', price: 3.11, currency: 'GBP', units: 50)
```

**Attributes:**
- `code`: String product identifier
- `name`: Human-readable product name
- `price`: Money object representing the price or price itself
- `currency`: Currency if price is not a Money object
- `units`: Integer for initial inventory units

### Money

Immutable money class with precise decimal arithmetic.

```ruby
money = Money.new(amount: 3.11, currency: 'GBP')
```

**Operations:**
```ruby
add = money1 + money2
subtract = money1 - money2
multiply = money * 2
```

### ProductCatalog

Manages product inventory and lookup.

```ruby
catalog = ProductCatalog.new
catalog.add(product)
found_product = catalog.find('GR1')
```

## Inventory Management

### Inventory

Manages stock levels with reservation-based inventory tracking.

```ruby
inventory = Inventory.new
inventory.add_product('GR1', units: 50)
```

**Methods:**

#### `add_product(product_code, units:)`
Adds a product to inventory tracking.
```ruby
inventory.add_product('GR1', units: 50)
```

#### `stock_level(product_code)`
Returns current stock information.
```ruby
stock = inventory.stock_level('GR1')
# Returns: { total: 50, reserved: 2, sold: 3, available: 45 }
```

#### `available?(product_code, quantity)`
Checks if sufficient stock is available.
```ruby
if inventory.available?('GR1', 3)
  # Sufficient stock available
end
```

#### `reserve(product_code, quantity, cart_id)`
Reserves stock for a cart.
```ruby
success = inventory.reserve('GR1', 2, 'cart_123')
```

#### `release(product_code, quantity, cart_id)`
Releases reserved stock back to available.
```ruby
inventory.release('GR1', 1, 'cart_123')
```

#### `commit(cart_id)`
Commits all reservations for a cart to sold state.
```ruby
inventory.commit('cart_123')
```

#### `cancel(cart_id)`
Releases all reservations for a cart.
```ruby
inventory.cancel('cart_123')
```

### InsufficientStockError

Custom exception raised when insufficient stock is available.

```ruby
unless @inventory.available?('GR1', 1)
  stock = @inventory.stock_level(product.code)
  raise InsufficientStockError.new(product.code, 1, stock[:available])
end

unless @inventory.reserve('GR1', 1, 'cart1')
  stock = @inventory.stock_level(product.code)
  raise InsufficientStockError.new(product.code, 1, stock[:available])
end
```

```text
error_message = "Insufficient stock for product 'GR1': requested: 2, available: 1, shortage: 1"
```

**Attributes:**
- `product_code`: Product that caused the error
- `requested`: Quantity that was requested
- `available`: Quantity actually available

### Cart

The Cart class automatically integrates with inventory when provided.

```ruby
# With inventory integration
cart = Cart.new(rule_engine, converter, base_currency,
                inventory: inventory, cart_id: cart_id)
```

**Inventory Integration:**
- Automatically reserves stock when items are added
- Releases stock when items are removed
- Raises InsufficientStockError when stock unavailable

## Pricing Rules

### QuantityDiscountRule (BOGO)

Buy-One-Get-One discount rule.

```ruby
rule = QuantityDiscountRule.new(product_code: 'GR1', buy_quantity: 2, free_quantity: 1)  # Buy 2, get 1 free
```

**Parameters:**
- `product_code`: Product this rule applies to
- `buy_quantity`: Quantity that triggers discount
- `free_quantity`: Number of free items

### BulkFixedPriceRule

Fixed price for bulk purchases.

```ruby
rule = BulkFixedPriceRule.new(product_code: 'SR1', min_quantity: 3, fixed_price: 4.50)  # 3 or more for £4.50 each
```

**Parameters:**
- `product_code`: Product this rule applies to
- `min_quantity`: Minimum quantity for bulk pricing
- `fixed_price`: Price per item when bulk threshold is met

### BulkPercentageRule

Percentage discount for bulk purchases.

```ruby
rule = BulkPercentageRule.new(product_code: 'CF1', min_quantity: 3, discount_percentage: 33.33)  # 2/3 price (33.33% off)
```

**Parameters:**
- `product_code`: Product this rule applies to
- `min_quantity`: Minimum quantity for discount
- `discount_percentage`: Final price percentage (66.67 = 2/3 price)

## Rule Engine

Evaluates and applies pricing rules.

```ruby
engine = RuleEngine.new(rules)
discount = engine.apply_rules(cart_items)
```

## Multi-Currency Support

### CurrencyConverter

Handles currency conversion with configurable exchange rates.

```ruby
converter = CurrencyConverter.new(rates: nil)
usd_money = converter.convert(gbp_money, 'USD')
```

**Supported Currencies:** GBP, USD, EUR

## Monitoring & Observability

### MetricsCollector

Real-time metrics collection for production monitoring.

```ruby
metrics = MetricsCollector.new
metrics.record_checkout(checkout_result)
```

**Metrics Collected:**
- Checkout operations and revenue
- Error rates and types

## Example Usage

```ruby
# Setup
catalog = ProductCatalog.new

grean_tea = Product.new(code: 'GR1', name: 'Green Tea', price: 3.11, units: 50)
strawberries = Product.new(code: 'SR1', name: 'Strawberries', price: 5.00, units: 50)
coffee = Product.new(code: 'CF1', name: 'Coffee', price: 11.23, units: 50)

catalog.add(grean_tea)
catalog.add(strawberries)
catalog.add(coffee)

# Rules
rules = [
  QuantityDiscountRule.new(product_code: 'GR1', buy_quantity: 2, free_quantity: 1),  # BOGO
  BulkFixedPriceRule.new(product_code: 'SR1', min_quantity: 3, fixed_price: 4.50), # Bulk discount
  BulkPercentageRule.new(product_code: 'CF1', min_quantity: 3, discount_percentage: 33.33) # Percentage discount
]

# Setup with inventory
inventory = Inventory.new
inventory.add_product('GR1', units: 50)
inventory.add_product('SR1', units: 30)
inventory.add_product('CF1', units: 20)

# Checkout with inventory
checkout = Checkout.new(pricing_rules: rules, catalog: catalog, inventory: inventory)

# Scanning automatically reserves stock
checkout.scan('GR1')  # Reserves 1 GR1
checkout.scan('SR1')  # Reserves 1 SR1
checkout.scan('GR1')  # Reserves 1 more GR1
checkout.scan('GR1')  # Reserves 1 more GR1
checkout.scan('CF1')  # Reserves 1 CF1

# Check inventory state
stock = inventory.stock_level('GR1')
puts "GR1: #{stock[:available]} available, #{stock[:reserved]} reserved"

puts checkout.total  # => £22.45

# Complete the purchase
checkout.process  # Commits all reservations to sold

# Or cancel to release reservations
# checkout.cancel  # Releases all reservations back to available
```
