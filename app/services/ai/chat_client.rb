require "json"
require "net/http"
require "openssl"

module Ai
  class ChatClient
    OPENAI_URI = URI("https://api.openai.com/v1/chat/completions")
    DEFAULT_MODEL = ENV.fetch("OPENAI_GROUP_SUMMARY_MODEL", "gpt-4.1-mini")

    def self.available?
      api_key.present?
    end

    def self.api_key
      ENV["OPENAI_API_KEY"].presence || Rails.application.credentials.dig(:openai, :api_key).presence
    end

    def initialize(model: DEFAULT_MODEL)
      @model = model
    end

    def summarize(prompt:)
      response = http_client.request(request(prompt))

      body = JSON.parse(response.body)
      raise body["error"]["message"] if response.code.to_i >= 400 && body["error"].present?
      raise "OpenAI request failed with status #{response.code}" if response.code.to_i >= 400

      body.dig("choices", 0, "message", "content").to_s.strip
    end

    private

    def http_client
      Net::HTTP.new(OPENAI_URI.host, OPENAI_URI.port).tap do |http|
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
        http.open_timeout = 10
        http.read_timeout = 30
      end
    end

    def request(prompt)
      request = Net::HTTP::Post.new(OPENAI_URI)
      request["Authorization"] = "Bearer #{self.class.api_key}"
      request["Content-Type"] = "application/json"
      request.body = {
        model: @model,
        temperature: 0.3,
        messages: [
          {
            role: "system",
            content: "You summarize small private group updates. " \
                     "Be specific, concise, and grounded only in the supplied posts."
          },
          {
            role: "user",
            content: prompt
          }
        ]
      }.to_json
      request
    end
  end
end
