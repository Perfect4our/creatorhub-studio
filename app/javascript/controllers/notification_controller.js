import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification"
export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Auto-remove existing notifications after 5 seconds
    this.element.querySelectorAll('.notification').forEach(notification => {
      this.setupNotificationLifecycle(notification);
    });
    
    // Set up mobile optimizations
    this.setupMobileOptimizations();
  }

  // Show a notification
  show(message, type = 'success') {
    const notification = this.createNotification(message, type);
    this.containerTarget.appendChild(notification);
    
    this.setupNotificationLifecycle(notification);
    
    return notification;
  }
  
  // Create a notification element with enhanced design
  createNotification(message, type) {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    
    // Get icon based on type
    const icon = this.getIcon(type);
    
    notification.innerHTML = `
      <div class="notification-icon">
        <i class="fas ${icon}"></i>
      </div>
      <div class="notification-content">
        <p class="notification-message">${message}</p>
      </div>
      <button type="button" class="notification-close" data-action="click->notification#close">
        <i class="fas fa-times"></i>
      </button>
      <div class="notification-progress"></div>
    `;
    
    // Set initial state for animation
    notification.style.opacity = '0';
    notification.style.transform = 'translateX(100%) scale(0.9)';
    
    // Trigger slide-in animation
    requestAnimationFrame(() => {
      notification.style.transition = 'all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)';
      notification.style.opacity = '1';
      notification.style.transform = 'translateX(0) scale(1)';
    });
    
    return notification;
  }
  
  // Get appropriate icon for notification type
  getIcon(type) {
    const icons = {
      success: 'fa-check',
      error: 'fa-exclamation-triangle',
      warning: 'fa-exclamation-circle',
      info: 'fa-info-circle'
    };
    return icons[type] || icons.info;
  }
  
  // Setup notification lifecycle with progress bar
  setupNotificationLifecycle(notification) {
    const progressBar = notification.querySelector('.notification-progress');
    
    // Start progress bar animation
    if (progressBar) {
      progressBar.style.animation = 'notification-progress 5s linear forwards';
    }
    
    // Auto-remove after 5 seconds
    const timeoutId = setTimeout(() => {
      this.fadeOut(notification);
    }, 5000);
    
    // Pause on hover
    notification.addEventListener('mouseenter', () => {
      if (progressBar) {
        progressBar.style.animationPlayState = 'paused';
      }
      clearTimeout(timeoutId);
    });
    
    // Resume on mouse leave
    notification.addEventListener('mouseleave', () => {
      if (progressBar) {
        progressBar.style.animationPlayState = 'running';
      }
      
      // Calculate remaining time and set new timeout
      const remainingTime = this.getRemainingTime(progressBar);
      setTimeout(() => {
        this.fadeOut(notification);
      }, remainingTime);
    });
  }
  
  // Calculate remaining time from progress bar
  getRemainingTime(progressBar) {
    if (!progressBar) return 1000;
    
    const computedStyle = window.getComputedStyle(progressBar);
    const transform = computedStyle.transform;
    
    if (transform && transform !== 'none') {
      const matrix = transform.match(/matrix\((.+)\)/);
      if (matrix) {
        const scaleX = parseFloat(matrix[1].split(', ')[0]);
        return Math.max(scaleX * 5000, 500); // At least 500ms
      }
    }
    
    return 2000; // Default fallback
  }
  
  // Close notification
  close(event) {
    const notification = event.currentTarget.closest('.notification');
    this.fadeOut(notification);
  }
  
  // Enhanced fade out with slide animation
  fadeOut(notification) {
    if (!notification || notification.classList.contains('fade-out')) return;
    
    notification.classList.add('fade-out');
    
    // Stop progress bar
    const progressBar = notification.querySelector('.notification-progress');
    if (progressBar) {
      progressBar.style.animationPlayState = 'paused';
    }
    
    // Enhanced slide-out animation
    notification.style.transition = 'all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)';
    notification.style.opacity = '0';
    
    // Check if mobile or desktop for appropriate animation
    const isMobile = window.innerWidth <= 768;
    
    if (isMobile) {
      notification.style.transform = 'translateY(-100%) scale(0.9)';
    } else {
      notification.style.transform = 'translateX(100%) scale(0.9)';
    }
    
    setTimeout(() => {
      if (notification && notification.parentNode) {
        notification.parentNode.removeChild(notification);
      }
    }, 300);
  }
  
  // Helper methods for common notification types with enhanced icons
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
  
  // Bulk operations
  clearAll() {
    const notifications = this.containerTarget.querySelectorAll('.notification');
    notifications.forEach(notification => {
      this.fadeOut(notification);
    });
  }
  
  // Show notification with custom duration
  showWithDuration(message, type = 'success', duration = 5000) {
    const notification = this.createNotification(message, type);
    this.containerTarget.appendChild(notification);
    
    const progressBar = notification.querySelector('.notification-progress');
    if (progressBar) {
      progressBar.style.animation = `notification-progress ${duration}ms linear forwards`;
    }
    
    setTimeout(() => {
      this.fadeOut(notification);
    }, duration);
    
    return notification;
  }

  // Mobile-specific optimizations for notifications
  setupMobileOptimizations() {
    if (!('ontouchstart' in window)) return;
    
    console.log("📱 Setting up mobile notification optimizations");
    
    // Add swipe-to-dismiss for mobile
    this.containerTarget.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: false });
    this.containerTarget.addEventListener('touchmove', this.handleTouchMove.bind(this), { passive: false });
    this.containerTarget.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: false });
  }

  handleTouchStart(event) {
    const notification = event.target.closest('.notification');
    if (!notification) return;
    
    this.touchStartX = event.touches[0].clientX;
    this.touchStartY = event.touches[0].clientY;
    this.touchingNotification = notification;
    this.initialTransform = notification.style.transform || '';
  }

  handleTouchMove(event) {
    if (!this.touchingNotification) return;
    
    const deltaX = event.touches[0].clientX - this.touchStartX;
    const deltaY = Math.abs(event.touches[0].clientY - this.touchStartY);
    
    // Only handle horizontal swipes (avoid interfering with scrolling)
    if (deltaY > 50) {
      this.resetTouchState();
      return;
    }
    
    if (Math.abs(deltaX) > 10) {
      event.preventDefault();
      
      // Apply transform based on swipe direction
      const opacity = Math.max(0.3, 1 - Math.abs(deltaX) / 300);
      this.touchingNotification.style.transform = `translateX(${deltaX}px) scale(${0.9 + opacity * 0.1})`;
      this.touchingNotification.style.opacity = opacity;
    }
  }

  handleTouchEnd(event) {
    if (!this.touchingNotification) return;
    
    const deltaX = this.touchStartX - event.changedTouches[0].clientX;
    
    // Dismiss if swiped far enough
    if (Math.abs(deltaX) > 100) {
      this.fadeOut(this.touchingNotification);
    } else {
      // Reset position
      this.touchingNotification.style.transform = this.initialTransform;
      this.touchingNotification.style.opacity = '';
    }
    
    this.resetTouchState();
  }

  resetTouchState() {
    this.touchStartX = null;
    this.touchStartY = null;
    this.touchingNotification = null;
    this.initialTransform = '';
  }
} 