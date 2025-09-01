# Design Patterns Implementation

This checkout system implements several design patterns that promote code maintainability, extensibility, and separation of concerns.

## 1. Template Method Pattern
**Location:** `BaseRule` → `BulkRuleBase`
- **Purpose:** Defines the skeleton of pricing rule algorithms while allowing subclasses to customize specific steps
- **Implementation:** Base classes define common flow (`applicable?`, `apply`), subclasses implement specific calculations
- **Files:**
  - `lib/rules/base_rule.rb` - Abstract template
  - `lib/rules/bulk_rule_base.rb` - Concrete template with shared bulk logic

## 2. Strategy Pattern
**Location:** `RuleEngine` class
- **Purpose:** Encapsulates different pricing algorithms and makes them interchangeable at runtime
- **Implementation:** Rules array allows dynamic composition of pricing strategies
- **Files:** `lib/rule_engine.rb`
- **Benefits:** Easy to add new rules without modifying existing code

## 3. Inheritance Hierarchy
**Location:** Rule class family
- **Purpose:** Creates reusable discount rule hierarchies with shared behavior
- **Structure:**
  ```
  BaseRule
  ├── BulkRuleBase
  │   ├── BulkPercentageRule
  │   └── BulkFixedPriceRule
  └── QuantityDiscountRule
  ```
- **Files:** `lib/rules/` directory

## 4. Singleton Pattern
**Location:** `GlobalMetrics` class
- **Purpose:** Ensures single instance of metrics collector across the application
- **Implementation:** Thread-safe lazy initialization with `Mutex`
- **Files:** `lib/metrics_collector.rb`
- **Benefits:** Centralized metrics collection without multiple instances

## 5. Decorator/Middleware Pattern
**Location:** `MetricsMiddleware` class
- **Purpose:** Adds metrics collection functionality to existing checkout operations
- **Implementation:** Wraps operations with before/after metric recording
- **Files:** `lib/metrics_collector.rb`
- **Benefits:** Non-intrusive monitoring capabilities

## 6. Repository Pattern
**Location:** `ProductCatalog` and `Inventory` classes
- **Purpose:** Encapsulates data access logic and provides clean interface for data operations
- **Implementation:** Abstract data access behind simple query methods
- **Files:**
  - `lib/product_catalog.rb` - Product data repository
  - `lib/inventory.rb` - Inventory state repository
- **Benefits:** Separation of business logic from data access

## 7. Value Object Pattern
**Location:** `Money` class
- **Purpose:** Represents monetary values as immutable objects with currency awareness
- **Implementation:** Immutable object with value equality and currency validation
- **Files:** `lib/money.rb`
- **Benefits:** Prevents precision errors and currency mixing bugs

## 8. Dependency Injection Pattern
**Location:** `Checkout` and `Cart` classes
- **Purpose:** Reduces coupling by injecting dependencies through constructors
- **Implementation:** Dependencies passed as constructor parameters
- **Files:**
  - `lib/checkout.rb` - Injects pricing rules, catalog, currency converter
  - `lib/cart.rb` - Injects rule engine, currency converter, inventory
- **Benefits:** Improved testability and flexibility
