require 'json'

# Production metrics collection system for monitoring checkout
class MetricsCollector
  attr_reader :metrics

  def initialize
    @metrics = {
      checkout_operations: 0,
      total_revenue: 0.0,
      average_cart_size: 0.0,
      rule_applications: Hash.new(0),
      error_counts: Hash.new(0),
      product_popularity: Hash.new(0),
      discount_savings: 0.0,
      hourly_stats: Hash.new { |h, k| h[k] = { checkouts: 0, revenue: 0.0 } },
      daily_stats: Hash.new { |h, k| h[k] = { checkouts: 0, revenue: 0.0 } }
    }
    @start_time = Time.now
  end

  def record_checkout(checkout_result)
    @metrics[:checkout_operations] += 1

    if checkout_result[:success]
      record_successful_checkout(checkout_result)
    else
      record_failed_checkout(checkout_result)
    end

    update_time_based_stats(checkout_result)
  end

  def record_rule_application(rule_type, discount_amount)
    @metrics[:rule_applications][rule_type] += 1
    @metrics[:discount_savings] += discount_amount
  end

  def record_error(error_type, error_message = nil)
    @metrics[:error_counts][error_type] += 1

    # Log detailed error information
    error_detail = {
      type: error_type,
      message: error_message,
      timestamp: Time.now,
      operation_count: @metrics[:checkout_operations]
    }

    (@error_log ||= []) << error_detail
  end

  def get_summary_report
    {
      system_uptime: Time.now - @start_time,
      total_operations: @metrics[:checkout_operations],
      success_rate: calculate_success_rate,
      financial_summary: {
        total_revenue: @metrics[:total_revenue],
        total_savings: @metrics[:discount_savings],
        average_order_value: calculate_average_order_value
      },
      top_products: get_top_products(5),
      most_used_rules: get_most_used_rules(5),
      error_summary: get_error_summary
    }
  end

  def reset_metrics
    initialize
  end

  private

  def record_successful_checkout(result)
    @metrics[:total_revenue] += result[:total_amount] || 0

    # Update cart size average
    items_count = result[:items_count] || 0
    total_items = @metrics[:average_cart_size] * (@metrics[:checkout_operations] - 1) + items_count
    @metrics[:average_cart_size] = total_items / @metrics[:checkout_operations]

    # Track product popularity
    if result[:products]
      result[:products].each do |product_code|
        @metrics[:product_popularity][product_code] += 1
      end
    end
  end

  def record_failed_checkout(result)
    error_type = result[:error_type] || 'unknown_error'
    record_error(error_type, result[:error_message])
  end

  def update_time_based_stats(result)
    now = Time.now
    hour_key = now.strftime('%Y-%m-%d %H:00')
    day_key = now.strftime('%Y-%m-%d')

    revenue = result[:total_amount] || 0

    @metrics[:hourly_stats][hour_key][:checkouts] += 1
    @metrics[:hourly_stats][hour_key][:revenue] += revenue

    @metrics[:daily_stats][day_key][:checkouts] += 1
    @metrics[:daily_stats][day_key][:revenue] += revenue
  end

  def calculate_success_rate
    return 100.0 if @metrics[:checkout_operations] == 0

    total_errors = @metrics[:error_counts].values.sum
    successful_operations = @metrics[:checkout_operations] - total_errors
    (successful_operations.to_f / @metrics[:checkout_operations] * 100).round(2)
  end

  def calculate_average_order_value
    return 0.0 if @metrics[:checkout_operations] == 0
    (@metrics[:total_revenue] / @metrics[:checkout_operations]).round(2)
  end

  def get_top_products(limit)
    @metrics[:product_popularity]
      .sort_by { |_, count| -count }
      .first(limit)
      .to_h
  end

  def get_most_used_rules(limit)
    @metrics[:rule_applications]
      .sort_by { |_, count| -count }
      .first(limit)
      .to_h
  end

  def get_error_summary
    {
      total_errors: @metrics[:error_counts].values.sum,
      error_types: @metrics[:error_counts].dup,
      error_rate: (100.0 - calculate_success_rate).round(2)
    }
  end
end

# Singleton metrics collector for global access
class GlobalMetrics
  @instance = nil
  @mutex = Mutex.new

  def self.instance
    return @instance if @instance

    @mutex.synchronize do
      @instance ||= MetricsCollector.new
    end
  end

  def self.method_missing(method, *args, &block)
    instance.send(method, *args, &block)
  end

  def self.respond_to_missing?(method, include_private = false)
    instance.respond_to?(method, include_private) || super
  end
end

# Metrics middleware for automatic checkout tracking
class MetricsMiddleware
  def initialize(app)
    @app = app
    @metrics = GlobalMetrics.instance
  end

  def call(checkout_operation)

    begin
      result = @app.call(checkout_operation)

      @metrics.record_checkout({
        success: true,
        total_amount: result[:total_amount],
        items_count: result[:items_count],
        products: result[:products]
      })

      result
    rescue => error
      @metrics.record_checkout({
        success: false,
        error_type: error.class.name,
        error_message: error.message
      })

      raise error
    end
  end
end
