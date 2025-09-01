class Cart
  attr_accessor :items

  def initialize(rule_engine: nil)
    @items = []
    @rule_engine = rule_engine
  end

  def total
    if @items.empty?
      return Money.new(amount: 0, currency: 'GBP')
    end

    subtotal = @items.map(&:price).reduce(&:add)
    discount_amount = @rule_engine && @rule_engine.respond_to?(:apply_rules) ? @rule_engine.apply_rules(grouped_items) : 0
    discount = Money.new(amount: discount_amount, currency: subtotal.currency)

    result = subtotal.subtract(discount)
    result.amount < 0 ? Money.new(amount: 0, currency: subtotal.currency) : result
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
