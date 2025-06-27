import { Controller } from "@hotwired/stimulus"

// Simple, reliable time selector that replaces Bootstrap dropdown
export default class extends Controller {
  static targets = ["dropdown", "button", "selected", "customModal", "startDate", "endDate", "menu", "customRangeLink", "selectedPeriod"]
  static values = { 
    currentValue: String, 
    platform: String,
    updateUrl: String,
    currentPeriod: String,
    userId: String
  }

  connect() {
    this.updateDisplay()
    this.setupEventListeners()
    
    // Set initial update URL if not provided
    if (!this.updateUrlValue) {
      this.updateUrlValue = "/dashboard/update_dashboard_data"
    }

    console.log('Time selector controller connected')
    this.initializeDropdown()
    this.setupCustomDatePicker()
  }

  setupEventListeners() {
    // Close dropdown when clicking outside
    document.addEventListener('click', this.handleOutsideClick.bind(this))
    
    // Handle escape key
    document.addEventListener('keydown', this.handleEscapeKey.bind(this))
    
    // Mobile touch events for better mobile experience
    if ('ontouchstart' in window) {
      document.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: true })
      document.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: true })
    }
  }

  disconnect() {
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
    document.removeEventListener('keydown', this.handleEscapeKey.bind(this))
    
    // Remove mobile touch events
    if ('ontouchstart' in window) {
      document.removeEventListener('touchstart', this.handleTouchStart.bind(this))
      document.removeEventListener('touchend', this.handleTouchEnd.bind(this))
    }

    console.log('Time selector controller disconnected')
    this.cleanup()
  }

  toggleDropdown(event) {
    event.stopPropagation()
    const isOpen = this.dropdownTarget.classList.contains('show')
    
    if (isOpen) {
      this.closeDropdown()
    } else {
      this.openDropdown()
    }
  }

  openDropdown() {
    this.dropdownTarget.classList.add('show')
    this.buttonTarget.setAttribute('aria-expanded', 'true')
    
    // Add animation class
    this.dropdownTarget.style.opacity = '0'
    this.dropdownTarget.style.transform = 'translateY(-10px)'
    
    requestAnimationFrame(() => {
      this.dropdownTarget.style.transition = 'all 0.2s ease'
      this.dropdownTarget.style.opacity = '1'
      this.dropdownTarget.style.transform = 'translateY(0)'
    })
  }

  closeDropdown() {
    this.dropdownTarget.style.transition = 'all 0.15s ease'
    this.dropdownTarget.style.opacity = '0'
    this.dropdownTarget.style.transform = 'translateY(-5px)'
    
    setTimeout(() => {
      this.dropdownTarget.classList.remove('show')
      this.buttonTarget.setAttribute('aria-expanded', 'false')
      this.dropdownTarget.style.transition = ''
      this.dropdownTarget.style.transform = ''
      this.dropdownTarget.style.opacity = ''
    }, 150)
  }

  async selectPeriod(event) {
    event.preventDefault()
    const item = event.currentTarget
    const period = item.dataset.period
    const label = item.textContent.trim()

    // Update visual state immediately
    this.currentValueValue = period
    this.selectedTarget.textContent = label
    this.updateActiveState(item)
    this.closeDropdown()

    // Show custom loading bar for AJAX (safely)
    try {
      if (window.loadingController && typeof window.loadingController.showAjaxLoading === 'function') {
        window.loadingController.showAjaxLoading()
      }
    } catch (e) {
      console.log('Loading controller not available:', e.message)
    }

    // Show local loading state as well
    this.showLoadingState()

    try {
      // Make AJAX request to update dashboard data
      await this.updateDashboardData(period)
    } catch (error) {
      console.error('Failed to update dashboard:', error)
      this.showErrorState()
    }
  }

  async customRange(event) {
    event.preventDefault()
    this.closeDropdown()
    this.showCustomModal()
  }

  showCustomModal() {
    if (this.hasCustomModalTarget) {
      this.customModalTarget.classList.remove('custom-modal-hidden')
      
      // Set default dates (28 days)
      const endDate = new Date().toISOString().split('T')[0]
      const startDate = new Date(Date.now() - 28 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
      
      this.startDateTarget.value = startDate
      this.endDateTarget.value = endDate
      
      // Focus first input
      this.startDateTarget.focus()
    }
  }

  closeCustomModal() {
    if (this.hasCustomModalTarget) {
      this.customModalTarget.classList.add('custom-modal-hidden')
    }
  }

  async applyCustomRange(event) {
    event.preventDefault()
    
    const startDate = this.startDateTarget.value
    const endDate = this.endDateTarget.value
    
    if (!startDate || !endDate) {
      alert('Please select both start and end dates')
      return
    }
    
    if (new Date(startDate) > new Date(endDate)) {
      alert('Start date must be before end date')
      return
    }

    // Update visual state
    this.currentValueValue = 'custom'
    const dateRange = `${this.formatDate(startDate)} - ${this.formatDate(endDate)}`
    this.selectedTarget.textContent = dateRange
    this.closeCustomModal()

    // Show custom loading bar for AJAX (safely)
    try {
      if (window.loadingController && typeof window.loadingController.showAjaxLoading === 'function') {
        window.loadingController.showAjaxLoading()
      }
    } catch (e) {
      console.log('Loading controller not available:', e.message)
    }

    // Show local loading state
    this.showLoadingState()

    try {
      // Make AJAX request with custom dates
      await this.updateDashboardData('custom', startDate, endDate)
    } catch (error) {
      console.error('Failed to update dashboard:', error)
      this.showErrorState()
    }
  }

  async updateDashboardData(timeWindow, startDate = null, endDate = null) {
    const params = new URLSearchParams({
      time_window: timeWindow,
      platform: this.platformValue || ''
    })

    if (startDate && endDate) {
      params.append('start_date', startDate)
      params.append('end_date', endDate)
    }

    const url = `${this.updateUrlValue}?${params}`

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }

    const data = await response.json()
    
    // Update the dashboard with new data
    this.updateDashboardElements(data)
    
    // Hide both loading states
    this.hideLoadingState()
    try {
      if (window.loadingController && typeof window.loadingController.hideAjaxLoading === 'function') {
        window.loadingController.hideAjaxLoading()
      }
    } catch (e) {
      console.log('Loading controller not available:', e.message)
    }
  }

  updateDashboardElements(data) {
    // Update stats cards
    this.updateStatsCards(data.stats)
    
    // Update platform stats
    this.updatePlatformStats(data.platform_stats)
    
    // Update charts
    this.updateCharts(data.chart_data, data.chart_labels)
    
    // Update top videos section
    this.updateTopVideos(data.top_videos)
    
    // Update summary title
    this.updateSummaryTitle(data.summary_title)
    
    // Dispatch custom event for other controllers to react
    this.dispatch('updated', { detail: data })
  }

  updateStatsCards(stats) {
    // Update view count
    const viewsElement = document.querySelector('[data-stat="views"]')
    if (viewsElement && stats.views !== undefined) {
      this.animateNumber(viewsElement, stats.views)
    }
    
    // Update followers count
    const followersElement = document.querySelector('[data-stat="followers"]')
    if (followersElement && stats.followers !== undefined) {
      this.animateNumber(followersElement, stats.followers)
    }
    
    // Update revenue
    const revenueElement = document.querySelector('[data-stat="revenue"]')
    if (revenueElement && stats.revenue !== undefined) {
      this.animateNumber(revenueElement, stats.revenue, true)
    }
  }

  updatePlatformStats(platformStats) {
    // Update platform-specific stats if present
    Object.entries(platformStats).forEach(([platform, stats]) => {
      const platformElement = document.querySelector(`[data-platform="${platform}"]`)
      if (platformElement) {
        const viewsEl = platformElement.querySelector('[data-platform-stat="views"]')
        const followersEl = platformElement.querySelector('[data-platform-stat="followers"]')
        const revenueEl = platformElement.querySelector('[data-platform-stat="revenue"]')
        
        if (viewsEl) this.animateNumber(viewsEl, stats.views)
        if (followersEl) this.animateNumber(followersEl, stats.followers)
        if (revenueEl) this.animateNumber(revenueEl, stats.revenue, true)
      }
    })
  }

  updateCharts(chartData, chartLabels) {
    // Update Chart.js charts if they exist
    if (window.dashboardCharts) {
      Object.entries(chartData).forEach(([platform, data]) => {
        const chart = window.dashboardCharts[platform]
        if (chart) {
          chart.data.labels = chartLabels
          chart.data.datasets[0].data = data.views
          if (chart.data.datasets[1]) chart.data.datasets[1].data = data.followers
          if (chart.data.datasets[2]) chart.data.datasets[2].data = data.revenue
          chart.update('none') // No animation for faster updates
        }
      })
    }
    
    // Update main chart if it exists
    if (window.TikTokStudio && window.TikTokStudio.mainChart) {
      window.TikTokStudio.mainChart.data.labels = chartLabels
      if (chartData && Object.keys(chartData).length > 0) {
        // Update datasets for each platform
        let datasetIndex = 0
        Object.entries(chartData).forEach(([platform, data]) => {
          if (window.TikTokStudio.mainChart.data.datasets[datasetIndex]) {
            window.TikTokStudio.mainChart.data.datasets[datasetIndex].data = data.views || []
            datasetIndex++
          }
        })
      }
      window.TikTokStudio.mainChart.update('none')
    }
  }

  updateTopVideos(topVideos) {
    const topVideosContainer = document.querySelector('[data-top-videos-container]')
    if (!topVideosContainer || !topVideos) return
    
    // Clear existing videos
    topVideosContainer.innerHTML = ''
    
    if (topVideos.length === 0) {
      topVideosContainer.innerHTML = `
        <div class="text-center py-3">
          <i class="fas fa-video text-muted mb-2" style="font-size: 2rem;"></i>
          <p class="text-muted mb-1">No videos found</p>
          <small class="text-muted">Videos will appear here once your accounts are synced</small>
        </div>
      `
      return
    }
    
    // Add new videos
    topVideos.forEach((video, index) => {
      const videoElement = document.createElement('div')
      videoElement.className = `top-video-item mb-3 ${index < topVideos.length - 1 ? 'border-bottom pb-3' : ''}`
      
      const thumbnailHtml = video.thumbnail_url ? 
        `<img src="${video.thumbnail_url}" alt="Video thumbnail" class="img-fluid rounded" style="width: 60px; height: 45px; object-fit: cover;">` :
        `<div class="d-flex align-items-center justify-content-center bg-light rounded" style="width: 60px; height: 45px;">
           <i class="fab fa-${video.platform} text-${video.platform === 'youtube' ? 'danger' : 'dark'}"></i>
         </div>`
      
      const linkHtml = video.link && video.link !== '#' ?
        `<a href="${video.link}" target="${video.link_target || '_blank'}" class="text-decoration-none">
           <h6 class="video-title-small mb-1 text-dark">${this.truncateText(video.title, 45)}</h6>
         </a>` :
        `<h6 class="video-title-small mb-1">${this.truncateText(video.title, 45)}</h6>`
      
      videoElement.innerHTML = `
        <div class="d-flex">
          <div class="video-thumbnail-small me-3 position-relative">
            ${thumbnailHtml}
            <span class="position-absolute top-0 start-0 translate-middle badge rounded-pill bg-primary" style="font-size: 0.7rem;">
              ${index + 1}
            </span>
          </div>
          <div class="video-info flex-grow-1">
            ${linkHtml}
            <div class="video-stats-small">
              <small class="text-muted d-flex flex-wrap gap-2">
                <span><i class="fas fa-eye"></i> ${this.formatNumber(video.views)}</span>
                ${video.likes > 0 ? `<span><i class="fas fa-thumbs-up"></i> ${this.formatNumber(video.likes)}</span>` : ''}
                ${video.comments > 0 ? `<span><i class="fas fa-comment"></i> ${this.formatNumber(video.comments)}</span>` : ''}
              </small>
              <small class="text-muted d-block mt-1">
                <i class="fab fa-${video.platform}"></i> 
                ${video.platform.charAt(0).toUpperCase() + video.platform.slice(1)}
                ${video.source === 'analytics_api' ? '<span class="badge bg-success ms-1" style="font-size: 0.6rem;">Enhanced</span>' : ''}
              </small>
            </div>
          </div>
        </div>
      `
      
      topVideosContainer.appendChild(videoElement)
    })
    
    // Add "View All Videos" link
    const viewAllLink = document.createElement('div')
    viewAllLink.className = 'text-center mt-3'
    const platform = this.platformValue
    const linkUrl = platform ? `/videos?platform=${platform}` : '/videos'
    const linkText = platform ? `View All ${platform.charAt(0).toUpperCase() + platform.slice(1)} Videos` : 'View All Videos'
    
    viewAllLink.innerHTML = `
      <a href="${linkUrl}" class="btn btn-outline-primary btn-sm">
        <i class="fas fa-video me-1"></i>
        ${linkText}
      </a>
    `
    
    topVideosContainer.appendChild(viewAllLink)
  }

  updateSummaryTitle(summaryTitle) {
    // Update the summary title
    const summaryTitleElement = document.querySelector('[data-summary-title]')
    if (summaryTitleElement && summaryTitle) {
      summaryTitleElement.textContent = summaryTitle
    }
    
    // Update the chart title
    const chartTitleElement = document.querySelector('[data-chart-title]')
    if (chartTitleElement && summaryTitle) {
      const chartTitle = summaryTitle.replace(' Summary', '')
      chartTitleElement.textContent = chartTitle
    }
    
    // Update the top videos title
    const topVideosTitleElement = document.querySelector('[data-top-videos-title]')
    if (topVideosTitleElement && summaryTitle) {
      // Convert summary title to time window display
      const timeWindowDisplay = this.getTimeWindowDisplay(summaryTitle)
      topVideosTitleElement.textContent = timeWindowDisplay
    }
    
    // Update platform insights time displays
    this.updatePlatformInsightsTime(summaryTitle)
  }
  
  updatePlatformInsightsTime(summaryTitle) {
    if (!summaryTitle) return
    
    // Get the time window number
    const timeWindow = this.getTimeWindowNumber(summaryTitle)
    
    // Update Cross-Platform Analytics time
    const crossPlatformElement = document.querySelector('[data-cross-platform-time]')
    if (crossPlatformElement) {
      crossPlatformElement.textContent = timeWindow
    }
    
    // Update YouTube insights time
    const youtubeElement = document.querySelector('[data-youtube-time]')
    if (youtubeElement) {
      youtubeElement.textContent = timeWindow
    }
    
    // Update TikTok insights time
    const tiktokElement = document.querySelector('[data-tiktok-time]')
    if (tiktokElement) {
      tiktokElement.textContent = timeWindow
    }
  }
  
  getTimeWindowNumber(summaryTitle) {
    if (!summaryTitle) return '28'
    
    if (summaryTitle.includes('7 Days')) return '7'
    if (summaryTitle.includes('28 Days')) return '28'
    if (summaryTitle.includes('90 Days')) return '90'
    if (summaryTitle.includes('365 Days')) return '365'
    if (summaryTitle.includes('2025')) return '2025'
    if (summaryTitle.includes('2024')) return '2024'
    if (summaryTitle.includes('Custom')) return 'custom range'
    
    // Fallback
    return '28'
  }
  
  getTimeWindowDisplay(summaryTitle) {
    if (!summaryTitle) return '28 days'
    
    if (summaryTitle.includes('7 Days')) return '7 days'
    if (summaryTitle.includes('28 Days')) return '28 days'
    if (summaryTitle.includes('90 Days')) return '90 days'
    if (summaryTitle.includes('365 Days')) return '365 days'
    if (summaryTitle.includes('2025')) return '2025'
    if (summaryTitle.includes('2024')) return '2024'
    if (summaryTitle.includes('Custom')) return 'custom range'
    
    // Fallback
    return '28 days'
  }

  truncateText(text, length) {
    if (!text) return ''
    return text.length > length ? text.substring(0, length) + '...' : text
  }

  formatNumber(num) {
    if (!num) return '0'
    return num.toLocaleString()
  }

  animateNumber(element, newValue, isCurrency = false) {
    const currentValue = parseFloat(element.textContent.replace(/[^0-9.-]/g, '')) || 0
    const duration = 300 // Faster animation
    const steps = 20 // Fewer steps for smoother performance
    const increment = (newValue - currentValue) / steps
    let current = currentValue
    let step = 0

    const animate = () => {
      step++
      current += increment
      
      if (step >= steps) {
        current = newValue
      }
      
      if (isCurrency) {
        element.textContent = `$${current.toFixed(2)}`
      } else {
        element.textContent = Math.round(current).toLocaleString()
      }
      
      if (step < steps) {
        requestAnimationFrame(animate)
      }
    }
    
    animate()
  }

  showLoadingState() {
    // Add loading spinner to the selector button (lighter version)
    const originalText = this.selectedTarget.textContent
    this.selectedTarget.dataset.originalText = originalText
    this.selectedTarget.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Updating...'
    
    // Disable the button
    this.buttonTarget.disabled = true
    this.buttonTarget.style.opacity = '0.8'
    
    // Light loading effect on content
    document.querySelectorAll('.card-body').forEach(card => {
      card.style.opacity = '0.7'
      card.style.transition = 'opacity 0.2s ease'
    })
  }

  hideLoadingState() {
    // Restore original text
    const originalText = this.selectedTarget.dataset.originalText
    if (originalText) {
      this.selectedTarget.textContent = originalText
    }
    
    // Re-enable the button
    this.buttonTarget.disabled = false
    this.buttonTarget.style.opacity = '1'
    
    // Remove loading from content
    document.querySelectorAll('.card-body').forEach(card => {
      card.style.opacity = '1'
    })
  }

  showErrorState() {
    this.hideLoadingState()
    
    // Hide custom loading bar if showing (safely)
    try {
      if (window.loadingController && typeof window.loadingController.hideLoadingBar === 'function') {
        window.loadingController.hideLoadingBar()
      }
    } catch (e) {
      console.log('Loading controller not available:', e.message)
    }
    
    this.selectedTarget.innerHTML = '<i class="fas fa-exclamation-triangle me-2"></i>Error - Retry'
    this.selectedTarget.style.color = '#dc3545'
    
    setTimeout(() => {
      const originalText = this.selectedTarget.dataset.originalText
      if (originalText) {
        this.selectedTarget.textContent = originalText
        this.selectedTarget.style.color = ''
      }
    }, 3000)
  }

  updateActiveState(selectedItem) {
    // Remove active class from all items
    this.element.querySelectorAll('.time-selector-item').forEach(item => {
      item.classList.remove('active')
    })
    
    // Add active class to selected item
    selectedItem.classList.add('active')
  }

  updateDisplay() {
    const activeItem = this.element.querySelector('.time-selector-item.active')
    if (activeItem) {
      this.selectedTarget.textContent = activeItem.textContent.trim()
    }
  }

  formatDate(dateString) {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: date.getFullYear() !== new Date().getFullYear() ? 'numeric' : undefined
    })
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.closeDropdown()
    }
  }

  handleEscapeKey(event) {
    if (event.key === 'Escape') {
      this.closeDropdown()
      if (this.hasCustomModalTarget && this.customModalTarget.classList.contains('custom-modal-hidden') === false) {
        this.closeCustomModal()
      }
    }
  }

  // Mobile touch handling for better UX
  handleTouchStart(event) {
    this.touchStartTarget = event.target
  }

  handleTouchEnd(event) {
    // Only handle if the touch started and ended on the same element
    if (this.touchStartTarget === event.target) {
      this.handleOutsideClick(event)
    }
    this.touchStartTarget = null
  }

  initializeDropdown() {
    if (!this.hasDropdownTarget) {
      console.warn('Dropdown target not found, skipping initialization')
      return
    }

    console.log('Initializing time window dropdown...')

    // Clean up any existing Bootstrap dropdown instances
    try {
      const existingDropdown = bootstrap.Dropdown.getInstance(this.dropdownTarget)
      if (existingDropdown) {
        console.log('Disposing existing dropdown instance')
        existingDropdown.dispose()
      }
    } catch (e) {
      console.log('No existing dropdown to dispose')
    }

    // Reset dropdown state
    this.resetDropdownState()

    // Create new Bootstrap dropdown instance
    try {
      if (typeof bootstrap !== 'undefined' && bootstrap.Dropdown) {
        console.log('Creating new Bootstrap dropdown instance')
        this.dropdown = new bootstrap.Dropdown(this.dropdownTarget, {
          boundary: 'viewport',
          display: 'dynamic'
        })

        this.setupDropdownEventListeners()
        console.log('Dropdown initialization complete')
      } else {
        console.error('Bootstrap is not available')
        this.createFallbackDropdown()
      }
    } catch (error) {
      console.error('Error initializing dropdown:', error)
      this.createFallbackDropdown()
    }
  }

  resetDropdownState() {
    this.dropdownTarget.removeAttribute('disabled')
    this.dropdownTarget.style.pointerEvents = 'auto'
    this.dropdownTarget.style.opacity = '1'
    this.dropdownTarget.classList.remove('disabled')
    this.dropdownTarget.setAttribute('aria-expanded', 'false')
    
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove('show')
      this.menuTarget.style.display = ''
    }
  }

  setupDropdownEventListeners() {
    // Add click handler
    this.dropdownTarget.addEventListener('click', (e) => {
      console.log('Dropdown clicked')
      this.closeOtherDropdowns()
    })

    // Add Bootstrap dropdown events
    this.dropdownTarget.addEventListener('show.bs.dropdown', () => {
      console.log('Dropdown showing')
    })

    this.dropdownTarget.addEventListener('shown.bs.dropdown', () => {
      console.log('Dropdown shown')
    })

    this.dropdownTarget.addEventListener('hide.bs.dropdown', () => {
      console.log('Dropdown hiding')
    })

    this.dropdownTarget.addEventListener('hidden.bs.dropdown', () => {
      console.log('Dropdown hidden')
    })
  }

  closeOtherDropdowns() {
    document.querySelectorAll('.dropdown-menu.show').forEach(menu => {
      if (this.hasMenuTarget && menu !== this.menuTarget) {
        menu.classList.remove('show')
      }
    })
  }

  createFallbackDropdown() {
    console.log('Creating fallback dropdown functionality')
    
    this.dropdownTarget.addEventListener('click', (e) => {
      e.preventDefault()
      e.stopPropagation()
      
      if (!this.hasMenuTarget) return
      
      const isVisible = this.menuTarget.classList.contains('show')
      
      // Close other dropdowns
      this.closeOtherDropdowns()
      
      // Toggle this dropdown
      if (isVisible) {
        this.menuTarget.classList.remove('show')
      } else {
        this.menuTarget.classList.add('show')
      }
      
      console.log('Fallback dropdown toggled:', !isVisible)
    })

    // Close on outside click
    document.addEventListener('click', (e) => {
      if (this.hasMenuTarget && !this.element.contains(e.target)) {
        this.menuTarget.classList.remove('show')
      }
    })
  }

  setupCustomDatePicker() {
    if (!this.hasCustomRangeLinkTarget) return

    // Remove existing listeners by cloning
    const newCustomRangeLink = this.customRangeLinkTarget.cloneNode(true)
    this.customRangeLinkTarget.parentNode.replaceChild(newCustomRangeLink, this.customRangeLinkTarget)
    
    // Update our target reference
    this.customRangeLinkTarget = newCustomRangeLink

    this.customRangeLinkTarget.addEventListener('click', (e) => {
      e.preventDefault()
      e.stopPropagation()
      console.log('Custom range link clicked')
      
      try {
        this.showCustomDatePicker()
      } catch (error) {
        console.error('Error showing custom date picker:', error)
      }
    })
  }

  showCustomDatePicker() {
    // Create modal if it doesn't exist
    let modal = document.getElementById('customDateModal')
    if (!modal) {
      modal = this.createCustomDateModal()
      document.body.appendChild(modal)
    }

    // Show modal
    const bootstrapModal = new bootstrap.Modal(modal)
    bootstrapModal.show()
  }

  createCustomDateModal() {
    const modal = document.createElement('div')
    modal.className = 'modal fade'
    modal.id = 'customDateModal'
    modal.tabIndex = -1

    const today = new Date().toISOString().split('T')[0]
    const monthAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]

    modal.innerHTML = `
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              <i class="fas fa-calendar-alt me-2"></i>
              Custom Date Range
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <form id="customDateForm">
              <div class="row g-3">
                <div class="col-md-6">
                  <label for="startDate" class="form-label">Start Date</label>
                  <input type="date" class="form-control" id="startDate" value="${monthAgo}" max="${today}" required>
                </div>
                <div class="col-md-6">
                  <label for="endDate" class="form-label">End Date</label>
                  <input type="date" class="form-control" id="endDate" value="${today}" max="${today}" required>
                </div>
              </div>
              <div class="mt-3">
                <small class="text-muted">
                  <i class="fas fa-info-circle me-1"></i>
                  Select a date range up to 90 days for detailed analytics.
                </small>
              </div>
            </form>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary" onclick="applyCustomDateRange()">Apply Range</button>
          </div>
        </div>
      </div>
    `

    return modal
  }

  selectTimeWindow(event) {
    event.preventDefault()
    
    const selectedPeriod = event.currentTarget.dataset.period
    console.log('Time window selected:', selectedPeriod)
    
    // Update the current period
    this.currentPeriodValue = selectedPeriod
    
    // Update the display
    if (this.hasSelectedPeriodTarget) {
      this.selectedPeriodTarget.textContent = event.currentTarget.textContent.trim()
    }
    
    // Close the dropdown
    if (this.dropdown) {
      this.dropdown.hide()
    } else if (this.hasMenuTarget) {
      this.menuTarget.classList.remove('show')
    }
    
    // Trigger page reload with the new period
    const url = new URL(window.location)
    url.searchParams.set('period', selectedPeriod)
    window.location.href = url.toString()
  }

  cleanup() {
    // Clean up any Bootstrap instances
    if (this.dropdown) {
      try {
        this.dropdown.dispose()
      } catch (e) {
        console.log('Error disposing dropdown:', e)
      }
    }
  }
}

// Global function for custom date range (called from modal)
window.applyCustomDateRange = function() {
  const startDate = document.getElementById('startDate')?.value
  const endDate = document.getElementById('endDate')?.value
  
  if (!startDate || !endDate) {
    alert('Please select both start and end dates.')
    return
  }
  
  if (new Date(startDate) > new Date(endDate)) {
    alert('Start date must be before end date.')
    return
  }
  
  // Close the modal
  const modal = bootstrap.Modal.getInstance(document.getElementById('customDateModal'))
  if (modal) {
    modal.hide()
  }
  
  // Trigger the custom date range update
  const customPeriod = `${startDate}_to_${endDate}`
  
  // Find the time selector controller and update it
  const timeSelectorElement = document.querySelector('[data-controller*="time-selector"]')
  if (timeSelectorElement) {
    const controller = timeSelectorElement.stimulusController || 
                     timeSelectorElement.stimulus?.controllers?.find(c => c.identifier === 'time-selector')
    
    if (controller) {
      controller.updateAnalytics(customPeriod)
      
      // Update the display
      if (controller.hasSelectedPeriodTarget) {
        controller.selectedPeriodTarget.textContent = `${startDate} to ${endDate}`
      }
    }
  }
  
  console.log('Custom date range applied:', customPeriod)
} 