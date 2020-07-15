class User < ApplicationRecord
  has_many :time_reports, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :experience_records, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_one :experience, dependent: :destroy

  scope :join_exp, -> { joins(:experience).select('users.*,
    experiences.experience_to_next, experiences.total_experience,
    experiences.level') }
  scope :includes_tags, -> { includes(time_reports:
    { time_report_tag_links: :tag }) }
  scope :left_joins_tags, -> { left_joins(time_reports:
    { time_report_tag_links: :tag }) }
  scope :main_tags, -> (id) { includes_tags.left_joins_tags
    .select('COUNT(time_report_tag_links.*), tags.name, users.id')
    .group('tags.name, users.id')
    .where('users.id = ?', id)
    .limit(5)
    .order('COUNT(time_report_tag_links.time_report_id) DESC')
  }
  scope :search_time_reports_in_tags, ->(user_id, tag) {
    includes_tags.left_joins_tags
    .select('time_reports.id')
    .where('users.id = ? AND tags.name LIKE ?', user_id, "%#{tag}%")
    .order('time_reports.created_at')
  }

  validates :name, presence: true, length: { maximum: 20 }
  validates :email, presence: true, length: { maximum: 255 },
    uniqueness:   { case_sensitive: false }
  validates :uid, presence: true
  VALID_SCREEN_NAME_REGEX = /\A[a-z0-9_]+\z/i
  validates :screen_name, presence: true, length: { in: 5..15 },
    uniqueness:   { case_sensitive: false },
    format: { with: VALID_SCREEN_NAME_REGEX }
end
