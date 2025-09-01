require 'spec_helper'
require_relative '../lib/rule_engine'
require_relative '../lib/rules/base_rule'

RSpec.describe RuleEngine do
  let(:rule_engine) { RuleEngine.new }

  describe '#initialize' do
    it 'creates empty rule engine' do
      expect(rule_engine).to be_a(RuleEngine)
    end

    it 'accepts initial rules' do
      rule = BaseRule.new
      engine = RuleEngine.new(rules: [rule])
      expect(engine).to be_a(RuleEngine)
    end
  end

  describe '#add_rule' do
    it 'adds rule to engine' do
      rule = BaseRule.new
      expect { rule_engine.add_rule(rule) }.not_to raise_error
    end
  end

  describe '#apply_rules' do
    let(:cart_items) { {} }

    it 'returns 0 discount when no rules' do
      discount = rule_engine.apply_rules(cart_items)
      expect(discount).to eq(0)
    end

    context 'with mock rule' do
      let(:mock_rule) do
        rule = double('MockRule')
        allow(rule).to receive(:applicable?).and_return(true)
        allow(rule).to receive(:apply).and_return(5.0)
        rule
      end

      it 'applies applicable rules' do
        rule_engine.add_rule(mock_rule)
        discount = rule_engine.apply_rules(cart_items)

        expect(discount).to eq(5.0)
        expect(mock_rule).to have_received(:applicable?).with(cart_items)
        expect(mock_rule).to have_received(:apply).with(cart_items)
      end
    end
  end
end
