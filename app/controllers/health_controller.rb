class HealthController < ApplicationController
  def up
    render plain: "ok", status: :ok
  end

  def ready
    checks = {
      database: database_ready?,
      cache: cache_ready?,
      queue: queue_ready?
    }

    status = checks.values.all? ? :ok : :service_unavailable
    render json: { status: status == :ok ? "ok" : "degraded", checks: checks }, status: status
  end

  private

  def database_ready?
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.active? && connection.select_value("SELECT 1").to_i == 1
    end
  rescue StandardError
    false
  end

  def cache_ready?
    key = "healthcheck:#{SecureRandom.hex(8)}"
    Rails.cache.write(key, "ok", expires_in: 1.minute)
    Rails.cache.read(key) == "ok"
  rescue StandardError
    false
  ensure
    Rails.cache.delete(key) if key
  end

  def queue_ready?
    return true unless defined?(SolidQueue::Record)

    SolidQueue::Record.connection_pool.with_connection do |connection|
      connection.active? && connection.select_value("SELECT 1").to_i == 1
    end
  rescue StandardError
    false
  end
end
