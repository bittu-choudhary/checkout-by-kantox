# Checkout By Kantox

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
  - [Original Problem Statement](#original-problem-statement)
  - [Products](#products)
  - [Pricing Rules](#pricing-rules)
  - [Interface Requirement](#interface-requirement)
  - [Technical Requirements](#technical-requirements)
  - [Test Cases](#test-cases)
- [Assignment Scope & Constraints](#assignment-scope--constraints)
- [Architectural Decisions](#architectural-decisions)
  - [Strategy Pattern for Pricing Rules](#strategy-pattern-for-pricing-rules)
  - [Template Method for Rule Hierarchies](#template-method-for-rule-hierarchies)
  - [Composition Over Inheritance for Checkout](#composition-over-inheritance-for-checkout)
  - [Money as Value Object](#money-as-value-object)
- [Core Design Principles](#core-design-principles)
- [Testing Strategy](#testing-strategy)
  - [Test-Driven Development Approach](#test-driven-development-approach)
  - [Test Categories](#test-categories)
- [Performance & Scalability Analysis](#performance--scalability-analysis)
  - [Current Performance Characteristics](#current-performance-characteristics)
  - [Performance Optimizations (If Needed)](#performance-optimizations-if-needed)
- [Extension Strategy](#extension-strategy)
  - [Adding New Pricing Rules](#adding-new-pricing-rules)
  - [Rule Priority System (Future)](#rule-priority-system-future)
- [Error Handling Strategy](#error-handling-strategy)
  - [Error Categories](#error-categories)
  - [Error Handling Pattern](#error-handling-pattern)
- [Business Context & Trade-offs](#business-context--trade-offs)
  - [Business Requirements Priority](#business-requirements-priority)
- [Implementation Highlights](#implementation-highlights)
  - [Key Classes](#key-classes)
  - [Critical Implementation Details](#critical-implementation-details)
- [Testing Results](#testing-results)
  - [Test Coverage](#test-coverage)
  - [Test Case Validation](#test-case-validation)
- [Quick Start](#quick-start)
  - [Basic Usage](#basic-usage)

---

## Overview
This directory contains documentation for the Kantox Checkout System, including technical specifications, inventory management, and implementation guides.

**Key Results:**
- All test cases passing with exact expected totals
- Clean, testable architecture supporting easy rule additions
- 98% test coverage with comprehensive test suite

## Requirements

### Original Problem Statement

You are the lead programmer for a small chain of supermarkets. You need to build a cashier function that adds products to a cart, applies pricing rules, and displays the total price.

### Products

| Product Code | Name         | Price  |
|--------------|--------------|--------|
| GR1          | Green tea    | £3.11  |
| SR1          | Strawberries | £5.00  |
| CF1          | Coffee       | £11.23 |

### Pricing Rules

1. **Green Tea (GR1)**: Buy-one-get-one-free
2. **Strawberries (SR1)**: Bulk discount - price drops to £4.50 when buying 3 or more
3. **Coffee (CF1)**: Bulk discount - price drops to 2/3 of original when buying 3 or more

### Interface Requirement

```ruby
co = Checkout.new(pricing_rules)
co.scan(item)
co.scan(item)
price = co.total
```

### Technical Requirements

- Use Ruby language (not Ruby on Rails)
- Use TDD (Test-Driven Development) methodology
- Use of DB is not required

### Test Cases

The following test cases must pass exactly:

#### Test Case 1
**Basket:** GR1,SR1,GR1,GR1,CF1
**Expected Total:** £22.45

#### Test Case 2
**Basket:** GR1,GR1
**Expected Total:** £3.11

#### Test Case 3
**Basket:** SR1,SR1,GR1,SR1
**Expected Total:** £16.61

#### Test Case 4
**Basket:** GR1,CF1,SR1,CF1,CF1
**Expected Total:** £30.57

## Assignment Scope & Constraints

**Core Focus:** Demonstrate clean architecture and extensible design
**Constraints:** Small supermarket chain (current scale), Ruby-only,
no database

**Intentionally Excluded:** Given 5-day constraint
- Events: Event-driven architecture for real-time rule changes and
checkout notifications
- Audit Trail: Comprehensive logging and tracking of all pricing
decisions and cart modifications
- Performance Optimizer: Caching, memoization, and rule execution
optimization for high-volume scenarios
- Rule Configuration: Dynamic rule management via yaml/json
- Rule Priority: Priority-based rule ordering and execution control
mechanisms
- Conditional Rules: Time-based, customer-segment, or
location-specific rule conditions
- Rule Conflict Resolution: Automated detection and resolution of
competing or contradictory pricing rules

**Demonstrated Instead:**
- Checkout: Clean orchestration of scanning, cart management, and
total calculation with dependency injection
- RuleEngine: Strategy pattern implementation for flexible rule
composition and application
- Money: Precision financial calculations with currency awareness and
immutable value object design
- Cart: Inventory-integrated shopping cart with automatic stock
reservation and error handling
- BaseRule/BulkRuleBase: Template method pattern foundation for
extensible pricing rule hierarchies
- QuantityDiscountRule: Buy-one-get-one-free implementation with
flexible quantity configuration
- BulkFixedPriceRule/BulkPercentageRule: Bulk pricing strategies with
shared logic abstraction
- ProductCatalog: Repository pattern for clean product data access
and management
- Inventory: Comprehensive stock tracking with reservation system and
transaction safety
- CurrencyConverter: Multi-currency support with bidirectional rate
management and error handling
- MetricsCollector/GlobalMetrics: Monitoring with
singleton pattern and comprehensive analytics

## Architectural Decisions

### Strategy Pattern for Pricing Rules
**Decision:** Use Strategy pattern with rule engine for pricing logic
**Rationale:**
- Requirement for multiple pricing algorithms suggests Strategy pattern
- Problem statement suggests rules will change frequently
- Strategy enables adding rules without modifying existing code (Open/Closed Principle)

**Alternatives Considered:**
- Conditional logic in checkout class (rejected: violates Open/Closed)
- Rule inheritance only (rejected: doesn't handle rule combinations)

### Template Method for Rule Hierarchies
**Decision:** Use Template Method pattern for bulk pricing rules
**Ratational:**
- BulkFixedPrice and BulkPercentage share identical logic except calculation step
- Template Method eliminates duplication while preserving flexibility
- Follows DRY principle without sacrificing extensibility

### Composition Over Inheritance for Checkout
**Decision:** Inject pricing rules into Checkout via constructor
**Rationale:**
- Enables different pricing configurations without subclassing
- Improves testability (can mock rule engine)
- Supports runtime rule configuration changes

### Money as Value Object
**Decision:** Implement Money class for currency calculations
**Rationale:**
- Prevents floating-point precision errors in financial calculations
- Makes currency explicit and type-safe
- Foundation for multi-currency support

**Trade-off:** Added complexity for single-currency requirement, but eliminates entire class of financial bugs and allowed us to support multi currency.

## Core Design Principles

### 1. Single Responsibility Principle
- `Checkout`: Orchestrates scanning and total calculation
- `RuleEngine`: Applies pricing rules to cart
- Each rule class: Single pricing algorithm
- `Money`: Currency calculations and representation

### 2. Open/Closed Principle
- Adding new pricing rules requires zero changes to existing code
- New rules implement `BaseRule` interface
- `RuleEngine` automatically handles new rule types

### 3. Liskov Substitution Principle
- All rule implementations are interchangeable
- Any `BaseRule` subclass works with `RuleEngine`

### 4. Interface Segregation Principle
- `BaseRule` defines minimal interface: `applicable?` and `apply`
- No client depends on methods it doesn't use

### 5. Dependency Inversion Principle
- `Checkout` depends on rule abstraction, not concrete rules
- Rules injected via constructor, enabling flexible configurations
### 6. [Used Design Patterns](docs/used-design-patterns.md)
  List of all design patterns used

## Testing Strategy

### Test-Driven Development Approach
1. **Red**: Write failing test for requirement
2. **Green**: Implement minimal code to pass
3. **Refactor**: Improve design while maintaining green tests

### Test Categories

#### 1. Unit Tests (Primary Focus)
- Each class tested in isolation
- Mock dependencies to test behavior, not implementation
- Edge cases and error conditions thoroughly covered

#### 2. Integration Tests
- End-to-end test cases matching exact requirements
- `Checkout` integration with real rule implementations
- Test rule combinations and interactions

#### 3. Usage
```bash
# Run all tests
bundle exec rspec

# Run with coverage
bundle exec rspec --format documentation

# Run specific test suites
bundle exec rspec spec/checkout_spec.rb
bundle exec rspec spec/rules/
```

## Performance & Scalability Analysis

### Current Performance Characteristics

#### Time Complexity
- Scanning: O(1) per item
- Total calculation: O(n*r) where n = items, r = rules
- Memory: O(n) for cart storage

#### Performance Bottlenecks (Theoretical)
1. Rule evaluation for large carts
2. Money object creation overhead
3. String-based product code lookups

#### Performance Optimizations (If Needed)
1. Rule short-circuiting (exit early if rule not applicable)
2. Memoization of expensive calculations
3. Product code indexing for large catalogs

## Extension Strategy

### Adding New Pricing Rules

#### Simple Rules
```ruby
class FreeShippingRule < BaseRule
  def initialize(min_purchase:)
    @min_purchase = min_purchase
  end

  def applicable?(cart_items)
    cart_total(cart_items) >= @min_purchase
  end

  def apply(cart_items)
    # Return shipping discount amount
  end
end
```

#### Complex Rules
- Time-based rules (happy hour discounts)
- Combination rules (buy X get Y free)
- Customer-specific rules (loyalty discounts)
- Category-based rules (all produce 20% off)

### Rule Priority System (Future)
```ruby
class PriorityRuleEngine < RuleEngine
  def apply_rules(cart_items)
    @rules
      .sort_by(&:priority)
      .reduce(0) { |total, rule| total + apply_rule(rule, cart_items) }
  end
end
```

## Error Handling Strategy

### Error Categories

#### 1. Business Rule Violations
- Out of stock → `InsufficientStockError`
Custom exception raised when insufficient stock is available.

```text
error_message = "Insufficient stock for product 'GR1': requested: 2, available: 1, shortage: 1"
```

### Error Handling Pattern
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

## Business Context & Trade-offs

### Business Requirements Priority
1. **Correctness**: Exact test case compliance (non-negotiable)
2. **Maintainability**: Easy to add new rules (high business value)
3. **Extensibility**: Support growth (important for future)

## Implementation Highlights

### Key Classes

#### Checkout
**Responsibilities:** Session management, item scanning, total calculation
**Key Design:** Composition-based with injected dependencies

#### RuleEngine
**Responsibilities:** Rule orchestration and application
**Key Design:** Strategy pattern with rule collection

#### Money
**Responsibilities:** Financial calculations with precision
**Key Design:** Immutable value object with currency awareness

#### BaseRule Hierarchy
**Responsibilities:** Encapsulate pricing algorithms
**Key Design:** Template Method + Strategy patterns combined

#### [API Documentation](docs/api-documentation.md)
  Complete list of classes and endpoints available


### Critical Implementation Details

#### Rule Application Order
- Rules applied in array order (predictable behavior)
- Each rule sees current cart state
- Total discount = sum of all applicable discounts

## Testing Results

### Test Coverage
- **Unit Tests**: 98.55% line coverage
- **Integration Tests**: All required test cases passing
- **Edge Cases**: Null inputs, empty carts, zero prices handled

### Test Case Validation
```
PASSED Test Case 1: GR1,SR1,GR1,GR1,CF1 → £22.45
PASSED Test Case 2: GR1,GR1 → £3.11
PASSED Test Case 3: SR1,SR1,GR1,SR1 → £16.61
PASSED Test Case 4: GR1,CF1,SR1,CF1,CF1 → £30.57
```

## Quick Start

### Basic Usage

Check - [API Documentation](docs/api-documentation.md) OR [Demo Script](demo_script.rb) for basic usage.

---
