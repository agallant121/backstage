# frozen_string_literal: true

class RateLimitMiddleware
  Rule = Struct.new(:name, :limit, :period, :match, keyword_init: true)

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    return @app.call(env) if health_check?(request)

    rule = matching_rule(request)
    return @app.call(env) unless rule

    return throttled_response if throttled?(request, rule)

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
        match: ->(request) { request.post? && request.path == "/users/sign_in" }
      ),
      Rule.new(
        name: "signups",
        limit: integer_env("RATE_LIMIT_SIGNUP_PER_MINUTE", 10),
        period: 1.minute,
        match: ->(request) { request.post? && request.path == "/users" }
      ),
      Rule.new(
        name: "group_invites",
        limit: integer_env("RATE_LIMIT_GROUP_INVITES_PER_HOUR", 30),
        period: 1.hour,
        match: ->(request) { request.post? && request.path.match?(%r{\A/groups/\d+/invitations\z}) }
      ),
      Rule.new(
        name: "invitation_acceptance",
        limit: integer_env("RATE_LIMIT_INVITATION_ACCEPT_PER_HOUR", 60),
        period: 1.hour,
        match: ->(request) { request.post? && request.path.match?(%r{\A/invitations/[^/]+/accept\z}) }
      )
    ]
  end

  def throttled?(request, rule)
    key = cache_key(rule.name, request.ip, rule.period)
    count = Rails.cache.read(key).to_i + 1

    Rails.cache.write(key, count, expires_in: rule.period)

    count > rule.limit
  end

  def cache_key(rule_name, ip, period)
    window = Time.current.to_i / period.to_i
    "rate_limit:#{rule_name}:#{ip}:#{window}"
  end

  def health_check?(request)
    request.get? && ["/up", "/ready"].include?(request.path)
  end

  def throttled_response
    [
      429,
      {
        "Content-Type" => "text/plain",
        "Retry-After" => "60"
      },
      ["Too many requests. Please try again later."]
    ]
  end

  def integer_env(key, default)
    Integer(ENV.fetch(key, default))
  rescue ArgumentError, TypeError
    default
  end
end
