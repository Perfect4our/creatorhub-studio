# Demo Video Script for Google OAuth Verification

## 🎬 **Video Requirements**
- **Length**: 3-5 minutes
- **Quality**: 1080p HD minimum
- **Audio**: Clear narration in English
- **Platform**: Upload to YouTube (unlisted) or Vimeo

## 📝 **Detailed Script**

### **Scene 1: App Introduction (30 seconds)**
```
[Screen: Show creatorhubstudio.com homepage]

"Hello, I'm going to demonstrate CreatorHub Studio, a multi-platform creator analytics dashboard that helps content creators track their performance across YouTube, TikTok, Instagram, and other social media platforms.

Let me show you how users can securely connect their YouTube account to access their analytics data."
```

### **Scene 2: User Registration/Login (30 seconds)**
```
[Screen: Navigate to sign up or login]

"First, users need to create an account or sign in to CreatorHub Studio. I'll click on 'Get Started Free' to begin the process."

[Show the registration/login form and complete it]

"After signing up, users are taken to their dashboard where they can connect their social media accounts."
```

### **Scene 3: YouTube Integration Start (45 seconds)**
```
[Screen: Dashboard or Subscriptions page]

"To connect their YouTube account, users click on 'Connect YouTube Account' or 'Add YouTube Integration'. This initiates the OAuth 2.0 flow that securely connects their YouTube channel to our analytics dashboard."

[Click the YouTube connection button]

"This redirects users to Google's official OAuth consent screen where they can review and authorize the permissions our app needs."
```

### **Scene 4: OAuth Consent Screen (90 seconds)**
```
[Screen: Google OAuth consent screen - PAUSE HERE]

"Here's the Google OAuth consent screen. You can see our app name 'CreatorHub Studio' at the top, along with our verified domain.

Let me walk through the permissions we're requesting:

1. First, we request 'See your YouTube channel' - this allows us to display basic channel information like the channel name and subscriber count.

2. Second, we request 'View your YouTube Analytics reports' - this gives us access to detailed analytics data including view counts, watch time, audience demographics, and engagement metrics.

3. Third, we request 'View monetary and non-monetary YouTube Analytics reports' - this allows us to show creators their estimated revenue and monetization performance.

These permissions are essential for our core functionality of providing comprehensive YouTube analytics in our dashboard."

[Scroll down to show the full consent screen]

"Users can see exactly what data we're accessing and can choose to grant these permissions."

[Click 'Allow' or 'Continue']
```

### **Scene 5: Successful Integration (60 seconds)**
```
[Screen: Redirect back to CreatorHub Studio dashboard]

"After granting permissions, users are redirected back to CreatorHub Studio where they can immediately see their YouTube data being populated.

As you can see, the dashboard now displays:
- Real-time subscriber count
- Recent video performance metrics
- Channel analytics overview
- Top performing videos
- Audience demographics data

All of this information comes directly from the YouTube Analytics API using the permissions the user just granted."
```

### **Scene 6: Feature Demonstration (60 seconds)**
```
[Screen: Navigate through different dashboard features]

"Let me show you how we use the granted permissions:

Here in the analytics section, you can see detailed performance metrics pulled from YouTube Analytics API - this includes view counts, watch time, and audience retention data.

In the videos section, we display the user's video library with performance metrics for each video.

The demographics page shows audience insights including age groups, geographic distribution, and viewing device information.

And in the revenue section, creators can track their monetization performance and estimated earnings - all sourced securely from their YouTube Analytics data."
```

### **Scene 7: Privacy and Security (30 seconds)**
```
[Screen: Show settings or privacy page]

"CreatorHub Studio takes data privacy seriously. Users can disconnect their accounts at any time, and we never sell or share their data with third parties. 

All data is encrypted and securely stored, and we only use the YouTube data to provide the analytics features shown in this demonstration.

Users can view our complete privacy policy and terms of service directly on our website."
```

### **Scene 8: Conclusion (15 seconds)**
```
[Screen: Dashboard overview]

"That concludes the demonstration of CreatorHub Studio's YouTube integration. The OAuth flow ensures secure, user-authorized access to YouTube Analytics data, enabling creators to get comprehensive insights into their channel performance.

Thank you for watching."
```

## 🎥 **Recording Tips**

### **Technical Setup**:
- Use screen recording software (OBS, ScreenFlow, Camtasia)
- Record at 1920x1080 resolution
- Use clear, professional narration
- Ensure stable internet connection for OAuth flow

### **Key Points to Emphasize**:
1. **App Name**: Make sure "CreatorHub Studio" is clearly visible
2. **Domain**: Show creatorhubstudio.com in the browser
3. **Consent Screen**: Pause to show all requested scopes clearly
4. **Real Data**: Use actual YouTube account with real data if possible
5. **Professional Flow**: Show smooth, realistic user experience

### **What NOT to Show**:
- Test accounts with fake data
- Development/staging environments
- Localhost URLs
- Debug information or error messages
- Multiple failed attempts

## 📋 **Pre-Recording Checklist**

- [ ] App is deployed to production (creatorhubstudio.com)
- [ ] Google OAuth is configured with production credentials
- [ ] Have a real YouTube account ready for demonstration
- [ ] Privacy policy and terms pages are accessible
- [ ] Dashboard features are working properly
- [ ] Clear script and talking points prepared

## 🎯 **Post-Recording**

1. **Upload to YouTube** (unlisted) or Vimeo
2. **Get shareable link** for verification submission
3. **Test the link** to ensure Google can access it
4. **Include in OAuth verification submission**

## 📞 **Backup Scenarios**

If OAuth flow fails during recording:
- Have a backup recording ready
- Use edited segments to show complete flow
- Ensure the final video shows successful integration

Remember: Google reviewers need to see the EXACT OAuth consent screen with YOUR app name and the EXACT scopes you're requesting for verification. 