# frozen_string_literal: true

class RateLimitMiddleware
  Rule = Struct.new(:name, :limit, :period, :match, :keys, :lockout_period, keyword_init: true)

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    return @app.call(env) if health_check?(request)

    rule = matching_rule(request)
    return @app.call(env) unless rule

    throttle = throttled_identifier(request, rule)
    return throttled_response(rule, throttle) if throttle

    @app.call(env)
  end

  private

  def matching_rule(request)
    rules.find { |rule| rule.match.call(request) }
  end

  def rules
    @rules ||= [
      Rule.new(
        name: "logins",
        limit: integer_env("RATE_LIMIT_LOGIN_PER_MINUTE", 10),
        period: 1.minute,
        lockout_period: integer_env("RATE_LIMIT_LOGIN_LOCKOUT_SECONDS", 0).seconds,
        match: ->(request) { request.post? && request.path == "/users/sign_in" },
        keys: lambda do |request|
          {
            ip: request.ip,
            email: normalized_email(request.params.dig("user", "email"))
          }
        end
      ),
      Rule.new(
        name: "signups",
        limit: integer_env("RATE_LIMIT_SIGNUP_PER_MINUTE", 10),
        period: 1.minute,
        lockout_period: integer_env("RATE_LIMIT_SIGNUP_LOCKOUT_SECONDS", 0).seconds,
        match: ->(request) { request.post? && request.path == "/users" },
        keys: ->(request) { { ip: request.ip, email: normalized_email(request.params.dig("user", "email")) } }
      ),
      Rule.new(
        name: "group_invites",
        limit: integer_env("RATE_LIMIT_GROUP_INVITES_PER_HOUR", 30),
        period: 1.hour,
        lockout_period: integer_env("RATE_LIMIT_GROUP_INVITES_LOCKOUT_SECONDS", 0).seconds,
        match: ->(request) { request.post? && request.path.match?(%r{\A/groups/\d+/invitations\z}) },
        keys: ->(request) { { ip: request.ip, user_id: current_user_id(request) } }
      ),
      Rule.new(
        name: "invitation_acceptance",
        limit: integer_env("RATE_LIMIT_INVITATION_ACCEPT_PER_HOUR", 60),
        period: 1.hour,
        lockout_period: integer_env("RATE_LIMIT_INVITATION_ACCEPT_LOCKOUT_SECONDS", 0).seconds,
        match: ->(request) { request.post? && request.path.match?(%r{\A/invitations/[^/]+/accept\z}) },
        keys: ->(request) { { ip: request.ip, invitation_token: request.path_parameters[:token] } }
      )
    ]
  end

  def throttled_identifier(request, rule)
    identifiers(rule, request).find do |identifier|
      key_type, key_value = identifier
      next false if key_value.blank?

      lockout_key = lockout_cache_key(rule.name, key_type, key_value)
      if lockout_active?(lockout_key)
        emit_alert(rule, request, key_type, key_value, :lockout)
        next true
      end

      count = next_count(counter_cache_key(rule.name, key_type, key_value, rule.period), rule.period)
      next false if count <= rule.limit

      apply_lockout(lockout_key, rule.lockout_period)
      emit_alert(rule, request, key_type, key_value, :threshold)
      true
    end
  end

  def counter_cache_key(rule_name, key_type, key_value, period)
    window = Time.current.to_i / period.to_i
    "rate_limit:#{rule_name}:#{key_type}:#{key_value}:#{window}"
  end

  def lockout_cache_key(rule_name, key_type, key_value)
    "rate_limit_lockout:#{rule_name}:#{key_type}:#{key_value}"
  end

  def health_check?(request)
    request.get? && ["/up", "/ready"].include?(request.path)
  end

  def throttled_response(rule, throttle)
    retry_after_seconds = retry_after(rule.period)
    if throttle
      key_type, key_value = throttle
      lockout = read_counter(lockout_cache_key(rule.name, key_type, key_value))
      retry_after_seconds = lockout if lockout.positive?
    end

    [
      429,
      {
        "Content-Type" => "text/plain",
        "Retry-After" => retry_after_seconds.to_s
      },
      ["Too many requests. Please try again later."]
    ]
  end

  def identifiers(rule, request)
    return { ip: request.ip } unless rule.keys

    rule.keys.call(request)
  rescue ActionController::BadRequest, ActionDispatch::Http::Parameters::ParseError
    { ip: request.ip }
  end

  def lockout_active?(lockout_key)
    read_counter(lockout_key).positive?
  end

  def apply_lockout(lockout_key, lockout_period)
    return if lockout_period.blank? || lockout_period <= 0

    Rails.cache.write(lockout_key, lockout_period.to_i, expires_in: lockout_period)
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

  def next_count(key, period)
    count = Rails.cache.increment(key, 1, expires_in: period, initial: 0)

    if count.nil?
      Rails.cache.write(key, 0, expires_in: period, unless_exist: true)
      count = Rails.cache.increment(key, 1, expires_in: period)
    end

    return count.to_i if count.present?

    fallback_increment_counter(key, period)
  rescue NotImplementedError, NoMethodError, ArgumentError
    fallback_increment_counter(key, period)
  end

  def fallback_increment_counter(key, period)
    count = Rails.cache.read(key).to_i + 1
    Rails.cache.write(key, count, expires_in: period)
    count
  end

  def retry_after(period)
    seconds = period.to_i
    remainder = Time.current.to_i % seconds
    remainder.zero? ? seconds : seconds - remainder
  end

  def read_counter(key)
    Rails.cache.read(key).to_i
  rescue StandardError
    0
  end

  def normalized_email(value)
    email = value.to_s.strip.downcase
    email.presence
  end

  def current_user_id(request)
    request.env["warden"]&.user&.id
  rescue StandardError
    nil
  end

  def integer_env(key, default)
    Integer(ENV.fetch(key, default))
  rescue ArgumentError, TypeError
    default
  end
end
