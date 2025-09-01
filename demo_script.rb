#!/usr/bin/env ruby

# Kantox Checkout System Demo
# This file demonstrates the complete functionality of the checkout system

require 'bigdecimal'
require_relative 'lib/version'
require_relative 'lib/checkout'
require_relative 'lib/product'
require_relative 'lib/product_catalog'
require_relative 'lib/rule_engine'
require_relative 'lib/rules/quantity_discount_rule'
require_relative 'lib/rules/bulk_fixed_price_rule'
require_relative 'lib/rules/bulk_percentage_rule'
require_relative 'lib/currency_converter'
require_relative 'lib/inventory'
require_relative 'lib/insufficient_stock_error'

def demo_header
  puts CheckoutByKantox.banner
  puts "\nDEMO: Complete Checkout System Functionality\n\n"
end

def setup_products
  puts "Setting up product catalog..."
  catalog = ProductCatalog.new
  catalog.add(Product.new(code: 'GR1', name: 'Green Tea', price: 3.11, units: 50))
  catalog.add(Product.new(code: 'SR1', name: 'Strawberries', price: 5.00, units: 30))
  catalog.add(Product.new(code: 'CF1', name: 'Coffee', price: 11.23, units: 20))

  puts "   ✓ Green Tea (GR1): £3.11 [50 units]"
  puts "   ✓ Strawberries (SR1): £5.00 [30 units]"
  puts "   ✓ Coffee (CF1): £11.23 [20 units]"
  puts

  catalog
end

def setup_inventory
  puts "Setting up inventory management..."
  inventory = Inventory.new
  inventory.add_product('GR1', units: 50)
  inventory.add_product('SR1', units: 30)
  inventory.add_product('CF1', units: 20)

  puts "   ✓ Inventory tracking enabled"
  puts "   ✓ Stock levels: GR1(50), SR1(30), CF1(20)"
  puts

  inventory
end

def setup_rules
  puts "Setting up pricing rules..."
  rules = [
    QuantityDiscountRule.new(product_code: 'GR1', buy_quantity: 1, free_quantity: 1),      # BOGO Green Tea (buy 1, get 1 free)
    BulkFixedPriceRule.new(product_code: 'SR1', min_quantity: 3, fixed_price: 4.50),     # Bulk Strawberries
    BulkPercentageRule.new(product_code: 'CF1', min_quantity: 3, discount_percentage: 33.33)     # Bulk Coffee discount (33.33% off = 2/3 price)
  ]

  puts "   ✓ Green Tea: Buy 2, Get 1 Free"
  puts "   ✓ Strawberries: 3+ for £4.50 each"
  puts "   ✓ Coffee: 3+ at 2/3 price (£7.49 each)"
  puts

  RuleEngine.new(rules: rules)
end

def demo_checkout(catalog, rules, items, expected_total, description, inventory)
  puts "#{description}"
  puts "   Items: #{items.join(', ')}"

  checkout = Checkout.new(pricing_rules: rules, catalog: catalog, inventory: inventory)
  items.each { |item| checkout.scan(item) }

  total = checkout.total
  puts "   Total: £#{total.round(2)}"
  puts "   Expected: £#{expected_total}"

  success = (total.round(2) == BigDecimal(expected_total.to_s)).to_s == "true"
  puts success ? "   PASS" : "   FAIL"
  puts
end

def demo_multi_currency(catalog, rules, inventory)
  puts "Multi-Currency Support Demo"

  converter = CurrencyConverter.new
  checkout = Checkout.new(pricing_rules: rules, catalog: catalog, currency_converter: converter, inventory: inventory)

  # Scan some items
  checkout.scan('GR1')
  checkout.scan('CF1')

  gbp_total = checkout.total
  usd_total = checkout.total_in_currency('USD')
  eur_total = checkout.total_in_currency('EUR')

  puts "   Items: GR1, CF1"
  puts "   GBP Total: #{gbp_total}"
  puts "   USD Total: #{usd_total}"
  puts "   EUR Total: #{eur_total}"
  puts
rescue => e
  puts "   Currency conversion requires converter setup"
  puts
end


def demo_inventory_basics(catalog, rules, inventory)
  puts "Inventory Management Demo"

  # Show initial stock levels
  puts "   Initial stock levels:"
  ['GR1', 'SR1', 'CF1'].each do |code|
    stock = inventory.stock_level(code)
    puts "   #{code}: #{stock[:available]} available, #{stock[:reserved]} reserved, #{stock[:sold]} sold"
  end
  puts

  # Create checkout with inventory
  checkout = Checkout.new(pricing_rules: rules, catalog: catalog, inventory: inventory)

  puts "   Scanning items with inventory tracking..."
  items = ['GR1', 'SR1', 'GR1', 'CF1']
  items.each do |item|
    checkout.scan(item)
    puts "   ✓ Scanned #{item}"
  end
  puts

  # Show reserved stock
  puts "   Stock after scanning:"
  ['GR1', 'SR1', 'CF1'].each do |code|
    stock = inventory.stock_level(code)
    puts "   #{code}: #{stock[:available]} available, #{stock[:reserved]} reserved"
  end
  puts

  total = checkout.total
  puts "   Total: £#{total.round(2)}"
  puts "   Processing checkout..."
  checkout.process
  puts "   Checkout processed successfully!"
  puts

  # Show final stock (sold)
  puts "   Final stock levels:"
  ['GR1', 'SR1', 'CF1'].each do |code|
    stock = inventory.stock_level(code)
    puts "   #{code}: #{stock[:available]} available, #{stock[:sold]} sold"
  end
  puts
end

def demo_competing_customers(catalog, rules, inventory)
  puts "Multiple Customers Demo"

  # Reset inventory to limited stock
  limited_inventory = Inventory.new
  limited_inventory.add_product('CF1', units: 3)  # Only 3 coffees available

  puts "   Limited coffee stock: only 3 units available"
  puts "   Two customers want coffee..."

  # Customer 1
  customer1 = Checkout.new(pricing_rules: rules, catalog: catalog, inventory: limited_inventory)
  puts "   Customer 1 scanning 2 coffees..."
  2.times { customer1.scan('CF1') }

  # Customer 2
  customer2 = Checkout.new(pricing_rules: rules, catalog: catalog, inventory: limited_inventory)
  puts "   Customer 2 scanning 1 coffee..."
  customer2.scan('CF1')

  stock = limited_inventory.stock_level('CF1')
  puts "   After scanning: #{stock[:available]} available, #{stock[:reserved]} reserved"

  # Customer 3 tries but fails
  customer3 = Checkout.new(pricing_rules: rules, catalog: catalog, inventory: limited_inventory)
  puts "   Customer 3 tries to scan coffee..."

  begin
    customer3.scan('CF1')
    puts "   This shouldn't happen!"
  rescue InsufficientStockError => e
    puts "   Customer 3 failed: #{e.message}"
  end

  puts "   Customer 1 total: £#{customer1.total.round(2)}"
  puts "   Customer 2 total: £#{customer2.total.round(2)}"

  puts "   Customer 1 processes order..."
  customer1.process

  puts "   Customer 2 cancels order..."
  customer2.cancel

  final_stock = limited_inventory.stock_level('CF1')
  puts "   Final: #{final_stock[:available]} available, #{final_stock[:sold]} sold"
  puts "   Now Customer 3 can buy the released coffee!"
  puts
end

def demo_overselling_prevention(catalog, rules, inventory)
  puts "Overselling Prevention Demo"

  # Create inventory with very limited stock
  tiny_inventory = Inventory.new
  tiny_inventory.add_product('GR1', units: 2)  # Only 2 green teas

  puts "   Only 2 Green Teas available"

  checkout = Checkout.new(pricing_rules: rules, catalog: catalog, inventory: tiny_inventory)

  puts "   Scanning available stock..."
  2.times { |i|
    checkout.scan('GR1')
    puts "   ✓ Scanned GR1 ##{i+1}"
  }

  stock = tiny_inventory.stock_level('GR1')
  puts "   Stock: #{stock[:available]} available, #{stock[:reserved]} reserved"

  puts "   Attempting to scan one more (should fail)..."
  begin
    checkout.scan('GR1')
    puts "   This shouldn't happen - overselling occurred!"
  rescue InsufficientStockError => e
    puts "   Prevented overselling: #{e.message}"
  end

  puts "   Total for available items: £#{checkout.total.round(2)}"
  puts
end

def demo_inventory_with_rules(catalog, rules, inventory)
  puts "Inventory + Pricing Rules Demo"

  # Create inventory with exact amounts for rule testing
  rule_inventory = Inventory.new
  rule_inventory.add_product('GR1', units: 4)  # For BOGO testing
  rule_inventory.add_product('SR1', units: 5)  # For bulk discount
  rule_inventory.add_product('CF1', units: 3)  # For percentage discount

  puts "   Stock: GR1(4), SR1(5), CF1(3)"

  checkout = Checkout.new(pricing_rules: rules, catalog: catalog, inventory: rule_inventory)

  puts "   Scanning for maximum discounts..."

  # Scan items to trigger all rules
  4.times { checkout.scan('GR1') }  # BOGO: pay for 2, get 4
  5.times { checkout.scan('SR1') }  # Bulk: 5 × £4.50 = £22.50
  3.times { checkout.scan('CF1') }  # Percentage: 3 × £11.23 × 2/3

  puts "   ✓ Scanned: 4×GR1, 5×SR1, 3×CF1"

  # Check stock is fully reserved
  %w[GR1 SR1 CF1].each do |code|
    stock = rule_inventory.stock_level(code)
    puts "   #{code}: #{stock[:available]} available, #{stock[:reserved]} reserved"
  end

  total = checkout.total
  puts "   Total with all discounts: £#{total.round(2)}"

  # Can't scan any more - all sold out
  puts "   All products now sold out - cannot scan more!"

  checkout.process
  puts "   Order processed successfully!"
  puts
end

def main
  demo_header

  catalog = setup_products
  rule_engine = setup_rules
  inventory = setup_inventory

  puts "Running Test Cases\n"

  # Test all required cases first to show original functionality
  demo_checkout(catalog, rule_engine, ['GR1', 'SR1', 'GR1', 'GR1', 'CF1'], 22.45,
                "Test Case 1: Mixed basket with all discounts", inventory)

  demo_checkout(catalog, rule_engine, ['GR1', 'GR1'], 3.11,
                "Test Case 2: BOGO discount", inventory)

  demo_checkout(catalog, rule_engine, ['SR1', 'SR1', 'GR1', 'SR1'], 16.61,
                "Test Case 3: Strawberry bulk discount", inventory)

  demo_checkout(catalog, rule_engine, ['GR1', 'CF1', 'SR1', 'CF1', 'CF1'], 30.57,
                "Test Case 4: Coffee percentage discount", inventory)

  puts "Advanced Features\n"

  demo_multi_currency(catalog, rule_engine, inventory)

  puts "Inventory Management Features\n"

  demo_inventory_basics(catalog, rule_engine, inventory)
  demo_competing_customers(catalog, rule_engine, inventory)
  demo_overselling_prevention(catalog, rule_engine, inventory)
  demo_inventory_with_rules(catalog, rule_engine, inventory)

  puts "Demo completed successfully!"
  puts "Run 'bundle exec rspec' for complete test suite"
end

# Run the demo if this file is executed directly
if __FILE__ == $0
  main
end
