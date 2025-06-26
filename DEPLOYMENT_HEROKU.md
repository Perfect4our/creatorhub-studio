# CreatorHub Studio - Heroku Deployment Guide

## Prerequisites

1. **Heroku Account**: Sign up at [heroku.com](https://heroku.com)
2. **Heroku CLI**: Install the Heroku CLI
   ```bash
   brew tap heroku/brew && brew install heroku
   ```
3. **Git Repository**: Your code should be in a Git repository

## Quick Deployment (Automated)

The easiest way to deploy is using our automated script:

```bash
# Login to Heroku (first time only)
heroku login

# Deploy to Heroku (will create app if it doesn't exist)
./bin/heroku_deploy

# Or specify a custom app name
./bin/heroku_deploy your-custom-name
```

This script will:
- Create a Heroku app
- Add PostgreSQL and Redis addons
- Set all required environment variables
- Deploy your code
- Run database migrations
- Open your app in the browser

## Manual Deployment Steps

If you prefer to deploy manually:

### 1. Login and Create App

```bash
heroku login
heroku create creatorhub-studio  # or your preferred name
```

### 2. Add Required Addons

```bash
# PostgreSQL database
heroku addons:create heroku-postgresql:essential-0

# Redis for caching and background jobs
heroku addons:create heroku-redis:essential-0
```

### 3. Set Environment Variables

```bash
heroku config:set \
  RAILS_ENV=production \
  RACK_ENV=production \
  RAILS_MASTER_KEY=ad5ab364558fc7e7ad801d64cbbe3aed \
  SECRET_KEY_BASE=ef6572c2e7298dd1777b74dc58a19afe93cb8763a57ec22dd0d334912c87bd5c4ea40ce1d9d4da3ee01e062e3a0755691857134e92e6aff22864ecfb98567807 \
      YOUTUBE_API_KEY=YOUR_YOUTUBE_API_KEY_HERE \
  YOUTUBE_CLIENT_ID=YOUR_YOUTUBE_CLIENT_ID_HERE \
YOUTUBE_CLIENT_SECRET=YOUR_YOUTUBE_CLIENT_SECRET_HERE
```

### 4. Deploy Your Code

```bash
git push heroku main
```

### 5. Setup Database

```bash
heroku run rails db:migrate
heroku run rails db:seed
```

## Adding a Custom Domain

Once deployed, you can add a custom domain:

### 1. Register Domain
- Register `creatorhub.studio` at a domain registrar (Namecheap, Cloudflare, etc.)
- Cost: ~$10-15/year

### 2. Add Domain to Heroku
```bash
heroku domains:add creatorhub.studio
heroku domains:add www.creatorhub.studio
```

### 3. Get SSL Certificate
```bash
heroku certs:auto:enable
```

### 4. Configure DNS
Add these DNS records at your domain registrar:

**CNAME Records:**
- `creatorhub.studio` → `your-app-name.herokuapp.com`
- `www.creatorhub.studio` → `your-app-name.herokuapp.com`

### 5. Update Environment
```bash
heroku config:set CUSTOM_DOMAIN=true
```

## Cost Breakdown

- **Heroku Dyno**: $7/month (Basic plan)
- **PostgreSQL**: $9/month (Essential plan)
- **Redis**: $15/month (Essential plan)
- **Domain**: $10-15/year
- **Total**: ~$31/month + domain

## Environment Variables

### Required for Basic Functionality
```
RAILS_ENV=production
RACK_ENV=production
RAILS_MASTER_KEY=ad5ab364558fc7e7ad801d64cbbe3aed
SECRET_KEY_BASE=ef6572c2e7298dd1777b74dc58a19afe93cb8763a57ec22dd0d334912c87bd5c4ea40ce1d9d4da3ee01e062e3a0755691857134e92e6aff22864ecfb98567807
```

### YouTube Integration
```
YOUTUBE_API_KEY=YOUR_YOUTUBE_API_KEY_HERE
YOUTUBE_CLIENT_ID=YOUR_YOUTUBE_CLIENT_ID_HERE
YOUTUBE_CLIENT_SECRET=YOUR_YOUTUBE_CLIENT_SECRET_HERE
```

### Optional Platform APIs
```
TIKTOK_CLIENT_KEY=your_tiktok_key
TIKTOK_CLIENT_SECRET=your_tiktok_secret
INSTAGRAM_CLIENT_ID=your_instagram_id
INSTAGRAM_CLIENT_SECRET=your_instagram_secret
TWITTER_API_KEY=your_twitter_key
TWITTER_API_SECRET=your_twitter_secret
LINKEDIN_CLIENT_ID=your_linkedin_id
LINKEDIN_CLIENT_SECRET=your_linkedin_secret
TWITCH_CLIENT_ID=your_twitch_id
TWITCH_CLIENT_SECRET=your_twitch_secret
```

### Email Configuration (Optional)
```
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_USERNAME=apikey
SMTP_PASSWORD=your_sendgrid_api_key
```

## Post-Deployment Setup

### 1. Create Admin User
```bash
heroku run rails console
User.create!(
  email: 'admin@creatorhub.studio',
  password: 'secure_password',
  admin: true,
  permanent_subscription: true
)
```

### 2. Test API Connections
```bash
heroku run rails runner "puts YoutubeService.new.test_connection"
```

### 3. Enable Background Jobs
```bash
# Scale worker dyno for background jobs
heroku ps:scale worker=1
```

## Monitoring & Logs

```bash
# View logs
heroku logs --tail

# Check app status
heroku ps

# View database info
heroku pg:info

# View Redis info
heroku redis:info
```

## Troubleshooting

### Common Issues

1. **Build Failures**: Check that all gems are in the Gemfile
2. **Database Errors**: Ensure migrations have run: `heroku run rails db:migrate`
3. **Asset Issues**: Check that assets are compiled: `heroku run rails assets:precompile`
4. **Environment Variables**: Verify all required vars: `heroku config`

### Debug Commands
```bash
# Check environment
heroku run rails runner "puts Rails.env"

# Test database connection
heroku run rails runner "puts ActiveRecord::Base.connection.active?"

# Check Redis connection
heroku run rails runner "puts Redis.new(url: ENV['REDIS_URL']).ping"
```

## Security Notes

- All API keys are already configured for development/testing
- For production, consider rotating the SECRET_KEY_BASE
- Enable 2FA on your Heroku account
- Regularly update dependencies

## Support

- Heroku Documentation: [devcenter.heroku.com](https://devcenter.heroku.com)
- Rails on Heroku: [devcenter.heroku.com/articles/getting-started-with-rails7](https://devcenter.heroku.com/articles/getting-started-with-rails7)

---

**Ready to deploy? Run `./bin/heroku_deploy` and your app will be live in minutes!** 🚀 