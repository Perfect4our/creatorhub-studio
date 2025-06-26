class BillingController < ApplicationController
  before_action :authenticate_user!, except: [:pricing]
  before_action :set_stripe_key
  
  def pricing
    # Display pricing plans
  end

  def index
    # Check if this is the user's first time viewing billing
    @first_time_viewing = current_user.billing_viewed_at.nil?
    
    # Track billing portal access server-side
    PosthogService.track_billing_access(
      user: current_user,
      source: @first_time_viewing ? 'first_time' : 'return_visit'
    )
    
    # Mark as viewed if it's their first time
    if @first_time_viewing
      current_user.update!(billing_viewed_at: Time.current)
    end
    
    # Always acknowledge subscription status when viewing billing page
    current_user.acknowledge_subscription_status!
    
    # Billing management page
    @subscription_details = get_subscription_details
    @usage_stats = get_usage_stats
    @billing_history = get_billing_history
  end
  
  def create_checkout_session
    plan = params[:plan]
    
    # Validate plan
    unless valid_plan?(plan)
      redirect_to pricing_path, alert: 'Invalid plan selected.'
      return
    end
    
    # Check if Stripe is properly configured
    price_id = price_id_for_plan(plan)
    if price_id.nil? || price_id.include?('placeholder') || price_id.include?('your_')
      redirect_to pricing_path, alert: 'Stripe is not configured yet. Please contact support.'
      return
    end
    
    # Create or retrieve Stripe customer
    customer_id = current_user.create_stripe_customer
    unless customer_id
      redirect_to pricing_path, alert: 'Unable to create customer. Please try again.'
      return
    end
    
    begin
      session = Stripe::Checkout::Session.create({
        customer: customer_id,
        payment_method_types: ['card'],
        line_items: [{
          price: price_id,
          quantity: 1,
        }],
        mode: 'subscription',
        success_url: billing_success_url + '?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: pricing_url,
        metadata: {
          user_id: current_user.id,
          plan: plan
        }
      })
      
      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe checkout error: #{e.message}"
      if e.message.include?('No such price')
        redirect_to pricing_path, alert: 'Invalid pricing configuration. Please contact support.'
      else
        redirect_to pricing_path, alert: 'Unable to create checkout session. Please try again.'
      end
    end
  end
  
  def success
    session_id = params[:session_id]
    
    if session_id
      begin
        session = Stripe::Checkout::Session.retrieve(session_id)
        
        if session.payment_status == 'paid'
          # The webhook will handle updating the user's subscription status
          redirect_to dashboard_path, notice: 'Welcome to CreatorHub Studio Pro! Your subscription is now active.'
        else
          redirect_to pricing_path, alert: 'Payment was not completed. Please try again.'
        end
      rescue Stripe::StripeError => e
        Rails.logger.error "Failed to retrieve checkout session: #{e.message}"
        redirect_to pricing_path, alert: 'Unable to verify payment. Please contact support if you were charged.'
      end
    else
      redirect_to pricing_path, alert: 'Invalid session.'
    end
  end
  
  def cancel
    redirect_to pricing_path, notice: 'Subscription cancelled. You can try again anytime.'
  end
  
  def portal
    # Check if user has an active subscription via development bypass
    if current_user.subscription_status == 'active' && current_user.plan_name == 'Development Plan'
      redirect_to settings_path, notice: 'Billing portal is not available for development subscriptions. Use the pricing page to manage your subscription.'
      return
    end
    
    unless current_user.stripe_customer_id
      redirect_to pricing_path, alert: 'No billing information found. Please subscribe first to access the billing portal.'
      return
    end
    
    begin
      session = Stripe::BillingPortal::Session.create({
        customer: current_user.stripe_customer_id,
        return_url: settings_url
      })
      
      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to create billing portal session: #{e.message}"
      redirect_to settings_path, alert: 'Unable to access billing portal. Please try again.'
    end
  end
  
  def cancel_subscription
    unless current_user.stripe_subscription_id
      redirect_to billing_path, alert: 'No active subscription found.'
      return
    end
    
    begin
      subscription = Stripe::Subscription.retrieve(current_user.stripe_subscription_id)
      
      # Cancel at period end (don't cancel immediately)
      Stripe::Subscription.update(subscription.id, {
        cancel_at_period_end: true
      })
      
      # Update user's local status
      current_user.update!(
        subscription_status: 'cancelled',
        cancel_at_period_end: true
      )
      
      # Track subscription cancellation server-side (critical event)
      PosthogService.track_cancellation(
        user: current_user,
        reason: 'user_initiated'
      )
      
      redirect_to billing_path, notice: 'Your subscription has been cancelled and will end at the current billing period.'
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to cancel subscription: #{e.message}"
      redirect_to billing_path, alert: 'Unable to cancel subscription. Please try again or contact support.'
    end
  end

  def dev_bypass
    # Only allow in development
    unless Rails.env.development?
      render json: { success: false, message: 'Not available in production' }, status: 403
      return
    end
    
    code = params[:code]
    
    if code == 'dev2025'
      # Simulate an active subscription for development
      current_user.update!(
        subscription_status: 'active',
        current_period_end: 1.year.from_now,
        plan_name: 'Development Plan'
      )
      
      Rails.logger.info "Development bypass applied for user #{current_user.id}"
      render json: { success: true, message: 'Development subscription activated!' }
    else
      render json: { success: false, message: 'Invalid bypass code' }, status: 400
    end
  end
  
  private

  def get_subscription_details
    if current_user.stripe_subscription_id
      begin
        subscription = Stripe::Subscription.retrieve(current_user.stripe_subscription_id)
        customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
        
        {
          id: subscription.id,
          status: subscription.status,
          current_period_start: Time.at(subscription.current_period_start),
          current_period_end: Time.at(subscription.current_period_end),
          cancel_at_period_end: subscription.cancel_at_period_end,
          plan_name: subscription.items.data.first.price.nickname || 'CreatorHub Studio Pro',
          amount: subscription.items.data.first.price.unit_amount / 100.0,
          currency: subscription.items.data.first.price.currency.upcase,
          interval: subscription.items.data.first.price.recurring.interval,
          customer_email: customer.email,
          payment_method: get_default_payment_method(customer.id)
        }
      rescue Stripe::StripeError => e
        Rails.logger.error "Failed to retrieve subscription details: #{e.message}"
        nil
      end
    elsif current_user.plan_name == 'Development Plan'
      {
        id: 'dev_subscription',
        status: 'active',
        current_period_start: 1.year.ago,
        current_period_end: current_user.current_period_end || 1.year.from_now,
        cancel_at_period_end: false,
        plan_name: 'Development Plan',
        amount: 0,
        currency: 'USD',
        interval: 'year',
        customer_email: current_user.email,
        payment_method: nil
      }
    else
      nil
    end
  end

  def get_default_payment_method(customer_id)
    begin
      payment_methods = Stripe::PaymentMethod.list({
        customer: customer_id,
        type: 'card'
      })
      
      if payment_methods.data.any?
        card = payment_methods.data.first.card
        {
          brand: card.brand.capitalize,
          last4: card.last4,
          exp_month: card.exp_month,
          exp_year: card.exp_year
        }
      else
        nil
      end
    rescue Stripe::StripeError
      nil
    end
  end

  def get_usage_stats
    # Calculate usage statistics for the current billing period
    if current_user.current_period_end
      period_start = current_user.current_period_end - 1.month
      period_end = current_user.current_period_end
    else
      period_start = 1.month.ago
      period_end = 1.month.from_now
    end
    
    connected_accounts = current_user.subscriptions.active.count
    total_views = current_user.subscriptions.active.joins(:daily_view_trackings)
                            .where(daily_view_trackings: { tracked_date: period_start..period_end })
                            .sum(:total_views) || 0
    
    {
      connected_accounts: connected_accounts,
      total_views: total_views,
      period_start: period_start,
      period_end: period_end,
      days_used: [(Date.current - period_start.to_date).to_i, 0].max,
      days_remaining: [(period_end.to_date - Date.current).to_i, 0].max
    }
  end

  def get_billing_history
    return [] unless current_user.stripe_customer_id
    
    begin
      invoices = Stripe::Invoice.list({
        customer: current_user.stripe_customer_id,
        limit: 12
      })
      
      invoices.data.map do |invoice|
        {
          id: invoice.id,
          amount_paid: invoice.amount_paid / 100.0,
          currency: invoice.currency.upcase,
          status: invoice.status,
          created: Time.at(invoice.created),
          period_start: invoice.period_start ? Time.at(invoice.period_start) : nil,
          period_end: invoice.period_end ? Time.at(invoice.period_end) : nil,
          invoice_pdf: invoice.invoice_pdf,
          hosted_invoice_url: invoice.hosted_invoice_url
        }
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to retrieve billing history: #{e.message}"
      []
    end
  end
  
  def set_stripe_key
    @stripe_publishable_key = if Rails.env.development?
      Rails.application.credentials.dig(:stripe, :publishable_key) ||
      Rails.application.credentials.dig(:stripe, :test_publishable_key) ||
      ENV['STRIPE_PUBLISHABLE_KEY'] || 
      'pk_test_placeholder_key'
    else
      Rails.application.credentials.dig(:stripe, :publishable_key) ||
      Rails.application.credentials.dig(:stripe, :test_publishable_key) ||
      'pk_test_placeholder_key'
    end
  end
  
  def valid_plan?(plan)
    %w[monthly yearly].include?(plan)
  end
  
  def price_id_for_plan(plan)
    case plan
    when 'monthly'
      if Rails.env.production?
        Rails.application.credentials.dig(:stripe, :live_monthly_price_id) ||
        Rails.application.credentials.dig(:stripe, :monthly_price_id)
      else
        Rails.application.credentials.dig(:stripe, :monthly_price_id) ||
        ENV['STRIPE_MONTHLY_PRICE_ID'] || 
        'price_placeholder_monthly'
      end
    when 'yearly'
      if Rails.env.production?
        Rails.application.credentials.dig(:stripe, :live_yearly_price_id) ||
        Rails.application.credentials.dig(:stripe, :yearly_price_id)
      else
        Rails.application.credentials.dig(:stripe, :yearly_price_id) ||
        ENV['STRIPE_YEARLY_PRICE_ID'] || 
        'price_placeholder_yearly'
      end
    end
  end
end 