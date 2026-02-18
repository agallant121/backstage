require "net/http"
require "json"

if ENV["ERROR_TRACKING_WEBHOOK_URL"].present?
  Rails.error.subscribe do |error, handled:, severity:, context:, source:|
    uri = URI.parse(ENV.fetch("ERROR_TRACKING_WEBHOOK_URL"))

    payload = {
      application: Rails.application.class.module_parent_name,
      environment: Rails.env,
      handled: handled,
      severity: severity,
      source: source,
      error_class: error.class.name,
      error_message: error.message,
      backtrace: Array(error.backtrace).first(20),
      context: context,
      occurred_at: Time.current.iso8601
    }

    headers = { "Content-Type" => "application/json" }
    if ENV["ERROR_TRACKING_WEBHOOK_TOKEN"].present?
      headers["Authorization"] = "Bearer #{ENV.fetch('ERROR_TRACKING_WEBHOOK_TOKEN')}"
    end

    Thread.new(uri, payload.to_json, headers) do |target_uri, body, request_headers|
      http = Net::HTTP.new(target_uri.host, target_uri.port)
      http.use_ssl = target_uri.scheme == "https"
      request = Net::HTTP::Post.new(target_uri.request_uri, request_headers)
      request.body = body
      http.request(request)
    rescue StandardError => e
      Rails.logger.warn("Error tracking webhook delivery failed: #{e.class} #{e.message}")
    end
  end
end
