class HealthController < ApplicationController
  def up
    render plain: "ok", status: :ok
  end

  def ready
    checks = Platform::ReadinessChecks.new.call

    status = checks.values.all? ? :ok : :service_unavailable
    render json: { status: status == :ok ? "ok" : "degraded", checks: checks }, status: status
  end
end
