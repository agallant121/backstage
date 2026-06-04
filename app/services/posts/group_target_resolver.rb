module Posts
  class GroupTargetResolver
    def initialize(user:, params:)
      @user = user
      @params = params
    end

    def attach_ids
      return nil unless all_submitted_values_valid?
      return user.groups.pluck(:id) if selected_ids.empty?
      return selected_ids if user_group_ids.sort == selected_ids.sort

      nil
    end

    def selected_ids
      submitted_ids.uniq
    end

    private

    attr_reader :params, :user

    def all_submitted_values_valid?
      submitted_ids.size == submitted_values.size
    end

    def submitted_ids
      @submitted_ids ||= submitted_values.filter_map { |group_id| Integer(group_id, exception: false) }
    end

    def user_group_ids
      user.groups.where(id: selected_ids).pluck(:id)
    end

    def submitted_values
      submitted_group_ids =
        if params.dig(:post, :group_ids).present?
          Array(params.dig(:post, :group_ids))
        else
          Array(params.dig(:post, :group_id))
        end

      submitted_group_ids.compact_blank
    end
  end
end
