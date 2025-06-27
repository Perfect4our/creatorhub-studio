// Chart initialization and management
function initializePerformanceChart(chartData = {}) {
  document.addEventListener('DOMContentLoaded', function() {
    // Performance chart
    try {
      const ctx = document.getElementById('performanceChart')?.getContext('2d');
      if (!ctx) {
        console.warn('Performance chart canvas not found');
        return;
      }
    
      // Prepare datasets from all platforms
      const datasets = [];
      const colors = {
        tiktok: { border: 'rgba(238, 29, 82, 1)', background: 'rgba(238, 29, 82, 0.2)' },
        youtube: { border: 'rgba(255, 0, 0, 1)', background: 'rgba(255, 0, 0, 0.2)' },
        instagram: { border: 'rgba(131, 58, 180, 1)', background: 'rgba(131, 58, 180, 0.2)' },
        twitter: { border: 'rgba(29, 161, 242, 1)', background: 'rgba(29, 161, 242, 0.2)' },
        facebook: { border: 'rgba(66, 103, 178, 1)', background: 'rgba(66, 103, 178, 0.2)' },
        linkedin: { border: 'rgba(0, 119, 181, 1)', background: 'rgba(0, 119, 181, 0.2)' },
        twitch: { border: 'rgba(100, 65, 165, 1)', background: 'rgba(100, 65, 165, 0.2)' }
      };
      
      if (chartData && Object.keys(chartData).length > 0) {
        // Combine all dates from all platforms
        const allDates = [];
        Object.values(chartData).forEach(data => {
          if (data.dates && data.dates.length > 0) {
            allDates.push(...data.dates);
          }
        });
        
        // Get unique dates and sort them
        const uniqueDates = [...new Set(allDates)].sort();
        
        // Create view datasets for each platform
        Object.entries(chartData).forEach(([platform, data]) => {
          if (data.views && data.views.length > 0 && data.dates && data.dates.length > 0) {
            // Map data to the unique dates array (fill gaps with null)
            const viewData = uniqueDates.map(date => {
              const index = data.dates.indexOf(date);
              return index !== -1 ? data.views[index] : null;
            });
            
            datasets.push({
              label: platform.charAt(0).toUpperCase() + platform.slice(1) + ' Views',
              data: viewData,
              borderColor: colors[platform]?.border || 'rgba(75, 192, 192, 1)',
              backgroundColor: colors[platform]?.background || 'rgba(75, 192, 192, 0.2)',
              tension: 0.4,
              fill: true
            });
          }
        });
        
        const chart = new Chart(ctx, {
          type: 'line',
          data: {
            labels: uniqueDates,
            datasets: datasets
          },
          options: {
            responsive: true,
            interaction: {
              mode: 'index',
              intersect: false,
            },
            scales: {
              y: {
                beginAtZero: true,
                title: {
                  display: true,
                  text: 'Views'
                }
              }
            }
          }
        });
      } else {
        // No data available
        const chart = new Chart(ctx, {
          type: 'line',
          data: {
            labels: [],
            datasets: []
          },
          options: {
            responsive: true
          }
        });
      }
      
    } catch (error) {
      console.error('Error initializing performance chart:', error);
      // Display a fallback message
      const chartContainer = document.querySelector('.chart-container');
      if (chartContainer) {
        chartContainer.innerHTML = '<div class="text-center text-muted py-4"><i class="fas fa-chart-line fa-2x mb-2"></i><br>Chart temporarily unavailable</div>';
      }
    }
    
    // Period buttons
    document.querySelectorAll('[data-period]').forEach(button => {
      button.addEventListener('click', function() {
        document.querySelectorAll('[data-period]').forEach(btn => btn.classList.remove('active'));
        this.classList.add('active');
        
        const period = this.getAttribute('data-period');
        // In a real app, this would fetch data for the selected period
        // For now, we'll just log it
        console.log('Selected period:', period);
      });
    });
    
    // Platform row click
    document.querySelectorAll('.platform-row').forEach(row => {
      row.addEventListener('click', function() {
        const platform = this.getAttribute('data-platform');
        // In a real app, this would navigate to platform-specific details
        console.log('Selected platform:', platform);
      });
    });
  });
}

// Global function for reinitialization after Turbo navigation
window.initializeDashboardCharts = function(chartData) {
  initializePerformanceChart(chartData);
};

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { initializePerformanceChart };
} 