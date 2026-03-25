module Groups
  class MessageSummaryGenerator
    OPENAI_SOURCE = "openai".freeze
    UNAVAILABLE_SOURCE = "unavailable".freeze
    ERROR_SOURCE = "error".freeze

    def initialize(group:)
      @group = group
    end

    def call
      posts = @group.recent_posts_for_summary.to_a

      if posts.empty?
        @group.update!(
          message_summary: nil,
          message_summary_generated_at: Time.current,
          message_summary_source: nil
        )
        return
      end

      unless Ai::ChatClient.available?
        @group.update!(
          message_summary: nil,
          message_summary_generated_at: nil,
          message_summary_source: UNAVAILABLE_SOURCE
        )
        return
      end

      @group.update!(
        message_summary: generate_ai_summary(posts).presence,
        message_summary_generated_at: Time.current,
        message_summary_source: OPENAI_SOURCE
      )
    rescue StandardError => e
      Rails.logger.error("Group summary refresh failed for group #{@group.id}: #{e.class}: #{e.message}")

      @group.update!(
        message_summary: nil,
        message_summary_generated_at: nil,
        message_summary_source: ERROR_SOURCE
      )
    end

    private

    def generate_ai_summary(posts)
      Ai::ChatClient.new.summarize(prompt: prompt_for(posts))
    end

    def prompt_for(posts)
      <<~PROMPT
        Summarize the latest updates for this private group.
        Write one short natural-sounding recap paragraph, followed by at most 2 short sentences if needed.
        Do not turn it into a person-by-person list unless that is the only natural way to explain the updates.
        Combine overlapping updates into a cohesive summary.
        Mention names only when they help the recap feel clear and natural.
        Do not invent details.

        Group: #{@group.name}

        Recent posts:
        #{posts.reverse_each.with_index(1).map { |post, index| formatted_post(post, index) }.join("\n")}
      PROMPT
    end

    def formatted_post(post, index)
      author = post.user&.display_name || "Unknown author"
      body = post.body.to_s.squish.presence || "[Attachment only post]"
      "#{index}. #{author} at #{post.created_at.iso8601}: #{body}"
    end
  end
end
