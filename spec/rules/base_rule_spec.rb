require 'spec_helper'
require_relative '../../lib/rules/base_rule'

RSpec.describe BaseRule do
  describe '#apply' do
    it 'raises NotImplementedError when called directly' do
      rule = BaseRule.new
      cart_items = {}

      expect { rule.apply(cart_items) }.to raise_error(NotImplementedError)
    end
  end

  describe '#applicable?' do
    it 'returns true by default' do
      rule = BaseRule.new
      cart_items = {}

      expect(rule.applicable?(cart_items)).to be true
    end
  end
end
