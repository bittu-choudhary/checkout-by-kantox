class Product
  attr_reader :code, :name, :price

  def initialize(code:, name:, price:)
    @code = code
    @name = name
    @price = price
  end

  def ==(other)
    return false unless other.is_a?(Product)
    code == other.code
  end

  alias eql? ==

  def hash
    code.hash
  end
end
