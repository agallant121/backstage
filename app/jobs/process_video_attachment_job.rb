class ProcessVideoAttachmentJob < ApplicationJob
  queue_as :default

  THUMBNAIL_SIZE = [800, 800].freeze
  TRANSCODE_SIZE = [1280, 720].freeze
  TRANSCODE_FORMAT = "mp4"

  def perform(attachment_id)
    attachment = ActiveStorage::Attachment.find_by(id: attachment_id)
    return unless attachment&.blob
    return unless attachment.content_type.to_s.start_with?("video")

    attachment.blob.analyze

    if attachment.blob.previewable?
      attachment.preview(resize_to_limit: THUMBNAIL_SIZE).processed
    end

    if attachment.blob.variable?
      attachment.variant(resize_to_limit: TRANSCODE_SIZE, format: TRANSCODE_FORMAT).processed
    end
  end
end
