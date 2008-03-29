class Crew < ActiveRecord::Base
  belongs_to :team
  has_many :chat_users
end
