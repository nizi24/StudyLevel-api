class TimeReport < ApplicationRecord
  include Likeable
  include Noticeable

  belongs_to :user
  has_one :experience_record, dependent: :destroy
  has_many :passives, class_name: 'Notice', foreign_key: 'time_report_id'
  has_many :time_report_tag_links, dependent: :destroy
  has_many :tags, -> { order(:name) }, through: :time_report_tag_links
  has_many :comments, -> { order(created_at: :desc) }, dependent: :destroy

  scope :newest, -> { order(study_date: :desc) }

  validates :study_time, presence: true
  validates :memo, length: { maximum: 280 }

  def links
    time_report_tag_links
  end

  def comments_count
    comments.count
  end

  def self.tag_search(word)
    tag_ids_query = "SELECT id FROM tags
                    WHERE name LIKE ?"
    tag_ids = Tag.find_by_sql([tag_ids_query, "%#{sanitize_sql_like(word)}%"])
      .map(&:id).join(',')
    time_report_ids = "SELECT time_report_id FROM time_report_tag_links
                      WHERE tag_id IN (#{tag_ids})"
    TimeReport.where("id IN (#{time_report_ids})").newest
  end
end
