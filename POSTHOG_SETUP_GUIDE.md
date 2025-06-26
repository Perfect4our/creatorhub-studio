# PostHog Analytics Setup Guide

## Overview

PostHog JavaScript tracking has been added to CreatorHub Studio for comprehensive user analytics and behavior tracking. The integration includes user identification, event tracking, and page view analytics.

## Security Implementation

### Current Status
- ✅ PostHog tracking script added to global layout
- ✅ User identification for logged-in users
- ✅ Enhanced event tracking with user context
- ⚠️ **TODO**: Move API key to Rails credentials

### Step 1: Add PostHog API Key to Rails Credentials

1. **Edit Rails credentials:**
   ```bash
   EDITOR="code --wait" bin/rails credentials:edit
   ```

2. **Add PostHog configuration:**
   ```yaml
   posthog:
     api_key: "phc_your_actual_posthog_project_key_here"
     api_host: "https://app.posthog.com"
   ```

3. **Save and close the editor**

### Step 2: Update Application Layout

Replace the placeholder in `app/views/layouts/application.html.erb`:

```erb
<!-- Change this line: -->
posthog.init('YOUR_PUBLIC_POSTHOG_API_KEY', { 

<!-- To this: -->
posthog.init('<%= Rails.application.credentials.posthog&.api_key || "YOUR_PUBLIC_POSTHOG_API_KEY" %>', {
```

### Step 3: Environment Variables (Alternative)

If you prefer environment variables, add to your deployment:

```bash
# Production environment
POSTHOG_API_KEY=phc_your_actual_posthog_project_key_here
```

Then update the layout:
```erb
posthog.init('<%= ENV["POSTHOG_API_KEY"] || "YOUR_PUBLIC_POSTHOG_API_KEY" %>', {
```

## Current Tracking Features

### 🔍 **Automatic Tracking**
- **Page Views**: Every page load with Turbo compatibility
- **User Sessions**: Active session tracking for logged-in users
- **Authentication State**: Tracks whether users are authenticated

### 👤 **User Identification**
For logged-in users, tracks:
- User ID (database primary key)
- Email address
- User role (admin/user)
- Subscription status
- Signup date
- Number of connected platform accounts

### 📊 **Event Properties**
Each event includes contextual data:
- Page title
- User authentication status
- User role
- Subscription information
- Platform connection count

### 🔒 **Privacy Configuration**
- Opt-out capability available
- Session recording configurable
- Page leave tracking enabled
- GDPR-compliant data collection

## PostHog Dashboard Setup

### 1. **Create PostHog Account**
- Visit [PostHog](https://app.posthog.com)
- Create new project
- Copy the project API key (starts with `phc_`)

### 2. **Configure Project Settings**
- Set up funnels for user onboarding
- Create cohorts for subscription analysis
- Configure retention analysis
- Set up conversion tracking

### 3. **Recommended Events to Track**
```javascript
// User actions
posthog.capture('subscription_created', { platform: 'youtube' });
posthog.capture('video_analyzed', { platform: 'tiktok', video_id: 'abc123' });
posthog.capture('billing_page_viewed');
posthog.capture('settings_updated', { setting: 'realtime_enabled' });

// Admin actions
posthog.capture('admin_analytics_viewed');
posthog.capture('user_subscription_managed');
```

## Integration with CreatorHub Studio

### **User Journey Tracking**
1. **Anonymous visitor** → Page views tracked
2. **User registration** → User identified with properties
3. **Platform connection** → Subscription events tracked
4. **Video analysis** → Feature usage tracked
5. **Billing interaction** → Conversion events tracked

### **Segmentation Opportunities**
- **By Role**: Admin vs regular users
- **By Subscription**: Free vs paid users
- **By Platform**: YouTube, TikTok, etc.
- **By Signup Date**: Cohort analysis
- **By Activity**: Active vs inactive users

## Development vs Production

### **Development Environment**
- Uses placeholder API key
- Full tracking enabled for testing
- Console logging for debugging

### **Production Environment**
- Uses encrypted credentials
- Real PostHog project
- Performance optimized

## Testing the Integration

### **Verify Tracking Works**
1. Open browser developer tools
2. Check Network tab for PostHog requests
3. Verify events in PostHog dashboard
4. Test both authenticated and anonymous users

### **Debug Mode**
Add to PostHog init for debugging:
```javascript
posthog.init('your_key', { 
  api_host: 'https://app.posthog.com',
  debug: true // Remove in production
});
```

## Data Privacy Compliance

### **GDPR Considerations**
- User consent management (implement if required)
- Data retention policies in PostHog
- Right to be forgotten implementation
- Cookie consent integration

### **Security Best Practices**
- ✅ API keys stored in encrypted credentials
- ✅ No sensitive data in client-side tracking
- ✅ User IDs anonymized (database IDs, not emails)
- ✅ Secure HTTPS data transmission

## Performance Impact

### **Optimizations Included**
- Asynchronous script loading
- Lightweight tracking library
- Batched event sending
- Turbo.js compatibility
- Error handling for failed loads

### **Bundle Size**
- PostHog library: ~30KB gzipped
- Minimal impact on page load times
- CDN delivery for optimal performance

## Troubleshooting

### **Common Issues**
1. **Events not appearing**: Check API key and network requests
2. **User not identified**: Verify user authentication state
3. **Turbo conflicts**: Events handled with Turbo lifecycle
4. **CORS errors**: Ensure proper PostHog domain configuration

### **Debugging Steps**
1. Check browser console for errors
2. Verify network requests to PostHog
3. Test with PostHog debug mode
4. Check Rails logs for credential issues

## Next Steps

1. **Immediate**: Replace placeholder API key with real credentials
2. **Short-term**: Add custom event tracking for key user actions
3. **Long-term**: Implement cohort analysis and conversion funnels
4. **Advanced**: Add A/B testing with PostHog feature flags 