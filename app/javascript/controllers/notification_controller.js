import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification"
export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Auto-remove existing notifications after 5 seconds
    this.element.querySelectorAll('.notification').forEach(notification => {
      setTimeout(() => {
        this.fadeOut(notification);
      }, 5000);
    });
  }

  // Show a notification
  show(message, type = 'success') {
    const notification = this.createNotification(message, type);
    this.containerTarget.appendChild(notification);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      this.fadeOut(notification);
    }, 5000);
    
    return notification;
  }
  
  // Create a notification element
  createNotification(message, type) {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
      ${message}
      <button type="button" class="notification-close" data-action="click->notification#close">&times;</button>
    `;
    
    // Add animation classes
    notification.style.opacity = '0';
    notification.style.transform = 'translateY(-100%)';
    
    // Trigger animation
    setTimeout(() => {
      notification.style.transition = 'all 0.5s ease';
      notification.style.opacity = '1';
      notification.style.transform = 'translateY(0)';
    }, 10);
    
    return notification;
  }
  
  // Close notification
  close(event) {
    const notification = event.currentTarget.closest('.notification');
    this.fadeOut(notification);
  }
  
  // Fade out and remove notification
  fadeOut(notification) {
    if (!notification) return;
    
    notification.style.opacity = '0';
    notification.style.transform = 'translateY(-100%)';
    
    setTimeout(() => {
      if (notification.parentNode) {
        notification.parentNode.removeChild(notification);
      }
    }, 500);
  }
  
  // Helper methods for common notification types
  success(message) {
    return this.show(message, 'success');
  }
  
  error(message) {
    return this.show(message, 'error');
  }
  
  info(message) {
    return this.show(message, 'info');
  }
  
  warning(message) {
    return this.show(message, 'warning');
  }
} 