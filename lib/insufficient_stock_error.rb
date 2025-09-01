class InsufficientStockError < StandardError
  attr_reader :product_code, :requested, :available

  def initialize(product_code, requested, available)
    @product_code = product_code
    @requested = requested
    @available = available

    shortage = requested - available
    super("Insufficient stock for product '#{product_code}': requested: #{requested}, available: #{available}, shortage: #{shortage}")
  end
end
