require "net/http"
require "json"

if ENV["ERROR_TRACKING_WEBHOOK_URL"].present?
  webhook_uri = URI.parse(ENV.fetch("ERROR_TRACKING_WEBHOOK_URL"))
  webhook_headers = { "Content-Type" => "application/json" }
  if ENV["ERROR_TRACKING_WEBHOOK_TOKEN"].present?
    webhook_headers["Authorization"] = "Bearer #{ENV.fetch('ERROR_TRACKING_WEBHOOK_TOKEN')}"
  end

  webhook_queue = SizedQueue.new(100)
  worker_count = 2

  worker_count.times do
    Thread.new(webhook_uri, webhook_headers, webhook_queue) do |target_uri, request_headers, queue|
      Thread.current.name = "error-tracking-webhook" if Thread.current.respond_to?(:name=)

      loop do
        body = queue.pop

        http = Net::HTTP.new(target_uri.host, target_uri.port)
        http.use_ssl = target_uri.scheme == "https"
        http.open_timeout = 2
        http.read_timeout = 2

        request = Net::HTTP::Post.new(target_uri.request_uri, request_headers)
        request.body = body
        http.request(request)
      rescue StandardError => e
        Rails.logger.warn("Error tracking webhook delivery failed: #{e.class} #{e.message}")
      end
    end
  end

  Rails.error.subscribe do |error, handled:, severity:, context:, source:|
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

    webhook_queue.push(payload.to_json, true)
  rescue ThreadError
    Rails.logger.warn("Error tracking webhook dropped: delivery queue is full")
  end
end
