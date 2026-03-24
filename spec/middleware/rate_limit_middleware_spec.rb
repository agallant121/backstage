require "rails_helper"

RSpec.describe RateLimitMiddleware do
  let(:app) { ->(_env) { [200, { "Content-Type" => "text/plain" }, ["ok"]] } }
  let(:middleware) { described_class.new(app) }

  before { Rails.cache.clear }

  it "uses cache increment for counter updates" do
    cache = instance_double(ActiveSupport::Cache::Store)
    configure_cache_double(cache)

    described_class.new(app, store: RateLimit::Store.new(cache: cache)).call(sign_in_env(email: "person@example.com"))

    expect(cache).to have_received(:increment).with(
      a_string_matching(/\Arate_limit:logins:ip:127\.0\.0\.1:\d+\z/),
      1,
      expires_in: 1.minute,
      initial: 0
    )
  end

  it "sets retry-after based on remaining lockout period" do
    with_env("RATE_LIMIT_GROUP_INVITES_PER_HOUR" => "0", "RATE_LIMIT_GROUP_INVITES_LOCKOUT_SECONDS" => "120") do
      env = Rack::MockRequest.env_for("/groups/1/invitations", method: "POST", "REMOTE_ADDR" => "127.0.0.1")
      status, headers, = middleware.call(env)

      expect(status).to eq(429)
      expect(headers["Retry-After"].to_i).to be_between(118, 120)
    end
  end

  it "keeps returning 429 during lockout without incrementing counters" do
    with_env("RATE_LIMIT_GROUP_INVITES_PER_HOUR" => "0", "RATE_LIMIT_GROUP_INVITES_LOCKOUT_SECONDS" => "120") do
      store = build_store_spy
      locked_middleware = described_class.new(app, store: store)

      first_response = locked_middleware.call(group_invitation_env)
      second_response = locked_middleware.call(group_invitation_env)

      expect_lockout_response(first_response)
      expect_lockout_response(second_response)
      expect(store).to have_received(:next_count).once
    end
  end

  it "falls back to ip-only keys when params parsing raises" do
    with_env("RATE_LIMIT_LOGIN_PER_MINUTE" => "0") do
      events = []
      subscriber = subscribe_to_rate_limit_alerts(events)

      expect { middleware.call(broken_sign_in_env) }.not_to raise_error
      expect_rate_limit_event(events.last)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    end
  end

  it "emits a security notification when throttling occurs" do
    with_env("RATE_LIMIT_LOGIN_PER_MINUTE" => "0") do
      events = []
      subscriber = subscribe_to_rate_limit_alerts(events)

      middleware.call(sign_in_env(email: "abuse@example.com"))

      expect(events.last).to include(rule: "logins", key_type: :ip, key_value: "127.0.0.1")
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    end
  end

  it "extracts invitation token directly from request path" do
    request = ActionDispatch::Request.new(
      Rack::MockRequest.env_for("/invitations/abc123/accept", method: "POST", "REMOTE_ADDR" => "127.0.0.1")
    )

    rule = RateLimit::RuleSet.new.matching_rule(request)

    expect(rule.keys.call(request)).to include(invitation_token: "abc123")
  end

  def configure_cache_double(cache)
    allow(Rails).to receive(:cache).and_return(cache)
    allow(cache).to receive_messages(increment: 1, read: 0)
  end

  def sign_in_env(email:)
    Rack::MockRequest.env_for(
      "/users/sign_in",
      method: "POST",
      "REMOTE_ADDR" => "127.0.0.1",
      params: { user: { email: email } }
    )
  end

  def broken_sign_in_env
    Rack::MockRequest.env_for(
      "/users/sign_in",
      method: "POST",
      "REMOTE_ADDR" => "127.0.0.1",
      "CONTENT_TYPE" => "application/json",
      "rack.input" => StringIO.new("{")
    )
  end

  def group_invitation_env
    Rack::MockRequest.env_for("/groups/1/invitations", method: "POST", "REMOTE_ADDR" => "127.0.0.1")
  end

  def build_store_spy
    store = RateLimit::Store.new(cache: ActiveSupport::Cache::MemoryStore.new)
    allow(store).to receive(:next_count).and_call_original
    store
  end

  def expect_lockout_response(response)
    status, headers, = response

    expect(status).to eq(429)
    expect(headers["Retry-After"].to_i).to be >= 0
  end

  def expect_rate_limit_event(event)
    expect(event).to include(rule: "logins", key_type: :ip, key_value: "127.0.0.1")
  end

  def subscribe_to_rate_limit_alerts(events)
    ActiveSupport::Notifications.subscribe("security.rate_limit_triggered") do |_name, _start, _finish, _id, payload|
      events << payload
    end
  end

  def with_env(overrides)
    previous = overrides.to_h { |key, _value| [key, ENV.fetch(key, nil)] }
    overrides.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end
end
