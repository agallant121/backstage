require "rails_helper"

RSpec.describe RateLimitMiddleware do
  let(:app) { ->(_env) { [200, { "Content-Type" => "text/plain" }, ["ok"]] } }
  let(:middleware) { described_class.new(app) }

  before do
    Rails.cache.clear
  end

  it "uses cache increment for counter updates" do
    cache = instance_double(ActiveSupport::Cache::Store)

    allow(Rails).to receive(:cache).and_return(cache)
    allow(cache).to receive(:increment).and_return(1)

    env = Rack::MockRequest.env_for("/users/sign_in", method: "POST", "REMOTE_ADDR" => "127.0.0.1")
    middleware.call(env)

    expect(cache).to have_received(:increment).with(
      a_string_matching(/\Arate_limit:logins:127\.0\.0\.1:\d+\z/),
      1,
      expires_in: 1.minute,
      initial: 0
    )
  end

  it "sets retry-after based on the matched rule period" do
    previous = ENV.fetch("RATE_LIMIT_GROUP_INVITES_PER_HOUR", nil)
    ENV["RATE_LIMIT_GROUP_INVITES_PER_HOUR"] = "0"

    env = Rack::MockRequest.env_for("/groups/1/invitations", method: "POST", "REMOTE_ADDR" => "127.0.0.1")
    status, headers, = middleware.call(env)

    expect(status).to eq(429)
    expect(headers["Retry-After"].to_i).to be_between(1, 3600)
  ensure
    ENV["RATE_LIMIT_GROUP_INVITES_PER_HOUR"] = previous
  end
end
