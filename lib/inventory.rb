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
end
