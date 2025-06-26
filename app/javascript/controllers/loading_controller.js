import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar"]
  
  connect() {
    this.setupLoadingBar()
    this.interceptTurboEvents()
  }

  setupLoadingBar() {
    // Create a custom loading bar that syncs with actual performance
    if (!document.getElementById('custom-loading-bar')) {
      const loadingBar = document.createElement('div')
      loadingBar.id = 'custom-loading-bar'
      loadingBar.innerHTML = `
        <div class="loading-bar-container">
          <div class="loading-bar-progress"></div>
        </div>
      `
      document.body.appendChild(loadingBar)
      
      this.loadingBar = loadingBar.querySelector('.loading-bar-progress')
      this.container = loadingBar.querySelector('.loading-bar-container')
    }
  }

  interceptTurboEvents() {
    // Override default Turbo progress bar with error handling
    try {
      if (window.Turbo && window.Turbo.session && window.Turbo.session.progressBar) {
        window.Turbo.session.progressBar.hide()
      }
    } catch (error) {
      console.log('Turbo progress bar not available, using custom loading bar only')
    }
    
    // Listen for Turbo navigation events
    document.addEventListener('turbo:load', this.handleTurboLoad.bind(this))
    document.addEventListener('turbo:visit', this.handleTurboVisit.bind(this))
    document.addEventListener('turbo:before-cache', this.handleBeforeCache.bind(this))

    // Listen for regular page loads
    if (document.readyState === 'loading') {
      this.startLoading()
    }
  }

  handleTurboVisit(event) {
    this.startLoading()
  }

  handleTurboLoad(event) {
    // Fast completion for our optimized pages
    this.completeLoading(200) // Complete in 200ms for optimized pages
  }

  handleBeforeCache(event) {
    this.hideLoadingBar()
  }

  startLoading() {
    if (!this.container || !this.loadingBar) return
    
    // Show loading bar
    this.container.style.display = 'block'
    this.container.style.opacity = '1'
    this.loadingBar.style.width = '0%'
    this.loadingBar.style.transition = 'none'
    
    // Start progress simulation
    this.startTime = Date.now()
    this.simulateProgress()
  }

  simulateProgress() {
    if (!this.loadingBar) return
    
    const elapsed = Date.now() - this.startTime
    
    // Faster progress for our optimized dashboard
    let progress = 0
    
    if (elapsed < 100) {
      // Quick initial progress (0-40% in first 100ms)
      progress = (elapsed / 100) * 40
    } else if (elapsed < 300) {
      // Steady progress (40-80% in next 200ms)
      progress = 40 + ((elapsed - 100) / 200) * 40
    } else if (elapsed < 600) {
      // Slow down near completion (80-95% in next 300ms)
      progress = 80 + ((elapsed - 300) / 300) * 15
    } else {
      // Stay at 95% until completion
      progress = 95
    }
    
    this.loadingBar.style.transition = 'width 0.1s ease'
    this.loadingBar.style.width = Math.min(progress, 95) + '%'
    
    // Continue if not completed
    if (progress < 95) {
      requestAnimationFrame(() => this.simulateProgress())
    }
  }

  completeLoading(delay = 100) {
    if (!this.loadingBar) return
    
    setTimeout(() => {
      // Complete the loading bar
      this.loadingBar.style.transition = 'width 0.2s ease'
      this.loadingBar.style.width = '100%'
      
      // Hide after completion
      setTimeout(() => {
        this.hideLoadingBar()
      }, 200)
    }, delay)
  }

  hideLoadingBar() {
    if (!this.container) return
    
    this.container.style.transition = 'opacity 0.3s ease'
    this.container.style.opacity = '0'
    
    setTimeout(() => {
      this.container.style.display = 'none'
    }, 300)
  }

  // Handle AJAX loading for dashboard updates
  showAjaxLoading() {
    this.startLoading()
  }

  hideAjaxLoading() {
    this.completeLoading(50) // Very fast completion for AJAX
  }

  disconnect() {
    if (this.container) {
      this.container.remove()
    }
  }
}

// Make loading controller globally available for sidebar and other components  
window.addEventListener('DOMContentLoaded', function() {
  // Store reference to loading controller for global access via sidebar
  window.loadingController = {
    showLoading: () => {
      const loadingElement = document.querySelector('[data-controller*="loading"]')
      if (loadingElement && window.Stimulus) {
        const controller = window.Stimulus.getControllerForElementAndIdentifier(loadingElement, 'loading')
        if (controller && controller.startLoading) {
          controller.startLoading()
        }
      }
    },
    hideLoading: () => {
      const loadingElement = document.querySelector('[data-controller*="loading"]')
      if (loadingElement && window.Stimulus) {
        const controller = window.Stimulus.getControllerForElementAndIdentifier(loadingElement, 'loading')
        if (controller && controller.completeLoading) {
          controller.completeLoading(50)
        }
      }
    }
  }
}) 