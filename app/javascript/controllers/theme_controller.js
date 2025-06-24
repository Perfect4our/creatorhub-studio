import { Controller } from "@hotwired/stimulus"

// Manages theme switching between light and dark modes
export default class extends Controller {
  static targets = ["toggle"]
  
  connect() {
    this.loadTheme()
  }
  
  loadTheme() {
    // Check for saved theme preference or use system preference
    const savedTheme = localStorage.getItem('theme')
    
    if (savedTheme) {
      document.documentElement.setAttribute('data-theme', savedTheme)
      if (this.hasToggleTarget) {
        this.toggleTarget.checked = savedTheme === 'dark'
      }
    } else {
      // Check system preference
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      if (prefersDark) {
        document.documentElement.setAttribute('data-theme', 'dark')
        if (this.hasToggleTarget) {
          this.toggleTarget.checked = true
        }
      }
    }
  }
  
  toggle(event) {
    const isDark = event.target.checked
    const theme = isDark ? 'dark' : 'light'
    
    document.documentElement.setAttribute('data-theme', theme)
    localStorage.setItem('theme', theme)
  }
}
