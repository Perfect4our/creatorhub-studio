import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { userId: String }

  connect() {
    this.syncConnectionStatus()
    this.setupMobileSidebar()
    
    // Sync connection status between main and mobile elements
    const mainStatus = document.getElementById('connection-status-indicator')
    if (mainStatus) {
      const observer = new MutationObserver(() => this.syncConnectionStatus())
      observer.observe(mainStatus, { 
        attributes: true, 
        attributeFilter: ['class'] 
      })
    }
  }

  acknowledgeSubscription(event) {
    // Prevent default link behavior if it's a link
    if (event.target.tagName === 'A' || event.target.closest('a')) {
      // Let the link navigate normally, but also acknowledge
      this.sendAcknowledgment()
      return true
    } else {
      // For close button, prevent default and acknowledge
      event.preventDefault()
      this.sendAcknowledgment()
      
      // Hide the alert
      const alert = this.element
      if (alert) {
        const bsAlert = bootstrap.Alert.getOrCreateInstance(alert)
        bsAlert.close()
      }
    }
  }

  sendAcknowledgment() {
    fetch('/acknowledge_subscription_status', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        user_id: this.userIdValue
      })
    }).catch(error => {
      console.error('Failed to acknowledge subscription status:', error)
    })
  }

  setupMobileSidebar() {
    const sidebarToggle = document.getElementById('mobileSidebarToggle')
    const sidebar = document.getElementById('sidebar')
    
    if (sidebarToggle && sidebar) {
      // Create backdrop if it doesn't exist
      let backdrop = document.querySelector('.sidebar-backdrop')
      if (!backdrop) {
        backdrop = document.createElement('div')
        backdrop.className = 'sidebar-backdrop'
        document.body.appendChild(backdrop)
      }
      
      // Handle sidebar toggle
      sidebarToggle.addEventListener('click', () => {
        const isShown = sidebar.classList.contains('show')
        
        if (isShown) {
          this.hideMobileSidebar()
        } else {
          this.showMobileSidebar()
        }
      })
      
      // Handle backdrop click
      backdrop.addEventListener('click', () => {
        this.hideMobileSidebar()
      })
      
      // Handle escape key
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && sidebar.classList.contains('show')) {
          this.hideMobileSidebar()
        }
      })
    }
  }

  showMobileSidebar() {
    const sidebar = document.getElementById('sidebar')
    const backdrop = document.querySelector('.sidebar-backdrop')
    
    if (sidebar && backdrop) {
      sidebar.classList.add('show')
      backdrop.classList.add('show')
      document.body.style.overflow = 'hidden'
    }
  }

  hideMobileSidebar() {
    const sidebar = document.getElementById('sidebar')
    const backdrop = document.querySelector('.sidebar-backdrop')
    
    if (sidebar && backdrop) {
      sidebar.classList.remove('show')
      backdrop.classList.remove('show')
      document.body.style.overflow = ''
    }
  }

  syncConnectionStatus() {
    const mainStatus = document.getElementById('connection-status-indicator')
    const mobileStatus = document.getElementById('mobile-connection-status-indicator')
    
    if (mainStatus && mobileStatus) {
      // Copy classes from main status to mobile status
      mobileStatus.className = mainStatus.className
      
      // Copy the connection dot color
      const mainDot = mainStatus.querySelector('.connection-dot')
      const mobileDot = mobileStatus.querySelector('.connection-dot')
      
      if (mainDot && mobileDot) {
        const mainColor = window.getComputedStyle(mainDot).backgroundColor
        mobileDot.style.backgroundColor = mainColor
      }
    }
  }
} 