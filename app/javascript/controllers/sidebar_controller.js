import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  showConnectPrompt(event) {
    event.preventDefault()
    const platform = event.currentTarget.dataset.platform
    
    if (window.notificationController) {
      window.notificationController.showNotification(
        `Connect your ${platform} account to view platform-specific data.`, 
        'info'
      )
    } else {
      alert(`Connect your ${platform} account to view platform-specific data.`)
    }
  }
  
  showComingSoon(event) {
    event.preventDefault()
    const feature = event.currentTarget.dataset.feature
    
    if (window.notificationController) {
      window.notificationController.showNotification(
        `${feature} feature coming soon!`, 
        'info'
      )
    } else {
      alert(`${feature} feature coming soon!`)
    }
  }
} 