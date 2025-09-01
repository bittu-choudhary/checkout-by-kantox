class RuleEngine
  def initialize(rules: [])
    @rules = rules.dup
  end

  def add_rule(rule)
    @rules << rule
  end

  def apply_rules(cart_items)
    total_discount = 0

    @rules.each do |rule|
      if rule.applicable?(cart_items)
        total_discount += rule.apply(cart_items)
      end
    end

    total_discount
  end
end
