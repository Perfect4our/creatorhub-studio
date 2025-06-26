class StripeWebhooksController < ApplicationController
  protect_from_forgery with: :null_session
  
  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.env.production? ? 
      Rails.application.credentials.dig(:stripe, :webhook_secret) : 
      ENV['STRIPE_WEBHOOK_SECRET'] || Rails.application.credentials.dig(:stripe, :test_webhook_secret)
    
    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON: #{e.message}"
      render json: { error: 'Invalid JSON' }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Invalid signature: #{e.message}"
      render json: { error: 'Invalid signature' }, status: 400
      return
    end
    
    # Handle the event
    case event['type']
    when 'checkout.session.completed'
      handle_checkout_session_completed(event['data']['object'])
    when 'customer.subscription.created'
      handle_subscription_created(event['data']['object'])
    when 'customer.subscription.updated'
      handle_subscription_updated(event['data']['object'])
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event['data']['object'])
    when 'invoice.payment_succeeded'
      handle_invoice_payment_succeeded(event['data']['object'])
    when 'invoice.payment_failed'
      handle_invoice_payment_failed(event['data']['object'])
    else
      Rails.logger.info "Unhandled event type: #{event['type']}"
    end
    
    render json: { status: 'success' }
  end
  
  private
  
  def handle_checkout_session_completed(session)
    Rails.logger.info "Checkout session completed: #{session['id']}"
    
    # Get the customer and subscription
    customer_id = session['customer']
    user = User.find_by(stripe_customer_id: customer_id)
    
    unless user
      Rails.logger.error "User not found for customer ID: #{customer_id}"
      return
    end
    
    # Get the subscription details
    subscription_id = session['subscription']
    if subscription_id
      subscription = Stripe::Subscription.retrieve(subscription_id)
      user.update_subscription_from_stripe(subscription)
      
      # Track successful subscription server-side (critical event)
      plan_name = subscription.items.data.first&.price&.nickname || 'Pro Plan'
      amount = subscription.items.data.first&.price&.unit_amount
      
      PosthogService.track_subscription(
        user: user,
        event_type: 'completed',
        plan_name: plan_name,
        amount: amount,
        currency: subscription.items.data.first&.price&.currency || 'usd'
      )
      
      Rails.logger.info "Updated subscription for user #{user.id}: #{subscription.status}"
    end
  rescue => e
    Rails.logger.error "Error handling checkout session completed: #{e.message}"
  end
  
  def handle_subscription_created(subscription)
    Rails.logger.info "Subscription created: #{subscription['id']}"
    
    # Track subscription creation
    user = User.find_by(stripe_customer_id: subscription['customer'])
    if user
      plan_name = subscription['items']['data'].first&.dig('price', 'nickname') || 'Pro Plan'
      amount = subscription['items']['data'].first&.dig('price', 'unit_amount')
      
      PosthogService.track_subscription(
        user: user,
        event_type: 'created',
        plan_name: plan_name,
        amount: amount,
        currency: subscription['items']['data'].first&.dig('price', 'currency') || 'usd'
      )
    end
    
    update_user_subscription(subscription)
  end
  
  def handle_subscription_updated(subscription)
    Rails.logger.info "Subscription updated: #{subscription['id']}"
    
    # Track subscription updates (plan changes, etc.)
    user = User.find_by(stripe_customer_id: subscription['customer'])
    if user
      plan_name = subscription['items']['data'].first&.dig('price', 'nickname') || 'Pro Plan'
      amount = subscription['items']['data'].first&.dig('price', 'unit_amount')
      
      PosthogService.track_subscription(
        user: user,
        event_type: 'updated',
        plan_name: plan_name,
        amount: amount,
        currency: subscription['items']['data'].first&.dig('price', 'currency') || 'usd'
      )
    end
    
    update_user_subscription(subscription)
  end
  
  def handle_subscription_deleted(subscription)
    Rails.logger.info "Subscription deleted: #{subscription['id']}"
    
    customer_id = subscription['customer']
    user = User.find_by(stripe_customer_id: customer_id)
    
    if user
      # Track subscription cancellation/deletion server-side (critical event)
      PosthogService.track_subscription(
        user: user,
        event_type: 'deleted'
      )
      
      user.update!(
        subscription_status: 'cancelled',
        current_period_end: nil,
        plan_name: nil
      )
      
      Rails.logger.info "Cancelled subscription for user #{user.id}"
    end
  rescue => e
    Rails.logger.error "Error handling subscription deletion: #{e.message}"
  end
  
  def handle_invoice_payment_succeeded(invoice)
    Rails.logger.info "Invoice payment succeeded: #{invoice['id']}"
    
    # Track successful payment
    user = User.find_by(stripe_customer_id: invoice['customer'])
    if user
      PosthogService.track_event(
        user_id: user.id,
        event: 'payment_succeeded_backend',
        properties: {
          email: user.email,
          invoice_id: invoice['id'],
          amount_paid: invoice['amount_paid'],
          currency: invoice['currency'],
          environment: Rails.env,
          server_tracked: true
        }
      )
    end
    
    # If this is a subscription invoice, update the user's subscription
    if invoice['subscription']
      subscription = Stripe::Subscription.retrieve(invoice['subscription'])
      update_user_subscription(subscription)
    end
  rescue => e
    Rails.logger.error "Error handling invoice payment succeeded: #{e.message}"
  end
  
  def handle_invoice_payment_failed(invoice)
    Rails.logger.error "Invoice payment failed: #{invoice['id']}"
    
    customer_id = invoice['customer']
    user = User.find_by(stripe_customer_id: customer_id)
    
    if user
      # Track failed payment (critical event for churn analysis)
      PosthogService.track_event(
        user_id: user.id,
        event: 'payment_failed_backend',
        properties: {
          email: user.email,
          invoice_id: invoice['id'],
          amount_due: invoice['amount_due'],
          currency: invoice['currency'],
          attempt_count: invoice['attempt_count'],
          environment: Rails.env,
          server_tracked: true
        }
      )
      
      # You might want to send an email notification here
      Rails.logger.info "Payment failed for user #{user.id}"
    end
  rescue => e
    Rails.logger.error "Error handling invoice payment failed: #{e.message}"
  end
  
  def update_user_subscription(subscription)
    customer_id = subscription['customer']
    user = User.find_by(stripe_customer_id: customer_id)
    
    if user
      user.update_subscription_from_stripe(subscription)
      Rails.logger.info "Updated subscription for user #{user.id}: #{subscription['status']}"
    else
      Rails.logger.error "User not found for customer ID: #{customer_id}"
    end
  rescue => e
    Rails.logger.error "Error updating user subscription: #{e.message}"
  end
end 