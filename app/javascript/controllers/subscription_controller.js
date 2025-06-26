import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["disconnectButton"]
  
  disconnect(event) {
    const button = event.currentTarget
    const platform = button.dataset.platform
    
    if (!confirm(`Are you sure you want to disconnect your ${platform} account?`)) {
      event.preventDefault()
      return
    }
    
    // Track analytics immediately (don't wait for server)
    this.trackDisconnection(platform)
    
    // Set loading state
    this.setLoadingState(button)
    
    // Let the form submit normally (Turbo will handle it)
  }
  
  trackDisconnection(platform) {
    try {
      // Track analytics event immediately
      if (window.analytics && typeof window.analytics.track === 'function') {
        window.analytics.track('account_disconnected', {
          platform: platform,
          location: 'card_footer',
          timestamp: new Date().toISOString()
        })
      }
    } catch (error) {
      console.log('Analytics tracking failed:', error)
    }
  }
  
  setLoadingState(button) {
    // Save original state
    const originalText = button.innerHTML
    const originalClass = button.className
    
    // Set loading state
    button.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Disconnecting...'
    button.classList.add('disabled')
    button.disabled = true
    
    // Reset after a timeout in case something goes wrong
    setTimeout(() => {
      if (button.disabled) {
        button.innerHTML = originalText
        button.className = originalClass
        button.disabled = false
      }
    }, 10000) // 10 second timeout
  }
} 