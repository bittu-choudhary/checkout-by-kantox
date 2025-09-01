class Inventory
  def initialize
    @products = {}
    @reservations = {}
  end

  def add_product(product_code, units:)
    @products[product_code] = {
      total_units: units,
      reserved_units: 0,
      sold_units: 0
    }
  end

  def stock_level(product_code)
    product = @products[product_code] || { total_units: 0, reserved_units: 0, sold_units: 0 }
    {
      total: product[:total_units],
      reserved: product[:reserved_units],
      available: product[:total_units] - product[:reserved_units] - product[:sold_units]
    }
  end

  def available?(product_code, quantity)
    return false unless @products.key?(product_code)
    return true if quantity <= 0

    stock = stock_level(product_code)
    stock[:available] >= quantity
  end

  def reserve(product_code, quantity, cart_id)
    return true if quantity <= 0
    return false unless available?(product_code, quantity)

    @products[product_code][:reserved_units] += quantity

    @reservations[cart_id] ||= {}
    @reservations[cart_id][product_code] ||= 0
    @reservations[cart_id][product_code] += quantity

    true
  end
end
