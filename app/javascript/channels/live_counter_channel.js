import consumer from "channels/consumer"

document.addEventListener('DOMContentLoaded', () => {
  const userId = document.querySelector('meta[name="user-id"]')?.content;
  
  // Initialize connection status indicator
  const statusIndicator = document.getElementById('connection-status-indicator');
  if (statusIndicator) {
    statusIndicator.classList.add('connected');
    
    // Set initial tooltip text
    const tooltipText = statusIndicator.parentElement.querySelector('.connection-tooltip-content');
    if (tooltipText) {
      tooltipText.textContent = 'Real-time updates connected';
    }
  }
  
  if (userId) {
    consumer.subscriptions.create({ channel: "LiveCounterChannel", user_id: userId }, {
      connected() {
        // Called when the subscription is ready for use on the server
        console.log("Connected to LiveCounterChannel");
        
        // Show connected status indicator
        this.updateConnectionStatus('connected');
      },

      disconnected() {
        // Called when the subscription has been terminated by the server
        console.log("Disconnected from LiveCounterChannel");
        
        // Show disconnected status indicator
        this.updateConnectionStatus('disconnected');
      },

      received(data) {
        // Called when there's incoming data on the websocket for this channel
        console.log("Received data:", data);
        
        // Handle real-time status updates
        this.handleRealtimeStatus(data);
        
        // If real-time is disabled, don't update the UI
        if (data.realtime_disabled) {
          return;
        }
        
        // Animate the connection indicator to show activity
        this.updateConnectionStatus('active');
        
        // Update total stats with animation
        this.updateTotalStats(data);
        
        // Update platform-specific stats with animation
        this.updatePlatformStats(data);
        
        // Update charts
        this.updateCharts(data);
      },
      
      updateConnectionStatus(status) {
        const statusIndicator = document.getElementById('connection-status-indicator');
        if (!statusIndicator) return;
        
        // Remove all status classes
        statusIndicator.classList.remove('connected', 'disconnected', 'active');
        
        // Add appropriate class
        statusIndicator.classList.add(status);
        
        // Update tooltip text
        const tooltipText = statusIndicator.parentElement.querySelector('.connection-tooltip-content');
        if (tooltipText) {
          switch (status) {
            case 'connected':
              tooltipText.textContent = 'Real-time updates connected';
              break;
            case 'disconnected':
              tooltipText.textContent = 'Real-time updates disconnected';
              break;
            case 'active':
              tooltipText.textContent = 'Receiving real-time data';
              // Reset to 'connected' after a short delay
              setTimeout(() => {
                statusIndicator.classList.remove('active');
                statusIndicator.classList.add('connected');
              }, 1000);
              break;
          }
        }
      },
      
      updateTotalStats(data) {
        // Update follower count with animation
        if (data.combined_followers) {
          const followerElement = document.getElementById('total-followers');
          if (followerElement) {
            this.animateCounterUpdate(followerElement, data.combined_followers);
          }
        }
        
        // Update views count with animation
        if (data.combined_views) {
          const viewsElement = document.getElementById('total-views');
          if (viewsElement) {
            this.animateCounterUpdate(viewsElement, data.combined_views);
          }
        }
        
        // Update revenue with animation
        if (data.combined_revenue) {
          const revenueElement = document.getElementById('total-revenue');
          if (revenueElement) {
            const currentValue = parseFloat(revenueElement.textContent.replace(/[^0-9.-]+/g, ''));
            const newValue = data.combined_revenue;
            
            this.animateCounterUpdate(revenueElement, newValue, {
              prefix: '$',
              startValue: currentValue
            });
          }
        }
      },
      
      updatePlatformStats(data) {
        // Update platform-specific stats
        if (data.platform_stats) {
          Object.entries(data.platform_stats).forEach(([platform, stats]) => {
            // Update platform views
            const viewsElement = document.getElementById(`${platform}-views`);
            if (viewsElement && stats.views) {
              this.animateCounterUpdate(viewsElement, stats.views);
            }
            
            // Update platform followers
            const followersElement = document.getElementById(`${platform}-followers`);
            if (followersElement && stats.followers) {
              this.animateCounterUpdate(followersElement, stats.followers);
            }
            
            // Update platform revenue
            const revenueElement = document.getElementById(`${platform}-revenue`);
            if (revenueElement && stats.revenue) {
              const currentValue = parseFloat(revenueElement.textContent.replace(/[^0-9.-]+/g, ''));
              this.animateCounterUpdate(revenueElement, stats.revenue, {
                prefix: '$',
                startValue: currentValue
              });
            }
          });
        }
      },
      
      updateCharts(data) {
        // Update views chart
        if (data.recent_views_48hr) {
          const chartElement = document.getElementById('performanceChart');
          if (chartElement && window.viewsChart) {
            // Update chart data
            const chart = window.viewsChart;
            
            // Update labels if provided
            if (data.chart_labels) {
              chart.data.labels = data.chart_labels;
            }
            
            // Update datasets with animation
            Object.entries(data.recent_views_48hr).forEach(([platform, views]) => {
              const datasetIndex = chart.data.datasets.findIndex(ds => ds.label === `${platform.charAt(0).toUpperCase() + platform.slice(1)} Views`);
              
              if (datasetIndex !== -1) {
                chart.data.datasets[datasetIndex].data = views;
              }
            });
            
            chart.update('active');
          }
        }
        
        // Update platform-specific charts if they exist
        if (data.realtime_platforms && data.recent_views_48hr) {
          data.realtime_platforms.forEach(platform => {
            const platformChartElement = document.getElementById(`${platform}Chart`);
            if (platformChartElement) {
              // Get chart instance using Chart.js API
              const chart = Chart.getChart(platformChartElement.id);
              if (chart) {
                const views = data.recent_views_48hr[platform];
                
                if (views && chart.data.datasets[0]) {
                  // Show loading overlay
                  const chartContainer = platformChartElement.closest('.chart-container');
                  const loadingOverlay = chartContainer.querySelector('.chart-loading-overlay');
                  
                  if (loadingOverlay) {
                    loadingOverlay.classList.add('show');
                  }
                  
                  // Update chart data
                  chart.data.datasets[0].data = views;
                  
                  // Update chart with animation
                  chart.update('active');
                  
                  // Hide loading overlay after animation completes
                  setTimeout(() => {
                    if (loadingOverlay) {
                      loadingOverlay.classList.remove('show');
                    }
                  }, 1000);
                }
              }
            }
          });
        }
      },
      
      animateCounterUpdate(element, newValue, options = {}) {
        // Get current value
        const currentText = element.textContent;
        const currentValue = parseInt(currentText.replace(/[^0-9]/g, '')) || 0;
        const startValue = options.startValue !== undefined ? options.startValue : currentValue;
        const prefix = options.prefix || '';
        
        // Add highlight class
        element.classList.add('highlight-update');
        
        // Animate counter
        const duration = 1000;
        const startTime = performance.now();
        
        const updateCounter = (timestamp) => {
          const elapsed = timestamp - startTime;
          const progress = Math.min(elapsed / duration, 1);
          
          // Use easeOutQuad easing function
          const easeProgress = 1 - (1 - progress) * (1 - progress);
          
          // Calculate current count
          const currentCount = Math.round(startValue + (newValue - startValue) * easeProgress);
          
          // Format with commas
          element.textContent = prefix + new Intl.NumberFormat().format(currentCount);
          
          // Continue animation if not complete
          if (progress < 1) {
            requestAnimationFrame(updateCounter);
          } else {
            // Remove highlight class after animation
            setTimeout(() => element.classList.remove('highlight-update'), 1000);
          }
        };
        
        requestAnimationFrame(updateCounter);
      },
      
      handleRealtimeStatus(data) {
        const statusContainer = document.getElementById('realtime-status-container');
        if (!statusContainer) return;
        
        if (data.realtime_disabled) {
          // Create and show the disabled banner with platform-specific info if available
          let platformSpecific = '';
          if (data.platform) {
            platformSpecific = `data-platform="${data.platform}"`;
          }
          
          statusContainer.innerHTML = `
            <div class="realtime-status-banner realtime-disabled" id="realtime-disabled-banner" ${platformSpecific}>
              <div class="realtime-status-icon">
                <i class="fas fa-exclamation-circle"></i>
              </div>
              <div class="realtime-status-message">
                <strong>Real-time updates are disabled</strong>
                <span>${data.message || "Real-time updates are currently disabled for all platforms."}</span>
              </div>
              <div class="d-flex align-items-center">
                ${data.platform ? 
                  `<a href="/settings?platform=${data.platform}" class="realtime-status-action">
                    <i class="fas fa-toggle-on me-1"></i> Enable for ${data.platform.charAt(0).toUpperCase() + data.platform.slice(1)}
                  </a>` : 
                  `<a href="/settings" class="realtime-status-action">
                    <i class="fas fa-toggle-on me-1"></i> Enable All
                  </a>`
                }
                <button class="btn btn-link text-muted ms-2 p-0" id="dismissDisabledBanner" aria-label="Dismiss">
                  <i class="fas fa-times"></i>
                </button>
              </div>
            </div>
          `;
          
          // Add event listener for dismiss button
          document.getElementById('dismissDisabledBanner')?.addEventListener('click', () => {
            const banner = document.getElementById('realtime-disabled-banner');
            if (banner) {
              banner.style.height = banner.offsetHeight + 'px';
              setTimeout(() => {
                banner.style.height = '0';
                banner.style.opacity = '0';
                banner.style.marginBottom = '0';
                banner.style.padding = '0';
              }, 10);
              setTimeout(() => {
                banner.style.display = 'none';
              }, 300);
            }
          });
        } else if (data.rate_limited) {
          // Create and show the rate limited banner
          statusContainer.innerHTML = `
            <div class="realtime-status-banner realtime-rate-limited" id="realtime-rate-limited-banner">
              <div class="realtime-status-icon">
                <i class="fas fa-exclamation-triangle"></i>
              </div>
              <div class="realtime-status-message">
                <strong>API rate limit reached</strong>
                <span>${data.message || "Real-time updates are temporarily paused due to API rate limits."}</span>
                <small class="d-block mt-1">Will resume automatically in <span id="rate-limit-countdown">5:00</span></small>
              </div>
              <div class="d-flex align-items-center">
                <div class="tooltip-wrapper">
                  <button class="realtime-status-action" id="refreshRateLimitStatus">
                    <i class="fas fa-sync-alt me-1"></i> Check Status
                  </button>
                  <span class="tooltip-content">Check if rate limit has expired</span>
                </div>
                <button class="btn btn-link text-muted ms-2 p-0" id="dismissRateLimitBanner" aria-label="Dismiss">
                  <i class="fas fa-times"></i>
                </button>
              </div>
            </div>
          `;
          
          // Add event listener for dismiss button
          document.getElementById('dismissRateLimitBanner')?.addEventListener('click', () => {
            const banner = document.getElementById('realtime-rate-limited-banner');
            if (banner) {
              banner.style.height = banner.offsetHeight + 'px';
              setTimeout(() => {
                banner.style.height = '0';
                banner.style.opacity = '0';
                banner.style.marginBottom = '0';
                banner.style.padding = '0';
              }, 10);
              setTimeout(() => {
                banner.style.display = 'none';
              }, 300);
            }
          });
          
          // Initialize countdown timer
          const countdownElement = document.getElementById('rate-limit-countdown');
          if (countdownElement) {
            let minutes = 5;
            let seconds = 0;
            
            const updateCountdown = () => {
              countdownElement.textContent = `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
              
              if (minutes === 0 && seconds === 0) {
                clearInterval(countdownInterval);
                
                // Add refresh button animation
                const refreshBtn = document.getElementById('refreshRateLimitStatus');
                if (refreshBtn) {
                  refreshBtn.classList.add('highlight-update');
                  refreshBtn.innerHTML = '<i class="fas fa-check-circle me-1"></i> Try Again';
                }
                
                return;
              }
              
              if (seconds === 0) {
                minutes--;
                seconds = 59;
              } else {
                seconds--;
              }
            };
            
            const countdownInterval = setInterval(updateCountdown, 1000);
          }
          
          // Add event listener for refresh button
          document.getElementById('refreshRateLimitStatus')?.addEventListener('click', function() {
            this.disabled = true;
            this.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i> Checking...';
            
            // Simulate API check (would be replaced with actual AJAX call)
            setTimeout(() => {
              this.disabled = false;
              
              // Randomly determine if rate limit is still active for demo purposes
              const stillRateLimited = Math.random() > 0.5;
              
              if (stillRateLimited) {
                this.innerHTML = '<i class="fas fa-sync-alt me-1"></i> Check Status';
                // Show notification that we're still rate limited
                const notificationController = document.querySelector('[data-controller="notification"]')?.__stimulusController;
                if (notificationController) {
                  notificationController.warning('Still rate limited. Please try again later.');
                }
              } else {
                this.innerHTML = '<i class="fas fa-check-circle me-1"></i> Resolved!';
                
                // Hide banner after a short delay
                setTimeout(() => {
                  const banner = document.getElementById('realtime-rate-limited-banner');
                  if (banner) {
                    banner.style.height = banner.offsetHeight + 'px';
                    setTimeout(() => {
                      banner.style.height = '0';
                      banner.style.opacity = '0';
                      banner.style.marginBottom = '0';
                      banner.style.padding = '0';
                    }, 10);
                    setTimeout(() => {
                      banner.style.display = 'none';
                    }, 300);
                  }
                }, 1000);
              }
            }, 1500);
          });
        } else if (data.realtime_enabled) {
          // Clear any existing banners
          statusContainer.innerHTML = '';
        }
      }
    });
  }
});
