require "net/http"
require "json"

if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV.fetch("SENTRY_DSN")
    config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
    config.enabled_environments = ENV.fetch("SENTRY_ENABLED_ENVIRONMENTS", "production").split(",").map(&:strip)
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.0").to_f
    config.send_default_pii = ENV.fetch("SENTRY_SEND_DEFAULT_PII", "false") == "true"
    config.release = ENV["SENTRY_RELEASE"] if ENV["SENTRY_RELEASE"].present?
  end
end

if ENV["ERROR_TRACKING_WEBHOOK_URL"].present?
  webhook_uri = URI.parse(ENV.fetch("ERROR_TRACKING_WEBHOOK_URL"))
  webhook_headers = { "Content-Type" => "application/json" }
  if ENV["ERROR_TRACKING_WEBHOOK_TOKEN"].present?
    webhook_headers["Authorization"] = "Bearer #{ENV.fetch('ERROR_TRACKING_WEBHOOK_TOKEN')}"
  end

  webhook_queue = SizedQueue.new(100)
  worker_count = 2
  shutdown_signal = Object.new

  workers = Array.new(worker_count) do
    Thread.new(webhook_uri, webhook_headers, webhook_queue, shutdown_signal) do |target_uri, request_headers, queue, signal|
      Thread.current.name = "error-tracking-webhook" if Thread.current.respond_to?(:name=)

      http = Net::HTTP.new(target_uri.host, target_uri.port)
      http.use_ssl = target_uri.scheme == "https"
      http.open_timeout = 2
      http.read_timeout = 2

      consecutive_failures = 0

      loop do
        body = queue.pop
        break if body.equal?(signal)

        request = Net::HTTP::Post.new(target_uri.request_uri, request_headers)
        request.body = body
        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          Rails.logger.warn(
            "Error tracking webhook delivery received non-success response: #{response.code} #{response.message}"
          )
        end

        consecutive_failures = 0
      rescue StandardError => e
        consecutive_failures += 1
        backoff = [0.25 * (2**(consecutive_failures - 1)), 5].min
        Rails.logger.warn(
          "Error tracking webhook delivery failed: #{e.class} #{e.message}; retrying in #{backoff}s"
        )
        sleep(backoff)
      end
    end
  end

  at_exit do
    worker_count.times do
      webhook_queue.push(shutdown_signal, true)
    rescue ThreadError
      # Queue full at shutdown; workers will terminate as process exits.
    end

    workers.each { |worker| worker.join(1) }
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
