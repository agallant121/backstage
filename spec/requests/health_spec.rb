require "rails_helper"

RSpec.describe "Health", type: :request do
  describe "GET /up" do
    it "returns ok" do
      get "/up"

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("ok")
    end
  end

  describe "GET /ready" do
    it "returns ok when all checks pass" do
      get "/ready"

      expect(response).to have_http_status(:ok)
      parsed = response.parsed_body
      expect(parsed["status"]).to eq("ok")
      expect(parsed["checks"]).to include(
        "database" => true,
        "cache" => true,
        "queue" => true
      )
    end

    it "returns service unavailable when a dependency check fails" do
      allow_any_instance_of(HealthController).to receive(:cache_ready?).and_return(false)

      get "/ready"

      expect(response).to have_http_status(:service_unavailable)
      parsed = response.parsed_body
      expect(parsed["status"]).to eq("degraded")
      expect(parsed.dig("checks", "cache")).to be(false)
    end
  end
end
