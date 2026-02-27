# frozen_string_literal: true

module RateLimit
  class RuleSet
    Rule = Struct.new(:name, :limit, :period, :match, :keys, :lockout_period, keyword_init: true)

    def initialize(env_fetcher: ENV.method(:fetch))
      @env_fetcher = env_fetcher
    end

    def matching_rule(request)
      rules.find { |rule| rule.match.call(request) }
    end

    private

    def rules
      @rules ||= [
        Rule.new(
          name: "logins",
          limit: integer_env("RATE_LIMIT_LOGIN_PER_MINUTE", 10),
          period: 1.minute,
          lockout_period: integer_env("RATE_LIMIT_LOGIN_LOCKOUT_SECONDS", 0).seconds,
          match: ->(request) { request.post? && request.path == "/users/sign_in" },
          keys: lambda do |request|
            { ip: request.ip, email: normalized_email(request.params.dig("user", "email")) }
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
          keys: ->(request) { { ip: request.ip, invitation_token: invitation_token_from_path(request.path) } }
        )
      ]
    end

    def normalized_email(value)
      value.to_s.strip.downcase.presence
    end

    def invitation_token_from_path(path)
      path.match(%r{\A/invitations/([^/]+)/accept\z})&.captures&.first
    end

    def current_user_id(request)
      request.env["warden"]&.user&.id
    rescue StandardError
      nil
    end

    def integer_env(key, default)
      Integer(@env_fetcher.call(key, default))
    rescue ArgumentError, TypeError
      default
    end
  end
end
