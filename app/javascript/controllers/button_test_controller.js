import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["log"]
  
  connect() {
    this.testLogElement = this.hasLogTarget ? this.logTarget : null
    this.initializeStatusMonitoring()
    this.logTest('Test page initialized successfully')
  }
  
  // Initialize status monitoring
  initializeStatusMonitoring() {
    this.updateSystemStatus()
    this.statusInterval = setInterval(() => {
      this.updateSystemStatus()
    }, 1000)
    
    // Monitor button clicks for logging
    this.element.addEventListener('click', (event) => {
      const button = event.target.closest('button, .btn, a[href]')
      if (button && button.dataset.analyticsTrack) {
        this.logTest(`Button clicked: ${button.dataset.analyticsTrack} - ${button.textContent.trim()}`)
      }
    })
    
    // Monitor form submissions
    this.element.addEventListener('submit', (event) => {
      const form = event.target
      if (form.dataset.analyticsTrack) {
        this.logTest(`Form submitted: ${form.dataset.analyticsTrack}`)
      }
    })
  }
  
  disconnect() {
    if (this.statusInterval) {
      clearInterval(this.statusInterval)
    }
  }
  
  // Update system status
  updateSystemStatus() {
    try {
      const body = document.querySelector('body[data-controller*="request-manager"]')
      const rmStatus = document.getElementById('request-manager-status')
      
      if (body) {
        const requestManager = window.application.getControllerForElementAndIdentifier(body, 'request-manager')
        if (requestManager) {
          rmStatus.textContent = 'Active'
          rmStatus.className = 'badge bg-success'
          
          // Update stats
          const stats = requestManager.getRequestStats()
          document.getElementById('active-requests-count').textContent = stats.activeRequests
          document.getElementById('loading-buttons-count').textContent = stats.loadingButtons
          
          // Update badge colors based on activity
          const reqCount = document.getElementById('active-requests-count')
          reqCount.className = stats.activeRequests > 0 ? 'badge bg-warning' : 'badge bg-success'
          
          const btnCount = document.getElementById('loading-buttons-count')
          btnCount.className = stats.loadingButtons > 0 ? 'badge bg-warning' : 'badge bg-success'
        } else {
          rmStatus.textContent = 'Initializing'
          rmStatus.className = 'badge bg-warning'
        }
      } else {
        rmStatus.textContent = 'Not Found'
        rmStatus.className = 'badge bg-danger'
      }
    } catch (error) {
      console.error('Status update error:', error)
    }
  }
  
  // Reset all states
  resetAllStates() {
    try {
      const body = document.querySelector('body[data-controller*="request-manager"]')
      if (body) {
        const requestManager = window.application.getControllerForElementAndIdentifier(body, 'request-manager')
        if (requestManager) {
          requestManager.cancelAllRequests()
          requestManager.resetAllButtonStates()
          this.logTest('All states reset successfully')
        }
      }
    } catch (error) {
      this.logTest(`Reset error: ${error.message}`, 'error')
    }
  }
  
  // Show system stats
  showSystemStats() {
    try {
      const body = document.querySelector('body[data-controller*="request-manager"]')
      if (body) {
        const requestManager = window.application.getControllerForElementAndIdentifier(body, 'request-manager')
        if (requestManager) {
          const stats = requestManager.getRequestStats()
          const statsText = JSON.stringify(stats, null, 2)
          this.logTest(`System Stats:\n${statsText}`)
        }
      }
    } catch (error) {
      this.logTest(`Stats error: ${error.message}`, 'error')
    }
  }
  
  // Simulate error
  simulateError() {
    this.logTest('Simulating error condition...')
    
    // Trigger an unhandled promise rejection
    Promise.reject(new Error('Simulated test error')).catch(() => {})
    
    // Trigger a JS error
    setTimeout(() => {
      try {
        throw new Error('Simulated JavaScript error')
      } catch (error) {
        this.logTest(`Simulated error triggered: ${error.message}`, 'error')
      }
    }, 100)
  }
  
  // Show debug commands
  showDebugCommands() {
    const commands = [
      'Available debug commands (run in browser console):',
      '',
      '// Check current system state',
      'window.requestManagerDebug.state()',
      '',
      '// Force emergency reset if system is stuck',
      'window.requestManagerDebug.reset()',
      '',
      '// Show request statistics',
      'window.requestManagerDebug.stats()',
      '',
      '// Navigation issue? Try this sequence:',
      'window.requestManagerDebug.reset()',
      'location.reload()',
      '',
      '// If dropdowns are stuck on dashboard:',
      'rebuildStuckDropdown() // (dashboard page only)',
      '',
      'Press F12 to open console and copy/paste these commands.'
    ]
    
    this.logTest(commands.join('\n'))
    
    // Also show in an alert for easy access
    alert('Debug commands logged to console. Open F12 console to see them.\n\nQuick fix: If system is stuck, run:\nwindow.requestManagerDebug.reset()')
  }
  
  // Log test messages
  logTest(message, type = 'info') {
    if (!this.testLogElement) return
    
    const timestamp = new Date().toLocaleTimeString()
    const logEntry = document.createElement('div')
    
    let className = 'text-primary'
    let icon = '📝'
    
    if (type === 'error') {
      className = 'text-danger'
      icon = '❌'
    } else if (type === 'success') {
      className = 'text-success'
      icon = '✅'
    } else if (type === 'warning') {
      className = 'text-warning'
      icon = '⚠️'
    }
    
    logEntry.className = className
    logEntry.innerHTML = `${icon} [${timestamp}] ${message}`
    
    this.testLogElement.appendChild(logEntry)
    this.testLogElement.scrollTop = this.testLogElement.scrollHeight
    
    // Keep only last 50 log entries
    const entries = this.testLogElement.children
    if (entries.length > 50) {
      this.testLogElement.removeChild(entries[0])
    }
  }
  
  // ===== NOTIFICATION SYSTEM TEST FUNCTIONS =====
  
  // Get notification controller instance
  getNotificationController() {
    const notificationElement = document.querySelector('[data-controller*="notification"]')
    if (notificationElement && window.application) {
      return window.application.getControllerForElementAndIdentifier(notificationElement, 'notification')
    }
    return null
  }
  
  // Show a test notification
  showTestNotification(event) {
    const message = event.params.message
    const type = event.params.type
    const controller = this.getNotificationController()
    
    if (controller) {
      controller.show(message, type)
      this.logTest(`Showed ${type} notification: ${message}`, 'success')
    } else {
      // Fallback to button controller notification
      const buttonElement = document.querySelector('[data-controller*="button"]')
      if (buttonElement && window.application) {
        const buttonController = window.application.getControllerForElementAndIdentifier(buttonElement, 'button')
        if (buttonController) {
          buttonController.showNotification(message, type)
          this.logTest(`Showed ${type} notification via button controller: ${message}`, 'success')
        } else {
          this.logTest('No notification system available', 'error')
        }
      } else {
        this.logTest('No button controller available', 'error')
      }
    }
  }
  
  // Show multiple notifications to test stacking
  showMultipleNotifications() {
    const messages = [
      { text: 'First notification - Success!', type: 'success' },
      { text: 'Second notification - Information', type: 'info' },
      { text: 'Third notification - Warning!', type: 'warning' },
      { text: 'Fourth notification - Error example', type: 'error' }
    ]
    
    messages.forEach((msg, index) => {
      setTimeout(() => {
        const controller = this.getNotificationController()
        if (controller) {
          controller.show(msg.text, msg.type)
        }
      }, index * 500) // Stagger by 500ms
    })
    
    this.logTest('Showing multiple notifications with staggered timing', 'info')
  }
  
  // Show a long message to test text wrapping
  showLongNotification() {
    const longMessage = 'This is a very long notification message that should test how the notification system handles text wrapping and longer content. It should maintain proper styling and readability even with extended text content that might span multiple lines in the notification display area.'
    const controller = this.getNotificationController()
    if (controller) {
      controller.show(longMessage, 'info')
    }
    this.logTest('Showing long message notification', 'info')
  }
  
  // Show notification with custom duration
  showCustomDuration() {
    const controller = this.getNotificationController()
    if (controller && controller.showWithDuration) {
      controller.showWithDuration('This notification will stay for 10 seconds!', 'warning', 10000)
      this.logTest('Showing 10-second duration notification', 'success')
    } else {
      if (controller) {
        controller.show('Custom duration not available - using default 5s', 'warning')
      }
      this.logTest('Custom duration method not available', 'warning')
    }
  }
  
  // Clear all notifications
  clearAllNotifications() {
    const controller = this.getNotificationController()
    if (controller && controller.clearAll) {
      controller.clearAll()
      this.logTest('Cleared all notifications', 'success')
    } else {
      // Fallback - manually remove all notifications
      const notifications = document.querySelectorAll('.notification')
      notifications.forEach(notification => {
        notification.style.opacity = '0'
        notification.style.transform = 'translateX(100%) scale(0.9)'
        setTimeout(() => {
          if (notification.parentNode) {
            notification.parentNode.removeChild(notification)
          }
        }, 300)
      })
      this.logTest(`Manually cleared ${notifications.length} notifications`, 'success')
    }
  }
} 