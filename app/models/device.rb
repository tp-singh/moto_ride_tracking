class Device < ApplicationRecord
  belongs_to :user

  validates :push_token, presence: true
end
