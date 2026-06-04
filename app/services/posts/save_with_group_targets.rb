module Posts
  class SaveWithGroupTargets
    def initialize(post:, group_ids:, error_message:, attributes: nil)
      @attributes = attributes
      @error_message = error_message
      @group_ids = group_ids
      @post = post
    end

    def call
      Post.transaction do
        post.assign_attributes(attributes) if attributes
        @saved = post.save
        @changed_group_ids = assign_group_targets if saved?
        raise ActiveRecord::Rollback unless saved?
      end

      refresh_group_summaries if saved?
      saved?
    rescue ActiveRecord::StatementInvalid
      post.errors.add(:base, error_message)
      false
    end

    private

    attr_reader :attributes, :changed_group_ids, :error_message, :group_ids, :post

    def assign_group_targets
      Posts::GroupTargetAssigner.new(post: post, group_ids: group_ids).call
    end

    def refresh_group_summaries
      Group.where(id: changed_group_ids.uniq).find_each(&:enqueue_message_summary_refresh)
    end

    def saved?
      @saved == true
    end
  end
end
