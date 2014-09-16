class User < ActiveRecord::Base

  validates :github_id, presence: true, uniqueness: true
  validates :screen_name, presence: true, uniqueness: true
  before_create :generate_remeber_token

  private

  def generate_remember_token
    self.remember_token = SecureRandom.hex(20)
  end

end
