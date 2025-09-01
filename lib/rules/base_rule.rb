class BaseRule
  def apply(cart_items)
    raise NotImplementedError, "#{self.class} must implement #apply"
  end

  def applicable?(cart_items)
    true
  end
end
