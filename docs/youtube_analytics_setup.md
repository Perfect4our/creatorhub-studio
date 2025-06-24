# YouTube Analytics API Setup Guide

## Overview

YouTube Analytics API provides more accurate and detailed data compared to the basic YouTube Data API. However, it requires additional Google approval and setup steps.

## Features Enabled with Analytics API

### 📊 Advanced Analytics
- **Real-time subscriber counts** (updated more frequently)
- **Hourly view breakdowns** (approximated from daily data)
- **Revenue data** (estimated revenue, ad revenue, YouTube Premium revenue)
- **Detailed demographics** (age groups, gender, geography)
- **Top-performing videos** with engagement metrics

### 📈 Enhanced Reporting
- **Custom date ranges** for historical data
- **Comparative analytics** (growth rates, trends)
- **Monetization insights** (RPM, CPM, revenue sources)
- **Audience retention** and engagement metrics

## Setup Requirements

### 1. Google Cloud Console Setup

1. **Create/Access Project**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select or create a project for your application

2. **Enable APIs**
   ```
   Required APIs:
   - YouTube Data API v3 (already enabled)
   - YouTube Analytics API
   - YouTube Reporting API (optional, for bulk data)
   ```

3. **OAuth 2.0 Credentials**
   - Your existing YouTube Data API credentials will work
   - Ensure redirect URIs include your callback URL

### 2. YouTube Analytics API Application

⚠️ **Important**: YouTube Analytics API requires separate approval from Google.

1. **Submit Application**
   - Go to [YouTube API Services](https://developers.google.com/youtube/reporting/v1/reports)
   - Click "Request Access" for Analytics API
   - Fill out the application form with:
     - **Application Name**: TikTok Studio
     - **Application Description**: Multi-platform analytics dashboard for content creators
     - **Use Case**: Provide creators with unified analytics across platforms
     - **Data Usage**: Display analytics, demographics, and revenue data to account owners

2. **Required Information**
   ```
   Business Information:
   - Company/Organization name
   - Contact email
   - Website URL
   - Privacy Policy URL
   - Terms of Service URL
   
   Technical Information:
   - OAuth 2.0 Client ID
   - Redirect URIs
   - Scopes requested:
     - https://www.googleapis.com/auth/yt-analytics.readonly
     - https://www.googleapis.com/auth/yt-analytics-monetary.readonly
   ```

3. **Approval Process**
   - **Timeline**: 2-6 weeks typically
   - **Review**: Google reviews your application and use case
   - **Compliance**: Must meet YouTube API Terms of Service
   - **Verification**: May require additional documentation

### 3. Application Configuration

Once approved, update your credentials:

```yaml
# config/credentials.yml.enc
youtube:
  api_key: "your_youtube_api_key"
  client_id: "your_client_id"
  client_secret: "your_client_secret"
  # These scopes will be available after approval
  analytics_scopes:
    - "https://www.googleapis.com/auth/yt-analytics.readonly"
    - "https://www.googleapis.com/auth/yt-analytics-monetary.readonly"
```

## How It Works

### 1. OAuth Flow

```ruby
# Basic Connection (available now)
GET /auth/youtube
# Scopes: youtube.readonly

# Analytics Connection (requires approval)
GET /auth/youtube?analytics=true  
# Scopes: youtube.readonly + yt-analytics.readonly + yt-analytics-monetary.readonly
```

### 2. API Endpoints Used

```ruby
# YouTube Data API v3 (Basic)
https://www.googleapis.com/youtube/v3/channels
https://www.googleapis.com/youtube/v3/videos
https://www.googleapis.com/youtube/v3/search

# YouTube Analytics API (Advanced)
https://youtubeanalytics.googleapis.com/v2/reports
```

### 3. Data Enhancement

| Feature | Basic API | Analytics API |
|---------|-----------|---------------|
| Subscriber Count | ✅ Total only | ✅ Daily changes, gains/losses |
| View Count | ✅ Total only | ✅ Daily breakdown, hourly estimates |
| Revenue Data | ❌ Not available | ✅ Estimated revenue, ad revenue |
| Demographics | ❌ Not available | ✅ Age, gender, geography |
| Real-time Data | ❌ Limited | ✅ More frequent updates |

## Testing During Development

### Mock Mode
While waiting for approval, the application uses mock data:

```ruby
# app/services/youtube_service.rb
def analytics_api_available?
  # Returns false until Analytics API is approved
  scope = @subscription.scope || ''
  scope.include?('yt-analytics.readonly')
end
```

### Approval Status Check
```ruby
# Check if user has Analytics API enabled
subscription = current_user.subscriptions.find_by(platform: 'youtube')
if subscription&.scope&.include?('yt-analytics.readonly')
  # Analytics API is available
  analytics_data = youtube_service.get_analytics_data
else
  # Fall back to basic API + mock data
  analytics_data = youtube_service.mock_analytics_data
end
```

## Implementation Status

### ✅ Completed
- [x] YouTube Analytics API service methods
- [x] OAuth flow with Analytics scopes
- [x] Fallback to mock data when not approved
- [x] UI indicators for Analytics API status
- [x] Enhanced subscription management

### 🔄 In Progress
- [ ] Google Cloud Console application submission
- [ ] YouTube Analytics API approval process
- [ ] Production credentials configuration

### ⏳ Pending Approval
- [ ] Real-time revenue data
- [ ] Detailed demographics
- [ ] Advanced analytics features

## Troubleshooting

### Common Issues

1. **"Analytics API not available"**
   - Check if scopes include `yt-analytics.readonly`
   - Verify Google approval status
   - Ensure credentials are properly configured

2. **"Insufficient permissions"**
   - Re-authenticate with Analytics scopes
   - Check OAuth consent screen configuration
   - Verify API is enabled in Google Cloud Console

3. **"Quota exceeded"**
   - YouTube Analytics API has different quotas
   - Implement caching for frequently accessed data
   - Consider batching requests

### Debug Commands

```bash
# Check current subscription scopes
rails runner "puts User.find(1).subscriptions.find_by(platform: 'youtube')&.scope"

# Test Analytics API availability
rails runner "puts YoutubeService.new(User.find(1).subscriptions.find_by(platform: 'youtube')).analytics_api_available?"

# Test Analytics API call (will use mock data if not approved)
rails runner "puts YoutubeService.new(User.find(1).subscriptions.find_by(platform: 'youtube')).get_analytics_data"
```

## Next Steps

1. **Submit Application**: Apply for YouTube Analytics API access
2. **Wait for Approval**: 2-6 weeks processing time
3. **Update Credentials**: Add approved scopes to production
4. **Test Integration**: Verify real Analytics API data
5. **Monitor Usage**: Track API quotas and limits

## Resources

- [YouTube Analytics API Documentation](https://developers.google.com/youtube/analytics)
- [YouTube API Terms of Service](https://developers.google.com/youtube/terms/api-services-terms-of-service)
- [Google Cloud Console](https://console.cloud.google.com/)
- [YouTube Creator Studio](https://studio.youtube.com/) (for comparison) 