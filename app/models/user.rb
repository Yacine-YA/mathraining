class User < ActiveRecord::Base
  attr_accessible :email, :fname, :lname, :password, :password_confirmation, :admin
  has_secure_password

  before_save { self.email.downcase! }
  before_save :create_remember_token

  validate :fname, presence: true, length: { maximum: 32 }
  validate :lname, presence: true, length: { maximum: 32 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },
	  uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }
  # presence: true <- commented to avoid
  # duplication of error message with confirmation
  validates :password_confirmation, presence: true

  def name
    "#{self.fname} #{self.lname}"
  end
  private
  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end
end
