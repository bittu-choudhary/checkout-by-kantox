require 'spec_helper'
require_relative '../../lib/rules/bulk_rule_base'

RSpec.describe BulkRuleBase do
  let(:concrete_rule) do
    Class.new(BulkRuleBase) do
      def calculate_discount(items, quantity)
        5.0
      end
    end
  end

  describe '#calculate_discount' do
    it 'raises NotImplementedError when called directly' do
      rule = BulkRuleBase.new('TEST', 2)

      expect { rule.send(:calculate_discount, [], 2) }.to raise_error(NotImplementedError)
    end
  end

  describe 'concrete implementation' do
    let(:rule) { concrete_rule.new('TEST', 2) }
    let(:product) { double('Product', price: 10.0) }
    let(:cart_items) { { 'TEST' => [product, product] } }

    it 'uses concrete calculate_discount implementation' do
      discount = rule.apply(cart_items)
      expect(discount).to eq(5.0)
    end
  end
end
