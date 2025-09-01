# Inventory Management System

## Context
The Checkout System implements inventory management capabilities to prevent overselling and track stock levels in real-time.

## Implementation Details

### Architecture Design
1. **Reservation-Based Stock Management**: Uses a three-state inventory model (Available, Reserved, Sold)
2. **Automatic Integration**: Integrates inventory checking directly into the Cart and Checkout classes
3. **Thread-Safe Operations**: Implements atomic stock operations to handle concurrent checkout scenarios

### Core Components
1. **Inventory Class**: Central inventory management with hash-based storage
2. **InsufficientStockError**: Custom exception for stock shortage scenarios
3. **Cart Integration**: Automatic stock reservation on scan, release on remove
4. **Checkout Lifecycle**: Process/cancel methods for inventory commitment/release

### Key Design Patterns
1. **Reservation Pattern**: Reserve stock when items are scanned, commit on purchase
2. **Cart-ID Tracking**: Use unique cart identifiers to track reservations per checkout session
3. **Error Recovery**: Comprehensive error handling with detailed stock information

### Inventory Data Model
```ruby
@products = {
  'GR1' => {
    total_units: 50,
    reserved_units: 3,
    sold_units: 5
    # available = total - reserved - sold = 42
  }
}

@reservations = {
  'cart_123' => {
    'GR1' => 2,
    'CF1' => 1
  }
}
```

### Integration Points
1. **Cart.add()**: Automatically checks inventory and reserves stock
2. **Cart.remove()**: Releases reserved stock back to available
3. **Checkout.process()**: Commits all cart reservations to sold state
4. **Checkout.cancel()**: Releases all cart reservations back to available
