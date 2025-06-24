import { Controller } from "@hotwired/stimulus"

// Manages platform selection and filtering
export default class extends Controller {
  static targets = ["platformSelector", "platformContent", "platformTab"]
  
  connect() {
    this.loadSelectedPlatform()
  }
  
  loadSelectedPlatform() {
    // Check for saved platform preference
    const savedPlatform = localStorage.getItem('selectedPlatform')
    
    if (savedPlatform && this.hasPlatformSelectorTarget) {
      // Find and select the saved platform
      const option = this.platformSelectorTarget.querySelector(`option[value="${savedPlatform}"]`)
      if (option) {
        this.platformSelectorTarget.value = savedPlatform
        this.filterContent(savedPlatform)
      }
    }
  }
  
  select(event) {
    const platform = event.target.value
    localStorage.setItem('selectedPlatform', platform)
    this.filterContent(platform)
  }
  
  // Add the missing switchPlatform method
  switchPlatform(event) {
    event.preventDefault()
    
    // Get the platform from the clicked tab
    const platform = event.currentTarget.getAttribute('data-platform')
    
    // Save the selected platform
    localStorage.setItem('selectedPlatform', platform)
    
    // Update active tab
    if (this.hasPlatformTabTarget) {
      this.platformTabTargets.forEach(tab => {
        tab.classList.remove('active')
      })
      event.currentTarget.classList.add('active')
    }
    
    // Filter content based on platform
    this.filterContent(platform)
  }
  
  filterContent(platform) {
    if (!this.hasPlatformContentTarget) return
    
    if (platform === 'all') {
      // Show all platforms
      this.platformContentTargets.forEach(content => {
        content.classList.remove('d-none')
      })
    } else {
      // Show only selected platform
      this.platformContentTargets.forEach(content => {
        const contentPlatform = content.getAttribute('data-platform')
        if (contentPlatform === platform) {
          content.classList.remove('d-none')
        } else {
          content.classList.add('d-none')
        }
      })
    }
  }
}
