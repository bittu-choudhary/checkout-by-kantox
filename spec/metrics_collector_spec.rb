require 'spec_helper'
require_relative '../lib/metrics_collector'

RSpec.describe MetricsCollector do
  let(:metrics) { MetricsCollector.new }

  describe '#initialize' do
    it 'initializes with empty metrics' do
      expect(metrics.metrics[:checkout_operations]).to eq(0)
      expect(metrics.metrics[:total_revenue]).to eq(0.0)
      expect(metrics.metrics[:rule_applications]).to be_a(Hash)
    end
  end

  describe '#record_checkout' do
    it 'records successful checkout' do
      checkout_result = {
        success: true,
        total_amount: 25.50,
        items_count: 3,
        products: ['GR1', 'SR1', 'CF1']
      }

      metrics.record_checkout(checkout_result)

      expect(metrics.metrics[:checkout_operations]).to eq(1)
      expect(metrics.metrics[:total_revenue]).to eq(25.50)
      expect(metrics.metrics[:average_cart_size]).to eq(3.0)
      expect(metrics.metrics[:product_popularity]['GR1']).to eq(1)
    end

    it 'records failed checkout' do
      checkout_result = {
        success: false,
        error_type: 'ValidationError',
        error_message: 'Invalid product code'
      }

      metrics.record_checkout(checkout_result)

      expect(metrics.metrics[:checkout_operations]).to eq(1)
      expect(metrics.metrics[:total_revenue]).to eq(0.0)
      expect(metrics.metrics[:error_counts]['ValidationError']).to eq(1)
    end
  end

  describe '#record_rule_application' do
    it 'tracks rule usage and savings' do
      metrics.record_rule_application('QuantityDiscountRule', 3.11)
      metrics.record_rule_application('BulkFixedPriceRule', 1.50)

      expect(metrics.metrics[:rule_applications]['QuantityDiscountRule']).to eq(1)
      expect(metrics.metrics[:rule_applications]['BulkFixedPriceRule']).to eq(1)
      expect(metrics.metrics[:discount_savings]).to be_within(0.01).of(4.61)
    end
  end

  describe '#get_summary_report' do
    before do
      # Set up some test data
      metrics.record_checkout({
        success: true,
        total_amount: 20.0,
        items_count: 2,
        products: ['GR1', 'SR1']
      })
      metrics.record_checkout({
        success: true,
        total_amount: 30.0,
        items_count: 4,
        products: ['GR1', 'CF1', 'CF1']
      })
      metrics.record_rule_application('QuantityDiscountRule', 5.0)
    end

    it 'generates comprehensive summary' do
      report = metrics.get_summary_report

      expect(report[:total_operations]).to eq(2)
      expect(report[:success_rate]).to eq(100.0)
      expect(report[:financial_summary][:total_revenue]).to eq(50.0)
      expect(report[:financial_summary][:average_order_value]).to eq(25.0)
      expect(report[:top_products]).to include('GR1' => 2, 'CF1' => 2, 'SR1' => 1)
      expect(report[:most_used_rules]).to include('QuantityDiscountRule' => 1)
    end
  end

  describe '#reset_metrics' do
    it 'resets all metrics to initial state' do
      metrics.record_checkout({ success: true, total_amount: 10.0 })
      metrics.record_rule_application('TestRule', 5.0)

      expect(metrics.metrics[:checkout_operations]).to eq(1)

      metrics.reset_metrics

      expect(metrics.metrics[:checkout_operations]).to eq(0)
      expect(metrics.metrics[:total_revenue]).to eq(0.0)
      expect(metrics.metrics[:rule_applications]).to be_empty
    end
  end
end

RSpec.describe GlobalMetrics do
  describe 'singleton behavior' do
    it 'returns same instance' do
      instance1 = GlobalMetrics.instance
      instance2 = GlobalMetrics.instance

      expect(instance1).to be(instance2)
    end

    it 'delegates methods to singleton instance' do
      GlobalMetrics.record_checkout({ success: true, total_amount: 5.0 })

      expect(GlobalMetrics.instance.metrics[:checkout_operations]).to eq(1)
      expect(GlobalMetrics.instance.metrics[:total_revenue]).to eq(5.0)
    end
  end
end

RSpec.describe MetricsMiddleware do
  let(:app) do
    ->(operation) { { total_amount: 15.0, items_count: 2, products: ['GR1'] } }
  end
  let(:middleware) { MetricsMiddleware.new(app) }

  before do
    # Reset global metrics for clean test
    GlobalMetrics.instance.reset_metrics
  end

  describe '#call' do
    it 'tracks successful operations' do
      result = middleware.call({ checkout: true })

      expect(result[:total_amount]).to eq(15.0)
      expect(GlobalMetrics.instance.metrics[:checkout_operations]).to eq(1)
      expect(GlobalMetrics.instance.metrics[:total_revenue]).to eq(15.0)
    end

    it 'tracks failed operations and re-raises errors' do
      failing_app = ->(_operation) { raise StandardError, 'Test error' }
      failing_middleware = MetricsMiddleware.new(failing_app)

      expect {
        failing_middleware.call({ checkout: true })
      }.to raise_error(StandardError, 'Test error')

      expect(GlobalMetrics.instance.metrics[:checkout_operations]).to eq(1)
      expect(GlobalMetrics.instance.metrics[:error_counts]['StandardError']).to eq(1)
    end
  end
end
