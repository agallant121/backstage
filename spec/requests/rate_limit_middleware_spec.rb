require "rails_helper"

RSpec.describe "RateLimitMiddleware", type: :request do
  before do
    Rails.cache.clear
  end

  it "throttles repeated login attempts" do
    10.times do
      post user_session_path, params: { user: { email: "missing@example.com", password: "nottherightpassword" } }
      expect(response).not_to have_http_status(:too_many_requests)
    end

    post user_session_path, params: { user: { email: "missing@example.com", password: "nottherightpassword" } }

    expect(response).to have_http_status(:too_many_requests)
    expect(response.body).to include("Too many requests")
  end

  it "does not throttle health checks" do
    20.times do
      get "/up"
      expect(response).to have_http_status(:ok)
    end
  end
end
