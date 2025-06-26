import { Controller } from "@hotwired/stimulus"

// Manages theme switching between light and dark modes
export default class extends Controller {
  static targets = ["toggle"]
  
  connect() {
    this.loadTheme()
  }
  
  loadTheme() {
    // Load saved theme preference or default to light mode
    const theme = localStorage.getItem('theme') || 'light'
    
    // Apply the saved or default theme
    this.applyTheme(theme)
    
    // Set toggle state based on current theme
    if (this.hasToggleTarget) {
      this.toggleTarget.checked = theme === 'dark'
    }
  }
  
  toggle(event) {
    const isDark = event.target.checked
    const theme = isDark ? 'dark' : 'light'
    
    this.applyTheme(theme)
    localStorage.setItem('theme', theme)
  }
  
  applyTheme(theme) {
    if (theme === 'dark') {
      document.body.classList.add('dark-mode')
      document.documentElement.setAttribute('data-theme', 'dark')
    } else {
      document.body.classList.remove('dark-mode')
      document.documentElement.setAttribute('data-theme', 'light')
    }
  }
}
