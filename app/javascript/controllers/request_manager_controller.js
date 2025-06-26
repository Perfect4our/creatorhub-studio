import { Controller } from "@hotwired/stimulus"

// Universal Request Manager - handles all request cancellation and state management
export default class extends Controller {
  static targets = ["button", "form", "link"]
  static values = { 
    timeout: { type: Number, default: 30000 },
    retryAttempts: { type: Number, default: 3 }
  }

  connect() {
    console.log("🔧 RequestManager connected - Managing all requests and button states")
    
    // Initialize request tracking
    this.activeRequests = new Map()
    this.buttonStates = new Map()
    this.timeouts = new Map()
    
    // Global abort controller for page-level cancellation
    this.globalAbortController = new AbortController()
    
    // Set up Turbo navigation listeners
    this.setupTurboListeners()
    
    // Set up button management
    this.setupButtonManagement()
    
    // Set up form management
    this.setupFormManagement()
    
    // Initialize global error handling
    this.setupGlobalErrorHandling()
    
    // Expose debug methods globally for easy access
    window.requestManagerDebug = {
      state: () => this.debugState(),
      reset: () => this.emergencyReset(),
      stats: () => this.getRequestStats()
    }
  }

  disconnect() {
    console.log("🔧 RequestManager disconnecting - Cancelling all active requests")
    this.cancelAllRequests()
    this.clearAllTimeouts()
  }

  // === TURBO INTEGRATION ===
  setupTurboListeners() {
    // Cancel all requests before navigation
    document.addEventListener('turbo:before-visit', this.handleBeforeVisit.bind(this))
    
    // Cleanup on new page load
    document.addEventListener('turbo:load', this.handleTurboLoad.bind(this))
    
    // Handle form submissions
    document.addEventListener('turbo:submit-start', this.handleTurboSubmitStart.bind(this))
    document.addEventListener('turbo:submit-end', this.handleTurboSubmitEnd.bind(this))
  }

  handleBeforeVisit(event) {
    console.log("🚀 Navigation starting - Cancelling all active requests")
    
    // Cancel all active requests immediately
    this.cancelAllRequests()
    
    // Reset all button states immediately
    this.resetAllButtonStates()
    
    // Force cleanup of any stuck form states
    document.querySelectorAll('form').forEach(form => {
      const formId = this.getElementId(form)
      if (this.isFormLoading(formId)) {
        this.setFormLoading(form, false)
      }
    })
    
    // Clear any pending timeouts
    this.clearAllTimeouts()
    
    // Reset any loading indicators
    document.querySelectorAll('.btn.loading, .btn[disabled]').forEach(btn => {
      if (btn.dataset.originalState !== 'disabled') {
        btn.disabled = false
        btn.classList.remove('loading')
      }
    })
    
    // Clean up any dropdown states that might interfere
    document.querySelectorAll('.dropdown-menu.show').forEach(menu => {
      menu.classList.remove('show')
    })
    
    // Force clear any analytics tracking states
    if (window.posthog) {
      try {
        window.posthog.capture('page_navigation_start', {
          from_url: window.location.href,
          to_url: event.detail?.url || 'unknown'
        })
      } catch (e) {
        console.log('PostHog tracking error during navigation:', e)
      }
    }
  }

  handleTurboLoad(event) {
    console.log("📄 Page loaded - Reinitializing request manager")
    
    // Reset all state for new page
    this.activeRequests.clear()
    this.buttonStates.clear()
    this.clearAllTimeouts()
    
    // Create new global abort controller
    this.globalAbortController = new AbortController()
    
    // Force cleanup any stuck states from previous page
    setTimeout(() => {
      // Clean up any buttons that might be stuck in loading state
      document.querySelectorAll('.btn').forEach(btn => {
        if (btn.classList.contains('loading') && !btn.dataset.currentlyLoading) {
          btn.classList.remove('loading')
          btn.disabled = false
        }
      })
      
      // Clean up any forms that might be stuck
      document.querySelectorAll('form').forEach(form => {
        if (form.dataset.submitting && !form.dataset.currentlySubmitting) {
          delete form.dataset.submitting
          const submitBtn = form.querySelector('button[type="submit"], input[type="submit"]')
          if (submitBtn) {
            submitBtn.disabled = false
            submitBtn.classList.remove('loading')
          }
        }
      })
      
      // Verify all controllers are properly connected
      if (window.application) {
        try {
          const controllers = window.application.controllers
          console.log(`📊 Active Stimulus controllers: ${controllers.length}`)
        } catch (e) {
          console.log('Controller check error:', e)
        }
      }
    }, 100)
    
    // Track page load in analytics
    if (window.posthog) {
      try {
        window.posthog.capture('page_loaded', {
          url: window.location.href,
          path: window.location.pathname,
          request_manager_active: true
        })
      } catch (e) {
        console.log('PostHog tracking error:', e)
      }
    }
  }

  handleTurboSubmitStart(event) {
    const form = event.target
    this.setFormLoading(form, true)
  }

  handleTurboSubmitEnd(event) {
    const form = event.target
    this.setFormLoading(form, false)
  }

  // === BUTTON MANAGEMENT ===
  setupButtonManagement() {
    // Handle all button clicks with prevention of rapid clicking
    this.element.addEventListener('click', this.handleButtonClick.bind(this), true)
  }

  handleButtonClick(event) {
    const button = event.target.closest('button, .btn, [role="button"]')
    if (!button) return

    const buttonId = this.getElementId(button)
    
    // Prevent rapid clicking
    if (this.isButtonLoading(buttonId)) {
      event.preventDefault()
      event.stopImmediatePropagation()
      console.log("🛑 Button click prevented - already loading:", buttonId)
      return false
    }

    // Check for data-request attribute (indicates this will make a request)
    if (button.dataset.request || button.dataset.action || button.dataset.url) {
      this.setButtonLoading(buttonId, true)
      
      // Auto-reset after timeout if no explicit reset
      setTimeout(() => {
        if (this.isButtonLoading(buttonId)) {
          this.setButtonLoading(buttonId, false)
        }
      }, this.timeoutValue)
    }
  }

  // === FORM MANAGEMENT ===
  setupFormManagement() {
    this.element.addEventListener('submit', this.handleFormSubmit.bind(this), true)
  }

  handleFormSubmit(event) {
    const form = event.target
    if (!form.tagName || form.tagName.toLowerCase() !== 'form') return

    const formId = this.getElementId(form)
    
    // Prevent double submission
    if (this.isFormLoading(formId)) {
      event.preventDefault()
      event.stopImmediatePropagation()
      console.log("🛑 Form submission prevented - already loading:", formId)
      return false
    }

    this.setFormLoading(form, true)
  }

  // === REQUEST MANAGEMENT ===
  
  // Create a managed fetch request
  createManagedRequest(url, options = {}) {
    const requestId = this.generateRequestId()
    const abortController = new AbortController()
    
    // Combine with global abort controller
    const combinedSignal = this.combineAbortSignals([
      this.globalAbortController.signal,
      abortController.signal,
      options.signal
    ].filter(Boolean))
    
    const requestOptions = {
      ...options,
      signal: combinedSignal
    }

    // Track the request
    this.activeRequests.set(requestId, {
      url,
      abortController,
      startTime: Date.now(),
      timeout: setTimeout(() => {
        console.log("⏰ Request timeout:", url)
        abortController.abort('timeout')
        this.activeRequests.delete(requestId)
      }, options.timeout || this.timeoutValue)
    })

    console.log("🌐 Starting managed request:", url, "ID:", requestId)

    const fetchPromise = fetch(url, requestOptions)
      .then(response => {
        this.cleanupRequest(requestId)
        return response
      })
      .catch(error => {
        this.cleanupRequest(requestId)
        if (error.name === 'AbortError') {
          console.log("❌ Request cancelled:", url)
        } else {
          console.error("❌ Request failed:", url, error)
        }
        throw error
      })

    return { requestId, promise: fetchPromise, abort: () => abortController.abort() }
  }

  // Cancel all active requests
  cancelAllRequests() {
    console.log(`🚫 Cancelling ${this.activeRequests.size} active requests`)
    
    this.activeRequests.forEach((request, id) => {
      request.abortController.abort('page_navigation')
      clearTimeout(request.timeout)
    })
    
    this.activeRequests.clear()
    this.globalAbortController.abort('cleanup')
    this.globalAbortController = new AbortController()
  }

  // Cancel specific request
  cancelRequest(requestId) {
    const request = this.activeRequests.get(requestId)
    if (request) {
      request.abortController.abort('manual_cancellation')
      this.cleanupRequest(requestId)
    }
  }

  // Cleanup individual request
  cleanupRequest(requestId) {
    const request = this.activeRequests.get(requestId)
    if (request) {
      clearTimeout(request.timeout)
      this.activeRequests.delete(requestId)
    }
  }

  // === BUTTON STATE MANAGEMENT ===
  
  setButtonLoading(elementOrId, loading = true) {
    const element = typeof elementOrId === 'string' 
      ? document.getElementById(elementOrId) || document.querySelector(`[data-id="${elementOrId}"]`)
      : elementOrId
    
    if (!element) return

    const elementId = this.getElementId(element)
    
    if (loading) {
      this.buttonStates.set(elementId, {
        originalText: element.textContent,
        originalDisabled: element.disabled,
        startTime: Date.now()
      })

      // Apply loading state
      element.disabled = true
      element.style.pointerEvents = 'none'
      element.classList.add('loading', 'disabled')
      
      // Update text if it's a button
      if (element.tagName === 'BUTTON' || element.classList.contains('btn')) {
        const loadingText = element.dataset.loadingText || 'Loading...'
        element.innerHTML = `<i class="fas fa-spinner fa-spin me-2"></i>${loadingText}`
      }
      
      console.log("⏳ Button loading:", elementId)
    } else {
      const state = this.buttonStates.get(elementId)
      if (state) {
        // Restore original state
        element.disabled = state.originalDisabled
        element.style.pointerEvents = ''
        element.classList.remove('loading', 'disabled')
        element.textContent = state.originalText
        
        this.buttonStates.delete(elementId)
        console.log("✅ Button restored:", elementId)
      }
    }
  }

  setFormLoading(form, loading = true) {
    const formId = this.getElementId(form)
    
    if (loading) {
      form.classList.add('loading')
      form.querySelectorAll('button, input[type="submit"]').forEach(btn => {
        this.setButtonLoading(btn, true)
      })
    } else {
      form.classList.remove('loading')
      form.querySelectorAll('button, input[type="submit"]').forEach(btn => {
        this.setButtonLoading(btn, false)
      })
    }
  }

  isButtonLoading(elementOrId) {
    const elementId = typeof elementOrId === 'string' ? elementOrId : this.getElementId(elementOrId)
    return this.buttonStates.has(elementId)
  }

  isFormLoading(formId) {
    return this.buttonStates.has(formId)
  }

  resetAllButtonStates() {
    console.log("🔄 Resetting all button states")
    this.buttonStates.forEach((state, elementId) => {
      const element = document.getElementById(elementId) || document.querySelector(`[data-id="${elementId}"]`)
      if (element) {
        this.setButtonLoading(element, false)
      }
    })
    this.buttonStates.clear()
  }

  // === UTILITY METHODS ===
  
  getElementId(element) {
    if (element.id) return element.id
    if (element.dataset.id) return element.dataset.id
    
    // Generate a unique ID based on element properties
    const tag = element.tagName.toLowerCase()
    const text = element.textContent.trim().slice(0, 20)
    const classes = Array.from(element.classList).slice(0, 3).join('-')
    return `${tag}-${text}-${classes}`.replace(/[^a-zA-Z0-9-]/g, '').toLowerCase()
  }

  generateRequestId() {
    return `req-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
  }

  combineAbortSignals(signals) {
    const controller = new AbortController()
    
    signals.forEach(signal => {
      if (signal.aborted) {
        controller.abort()
        return
      }
      signal.addEventListener('abort', () => controller.abort())
    })
    
    return controller.signal
  }

  clearAllTimeouts() {
    this.timeouts.forEach(timeout => clearTimeout(timeout))
    this.timeouts.clear()
  }

  setupGlobalErrorHandling() {
    window.addEventListener('error', this.handleGlobalError.bind(this))
    window.addEventListener('unhandledrejection', this.handleUnhandledRejection.bind(this))
  }

  handleGlobalError(event) {
    console.error("🚨 Global error:", event.error)
    // Reset any stuck states
    this.resetAllButtonStates()
  }

  handleUnhandledRejection(event) {
    console.error("🚨 Unhandled promise rejection:", event.reason)
    // Reset any stuck states
    this.resetAllButtonStates()
  }

  // === PUBLIC API ===
  
  // Method for other controllers to create managed requests
  fetch(url, options = {}) {
    return this.createManagedRequest(url, options)
  }

  // Method for other controllers to set button states
  setLoading(element, loading = true) {
    this.setButtonLoading(element, loading)
  }

  // Method to check if any requests are active
  hasActiveRequests() {
    return this.activeRequests.size > 0
  }

  // Method to get request stats
  getRequestStats() {
    return {
      activeRequests: this.activeRequests.size,
      loadingButtons: this.buttonStates.size,
      uptime: Date.now() - (this.connectTime || Date.now())
    }
  }

  // === DEBUG METHODS ===
  
  // Debug method to check current system state
  debugState() {
    const state = {
      activeRequests: this.activeRequests.size,
      buttonStates: this.buttonStates.size,
      timeouts: this.timeouts.size,
      globalAbortSignal: this.globalAbortController.signal.aborted,
      currentUrl: window.location.href,
      loadingButtons: document.querySelectorAll('.btn.loading').length,
      disabledButtons: document.querySelectorAll('.btn[disabled]').length,
      openDropdowns: document.querySelectorAll('.dropdown-menu.show').length,
      activeControllers: window.application ? window.application.controllers.length : 0
    }
    
    console.log('🔍 RequestManager Debug State:', state)
    return state
  }
  
  // Force emergency reset - can be called from console if needed
  emergencyReset() {
    console.log('🚨 Emergency reset triggered!')
    
    // Cancel everything
    this.cancelAllRequests()
    this.resetAllButtonStates()
    this.clearAllTimeouts()
    
    // Force reset all buttons
    document.querySelectorAll('.btn').forEach(btn => {
      btn.disabled = false
      btn.classList.remove('loading')
      delete btn.dataset.currentlyLoading
    })
    
    // Force reset all forms
    document.querySelectorAll('form').forEach(form => {
      delete form.dataset.submitting
      delete form.dataset.currentlySubmitting
    })
    
    // Close all dropdowns
    document.querySelectorAll('.dropdown-menu.show').forEach(menu => {
      menu.classList.remove('show')
    })
    
    // Reset global state
    this.globalAbortController = new AbortController()
    
    console.log('🚨 Emergency reset complete!')
    return this.debugState()
  }
} 