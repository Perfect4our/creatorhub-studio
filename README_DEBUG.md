# TikTok Studio Debug Tool

The TikTok Studio debug tool is a comprehensive health check system that validates your application's configuration, database integrity, API connections, and more.

## Quick Start

### Option 1: Using the convenient bin script
```bash
./bin/debug_studio
```

### Option 2: Using Rails directly
```bash
rails tiktok_studio:debug
```

## What It Checks

### 🔧 Environment Setup
- **Rails Environment**: Validates you're running in a standard Rails environment
- **Environment Variables**: Checks for required API keys and secrets:
  - `TIKTOK_CLIENT_KEY` & `TIKTOK_CLIENT_SECRET`
  - `YOUTUBE_API_KEY`
  - `INSTAGRAM_APP_ID` & `INSTAGRAM_APP_SECRET`
  - `TWITTER_API_KEY` & `TWITTER_API_SECRET`
  - `FACEBOOK_APP_ID` & `FACEBOOK_APP_SECRET`
  - `LINKEDIN_CLIENT_ID` & `LINKEDIN_CLIENT_SECRET`
  - `TWITCH_CLIENT_ID` & `TWITCH_CLIENT_SECRET`

### 💾 Database Health
- **Connection**: Tests database connectivity
- **Subscriptions**: Validates subscription records have required fields
- **Daily Stats**: Checks for recent analytics data
- **Orphaned Records**: Identifies data integrity issues

### ⚙️ Background Jobs
- **Sidekiq Status**: Checks if Sidekiq is running and connected to Redis
- **Failed Jobs**: Reports any jobs stuck in retry or dead queues

### 🌐 API Connections
Tests connectivity to all supported platforms:
- TikTok, YouTube, Instagram, Twitter, Facebook, LinkedIn, Twitch

### 👁️ View Health
- Scans ERB templates for unsafe variable usage
- Identifies potential nil reference errors
- Validates critical instance variables are handled safely

### 🛣️ Routes & Assets
- **Routes**: Ensures critical routes (`/dashboard`, `/subscriptions`) are registered
- **Partials**: Verifies required view partials exist

## Understanding the Output

### Status Icons
- ✅ **Pass**: Everything looks good
- ⚠️ **Warning**: Minor issues that may affect functionality  
- ❌ **Failed**: Critical issues that will likely break the app
- ⏭️ **Skipped**: Check couldn't be performed (usually missing dependencies)

### Exit Codes
- `0`: All checks passed or only warnings found
- `1`: Critical failures detected

## Common Issues & Solutions

### Missing Environment Variables
```bash
# Create a .env file or set in your shell:
export TIKTOK_CLIENT_KEY="your_key_here"
export TIKTOK_CLIENT_SECRET="your_secret_here"
# ... etc for other platforms
```

### Database Issues
```bash
# Run migrations
rails db:migrate

# Check for orphaned records
rails console
> Subscription.where(user_id: nil).count
```

### Sidekiq Not Running
```bash
# Start Sidekiq
bundle exec sidekiq

# Or check Redis connection
redis-cli ping
```

### View Safety Issues
The debug tool identifies ERB templates that use instance variables without nil safety. Fix by adding safe navigation:

```erb
<!-- Instead of: -->
<%= @stats[:views] %>

<!-- Use: -->
<%= @stats&.[](:views) || 0 %>
<!-- Or: -->
<%= number_with_delimiter(@stats[:views] || 0) %>
```

## Extending the Debug Tool

### Adding New Platform Checks
To add support for a new platform:

1. **Add environment variables** to the `required_vars` array in `check_required_env_vars`
2. **Add service class** to the `services` hash in `check_api_connections`
3. **Implement `test_connection`** in your service class:

```ruby
class NewPlatformService < BasePlatformService
  def self.test_connection
    begin
      # Test API connection here
      api_client = SomeApiClient.new(ENV['NEW_PLATFORM_API_KEY'])
      response = api_client.test_endpoint
      { success: true, message: "API connection successful" }
    rescue => e
      { success: false, message: "API test failed: #{e.message}" }
    end
  end
end
```

### Adding Custom Checks
Add new check methods to `lib/tasks/debug.rake`:

```ruby
def check_custom_feature
  begin
    # Your custom validation logic here
    if some_condition
      { status: :pass, details: "Feature working correctly", platform: "Custom" }
    else
      { status: :fail, details: "Feature is broken", platform: "Custom" }
    end
  rescue => e
    { status: :fail, details: "Error: #{e.message}", platform: "Custom" }
  end
end
```

Then add it to the main task:

```ruby
custom_result = check_custom_feature
debug_results << custom_result
print_check_result("Custom Feature", custom_result[:status], custom_result[:details])
```

## Automation & CI/CD

### Running in CI
```yaml
# .github/workflows/debug.yml
name: Health Check
on: [push, pull_request]
jobs:
  debug:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
      - name: Install dependencies
        run: bundle install
      - name: Run debug check
        run: rails tiktok_studio:debug
```

### Scheduled Health Checks
```ruby
# config/schedule.rb (using whenever gem)
every 1.hour do
  rake "tiktok_studio:debug"
end
```

## Troubleshooting

### Debug Tool Itself Fails
```bash
# Check if rake task loads
rails -T | grep tiktok

# Test individual components
rails runner "puts Rails.env"
rails runner "puts Subscription.count"
```

### False Positives
Some warnings may be expected in development:
- Missing API keys for platforms you're not using
- Sidekiq not running in development mode
- Empty stats tables in fresh installations

## Performance

The debug tool is designed to be fast and non-intrusive:
- Read-only operations (no data modification)
- Minimal API calls (only test endpoints)
- Cached results where possible
- Typically runs in under 10 seconds

---

**Need help?** Check the [troubleshooting wiki](https://github.com/your-org/tiktok-studio/wiki/troubleshooting) or open an issue. 