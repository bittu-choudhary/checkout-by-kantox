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
      sold: product[:sold_units],
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

  def release(product_code, quantity, cart_id)
    return true if quantity <= 0
    return true unless @products.key?(product_code)
    return true unless @reservations.key?(cart_id)
    return true unless @reservations[cart_id].key?(product_code)

    reserved_for_cart = @reservations[cart_id][product_code]
    release_amount = [quantity, reserved_for_cart].min

    @products[product_code][:reserved_units] -= release_amount
    @reservations[cart_id][product_code] -= release_amount

    if @reservations[cart_id][product_code] == 0
      @reservations[cart_id].delete(product_code)
      @reservations.delete(cart_id) if @reservations[cart_id].empty?
    end

    true
  end

  def commit(cart_id)
    return true unless @reservations[cart_id]

    @reservations[cart_id].each do |product_code, quantity|
      @products[product_code][:reserved_units] -= quantity
      @products[product_code][:sold_units] += quantity
    end

    @reservations.delete(cart_id)
    true
  end
end
