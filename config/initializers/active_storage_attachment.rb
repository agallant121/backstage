Rails.application.config.to_prepare do
  ActiveStorage::Attachment.class_eval do
    after_create_commit :enqueue_post_video_processing

    private

    def enqueue_post_video_processing
      return unless record.is_a?(Post)
      return unless content_type.to_s.start_with?("video")

      ProcessVideoAttachmentJob.perform_later(id)
    end
  end
end
