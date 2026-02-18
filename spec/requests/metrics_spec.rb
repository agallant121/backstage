require "rails_helper"

RSpec.describe "Metrics", type: :request do
  describe "GET /metrics" do
    it "exports prometheus formatted readiness metrics" do
      get "/metrics"

      expected_inclusions = [
        "# TYPE backstage_readiness_database gauge",
        "# TYPE backstage_readiness_cache gauge",
        "# TYPE backstage_readiness_queue gauge"
      ]

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to start_with("text/plain")

      expected_inclusions.each do |metric|
        expect(response.body).to include(metric)
      end
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
