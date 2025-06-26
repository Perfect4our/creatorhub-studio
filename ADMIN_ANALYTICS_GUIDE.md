# Admin Analytics Guide

## Overview

The Admin Analytics page provides comprehensive insights into CreatorHub Studio platform usage, user growth, and system activity. This page is restricted to admin users only.

## Access

- **Route**: `/admin/analytics`
- **Controller**: `Admin::AnalyticsController`
- **Access Control**: Only users with email `perfect4ouryt@gmail.com` can access this page
- **Navigation**: Available in the account dropdown menu (next to Settings/Billing) for admin users

## Features

### 1. Key Metrics Dashboard
- **Total Users**: Complete user count with weekly growth indicator
- **Active Subscriptions**: Number of users with active Stripe subscriptions
- **Total Videos**: Cross-platform video count from connected accounts
- **Online Now**: Real-time simulated user count (updates every 5 seconds)

### 2. User Signups Chart
- Interactive line chart showing 30-day signup trends
- Responsive design with hover interactions
- Time period selector (7, 30, 90 days)
- Smooth animations and modern styling

### 3. Regional Activity
- Geographic breakdown of user base
- Shows top countries with user counts and percentages
- Visual flag representation for each region
- Sample data with realistic distribution

### 4. Live Activity Feed
- Real-time stream of platform activities
- Shows recent signups and subscription events
- User email and timestamp information
- Auto-scrolling with activity icons
- Live indicator with pulsing animation

## Technical Implementation

### Controller (`app/controllers/admin/analytics_controller.rb`)
- Inherits from `ApplicationController`
- Uses `authenticate_user!` and `ensure_admin` before actions
- Calculates real-time metrics from database
- Generates activity feed from recent user actions
- Computes signup growth percentages

### View (`app/views/admin/analytics/index.html.erb`)
- Modern, responsive design with Bootstrap 5
- Chart.js integration for data visualization
- Custom CSS animations and hover effects
- Real-time JavaScript updates
- Mobile-friendly responsive layout

### Security
- Admin access restricted to specific email address
- Devise authentication required
- Helper method `admin_user?` for clean access checks
- Proper error handling for unauthorized access

## Data Sources

- **Users**: User registration data and Stripe integration
- **Subscriptions**: Platform account connections
- **Videos**: TikTok video data (extendable to other platforms)
- **Activity**: Recent user actions and system events

## Customization

### Adding New Metrics
1. Add data calculation in controller `index` action
2. Update view with new metric display
3. Add corresponding CSS styling if needed

### Extending Activity Feed
1. Modify `recent_activity_feed` method in controller
2. Add new activity types to view template
3. Update CSS for new activity icons

### Changing Admin Access
1. Update `ensure_admin` method in controller
2. Modify `admin_user?` helper in `ApplicationHelper`
3. Update navbar condition

## Testing

Test file: `test/controllers/admin/analytics_controller_test.rb`

Run tests:
```bash
bin/rails test test/controllers/admin/analytics_controller_test.rb
```

## Performance Notes

- Database queries are optimized for dashboard performance
- Real-time updates use JavaScript intervals (not WebSockets)
- Chart rendering is client-side for better responsiveness
- Activity feed is limited to 20 most recent items

## Future Enhancements

- WebSocket integration for true real-time updates
- Advanced filtering and date range selection
- Export functionality for analytics data
- Additional metrics and KPIs
- User behavior tracking and analytics 