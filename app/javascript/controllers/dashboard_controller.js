import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { userId: String }

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
} 