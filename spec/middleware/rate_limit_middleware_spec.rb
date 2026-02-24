require "rails_helper"

RSpec.describe RateLimitMiddleware do
  let(:app) { ->(_env) { [200, { "Content-Type" => "text/plain" }, ["ok"]] } }
  let(:middleware) { described_class.new(app) }

  before { Rails.cache.clear }

  it "uses cache increment for counter updates" do
    cache = instance_double(ActiveSupport::Cache::Store)

    allow(Rails).to receive(:cache).and_return(cache)
    allow(cache).to receive(:increment).and_return(1)
    allow(cache).to receive(:read).and_return(0)

    env = Rack::MockRequest.env_for(
      "/users/sign_in",
      method: "POST",
      "REMOTE_ADDR" => "127.0.0.1",
      params: { user: { email: "person@example.com" } }
    )

    described_class.new(app, store: RateLimit::Store.new(cache: cache)).call(env)

    expect(cache).to have_received(:increment).with(
      a_string_matching(/\Arate_limit:logins:ip:127\.0\.0\.1:\d+\z/),
      1,
      expires_in: 1.minute,
      initial: 0
    )
  end

  it "sets retry-after based on remaining lockout period" do
    previous_limit = ENV.fetch("RATE_LIMIT_GROUP_INVITES_PER_HOUR", nil)
    previous_lockout = ENV.fetch("RATE_LIMIT_GROUP_INVITES_LOCKOUT_SECONDS", nil)
    ENV["RATE_LIMIT_GROUP_INVITES_PER_HOUR"] = "0"
    ENV["RATE_LIMIT_GROUP_INVITES_LOCKOUT_SECONDS"] = "120"

    env = Rack::MockRequest.env_for("/groups/1/invitations", method: "POST", "REMOTE_ADDR" => "127.0.0.1")
    status, headers, = middleware.call(env)

    expect(status).to eq(429)
    expect(headers["Retry-After"].to_i).to be_between(1, 120)
  ensure
    ENV["RATE_LIMIT_GROUP_INVITES_PER_HOUR"] = previous_limit
    ENV["RATE_LIMIT_GROUP_INVITES_LOCKOUT_SECONDS"] = previous_lockout
  end

  it "emits a security notification when throttling occurs" do
    previous_limit = ENV.fetch("RATE_LIMIT_LOGIN_PER_MINUTE", nil)
    ENV["RATE_LIMIT_LOGIN_PER_MINUTE"] = "0"

    events = []
    callback = proc { |_name, _start, _finish, _id, payload| events << payload }
    subscriber = ActiveSupport::Notifications.subscribe("security.rate_limit_triggered", &callback)

    env = Rack::MockRequest.env_for(
      "/users/sign_in",
      method: "POST",
      "REMOTE_ADDR" => "127.0.0.1",
      params: { user: { email: "abuse@example.com" } }
    )

    middleware.call(env)

    expect(events.last).to include(rule: "logins", key_type: :ip, key_value: "127.0.0.1")
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    ENV["RATE_LIMIT_LOGIN_PER_MINUTE"] = previous_limit
  end

  it "extracts invitation token directly from request path" do
    request = ActionDispatch::Request.new(
      Rack::MockRequest.env_for("/invitations/abc123/accept", method: "POST", "REMOTE_ADDR" => "127.0.0.1")
    )
    rule_set = RateLimit::RuleSet.new
    rule = rule_set.matching_rule(request)

    expect(rule.keys.call(request)).to include(invitation_token: "abc123")
  end
end
