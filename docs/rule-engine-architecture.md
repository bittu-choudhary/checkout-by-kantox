# Rule Engine Architecture

## Context
The checkout system needs to support flexible pricing rules including:
- Buy-One-Get-One (BOGO) discounts
- Bulk fixed price discounts
- Bulk percentage discounts

The rule engine must be:
- Extensible for future rule types
- Maintainable and testable

## Implementation Details
The checkout system implements a polymorphic rule engine architecture with the following components:

1. **BaseRule**: Abstract base class defining the rule interface
2. **Concrete Rule Classes**: Specific implementations (QuantityDiscountRule, BulkFixedPriceRule, etc.)
3. **RuleEngine**: Orchestrates rule evaluation and conflict resolution

Single Monolithic Rule Class was not considered because it would violate Single Responsibility Principle and make testing difficult.

### Rule Interface
```ruby
class BaseRule
  def applicable?(cart_items, context = {})
  def apply(cart_items)
  def conditions_met?(cart_items, context = {})
end
```

## +ives And -ives

### Positive
- Easy to add new rule types without modifying existing code
- Clear separation of concerns between rule logic and rule orchestration
- Testable individual rule behaviors
- Support for complex rule combinations

### Negative
- Increased complexity compared to simple if/else discount logic
- More classes to maintain
- Potential performance overhead for simple cases
