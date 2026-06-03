class Post < ApplicationRecord
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true

  scope :published, -> { where.not(published_at: nil).order(published_at: :desc) }
end
