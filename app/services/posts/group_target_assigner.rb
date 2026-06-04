module Posts
  class GroupTargetAssigner
    def initialize(post:, group_ids:)
      @post = post
      @group_ids = group_ids.uniq
    end

    def call
      remove_stale_targets
      attach_new_targets
      changed_group_ids
    end

    private

    attr_reader :group_ids, :post

    def attach_new_targets
      return if group_ids_to_add.empty?

      now = Time.current
      rows = group_ids_to_add.map do |group_id|
        { post_id: post.id, group_id: group_id, created_at: now, updated_at: now }
      end

      # Bulk attach is intentional here; uniqueness is enforced by the composite index.
      # rubocop:disable Rails/SkipsModelValidations
      PostGroup.insert_all(rows, unique_by: :index_post_groups_on_post_id_and_group_id)
      # rubocop:enable Rails/SkipsModelValidations
    end

    def changed_group_ids
      group_ids_to_add + group_ids_to_remove
    end

    def existing_group_ids
      @existing_group_ids ||= post.group_ids
    end

    def group_ids_to_add
      @group_ids_to_add ||= group_ids - existing_group_ids
    end

    def group_ids_to_remove
      @group_ids_to_remove ||= existing_group_ids - group_ids
    end

    def remove_stale_targets
      return if group_ids_to_remove.empty?

      PostGroup.where(post: post, group_id: group_ids_to_remove).delete_all
    end
  end
end
