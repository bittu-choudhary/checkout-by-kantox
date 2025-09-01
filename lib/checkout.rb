require_relative 'cart'
require_relative 'metrics_collector'

class Checkout
  attr_reader :inventory, :cart_id, :cart

  def initialize(pricing_rules:, catalog: nil, currency_converter: nil, base_currency: 'GBP', inventory:, metrics_collector: nil)
    @pricing_rules = pricing_rules
    @catalog = catalog
    @currency_converter = currency_converter
    @base_currency = base_currency
    @inventory = inventory
    @cart_id = SecureRandom.uuid
    @processed = false
    @cancelled = false
    @metrics_collector = metrics_collector || GlobalMetrics.instance
    @start_time = Time.now
    @cart = Cart.new(rule_engine: pricing_rules, currency_converter: @currency_converter, base_currency: @base_currency, inventory: @inventory, cart_id: @cart_id)
  end

  def scan(item)
    begin
      product = resolve_product(item)
      @cart.add(product)
    rescue => error
      @metrics_collector.record_error('scan_error', error.message)
      raise error
    end
  end

  def total
    begin
      result = @cart.total
      amount = result.is_a?(Money) ? result.amount : result
      # Extract products for metrics
      products = @cart.items.map { |item| item.respond_to?(:code) ? item.code : 'unknown' }

      @metrics_collector.record_checkout({
        success: true,
        total_amount: amount,
        items_count: @cart.items.length,
        products: products.uniq
      })
      amount
    rescue => error
      @metrics_collector.record_checkout({
        success: false,
        error_type: error.class.name,
        error_message: error.message
      })
      raise error
    end
  end

  def total_money
    base_total = @cart.total
    return base_total unless @currency_converter

    # Convert total to base currency if it's not already
    if base_total.currency != @base_currency
      @currency_converter.convert(base_total, @base_currency)
    else
      base_total
    end
  end

  def total_in_currency(target_currency)
    raise ArgumentError, "Currency converter not available" unless @currency_converter

    base_total = @cart.total
    @currency_converter.convert(base_total, target_currency)
  end

  def process
    raise RuntimeError, "Checkout already processed" if @processed
    raise RuntimeError, "Cannot process checkout that has been cancelled" if @cancelled

    if @inventory && @cart_id
      @inventory.commit(@cart_id)
    end

    @processed = true
    true
  end

  def cancel
    raise RuntimeError, "Checkout already cancelled" if @cancelled
    raise RuntimeError, "Cannot cancel checkout that has been processed" if @processed

    if @inventory && @cart_id
      @inventory.cancel(@cart_id)
    end

    @cancelled = true
    true
  end

  private

  def resolve_product(item)
    return item if item.respond_to?(:price)

    if @catalog
      product = @catalog.find(item)
      raise ArgumentError, "Product not found: #{item}" unless product
      return product
    end

    item
  end
end
