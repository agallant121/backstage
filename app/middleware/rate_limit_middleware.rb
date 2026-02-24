# frozen_string_literal: true

class RateLimitMiddleware
  def initialize(app, rule_set: RateLimit::RuleSet.new, store: RateLimit::Store.new)
    @app = app
    @rule_set = rule_set
    @store = store
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    return @app.call(env) if health_check?(request)

    rule = @rule_set.matching_rule(request)
    return @app.call(env) unless rule

    throttle = throttled_identifier(request, rule)
    return throttled_response(rule, throttle) if throttle

    @app.call(env)
  end

  private

  def throttled_identifier(request, rule)
    identifiers(rule, request).find do |key_type, key_value|
      next false if key_value.blank?
      return true if lockout_active?(rule, request, key_type, key_value)

      count = @store.next_count(rule.name, key_type, key_value, rule.period)
      next false if count <= rule.limit

      @store.apply_lockout(rule.name, key_type, key_value, rule.lockout_period)
      emit_alert(rule, request, key_type, key_value, :threshold)
      true
    end
  end

  def lockout_active?(rule, request, key_type, key_value)
    return false unless @store.lockout_active?(rule.name, key_type, key_value)

    emit_alert(rule, request, key_type, key_value, :lockout)
    true
  end

  def throttled_response(rule, throttle)
    retry_after_seconds = retry_after(rule.period)
    if throttle
      key_type, key_value = throttle
      remaining = @store.remaining_lockout_seconds(rule.name, key_type, key_value)
      retry_after_seconds = remaining if remaining.positive?
    end

    [429, { "Content-Type" => "text/plain", "Retry-After" => retry_after_seconds.to_s }, ["Too many requests. Please try again later."]]
  end

  def identifiers(rule, request)
    return { ip: request.ip } unless rule.keys

    rule.keys.call(request)
  rescue ActionController::BadRequest, ActionDispatch::Http::Parameters::ParseError
    { ip: request.ip }
  end

  def emit_alert(rule, request, key_type, key_value, reason)
    payload = {
      rule: rule.name,
      request_path: request.path,
      method: request.request_method,
      source_ip: request.ip,
      key_type: key_type,
      key_value: key_value,
      reason: reason
    }
    Rails.logger.warn("[security][rate_limit] #{payload}")
    ActiveSupport::Notifications.instrument("security.rate_limit_triggered", payload)
  end

  def health_check?(request)
    request.get? && ["/up", "/ready"].include?(request.path)
  end

  def retry_after(period)
    seconds = period.to_i
    remainder = Time.current.to_i % seconds
    remainder.zero? ? seconds : seconds - remainder
  end
end
