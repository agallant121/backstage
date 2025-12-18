class Post < ApplicationRecord
  belongs_to :user

  has_many :post_groups, dependent: :destroy
  has_many :groups, through: :post_groups

  has_many_attached :attachments
  has_many_attached :images

  scope :visible_to, ->(user) {
    joins(:groups).where(groups: { id: user.groups.select(:id) }).distinct
  }

  validates :body, presence: true, unless: :attachments_attached?
  validate :body_or_attachment_present
  validate :attachments_are_media

  def media_attachments
    [ attachments.attachments, images.attachments ].flatten.compact
  end

  private

  def attachments_attached?
    media_attachments.any?
  end

  def body_or_attachment_present
    return if body.present? || attachments_attached?

    errors.add(:base, "Add a message or at least one attachment")
  end

  def attachments_are_media
    invalid = media_attachments.reject do |attachment|
      content_type = attachment.content_type.to_s
      content_type.start_with?("image") || content_type.start_with?("video")
    end

    return if invalid.empty?

    errors.add(:attachments, "must be images or videos")
  end
end
