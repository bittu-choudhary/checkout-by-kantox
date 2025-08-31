class Cart
  attr_accessor :items

  def initialize
    @items = []
  end

  def total
    @items.sum(&:price)
  end

  def add(product)
    @items << product
  end

  def items
    @items.dup
  end
end
