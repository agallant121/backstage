class Post < ApplicationRecord
  belongs_to :user

  has_many :post_groups, dependent: :destroy
  has_many :groups, through: :post_groups

  has_many_attached :attachments
  has_many_attached :images

  MAX_ATTACHMENTS = 10
  MAX_IMAGE_ATTACHMENTS = 8
  MAX_VIDEO_ATTACHMENTS = 2
  MAX_IMAGE_SIZE = 10.megabytes
  MAX_VIDEO_SIZE = 200.megabytes

  scope :visible_to, ->(user) {
    joins(:groups).where(groups: { id: user.groups.select(:id) }).distinct
  }

  validates :body, presence: true, unless: :attachments_attached?
  validate :body_or_attachment_present
  validate :attachments_are_media
  validate :attachments_within_limits

  after_update_commit :refresh_group_summaries_if_body_changed

  def media_attachments
    [ attachments.attachments, images.attachments ].flatten.compact
  end

  private

  def refresh_group_summaries_if_body_changed
    return unless saved_change_to_body?

    groups.find_each(&:refresh_message_summary_later)
  end

  def attachments_attached?
    media_attachments.any?
  end

  def body_or_attachment_present
    return if body.present? || attachments_attached?

    errors.add(:base, "Add a message or at least one attachment")
  end

  def attachments_are_media
    invalid = media_attachments.reject { |attachment| image_attachment?(attachment) || video_attachment?(attachment) }

    errors.add(:attachments, "must be images or videos") if invalid.any?
  end

  def attachments_within_limits
    images = media_attachments.select { |attachment| image_attachment?(attachment) }
    videos = media_attachments.select { |attachment| video_attachment?(attachment) }

    if media_attachments.size > MAX_ATTACHMENTS
      errors.add(:attachments, "limit is #{MAX_ATTACHMENTS} files per post")
    end

    if images.size > MAX_IMAGE_ATTACHMENTS
      errors.add(:attachments, "limit is #{MAX_IMAGE_ATTACHMENTS} images per post")
    end

    if videos.size > MAX_VIDEO_ATTACHMENTS
      errors.add(:attachments, "limit is #{MAX_VIDEO_ATTACHMENTS} videos per post")
    end

    images.each do |attachment|
      if attachment.blob.byte_size > MAX_IMAGE_SIZE
        errors.add(:attachments, "#{attachment.filename} exceeds #{MAX_IMAGE_SIZE / 1.megabyte}MB image limit")
      end
    end

    videos.each do |attachment|
      if attachment.blob.byte_size > MAX_VIDEO_SIZE
        errors.add(:attachments, "#{attachment.filename} exceeds #{MAX_VIDEO_SIZE / 1.megabyte}MB video limit")
      end
    end
  end

  def image_attachment?(attachment)
    attachment.content_type.to_s.start_with?("image")
  end

  def video_attachment?(attachment)
    attachment.content_type.to_s.start_with?("video")
  end
end
