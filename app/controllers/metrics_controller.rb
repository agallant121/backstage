class MetricsController < ActionController::API
  before_action :authorize_metrics!

  def index
    checks = Platform::ReadinessChecks.new.call
    service = Rails.application.class.module_parent_name.underscore

    payload = [
      metric_line("backstage_readiness_database", "Database readiness", checks[:database], service),
      metric_line("backstage_readiness_cache", "Cache readiness", checks[:cache], service),
      metric_line("backstage_readiness_queue", "Queue readiness", checks[:queue], service)
    ].join("\n")

    render plain: "#{payload}\n", content_type: "text/plain; version=0.0.4; charset=utf-8"
  end

  private

  def authorize_metrics!
    return if ENV["METRICS_TOKEN"].blank?

    token = request.get_header("HTTP_X_METRICS_TOKEN").to_s
    expected = ENV.fetch("METRICS_TOKEN")

    return if ActiveSupport::SecurityUtils.secure_compare(token, expected)

    head :unauthorized
  end

  def metric_line(name, description, healthy, service)
    <<~METRIC.chomp
      # HELP #{name} #{description}
      # TYPE #{name} gauge
      #{name}{service="#{service}"} #{healthy ? 1 : 0}
    METRIC
  end
end
