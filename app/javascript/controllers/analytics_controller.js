import { Controller } from "@hotwired/stimulus"

// Enhanced Analytics controller with RequestManager integration
export default class extends Controller {
  static targets = ["trackable"]
  static values = {
    event: String,
    properties: Object,
    userId: String,
    userRole: String,
    userEmail: String
  }

  connect() {
    console.log("📊 Analytics controller connected with RequestManager integration")
    
    // Get reference to RequestManager
    this.requestManager = this.getRequestManager()
    
    // Track page view automatically when controller connects
    this.trackPageView()
    
    // Set up automatic tracking for elements with data-analytics-track attribute
    this.setupAutomaticTracking()
    
    // Initialize page timing
    this.pageLoadTime = Date.now()
    this.setupPageTracking()
    
    // Initialize request tracking
    this.activeAnalyticsRequests = new Set()
  }

  disconnect() {
    this.trackTimeOnPage()
    
    // Cancel any pending analytics requests
    if (this.requestManager) {
      this.activeAnalyticsRequests.forEach(requestId => {
        this.requestManager.cancelRequest(requestId)
      })
    }
    
    console.log("📊 Analytics controller disconnected")
  }

  // Get RequestManager instance from global controller
  getRequestManager() {
    const body = document.querySelector('body[data-controller*="request-manager"]')
    if (body) {
      return this.application.getControllerForElementAndIdentifier(body, 'request-manager')
    }
    return null
  }

  // Enhanced track page views with request management
  trackPageView() {
    if (!window.posthog) return
    
    const properties = {
      path: window.location.pathname,
      page_title: document.title,
      referrer: document.referrer,
      timestamp: new Date().toISOString(),
      user_authenticated: this.userIdValue ? true : false,
      has_active_requests: this.requestManager ? this.requestManager.hasActiveRequests() : false,
      ...this.getCommonProperties()
    }

    // Add URL parameters for better tracking
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.has('utm_source')) {
      properties.utm_source = urlParams.get('utm_source')
      properties.utm_medium = urlParams.get('utm_medium')
      properties.utm_campaign = urlParams.get('utm_campaign')
    }

    window.posthog.capture('page_viewed', properties)
    console.log('📊 Page view tracked:', properties)
  }

  // Enhanced generic event tracking with request context
  trackEvent(eventName, customProperties = {}) {
    if (!window.posthog) {
      console.warn('PostHog not available, event not tracked:', eventName)
      return
    }

    const properties = {
      ...this.getCommonProperties(),
      ...customProperties,
      timestamp: new Date().toISOString(),
      // Add request context
      has_active_requests: this.requestManager ? this.requestManager.hasActiveRequests() : false,
      active_requests_count: this.requestManager ? this.requestManager.getRequestStats().activeRequests : 0,
      loading_buttons_count: this.requestManager ? this.requestManager.getRequestStats().loadingButtons : 0
    }

    // Track the analytics event itself as a managed request if it's external
    if (this.requestManager && this.isExternalAnalyticsEvent(eventName)) {
      const { requestId } = this.requestManager.createManagedRequest(
        this.getAnalyticsEndpoint(eventName), 
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ event: eventName, properties })
        }
      )
      this.activeAnalyticsRequests.add(requestId)
    }

    window.posthog.capture(eventName, properties)
    console.log(`📊 Event tracked: ${eventName}`, properties)
  }

  // Check if event should be sent to external analytics
  isExternalAnalyticsEvent(eventName) {
    const externalEvents = [
      'conversion_completed',
      'subscription_started', 
      'high_value_action',
      'critical_error',
      'revenue_event'
    ]
    return externalEvents.includes(eventName)
  }

  // Get analytics endpoint for external events
  getAnalyticsEndpoint(eventName) {
    return `/api/v1/analytics/events/${eventName}`
  }

  // Enhanced automatic tracking setup
  setupAutomaticTracking() {
    // Track clicks on elements with data-analytics-track
    this.element.addEventListener('click', (event) => {
      const target = event.target.closest('[data-analytics-track]')
      if (!target) return

      const eventName = target.dataset.analyticsTrack
      const properties = this.parseDataProperties(target)
      
      // Add button state information
      const buttonState = {
        button_loading: this.requestManager ? this.requestManager.isButtonLoading(target) : false,
        click_prevented: false
      }

      // Check if click should be prevented due to loading state
      if (this.requestManager && this.requestManager.isButtonLoading(target)) {
        buttonState.click_prevented = true
        console.log("🛑 Analytics: Click prevented - button loading")
        return
      }
      
      this.trackEvent(eventName, {
        element_text: target.textContent.trim(),
        element_type: target.tagName.toLowerCase(),
        element_class: target.className,
        ...properties,
        ...buttonState
      })
    })

    // Enhanced form submission tracking
    this.element.addEventListener('submit', (event) => {
      const form = event.target
      if (!form.dataset.analyticsTrack) return

      const eventName = form.dataset.analyticsTrack
      const formData = new FormData(form)
      const properties = {
        form_action: form.action,
        form_method: form.method,
        form_fields: Array.from(formData.keys()),
        form_loading: this.requestManager ? this.requestManager.isFormLoading(form) : false,
        submission_prevented: false,
        ...this.parseDataProperties(form)
      }

      // Check if form submission should be prevented
      if (this.requestManager && this.requestManager.isFormLoading(form)) {
        properties.submission_prevented = true
        console.log("🛑 Analytics: Form submission prevented - already loading")
        return
      }

      this.trackEvent(eventName, properties)
    })
  }

  // Parse data-analytics-* attributes from element
  parseDataProperties(element) {
    const properties = {}
    
    for (const attr of element.attributes) {
      if (attr.name.startsWith('data-analytics-') && attr.name !== 'data-analytics-track') {
        const key = attr.name.replace('data-analytics-', '').replace(/-/g, '_')
        properties[key] = attr.value
      }
    }
    
    return properties
  }

  // Get common properties for all events
  getCommonProperties() {
    return {
      user_id: this.userIdValue || null,
      user_role: this.userRoleValue || 'anonymous',
      user_email: this.userEmailValue || null,
      page_path: window.location.pathname,
      page_url: window.location.href,
      viewport_width: window.innerWidth,
      viewport_height: window.innerHeight,
      timestamp: new Date().toISOString()
    }
  }

  // Specific tracking methods for CreatorHub Studio actions
  
  // Track pricing page interactions
  trackPricingInteraction(event) {
    const target = event.target
    const planType = target.closest('[data-plan]')?.dataset.plan || 
                     target.querySelector('input[name="plan"]')?.value
    
    this.trackEvent('pricing_plan_clicked', {
      plan_type: planType,
      button_text: target.textContent.trim(),
      section: 'pricing_page',
      interaction_type: 'plan_selection'
    })
  }

  // Track account connection attempts
  trackAccountConnection(event) {
    const platform = event.params?.platform || 
                     event.target.dataset.platform ||
                     event.target.closest('[data-platform]')?.dataset.platform
    
    this.trackEvent('account_connection_started', {
      platform: platform,
      section: 'accounts_page',
      connection_type: 'oauth_initiation',
      source_element: event.target.textContent.trim()
    })
  }

  // Track video analysis interactions
  trackVideoAnalysis(event) {
    const videoId = event.params?.videoId || event.target.dataset.videoId
    const platform = event.params?.platform || event.target.dataset.platform
    
    this.trackEvent('video_analysis_viewed', {
      video_id: videoId,
      platform: platform,
      section: 'videos_page',
      interaction_type: 'video_details'
    })
  }

  // Track dashboard interactions
  trackDashboardInteraction(event) {
    const interactionType = event.params?.type || 
                           event.target.dataset.analyticsType ||
                           'general_interaction'
    
    this.trackEvent('dashboard_interaction', {
      interaction_type: interactionType,
      section: 'dashboard',
      element_text: event.target.textContent.trim(),
      element_location: event.target.closest('[data-section]')?.dataset.section
    })
  }

  // Track CTA button clicks
  trackCTA(event) {
    const ctaText = event.target.textContent.trim()
    const ctaLocation = event.params?.location || 
                       event.target.dataset.analyticsLocation ||
                       this.inferCTALocation(event.target)
    
    this.trackEvent('cta_clicked', {
      cta_text: ctaText,
      cta_location: ctaLocation,
      button_type: this.getButtonType(event.target),
      section: this.getCurrentSection()
    })
  }

  // Track trial and subscription events
  trackTrial(event) {
    const trialType = event.params?.type || 'subscription_trial'
    
    this.trackEvent('trial_started', {
      trial_type: trialType,
      source_page: window.location.pathname,
      user_funnel_stage: this.getUserFunnelStage()
    })
  }

  // Track navigation events
  trackNavigation(event) {
    const destination = event.params?.destination || 
                       event.target.href ||
                       event.target.closest('a')?.href
    const navigationText = event.target.textContent.trim()
    
    this.trackEvent('navigation_clicked', {
      destination: destination,
      navigation_text: navigationText,
      section: 'navigation',
      nav_type: this.getNavigationType(event.target)
    })
  }

  // Track connect accounts CTA specifically
  trackConnectAccountsCTA(event) {
    this.trackEvent('connect_accounts_cta_clicked', {
      cta_location: this.getCurrentSection(),
      user_has_accounts: this.hasConnectedAccounts(),
      accounts_count: this.getConnectedAccountsCount(),
      source_page: window.location.pathname
    })
  }

  // Track settings changes
  trackSettingsChange(event) {
    const settingName = event.target.name || event.params?.setting
    const settingValue = event.target.type === 'checkbox' ? event.target.checked : event.target.value
    
    this.trackEvent('settings_changed', {
      setting_name: settingName,
      setting_value: settingValue,
      setting_type: event.target.type,
      section: 'settings_page'
    })
  }

  // Helper methods
  getButtonType(element) {
    if (element.className.includes('btn-primary')) return 'primary'
    if (element.className.includes('btn-success')) return 'success'
    if (element.className.includes('btn-warning')) return 'warning'
    if (element.className.includes('btn-danger')) return 'danger'
    return 'secondary'
  }

  getCurrentSection() {
    const path = window.location.pathname
    if (path.includes('/pricing')) return 'pricing'
    if (path.includes('/dashboard')) return 'dashboard'
    if (path.includes('/videos')) return 'videos'
    if (path.includes('/subscriptions')) return 'accounts'
    if (path.includes('/settings')) return 'settings'
    if (path.includes('/billing')) return 'billing'
    if (path === '/') return 'homepage'
    return 'unknown'
  }

  inferCTALocation(element) {
    const section = element.closest('[data-section]')?.dataset.section
    if (section) return section

    const container = element.closest('.card, .hero, .navbar, .footer')
    if (container?.classList.contains('hero')) return 'hero'
    if (container?.classList.contains('navbar')) return 'navbar'
    if (container?.classList.contains('footer')) return 'footer'
    if (container?.classList.contains('card')) return 'card'
    
    return 'page_content'
  }

  getNavigationType(element) {
    if (element.closest('.navbar')) return 'navbar'
    if (element.closest('.sidebar')) return 'sidebar'
    if (element.closest('.footer')) return 'footer'
    if (element.closest('.breadcrumb')) return 'breadcrumb'
    return 'inline'
  }

  hasConnectedAccounts() {
    return document.querySelector('[data-connected-accounts]')?.dataset.connectedAccounts > 0
  }

  getConnectedAccountsCount() {
    return parseInt(document.querySelector('[data-connected-accounts]')?.dataset.connectedAccounts || 0)
  }

  getUserFunnelStage() {
    if (!this.userIdValue) return 'anonymous'
    if (this.hasConnectedAccounts()) return 'active_user'
    return 'registered_user'
  }

  // Setup page-level tracking
  setupPageTracking() {
    // Track time on page when user leaves
    window.addEventListener('beforeunload', () => {
      this.trackTimeOnPage()
    })

    // Track visibility changes (tab switching)
    document.addEventListener('visibilitychange', () => {
      this.trackEvent('page_visibility_changed', {
        visibility_state: document.visibilityState,
        page_path: window.location.pathname
      })
    })

    // Track scroll depth
    let maxScrollDepth = 0
    window.addEventListener('scroll', () => {
      const scrollDepth = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100)
      if (scrollDepth > maxScrollDepth) {
        maxScrollDepth = scrollDepth
        
        // Track milestone scroll depths
        if ([25, 50, 75, 90].includes(scrollDepth)) {
          this.trackEvent('scroll_depth_reached', {
            scroll_depth: scrollDepth,
            page_path: window.location.pathname
          })
        }
      }
    })
  }

  // Track time spent on page
  trackTimeOnPage() {
    if (!this.pageLoadTime) return
    
    const timeSpent = Date.now() - this.pageLoadTime
    
    this.trackEvent('time_on_page', {
      time_spent_seconds: Math.round(timeSpent / 1000),
      page_path: window.location.pathname,
      page_title: document.title
    })
  }
} 