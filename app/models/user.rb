class User < ApplicationRecord
  self.table_name = 'users'

  has_many :ride_memberships, dependent: :destroy
  has_many :devices, dependent: :destroy

  validates :email, presence: true
  validates :username, presence: true
  validates :name, presence: true
end
