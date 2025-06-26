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
    has_permanent_subscription? || subscriptions.where(active: true).exists? || stripe_subscribed?
  end
  
  # Stripe subscription methods
  def stripe_subscribed?
    subscription_status == 'active' && current_period_end&.future?
  end
  
  def stripe_subscription_expired?
    current_period_end&.past?
  end
  
  def subscription_days_remaining
    return nil unless current_period_end
    ((current_period_end - Time.current) / 1.day).round
  end
  
  def create_stripe_customer
    return stripe_customer_id if stripe_customer_id.present?
    
    # Skip if Stripe is not properly configured
    if Stripe.api_key.include?('placeholder')
      Rails.logger.warn "Skipping Stripe customer creation - API key not configured"
      return nil
    end
    
    customer = Stripe::Customer.create({
      email: email,
      name: name,
      metadata: {
        user_id: id
      }
    })
    
    update!(stripe_customer_id: customer.id)
    customer.id
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to create Stripe customer: #{e.message}"
    nil
  end
  
  def stripe_customer
    return nil unless stripe_customer_id
    return nil if Stripe.api_key.include?('placeholder')
    
    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to retrieve Stripe customer: #{e.message}"
    nil
  end
  
  def stripe_subscriptions
    return [] unless stripe_customer_id
    return [] if Stripe.api_key.include?('placeholder')
    
    Stripe::Subscription.list(customer: stripe_customer_id)
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to retrieve Stripe subscriptions: #{e.message}"
    []
  end
  
  def update_subscription_from_stripe(stripe_subscription)
    update!(
      subscription_status: stripe_subscription.status,
      current_period_end: Time.at(stripe_subscription.current_period_end),
      plan_name: stripe_subscription.items.data.first&.price&.nickname || 'Unknown Plan'
    )
  end

  def first_time_billing_viewer?
    billing_viewed_at.nil?
  end

  def billing_viewed_recently?
    billing_viewed_at&.> 1.hour.ago
  end

  def should_show_subscription_status?
    # Show if user has never acknowledged their subscription status
    # This ensures it shows on first login but gets hidden after interaction
    subscription_status_acknowledged_at.nil?
  end

  def acknowledge_subscription_status!
    update!(subscription_status_acknowledged_at: Time.current)
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
