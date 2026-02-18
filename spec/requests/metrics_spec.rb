require "rails_helper"

RSpec.describe "Metrics", type: :request do
  describe "GET /metrics" do
    it "exports prometheus formatted readiness metrics" do
      get "/metrics"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to start_with("text/plain")
      expect(response.body).to include("# TYPE backstage_readiness_database gauge")
      expect(response.body).to include("# TYPE backstage_readiness_cache gauge")
      expect(response.body).to include("# TYPE backstage_readiness_queue gauge")
    end

    it "requires X-Metrics-Token when METRICS_TOKEN is configured" do
      original = ENV.fetch("METRICS_TOKEN", nil)
      ENV["METRICS_TOKEN"] = "secret-token"

      get "/metrics"
      expect(response).to have_http_status(:unauthorized)

      get "/metrics", headers: { "X-Metrics-Token" => "secret-token" }
      expect(response).to have_http_status(:ok)
    ensure
      ENV["METRICS_TOKEN"] = original
    end
  end
end
