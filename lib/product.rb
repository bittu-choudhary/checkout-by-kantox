require_relative 'money'

class Product
  attr_reader :code, :name, :price

  def initialize(code:, name:, price:, currency: 'GBP')
    @code = code
    @name = name
    @price = price.is_a?(Money) ? price : Money.new(amount: price, currency: currency)
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
