# 🚀 CreatorHub.Studio Deployment Guide

## Overview
This guide will help you deploy CreatorHub.Studio to production using the domain `creatorhub.studio`.

## 1. 🌐 Domain Setup

### Register creatorhub.studio
1. Go to [Namecheap](https://namecheap.com) or [Cloudflare](https://cloudflare.com)
2. Search for `creatorhub.studio`
3. Purchase the domain (approximately $10-15/year)

## 2. 🚀 Deployment Options

### Option A: Railway (Recommended)
Railway offers the easiest deployment with built-in PostgreSQL and Redis.

1. **Create Railway Account**
   - Go to [railway.app](https://railway.app)
   - Sign up with GitHub

2. **Deploy from GitHub**
   ```bash
   # Push your code to GitHub first
   git add .
   git commit -m "Prepare for production deployment"
   git push origin main
   ```

3. **Create Railway Project**
   - Click "New Project" → "Deploy from GitHub repo"
   - Select your repository
   - Railway will auto-detect it's a Rails app

4. **Add Database**
   - Click "New" → "Database" → "Add PostgreSQL"
   - Railway will provide a DATABASE_URL automatically

5. **Add Redis**
   - Click "New" → "Database" → "Add Redis" 
   - Railway will provide a REDIS_URL automatically

6. **Configure Environment Variables**
   - Go to your app → Variables tab
   - Add all variables from `.env.production.example`
   - Railway auto-generates: `DATABASE_URL`, `REDIS_URL`

### Option B: Heroku
```bash
# Install Heroku CLI
brew install heroku/brew/heroku

# Create Heroku app
heroku create creatorhub-studio

# Add addons
heroku addons:create heroku-postgresql:mini
heroku addons:create heroku-redis:mini

# Set environment variables
heroku config:set RAILS_ENV=production
heroku config:set SECRET_KEY_BASE=$(rails secret)
# ... add all other environment variables

# Deploy
git push heroku main

# Run migrations
heroku run rails db:migrate
heroku run rails db:seed
```

## 3. 🔧 Domain Configuration

### Point Domain to Hosting Platform

#### For Railway:
1. Go to your Railway project → Settings → Domains
2. Click "Custom Domain" 
3. Enter `creatorhub.studio`
4. Railway will provide DNS records

#### DNS Configuration:
Add these records to your domain provider:
```
Type: CNAME
Name: @
Value: [your-railway-app].railway.app

Type: CNAME  
Name: www
Value: [your-railway-app].railway.app
```

## 4. 🔐 SSL Certificate
Most hosting platforms (Railway, Heroku) provide free SSL certificates automatically when you add a custom domain.

## 5. 📧 Email Configuration

### Using SendGrid (Recommended)
1. Sign up for [SendGrid](https://sendgrid.com)
2. Create an API key
3. Add to environment variables:
   ```
   SMTP_ADDRESS=smtp.sendgrid.net
   SMTP_USERNAME=apikey
   SMTP_PASSWORD=your_sendgrid_api_key
   FROM_EMAIL=noreply@creatorhub.studio
   ```

## 6. 🔑 API Keys Setup

You'll need to register your app with each platform:

### YouTube Data API
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create new project → Enable YouTube Data API v3
3. Create credentials (API Key + OAuth Client)

### TikTok for Developers
1. Go to [TikTok for Developers](https://developers.tiktok.com)
2. Register your app
3. Get Client Key and Client Secret

### Instagram Basic Display API
1. Go to [Facebook for Developers](https://developers.facebook.com)
2. Create app → Add Instagram Basic Display
3. Get App ID and App Secret

### Twitter API v2
1. Go to [Twitter Developer Portal](https://developer.twitter.com)
2. Create app and get API keys

### LinkedIn API
1. Go to [LinkedIn Developer Portal](https://developer.linkedin.com)
2. Create app and get Client ID/Secret

### Twitch API
1. Go to [Twitch Developer Console](https://dev.twitch.tv)
2. Register application

## 7. 🚀 Deploy!

### Option 1: Automated Deployment
```bash
# Copy environment template
cp .env.production.example .env.production

# Edit with your values
nano .env.production

# Run deployment script
./bin/deploy
```

### Option 2: Manual Deployment
```bash
# Install dependencies
bundle install --without development test

# Precompile assets
RAILS_ENV=production rails assets:precompile

# Run migrations
RAILS_ENV=production rails db:migrate

# Deploy to your platform
git push [platform] main
```

## 8. 🎯 Post-Deployment

### Verify Everything Works
1. Visit `https://creatorhub.studio`
2. Test user registration
3. Test social platform connections
4. Verify analytics dashboard
5. Check time selector functionality

### Monitor & Maintain
- Set up error tracking (Sentry)
- Monitor performance
- Regular backups
- Keep dependencies updated

## 9. 💰 Estimated Costs

### Monthly Operating Costs:
- **Domain**: ~$1/month (creatorhub.studio)
- **Railway Starter**: $5/month (512MB RAM, PostgreSQL, Redis)
- **SendGrid**: Free tier (100 emails/day)
- **Total**: ~$6/month to start

### Scaling Options:
- **Railway Pro**: $20/month (8GB RAM, better performance)
- **Dedicated database**: $15-30/month
- **CDN**: $5-10/month for faster global loading

## 🎉 You're Live!

Once deployed, your CreatorHub.Studio will be available at:
- Primary: `https://creatorhub.studio`
- WWW: `https://www.creatorhub.studio`

Users can register, connect their social media accounts, and start tracking their content performance across platforms!

## 4. Set Environment Variables

In your hosting platform dashboard, set these environment variables:

### **Critical Security Variables**
```bash
# Rails Master Key (REQUIRED for decrypting credentials)
RAILS_MASTER_KEY=ad5ab364558fc7e7ad801d64cbbe3aed

# Secret Key Base (OPTIONAL - has built-in fallback)
# SECRET_KEY_BASE=ef6572c2e7298dd1777b74dc58a19afe93cb8763a57ec22dd0d334912c87bd5c4ea40ce1d9d4da3ee01e062e3a0755691857134e92e6aff22864ecfb98567807

# Rails Environment
RAILS_ENV=production
RACK_ENV=production
```

### **Database & Redis** (Auto-configured on Railway)
```bash
# These are usually auto-set by Railway, but verify:
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
```

### **Domain Configuration**
```bash
# Your custom domain
RAILS_FORCE_SSL=true
``` 