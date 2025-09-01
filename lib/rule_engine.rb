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
        discount = rule.apply(cart_items)
        total_discount += discount

        # Record rule application for metrics if discount was applied
        if discount > 0 && defined?(GlobalMetrics)
          GlobalMetrics.record_rule_application(rule.class.name, discount)
        end
      end
    end

    total_discount
  end
end
