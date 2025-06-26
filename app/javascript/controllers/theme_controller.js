import { Controller } from "@hotwired/stimulus"

// Manages theme switching between light and dark modes
export default class extends Controller {
  static targets = ["toggle"]
  
  connect() {
    this.loadTheme()
    this.setupTurboHandlers()
  }
  
  disconnect() {
    this.cleanupTurboHandlers()
  }
  
  setupTurboHandlers() {
    // Handle Turbo navigation events to ensure theme persists
    this.turboLoadHandler = this.handleTurboLoad.bind(this)
    this.turboRenderHandler = this.handleTurboRender.bind(this)
    
    document.addEventListener('turbo:load', this.turboLoadHandler)
    document.addEventListener('turbo:render', this.turboRenderHandler)
    
    // Also handle traditional page loads for fallback
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', this.turboLoadHandler)
    }
  }
  
  cleanupTurboHandlers() {
    document.removeEventListener('turbo:load', this.turboLoadHandler)
    document.removeEventListener('turbo:render', this.turboRenderHandler)
    document.removeEventListener('DOMContentLoaded', this.turboLoadHandler)
  }
  
  handleTurboLoad() {
    // Ensure theme is applied after any Turbo navigation
    this.loadTheme()
  }
  
  handleTurboRender() {
    // Ensure theme classes are maintained during Turbo rendering
    const currentTheme = localStorage.getItem('theme') || 'light'
    this.applyTheme(currentTheme, { skipToggleUpdate: true })
  }
  
  loadTheme() {
    // Load saved theme preference or default to light mode
    const theme = localStorage.getItem('theme') || 'light'
    
    // Apply the saved or default theme
    this.applyTheme(theme)
    
    // Set toggle state based on current theme
    this.updateToggleState(theme)
  }
  
  updateToggleState(theme) {
    if (this.hasToggleTarget) {
      this.toggleTarget.checked = theme === 'dark'
    }
    
    // Also check for any other toggle elements that might exist
    const allToggles = document.querySelectorAll('[data-theme-target="toggle"]')
    allToggles.forEach(toggle => {
      toggle.checked = theme === 'dark'
    })
  }
  
  toggle(event) {
    const isDark = event.target.checked
    const theme = isDark ? 'dark' : 'light'
    
    this.applyTheme(theme)
    localStorage.setItem('theme', theme)
    
    // Dispatch custom event for other components that might need to know
    document.dispatchEvent(new CustomEvent('theme:changed', { 
      detail: { theme, isDark } 
    }))
  }
  
  applyTheme(theme, options = {}) {
    const { skipToggleUpdate = false } = options
    
    // Use requestAnimationFrame to ensure DOM is ready
    requestAnimationFrame(() => {
      if (theme === 'dark') {
        document.body.classList.add('dark-mode')
        document.documentElement.setAttribute('data-theme', 'dark')
        document.documentElement.classList.add('dark-mode')
      } else {
        document.body.classList.remove('dark-mode')
        document.documentElement.setAttribute('data-theme', 'light')
        document.documentElement.classList.remove('dark-mode')
      }
      
      // Update toggle state unless explicitly skipped
      if (!skipToggleUpdate) {
        this.updateToggleState(theme)
      }
      
      // Force a style recalculation to ensure CSS changes take effect
      document.body.offsetHeight
    })
  }
}

// Global theme initialization for immediate application
// This runs before Stimulus controllers are connected
(function() {
  const theme = localStorage.getItem('theme') || 'light'
  
  if (theme === 'dark') {
    document.documentElement.classList.add('dark-mode')
    if (document.body) {
      document.body.classList.add('dark-mode')
    } else {
      document.addEventListener('DOMContentLoaded', () => {
        document.body.classList.add('dark-mode')
      })
    }
    document.documentElement.setAttribute('data-theme', 'dark')
  } else {
    document.documentElement.classList.remove('dark-mode')
    if (document.body) {
      document.body.classList.remove('dark-mode')
    }
    document.documentElement.setAttribute('data-theme', 'light')
  }
})();
