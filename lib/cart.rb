class Cart
  attr_accessor :items

  def initialize(rule_engine: nil)
    @items = []
    @rule_engine = rule_engine
  end

  def total
    subtotal = @items.sum(&:price)
    discount = @rule_engine && @rule_engine.respond_to?(:apply_rules) ? @rule_engine.apply_rules(grouped_items) : 0
    [subtotal - discount, 0].max
  end

  def add(product)
    @items << product
  end

  def items
    @items.dup
  end

  def grouped_items
    @items.group_by(&:code)
  end
end
