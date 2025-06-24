class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :subscriptions, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  
  # Permanent subscription emails (you can add more emails here)
  PERMANENT_SUBSCRIPTION_EMAILS = [
    'adenshepard@gmail.com',  # Add your email here
    'perfect4ouryt@gmail.com', # Existing email
    # Add more emails as needed
  ].freeze
  
  # Check if user has permanent subscription access
  def has_permanent_subscription?
    permanent_subscription? || PERMANENT_SUBSCRIPTION_EMAILS.include?(email.downcase)
  end
  
  # Check if user has any active subscription or permanent access
  def has_active_subscription?
    has_permanent_subscription? || subscriptions.where(active: true).exists?
  end
  
  # Allow name to be updated through Devise
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(email) = :value", { value: login.downcase }]).first
    elsif conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end
end
