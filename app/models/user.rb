class User < ApplicationRecord
  include Rails.application.routes.url_helpers

  with_options dependent: :destroy do |assoc|
    assoc.has_many :time_reports, -> { order(study_date: :desc) }
    assoc.has_many :experience_records
    assoc.has_many :comments
    assoc.has_many :likes
    assoc.has_many :weekly_targets
    assoc.has_many :weekly_target_experience_records
    assoc.has_one :experience
    assoc.has_one :setting
    assoc.has_many :action, class_name: 'Notice',
      foreign_key: 'action_user_id'
    assoc.has_many :notices, -> { order(created_at: :desc) },
      class_name: 'Notice', foreign_key: 'received_user_id'
    assoc.has_many :active_relationships, class_name: 'Relationship',
      foreign_key: 'follower_id'
    assoc.has_many :passive_relationships, class_name: 'Relationship',
      foreign_key: 'followed_id'
    assoc.has_many :blocking_relationships, class_name: 'Block',
      foreign_key: 'blocker_id'
    assoc.has_many :blocked_relationships, class_name: 'Block',
      foreign_key: 'blocked_id'
    assoc.has_many :user_tag_relationships
    assoc.has_many :devices
  end

  has_one_attached :avatar
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  has_many :blocking, through: :blocking_relationships, source: :blocked
  has_many :blockers, through: :blocked_relationships, source: :blocker
  has_many :tags, through: :user_tag_relationships

  scope :newest, -> { order(created_at: :desc) }
  scope :join_exp, -> { joins(:experience).select('users.*,
    experiences.experience_to_next, experiences.total_experience,
    experiences.level') }
  scope :includes_tags, -> { includes(time_reports:
    { time_report_tag_links: :tag }) }
  scope :left_joins_tags, -> { left_joins(time_reports:
    { time_report_tag_links: :tag }) }
  scope :main_tags, -> (id) { includes_tags.left_joins_tags
    .select('COUNT(time_report_tag_links.*) AS count, tags.name, tags.id')
    .group('tags.name, tags.id')
    .where('users.id = ?', id)
    .limit(5)
    .order('count DESC')
  }
  scope :search_time_reports_in_tags, -> (user_id, tag) {
    left_joins_tags
    .select('time_reports.id')
    .where('users.id = ? AND tags.name LIKE ?', user_id, "%#{tag}%")
    .order('time_reports.study_date')
  }

  validates :name, presence: true, length: { maximum: 20 }
  validates :email, presence: true, length: { maximum: 255 },
    uniqueness:   { case_sensitive: false }
  validates :uid, presence: true
  VALID_SCREEN_NAME_REGEX = /\A[a-z0-9_]+\z/i
  validates :screen_name, presence: true, length: { in: 5..15 },
    uniqueness:   { case_sensitive: false },
    format: { with: VALID_SCREEN_NAME_REGEX }
  validates :profile, length: { maximum: 160 }

  def random_screen_name
    self.screen_name = SecureRandom.alphanumeric(12)
  end

  def target_of_the_week
    weekly_start = Time.current.beginning_of_week
    weekly_targets.where('weekly_targets.start_date = ?', weekly_start)
  end

  def target_of_non_checked
    weekly_start = Time.current.beginning_of_week
    prev_weekly_target = weekly_targets.find_by('weekly_targets.start_date < ?
      AND checked = false', weekly_start)
    prev_weekly_target.check if prev_weekly_target
    prev_weekly_target
  end

  def notice
    notices = self.notices.includes(:action_user)
      .joins(:action_user)
      .select('notices.*, users.screen_name')
      .limit(30)
      .order('notices.created_at DESC')
  end

  def notice_nonchecked
    notices.where(checked: false)
  end

  def follow(other_user)
    self.following << other_user
  end

  def unfollow(other_user)
    self.following.delete(other_user)
  end

  def following?(other_user)
    self.following.include?(other_user)
  end

  def following_count
    self.active_relationships.length
  end

  def follower_count
    self.passive_relationships.length
  end

  def block(other_user)
    self.blocking << other_user
  end

  def unblock(other_user)
    self.blocking.delete(other_user)
  end

  def avatar_url
    avatar.attached? ? url_for(avatar) : nil
  end

  def self.experience_rank(term = nil)
    if term
      User.includes(time_reports: :experience_record)
        .left_joins(time_reports: :experience_record)
        .select('SUM(experience_records.experience_point) AS exp, users.name, users.screen_name, users.id')
        .where('time_reports.study_date >= ? AND users.guest = false', term)
        .group('users.id')
        .limit(10)
        .order('exp DESC')
    else
      User.joins(:experience)
        .select('experiences.total_experience AS exp, users.name, users.screen_name, users.id')
        .where(id: Experience.total_experience_rank, guest: false)
        .order('experiences.total_experience DESC')
    end
  end

  def timeline(offset = 0, limit = 30)
    following_ids = "SELECT followed_id FROM relationships
                     WHERE follower_id = :user_id"
    TimeReport.where("user_id IN (#{following_ids})", user_id: id).limit(limit).offset(offset).newest
  end

  def tag_feed(offset = 0, limit = 30)
    user_id = self.id
    following_tag_ids = "SELECT tag_id FROM user_tag_relationships
                        WHERE user_id = #{user_id}"
    time_report_ids = "SELECT time_report_id FROM time_report_tag_links
                      WHERE tag_id IN (#{following_tag_ids})"
    TimeReport.where("id IN (#{time_report_ids})")
      .limit(limit).offset(offset).newest
  end

  def following_tags
    following_tag_ids = "SELECT tag_id FROM user_tag_relationships
                        WHERE user_id = :user_id"
    Tag.where("id IN (#{following_tag_ids})", user_id: id).order(:name)
  end

  def self.search(word)
    User.where(['name LIKE ?', "%#{word}%"]).newest
  end

  def self.screen_name_search(word)
    User.where(['screen_name LIKE ?', "%#{word}%"]).newest
  end
end
