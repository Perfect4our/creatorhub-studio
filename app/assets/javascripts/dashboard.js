// Dashboard JavaScript - CSP Compliant
// This file handles dashboard-specific functionality without inline scripts

document.addEventListener('DOMContentLoaded', function() {
  // Set dynamic widths for progress bars and other elements
  setDynamicWidths();
  
  // Initialize dashboard charts if they exist
  initializeDashboardCharts();
  
  // Handle any dashboard-specific interactions
  initializeDashboardInteractions();
});

// Function to set dynamic widths for progress bars and other elements
function setDynamicWidths() {
  try {
    // Handle progress bars with data-width attributes
    document.querySelectorAll('[data-width]').forEach(element => {
      const width = element.getAttribute('data-width');
      if (width && !isNaN(parseFloat(width))) {
        element.style.width = width + '%';
      }
    });
    
    // Handle custom width elements
    document.querySelectorAll('[data-custom-width]').forEach(element => {
      const width = element.getAttribute('data-custom-width');
      if (width) {
        element.style.width = width;
      }
    });
    
    // Handle height elements
    document.querySelectorAll('[data-height]').forEach(element => {
      const height = element.getAttribute('data-height');
      if (height && !isNaN(parseFloat(height))) {
        element.style.height = height + 'px';
      }
    });
  } catch (error) {
    console.log('Error setting dynamic widths:', error);
  }
}

// Function to initialize dashboard charts
function initializeDashboardCharts() {
  try {
    // Check if Chart.js is available
    if (typeof Chart !== 'undefined') {
      // Initialize any charts that need to be created
      const chartElements = document.querySelectorAll('[data-chart-type]');
      
      chartElements.forEach(element => {
        const chartType = element.getAttribute('data-chart-type');
        const chartData = element.getAttribute('data-chart-data');
        
        if (chartType && chartData) {
          try {
            const data = JSON.parse(chartData);
            new Chart(element, {
              type: chartType,
              data: data,
              options: {
                responsive: true,
                maintainAspectRatio: false
              }
            });
          } catch (parseError) {
            console.log('Error parsing chart data:', parseError);
          }
        }
      });
    }
  } catch (error) {
    console.log('Error initializing dashboard charts:', error);
  }
}

// Function to initialize dashboard interactions
function initializeDashboardInteractions() {
  try {
    // Handle platform tab switching
    const platformTabs = document.querySelectorAll('[data-platform-tab]');
    platformTabs.forEach(tab => {
      tab.addEventListener('click', function(e) {
        e.preventDefault();
        
        const targetPlatform = this.getAttribute('data-platform-tab');
        const targetContent = document.querySelector(`[data-platform-content="${targetPlatform}"]`);
        
        if (targetContent) {
          // Hide all platform content
          document.querySelectorAll('[data-platform-content]').forEach(content => {
            content.style.display = 'none';
          });
          
          // Remove active class from all tabs
          document.querySelectorAll('[data-platform-tab]').forEach(tab => {
            tab.classList.remove('active');
          });
          
          // Show target content and activate tab
          targetContent.style.display = 'block';
          this.classList.add('active');
        }
      });
    });
    
    // Handle time range selector
    const timeRangeButtons = document.querySelectorAll('[data-time-range]');
    timeRangeButtons.forEach(button => {
      button.addEventListener('click', function(e) {
        e.preventDefault();
        
        const timeRange = this.getAttribute('data-time-range');
        
        // Remove active class from all time range buttons
        document.querySelectorAll('[data-time-range]').forEach(btn => {
          btn.classList.remove('active');
        });
        
        // Add active class to clicked button
        this.classList.add('active');
        
        // Update any elements that depend on time range
        updateTimeRangeDependentElements(timeRange);
      });
    });
    
    // Handle custom date range modal
    const customDateButton = document.querySelector('[data-action="show-custom-date-modal"]');
    if (customDateButton) {
      customDateButton.addEventListener('click', function(e) {
        e.preventDefault();
        
        const modal = document.getElementById('customDateModal');
        if (modal) {
          // Show modal using Bootstrap if available
          if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const bsModal = new bootstrap.Modal(modal);
            bsModal.show();
          } else {
            modal.style.display = 'block';
            modal.classList.add('show');
          }
        }
      });
    }
    
  } catch (error) {
    console.log('Error initializing dashboard interactions:', error);
  }
}

// Function to update elements that depend on time range
function updateTimeRangeDependentElements(timeRange) {
  try {
    // Update any elements that show time range information
    const timeRangeDisplays = document.querySelectorAll('[data-time-range-display]');
    timeRangeDisplays.forEach(element => {
      element.textContent = timeRange;
    });
    
    // Trigger any custom events for time range changes
    const event = new CustomEvent('timeRangeChanged', {
      detail: { timeRange: timeRange }
    });
    document.dispatchEvent(event);
  } catch (error) {
    console.log('Error updating time range elements:', error);
  }
}

// Export functions for global access if needed
window.dashboardUtils = {
  setDynamicWidths: setDynamicWidths,
  initializeDashboardCharts: initializeDashboardCharts,
  initializeDashboardInteractions: initializeDashboardInteractions,
  updateTimeRangeDependentElements: updateTimeRangeDependentElements
};

// Re-initialize on Turbo navigation
document.addEventListener('turbo:load', function() {
  setDynamicWidths();
  initializeDashboardCharts();
  initializeDashboardInteractions();
}); 