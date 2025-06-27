# Stripe Integration Setup Guide

This guide will help you set up Stripe subscription billing for CreatorHub Studio.

## 1. Create a Stripe Account

1. Go to [stripe.com](https://stripe.com) and create an account
2. Complete the account verification process
3. Navigate to the Dashboard

## 2. Get API Keys

### Test Keys (for development)
1. In the Stripe Dashboard, make sure you're in **Test mode** (toggle in top-left)
2. Go to **Developers** > **API keys**
3. Copy the following keys:
   - **Publishable key** (starts with `pk_test_`)
   - **Secret key** (starts with `sk_test_`)

### Set Environment Variables

Create a `.env` file in your project root or set these environment variables:

```bash
# Stripe Test Keys
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
```

## 3. Create Products and Prices

### Via Stripe Dashboard:

1. Go to **Products** > **+ Add Product**

#### Monthly Plan:
- **Product Name**: CreatorHub Studio Pro (Monthly)
- **Pricing Model**: Recurring
- **Price**: $29.00
- **Billing Period**: Monthly
- **Currency**: USD
- Copy the **Price ID** (starts with `price_`)

#### Yearly Plan:
- **Product Name**: CreatorHub Studio Pro (Yearly)  
- **Pricing Model**: Recurring
- **Price**: $290.00
- **Billing Period**: Yearly
- **Currency**: USD
- Copy the **Price ID** (starts with `price_`)

### Add Price IDs to Environment:

```bash
STRIPE_MONTHLY_PRICE_ID=price_your_monthly_price_id
STRIPE_YEARLY_PRICE_ID=price_your_yearly_price_id
```

## 4. Set Up Webhooks

1. Go to **Developers** > **Webhooks**
2. Click **+ Add endpoint**
3. **Endpoint URL**: `https://your-domain.com/webhooks/stripe`
   - For local development: `https://your-ngrok-url.ngrok.io/webhooks/stripe`
4. **Events to send**:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Copy the **Signing secret** (starts with `whsec_`)

## 5. Update Rails Credentials

Instead of environment variables, you can store keys in Rails credentials:

```bash
EDITOR="nano" rails credentials:edit
```

Add this structure:

```yaml
stripe:
  test_publishable_key: pk_test_your_key_here
  test_secret_key: sk_test_your_key_here
  test_webhook_secret: whsec_your_webhook_secret_here
  publishable_key: pk_live_your_live_key_here  # For production
  secret_key: sk_live_your_live_key_here       # For production
  webhook_secret: whsec_your_live_webhook_secret_here  # For production
```

## 6. Test the Integration

### Test Cards:
Use these test card numbers in development:

- **Success**: `4242424242424242`
- **Decline**: `4000000000000002`
- **Insufficient funds**: `4000000000009995`
- **Expired card**: `4000000000000069`

**CVV**: Any 3 digits  
**Expiry**: Any future date  
**ZIP**: Any valid ZIP code

### Test Flow:
1. Start your Rails server: `rails server`
2. Visit `http://localhost:3000/pricing`
3. Click on a subscription plan
4. Use a test card to complete payment
5. Verify the webhook is received and user is updated

## 7. Local Development with ngrok

For webhook testing locally:

1. Install ngrok: `npm install -g ngrok` or download from [ngrok.com](https://ngrok.com)
2. Start your Rails server: `rails server`
3. In another terminal: `ngrok http 3000`
4. Use the ngrok HTTPS URL for your webhook endpoint

## 8. Production Setup

1. Switch to **Live mode** in Stripe Dashboard
2. Get your live API keys
3. Update your production environment variables or Rails credentials
4. Create a production webhook endpoint
5. Test thoroughly before going live

## 9. Billing Portal Configuration

1. In Stripe Dashboard, go to **Settings** > **Billing Portal**
2. Configure what customers can do:
   - ✅ Update payment method
   - ✅ Download invoices
   - ✅ Cancel subscription
   - ✅ Change plan (if you want to allow this)

## Environment Variables Summary

Here's the complete list of environment variables you need:

```bash
# Required for development
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_MONTHLY_PRICE_ID=price_...
STRIPE_YEARLY_PRICE_ID=price_...

# Required for production
STRIPE_LIVE_PUBLISHABLE_KEY=pk_live_...
STRIPE_LIVE_SECRET_KEY=sk_live_...
STRIPE_LIVE_WEBHOOK_SECRET=whsec_...
```

## Troubleshooting

### Common Issues:

1. **Webhook signature verification failed**
   - Check that your webhook secret is correct
   - Ensure the endpoint URL is accessible

2. **Invalid API key**
   - Verify you're using the correct keys for your environment
   - Check that keys haven't been regenerated

3. **Price not found**
   - Verify your price IDs are correct
   - Ensure products are active in Stripe

4. **Customer not found**
   - Check that customer creation is working properly
   - Verify webhook handling creates/updates users correctly

## Next Steps

After setup is complete:

1. Test the complete flow with test cards
2. Verify webhooks are updating user subscription status
3. Test the billing portal functionality
4. Set up monitoring for failed payments
5. Configure email notifications for subscription events 