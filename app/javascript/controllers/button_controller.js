import { Controller } from "@hotwired/stimulus"

// Enhanced Button Controller with RequestManager integration
export default class extends Controller {
  static targets = ["dropdown", "timeWindow", "period", "export", "share"]

  connect() {
    console.log("🔘 Button controller connected - Enhanced with RequestManager integration")
    
    // Get reference to RequestManager
    this.requestManager = this.getRequestManager()
    
    this.initializeButtons()
    this.fixDropdowns()
    this.setupEnhancedClickHandling()
    this.setupMobileOptimizations()
  }

  disconnect() {
    // Clean up any pending operations
    this.cancelPendingOperations()
  }

  // Get RequestManager instance from global controller
  getRequestManager() {
    const body = document.querySelector('body[data-controller*="request-manager"]')
    if (body) {
      return this.application.getControllerForElementAndIdentifier(body, 'request-manager')
    }
    return null
  }

  // Enhanced button initialization with state management
  initializeButtons() {
    // Fix any stuck dropdowns
    this.element.querySelectorAll('.dropdown-toggle').forEach(toggle => {
      // Reset any stuck states
      if (this.requestManager) {
        this.requestManager.setLoading(toggle, false)
      }
      
      toggle.removeAttribute('disabled')
      toggle.style.pointerEvents = 'auto'
      toggle.style.cursor = 'pointer'
    })

    // Ensure all dropdowns work with enhanced click prevention
    this.element.querySelectorAll('.dropdown').forEach(dropdown => {
      const toggle = dropdown.querySelector('.dropdown-toggle')
      const menu = dropdown.querySelector('.dropdown-menu')
      
      if (toggle && menu) {
        toggle.addEventListener('click', (e) => {
          e.preventDefault()
          e.stopPropagation()
          
          // Prevent interaction if any requests are active
          if (this.requestManager && this.requestManager.hasActiveRequests()) {
            console.log("🛑 Dropdown interaction blocked - requests active")
            return
          }
          
          this.toggleDropdown(dropdown)
        })
      }
    })

    // Handle dropdown item clicks with enhanced state management
    this.element.querySelectorAll('.dropdown-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault()
        
        // Check if button is in loading state
        if (this.requestManager && this.requestManager.isButtonLoading(item)) {
          console.log("🛑 Dropdown item click blocked - already loading")
          return
        }
        
        this.handleDropdownSelection(e)
      })
    })

    // Add click outside to close dropdowns - enhanced version
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.dropdown')) {
        this.closeAllDropdowns()
      }
    })
  }

  // Enhanced click handling that integrates with RequestManager
  setupEnhancedClickHandling() {
    // Override all button clicks in this element
    this.element.addEventListener('click', (event) => {
      const clickedElement = event.target.closest('button, .btn, a[href], [role="button"]')
      if (!clickedElement) return

      // Check if this element will trigger a request
      const willMakeRequest = this.elementWillMakeRequest(clickedElement)
      
      if (willMakeRequest && this.requestManager) {
        // Set loading state immediately
        this.requestManager.setLoading(clickedElement, true)
        
        // Track this as a pending operation
        this.trackPendingOperation(clickedElement)
      }
    }, true) // Use capture phase to intercept early
  }

  // Determine if an element will make a request
  elementWillMakeRequest(element) {
    // Check for various indicators that a request will be made
    return !!(
      element.dataset.request ||
      element.dataset.action ||
      element.dataset.url ||
      element.dataset.remote ||
      (element.href && element.href !== '#' && !element.href.startsWith('javascript:')) ||
      element.closest('form') ||
      element.classList.contains('export') ||
      element.classList.contains('share') ||
      element.id === 'refresh-button'
    )
  }

  // Track pending operations for cleanup
  trackPendingOperation(element) {
    if (!this.pendingOperations) {
      this.pendingOperations = new Set()
    }
    this.pendingOperations.add(element)
    
    // Auto-cleanup after reasonable timeout
    setTimeout(() => {
      this.completePendingOperation(element)
    }, 30000) // 30 second timeout
  }

  completePendingOperation(element) {
    if (this.pendingOperations) {
      this.pendingOperations.delete(element)
    }
    
    if (this.requestManager) {
      this.requestManager.setLoading(element, false)
    }
  }

  cancelPendingOperations() {
    if (this.pendingOperations) {
      this.pendingOperations.forEach(element => {
        this.completePendingOperation(element)
      })
      this.pendingOperations.clear()
    }
  }

  // Fix dropdown functionality with enhanced state checks
  fixDropdowns() {
    // Remove any stuck classes
    this.element.querySelectorAll('.dropdown-menu').forEach(menu => {
      menu.classList.remove('show')
    })
    
    this.element.querySelectorAll('.dropdown-toggle').forEach(toggle => {
      toggle.setAttribute('aria-expanded', 'false')
      
      // Reset any stuck loading states
      if (this.requestManager) {
        this.requestManager.setLoading(toggle, false)
      }
    })
  }

  // Toggle dropdown menu with state management
  toggleDropdown(dropdown) {
    const toggle = dropdown.querySelector('.dropdown-toggle')
    const menu = dropdown.querySelector('.dropdown-menu')
    const isOpen = menu.classList.contains('show')

    // Don't allow toggle if requests are active
    if (this.requestManager && this.requestManager.hasActiveRequests()) {
      return
    }

    // Close all other dropdowns first
    this.closeAllDropdowns()

    if (!isOpen) {
      menu.classList.add('show')
      toggle.setAttribute('aria-expanded', 'true')
    }
  }

  // Close all dropdowns
  closeAllDropdowns() {
    this.element.querySelectorAll('.dropdown-menu').forEach(menu => {
      menu.classList.remove('show')
    })
    
    this.element.querySelectorAll('.dropdown-toggle').forEach(toggle => {
      toggle.setAttribute('aria-expanded', 'false')
    })
  }

  // Enhanced dropdown selection handling
  handleDropdownSelection(event) {
    const item = event.currentTarget
    const dropdown = item.closest('.dropdown')
    const toggle = dropdown.querySelector('.dropdown-toggle')
    
    // Set loading state for navigation actions
    if (this.requestManager && this.elementWillMakeRequest(item)) {
      this.requestManager.setLoading(item, true)
    }

    // Handle time window selection
    if (item.hasAttribute('href') && item.getAttribute('href') !== '#') {
      this.trackPendingOperation(item)
      window.location.href = item.getAttribute('href')
      return
    }

    // Handle period selection
    if (item.hasAttribute('data-period')) {
      this.handlePeriodSelection(item, dropdown)
      return
    }

    // Handle custom actions
    if (item.id === 'customRangeLink') {
      this.handleCustomRange()
      return
    }

    // Close dropdown after selection
    this.closeAllDropdowns()
  }

  // Enhanced period selection with state management
  handlePeriodSelection(item, dropdown) {
    const period = item.getAttribute('data-period')
    const toggle = dropdown.querySelector('.dropdown-toggle')
    const textSpan = toggle.querySelector('#selectedPeriodText, #selectedTimeWindowText')
    
    // Update active state
    dropdown.querySelectorAll('.dropdown-item').forEach(i => i.classList.remove('active'))
    item.classList.add('active')
    
    // Update button text
    if (textSpan) {
      textSpan.textContent = item.textContent.trim()
    }
    
    // Handle custom period
    if (period === 'custom') {
      this.handleCustomRange()
    } else {
      // Set loading state for navigation
      if (this.requestManager) {
        this.requestManager.setLoading(item, true)
      }
      
      // Reload page with new period
      const url = new URL(window.location.href)
      url.searchParams.set('time_window', period)
      this.trackPendingOperation(item)
      window.location.href = url.toString()
    }
    
    this.closeAllDropdowns()
  }

  // Enhanced custom range handling
  handleCustomRange() {
    // Simple prompt for now - can be enhanced with a date picker later
    const startDate = prompt('Enter start date (YYYY-MM-DD):')
    const endDate = prompt('Enter end date (YYYY-MM-DD):')
    
    if (startDate && endDate) {
      const url = new URL(window.location.href)
      url.searchParams.set('start_date', startDate)
      url.searchParams.set('end_date', endDate)
      url.searchParams.set('time_window', 'custom')
      
      // Create a temporary element to track the request
      const tempElement = document.createElement('span')
      if (this.requestManager) {
        this.requestManager.setLoading(tempElement, true)
      }
      this.trackPendingOperation(tempElement)
      
      window.location.href = url.toString()
    }
  }

  // Enhanced export functionality with proper request management
  export(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    
    // Prevent double-clicks
    if (this.requestManager && this.requestManager.isButtonLoading(button)) {
      return
    }
    
    // Set loading state
    if (this.requestManager) {
      this.requestManager.setLoading(button, true)
    }
    
    try {
      // Get current page data for export
      const url = new URL(window.location.href)
      url.searchParams.set('format', 'csv')
      
      // Use RequestManager for the fetch if available
      if (this.requestManager) {
        const { promise } = this.requestManager.fetch(url.toString(), {
          method: 'GET'
        })
        
        promise
          .then(response => response.blob())
          .then(blob => {
            // Create download link
            const link = document.createElement('a')
            link.href = URL.createObjectURL(blob)
            link.download = `dashboard-export-${new Date().toISOString().split('T')[0]}.csv`
            document.body.appendChild(link)
            link.click()
            document.body.removeChild(link)
            URL.revokeObjectURL(link.href)
            
            this.showNotification('Export completed successfully!', 'success')
          })
          .catch(error => {
            if (error.name !== 'AbortError') {
              this.showNotification('Export failed. Please try again.', 'error')
            }
          })
          .finally(() => {
            if (this.requestManager) {
              this.requestManager.setLoading(button, false)
            }
          })
      } else {
        // Fallback for direct download
        const link = document.createElement('a')
        link.href = url.toString()
        link.download = `dashboard-export-${new Date().toISOString().split('T')[0]}.csv`
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        
        this.showNotification('Export started! Download will begin shortly.', 'success')
        
        setTimeout(() => {
          if (this.requestManager) {
            this.requestManager.setLoading(button, false)
          }
        }, 2000)
      }
    } catch (error) {
      console.error('Export error:', error)
      this.showNotification('Export failed. Please try again.', 'error')
      
      if (this.requestManager) {
        this.requestManager.setLoading(button, false)
      }
    }
  }

  // Enhanced share functionality
  share(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    
    // Prevent double-clicks
    if (this.requestManager && this.requestManager.isButtonLoading(button)) {
      return
    }
    
    // Set loading state
    if (this.requestManager) {
      this.requestManager.setLoading(button, true)
    }
    
    const url = window.location.href
    
    try {
      if (navigator.share) {
        // Use native share API if available
        navigator.share({
          title: 'CreatorHub Studio Dashboard',
          text: 'Check out my content analytics dashboard',
          url: url
        }).finally(() => {
          if (this.requestManager) {
            this.requestManager.setLoading(button, false)
          }
        })
      } else {
        // Fallback to clipboard
        navigator.clipboard.writeText(url).then(() => {
          this.showNotification('Dashboard link copied to clipboard!', 'success')
        }).catch(() => {
          // Final fallback - show URL in alert
          prompt('Copy this link to share your dashboard:', url)
        }).finally(() => {
          if (this.requestManager) {
            this.requestManager.setLoading(button, false)
          }
        })
      }
    } catch (error) {
      console.error('Share error:', error)
      if (this.requestManager) {
        this.requestManager.setLoading(button, false)
      }
    }
  }

  // Switch platform with enhanced state management
  switchPlatform(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    const platform = button.dataset.platform
    
    // Prevent double-clicks
    if (this.requestManager && this.requestManager.isButtonLoading(button)) {
      return
    }
    
    if (platform) {
      // Set loading state
      if (this.requestManager) {
        this.requestManager.setLoading(button, true)
      }
      
      const url = new URL(window.location.href)
      url.searchParams.set('platform', platform)
      this.trackPendingOperation(button)
      window.location.href = url.toString()
    }
  }

  // Enhanced notification with better integration
  showNotification(message, type = 'success') {
    // Try to use global notification controller
    if (window.notificationController) {
      window.notificationController.showNotification(message, type)
      return
    }
    
    // Fallback to Stimulus notification controller
    const notificationElement = document.querySelector('[data-controller*="notification"]')
    if (notificationElement) {
      const controller = this.application.getControllerForElementAndIdentifier(notificationElement, 'notification')
      if (controller) {
        controller.show(message, type)
        return
      }
    }
    
    // Final fallback - enhanced notification
    this.createFallbackNotification(message, type)
  }

  createFallbackNotification(message, type) {
    const getIcon = (type) => {
      const icons = {
        success: 'fa-check',
        error: 'fa-exclamation-triangle',
        warning: 'fa-exclamation-circle',
        info: 'fa-info-circle'
      }
      return icons[type] || icons.info
    }

    const notification = document.createElement('div')
    notification.className = `notification notification-${type}`
    notification.innerHTML = `
      <div class="notification-icon">
        <i class="fas ${getIcon(type)}"></i>
      </div>
      <div class="notification-content">
        <p class="notification-message">${message}</p>
      </div>
      <button type="button" class="notification-close">
        <i class="fas fa-times"></i>
      </button>
      <div class="notification-progress"></div>
    `
    
    // Add to container or create one
    let container = document.querySelector('.notification-container')
    if (!container) {
      container = document.createElement('div')
      container.className = 'notification-container'
      document.body.appendChild(container)
    }
    container.appendChild(notification)
    
    // Setup animations and lifecycle
    notification.style.opacity = '0'
    notification.style.transform = 'translateX(100%) scale(0.9)'
    
    requestAnimationFrame(() => {
      notification.style.transition = 'all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)'
      notification.style.opacity = '1'
      notification.style.transform = 'translateX(0) scale(1)'
    })

    // Progress bar
    const progressBar = notification.querySelector('.notification-progress')
    if (progressBar) {
      progressBar.style.animation = 'notification-progress 5s linear forwards'
    }
    
    // Auto-remove and add close handler
    const removeNotification = () => {
      notification.style.opacity = '0'
      notification.style.transform = 'translateX(100%) scale(0.9)'
      setTimeout(() => notification.remove(), 300)
    }
    
    notification.querySelector('.notification-close').addEventListener('click', removeNotification)
    setTimeout(removeNotification, 5000)
  }

  // Enhanced refresh with request management
  refresh(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    
    // Prevent double refresh
    if (this.requestManager && this.requestManager.isButtonLoading(button)) {
      return
    }
    
    // Set loading state
    if (this.requestManager) {
      this.requestManager.setLoading(button, true)
    }
    
    this.trackPendingOperation(button)
    window.location.reload()
  }

  // Enhanced connect accounts with state management
  connectAccounts(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    
    // Prevent double-clicks
    if (this.requestManager && this.requestManager.isButtonLoading(button)) {
      return
    }
    
    // Set loading state
    if (this.requestManager) {
      this.requestManager.setLoading(button, true)
    }
    
    this.trackPendingOperation(button)
    window.location.href = '/subscriptions'
  }

  // Mobile-specific optimizations
  setupMobileOptimizations() {
    if (!('ontouchstart' in window)) return
    
    console.log("📱 Setting up mobile optimizations")
    
    // Prevent iOS double-tap zoom on buttons
    this.element.querySelectorAll('button, .btn').forEach(button => {
      button.style.touchAction = 'manipulation'
    })
    
    // Add mobile-friendly feedback for touch interactions
    this.element.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: true })
    this.element.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: true })
    
    // Optimize dropdown positioning for mobile
    this.optimizeDropdownsForMobile()
    
    // Set up haptic feedback if available
    this.setupHapticFeedback()
  }

  handleTouchStart(event) {
    const target = event.target.closest('button, .btn')
    if (target && !target.disabled) {
      target.style.transform = 'scale(0.98)'
      target.style.transition = 'transform 0.1s ease'
    }
  }

  handleTouchEnd(event) {
    const target = event.target.closest('button, .btn')
    if (target) {
      setTimeout(() => {
        target.style.transform = ''
        target.style.transition = ''
      }, 100)
    }
  }

  optimizeDropdownsForMobile() {
    this.element.querySelectorAll('.dropdown-menu').forEach(menu => {
      // Ensure dropdown menus are properly positioned on mobile
      if (window.innerWidth <= 768) {
        menu.style.transform = 'none'
        menu.style.position = 'absolute'
        menu.style.willChange = 'transform'
      }
    })
  }

  setupHapticFeedback() {
    if ('vibrate' in navigator) {
      this.element.addEventListener('click', (event) => {
        const target = event.target.closest('button, .btn')
        if (target && !target.disabled && target.dataset.haptic !== 'false') {
          navigator.vibrate(10) // Short vibration
        }
      })
    }
  }
} 