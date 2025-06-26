# Stripe Webhook Setup Guide

This guide will help you set up Stripe webhooks for both development and production environments.

## Development Webhook Setup

### 1. Install and Authenticate Stripe CLI

```bash
# Install Stripe CLI (if not already installed)
brew install stripe/stripe-cli/stripe

# Authenticate with your Stripe account
stripe login
```

### 2. Start Local Webhook Listener

```bash
# Start the webhook listener (run this in a separate terminal)
stripe listen --forward-to localhost:3000/webhooks/stripe
```

This will output a webhook signing secret that looks like:
```
whsec_5390d7644df0018c308b2189ce8e726189f6289d109ac999a84c73366e827cf2
```

### 3. Add Development Webhook Secret to Credentials

```bash
# Edit encrypted credentials
EDITOR="code --wait" bin/rails credentials:edit
```

Add the development webhook secret:
```yaml
stripe:
  test_publishable_key: pk_test_your_key_here
  test_secret_key: sk_test_your_key_here
  test_webhook_secret: whsec_5390d7644df0018c308b2189ce8e726189f6289d109ac999a84c73366e827cf2
  monthly_price_id: price_your_monthly_price_id
  yearly_price_id: price_your_yearly_price_id
```

## Production Webhook Setup

### 1. Create Webhook Endpoint in Stripe Dashboard

1. Go to [Stripe Dashboard → Webhooks](https://dashboard.stripe.com/webhooks)
2. Click **"Add endpoint"**
3. Enter your production URL: `https://your-production-domain.com/webhooks/stripe`
4. Select these events to listen for:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Click **"Add endpoint"**

### 2. Get Production Webhook Secret

1. Click on your newly created webhook endpoint
2. In the **"Signing secret"** section, click **"Reveal"**
3. Copy the webhook signing secret (starts with `whsec_`)

### 3. Add Production Webhook Secret to Credentials

```bash
# Edit encrypted credentials
EDITOR="code --wait" bin/rails credentials:edit
```

Add the production webhook secret:
```yaml
stripe:
  # Test/Development keys
  test_publishable_key: pk_test_your_key_here
  test_secret_key: sk_test_your_key_here
  test_webhook_secret: whsec_your_development_secret_here
  
  # Production keys
  publishable_key: pk_live_your_live_key_here
  secret_key: sk_live_your_live_key_here
  webhook_secret: whsec_your_production_secret_here
  
  # Price IDs (same for test and live)
  monthly_price_id: price_your_monthly_price_id
  yearly_price_id: price_your_yearly_price_id
```

## Testing Webhooks

### Development Testing

1. Start your Rails server: `bin/rails server`
2. In another terminal, start the Stripe CLI listener:
   ```bash
   stripe listen --forward-to localhost:3000/webhooks/stripe
   ```
3. Trigger test events:
   ```bash
   # Test subscription creation
   stripe trigger customer.subscription.created
   
   # Test payment success
   stripe trigger invoice.payment_succeeded
   ```

### Production Testing

1. Use the Stripe Dashboard to create test subscriptions
2. Monitor your Rails logs for webhook events
3. Check the webhook endpoint logs in Stripe Dashboard

## Webhook Events Handled

Your application handles these webhook events:

- **`checkout.session.completed`** - When a customer completes checkout
- **`customer.subscription.created`** - When a subscription is created
- **`customer.subscription.updated`** - When a subscription is modified
- **`customer.subscription.deleted`** - When a subscription is cancelled
- **`invoice.payment_succeeded`** - When a payment succeeds
- **`invoice.payment_failed`** - When a payment fails

## Troubleshooting

### Common Issues

1. **"Invalid signature" error**
   - Check that your webhook secret is correct
   - Ensure you're using the right secret for your environment

2. **Webhook not receiving events**
   - Verify your endpoint URL is correct
   - Check that your server is accessible from the internet (for production)
   - Ensure the webhook events are selected in Stripe Dashboard

3. **"User not found" errors**
   - Make sure users have `stripe_customer_id` set when creating Stripe customers
   - Check that the customer ID matches between Stripe and your database

### Debugging

1. Check Rails logs for webhook processing:
   ```bash
   tail -f log/development.log | grep -i webhook
   ```

2. Check Stripe Dashboard webhook logs for delivery status

3. Use the test script to verify configuration:
   ```bash
   bin/test_stripe
   ```

## Security Notes

- Webhook secrets are encrypted in your credentials file
- Never commit webhook secrets to version control
- Use different secrets for development and production
- The webhook endpoint validates signatures to ensure requests come from Stripe

## Next Steps

1. Test webhook functionality in development
2. Deploy to production with proper webhook configuration
3. Monitor webhook delivery in Stripe Dashboard
4. Set up alerts for failed webhook deliveries 