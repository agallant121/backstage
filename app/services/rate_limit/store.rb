# frozen_string_literal: true

module RateLimit
  class Store
    def initialize(cache: Rails.cache)
      @cache = cache
    end

    def lockout_active?(rule_name, key_type, key_value)
      remaining_lockout_seconds(rule_name, key_type, key_value).positive?
    end

    def remaining_lockout_seconds(rule_name, key_type, key_value)
      expires_at = read_counter(lockout_cache_key(rule_name, key_type, key_value))
      return 0 if expires_at <= 0

      [expires_at - Time.current.to_i, 0].max
    end

    def apply_lockout(rule_name, key_type, key_value, lockout_period)
      return if lockout_period.blank? || lockout_period <= 0

      expires_at = Time.current.to_i + lockout_period.to_i
      @cache.write(lockout_cache_key(rule_name, key_type, key_value), expires_at, expires_in: lockout_period)
    end

    def next_count(rule_name, key_type, key_value, period)
      key = counter_cache_key(rule_name, key_type, key_value, period)
      count = @cache.increment(key, 1, expires_in: period, initial: 0)
      if count.nil?
        @cache.write(key, 0, expires_in: period, unless_exist: true)
        count = @cache.increment(key, 1, expires_in: period)
      end

      return count.to_i if count.present?

      fallback_increment_counter(key, period)
    rescue NotImplementedError, NoMethodError, ArgumentError
      fallback_increment_counter(key, period)
    end

    private

    def counter_cache_key(rule_name, key_type, key_value, period)
      window = Time.current.to_i / period.to_i
      "rate_limit:#{rule_name}:#{key_type}:#{key_value}:#{window}"
    end

    def lockout_cache_key(rule_name, key_type, key_value)
      "rate_limit_lockout:#{rule_name}:#{key_type}:#{key_value}"
    end

    def read_counter(key)
      @cache.read(key).to_i
    rescue StandardError
      0
    end

    # NOTE: This fallback implementation is not guaranteed to be atomic across
    # threads or processes. Some cache backends (for example, in-memory stores)
    # do not support atomic increment operations. In those cases we accept that
    # occasional lost increments may occur under high contention and that rate
    # limits are therefore approximate.
    def fallback_increment_counter(key, period)
      count = read_counter(key) + 1
      @cache.write(key, count, expires_in: period)
      count
    end
  end
end
