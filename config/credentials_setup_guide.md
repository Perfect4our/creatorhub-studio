# Encrypted Credentials Setup Guide

Rails provides a secure way to store sensitive data like API keys using encrypted credentials. This is much safer than environment variables for production.

## 🔐 How It Works

- Credentials are stored in encrypted `.yml.enc` files
- Each environment can have its own credentials file
- Encryption keys are stored separately and should never be committed to Git
- Rails automatically decrypts credentials at runtime

## 📁 File Structure

```
config/
├── credentials.yml.enc          # Development credentials (encrypted)
├── master.key                   # Development encryption key (gitignored)
├── credentials/
│   ├── test.yml.enc            # Test environment credentials
│   ├── test.key                # Test encryption key (gitignored)
│   ├── production.yml.enc      # Production credentials
│   └── production.key          # Production encryption key (gitignored)
```

## 🛠️ Setup Instructions

### 1. Development Environment

Edit development credentials:
```bash
EDITOR="code --wait" rails credentials:edit
```

Add your API credentials in this format:
```yaml
youtube:
  api_key: "your_youtube_api_key_here"
  client_id: "your_youtube_client_id_here"
  client_secret: "your_youtube_client_secret_here"

tiktok:
  client_id: "your_tiktok_client_id_here"
  client_secret: "your_tiktok_client_secret_here"

instagram:
  app_id: "your_instagram_app_id_here"
  app_secret: "your_instagram_app_secret_here"

twitter:
  api_key: "your_twitter_api_key_here"
  api_secret: "your_twitter_api_secret_here"

facebook:
  app_id: "your_facebook_app_id_here"
  app_secret: "your_facebook_app_secret_here"

linkedin:
  client_id: "your_linkedin_client_id_here"
  client_secret: "your_linkedin_client_secret_here"

twitch:
  client_id: "your_twitch_client_id_here"
  client_secret: "your_twitch_client_secret_here"

# Secret key base for sessions (auto-generated)
secret_key_base: "..."
```

### 2. Test Environment

Edit test credentials:
```bash
EDITOR="code --wait" rails credentials:edit --environment test
```

Use mock/test API keys:
```yaml
youtube:
  api_key: "test_youtube_api_key"
  client_id: "test_youtube_client_id"
  client_secret: "test_youtube_client_secret"

tiktok:
  client_id: "test_tiktok_client_id"
  client_secret: "test_tiktok_client_secret"

# Add other platforms with test values...
```

### 3. Production Environment

Edit production credentials:
```bash
EDITOR="code --wait" rails credentials:edit --environment production
```

Use your real production API keys (same format as development).

## 🔑 Managing Encryption Keys

### Development
- `config/master.key` is automatically created
- Keep this file secure and backed up
- Share with team members securely (password manager, etc.)

### Production
- `config/credentials/production.key` contains the production encryption key
- **CRITICAL**: Store this key securely on your production server
- Set as environment variable: `RAILS_MASTER_KEY=your_production_key`
- Or place the key file directly on the server (not in Git)

## 🚀 Deployment

### Heroku
```bash
heroku config:set RAILS_MASTER_KEY=your_production_key
```

### Other Platforms
Set the `RAILS_MASTER_KEY` environment variable on your server.

## 🔍 Accessing Credentials in Code

The app automatically falls back to environment variables if credentials aren't found:

```ruby
# In services/youtube_service.rb
@api_key = Rails.application.credentials.youtube&.api_key || ENV['YOUTUBE_API_KEY']
```

This allows for flexible deployment options.

## 🧪 Testing Your Setup

Run the debug script to check your credentials:
```bash
./bin/debug_studio
```

## 🔒 Security Best Practices

1. **Never commit encryption keys** - They're automatically gitignored
2. **Use different keys for each environment** - Test/staging/production should be separate
3. **Backup your keys securely** - Store in a password manager
4. **Rotate keys periodically** - Especially if compromised
5. **Use least privilege** - Only give API keys the minimum required permissions

## 🆘 Troubleshooting

### "Missing encryption key" error
- Make sure `config/master.key` exists
- Or set `RAILS_MASTER_KEY` environment variable

### "Couldn't decrypt" error
- The encryption key doesn't match the encrypted file
- You may need to re-encrypt with the correct key

### Credentials not loading
- Check file permissions
- Verify the YAML syntax is correct
- Run `rails credentials:show` to test decryption

## 📚 Additional Resources

- [Rails Guides: Securing Rails Applications](https://guides.rubyonrails.org/security.html#custom-credentials)
- [Rails Credentials Documentation](https://guides.rubyonrails.org/configuring.html#custom-credentials)

# Rails Encrypted Credentials Setup for Stripe

## Opening the Credentials File

```bash
EDITOR="nano" bin/rails credentials:edit
```

## Add This Structure to Your Credentials File

```yaml
# Stripe Configuration
stripe:
  # Test Keys (for development)
  test_publishable_key: pk_test_your_test_publishable_key_here
  test_secret_key: sk_test_your_test_secret_key_here
  test_webhook_secret: whsec_your_test_webhook_secret_here
  
  # Live Keys (for production)
  publishable_key: pk_live_your_live_publishable_key_here
  secret_key: sk_live_your_live_secret_key_here
  webhook_secret: whsec_your_live_webhook_secret_here
  
  # Price IDs
  monthly_price_id: price_your_monthly_price_id_here
  yearly_price_id: price_your_yearly_price_id_here
  
  # Live Price IDs (for production - usually the same as test)
  live_monthly_price_id: price_your_live_monthly_price_id_here
  live_yearly_price_id: price_your_live_yearly_price_id_here

# Your existing secret_key_base should remain unchanged
secret_key_base: your_existing_secret_key_base_here
```

## How to Edit:

1. **Run**: `EDITOR="nano" bin/rails credentials:edit`
2. **Add the stripe section** above (replace with your actual keys)
3. **Save**: `Ctrl+X`, then `Y`, then `Enter`
4. **Test**: `bin/rails credentials:show` to verify

## Security Notes:

- ✅ **DO** commit `config/credentials.yml.enc` to git
- ❌ **DON'T** commit `config/master.key` to git
- ✅ **DO** store `config/master.key` securely (environment variable in production)
- ✅ **DO** use different keys for test and production

## Production Deployment:

Set this environment variable on your production server:
```bash
RAILS_MASTER_KEY=your_master_key_from_config/master.key
```

## Testing Credentials:

```bash
# View credentials
bin/rails credentials:show

# Test specific values
bin/rails runner "puts Rails.application.credentials.dig(:stripe, :test_secret_key)"
``` 