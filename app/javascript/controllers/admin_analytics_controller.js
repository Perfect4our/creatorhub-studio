import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["signupsChart", "topPagesChart", "conversionChart", "platformChart", 
                   "revenueChart", "retentionChart", "geographicChart", "subscriptionChart",
                   "dateFilter", "roleFilter", "platformFilter", "refreshButton", "exportButton"]
  
  static values = { 
    signupsData: Array,
    topPagesData: Array,
    conversionData: Array,
    platformData: Array,
    revenueData: Array,
    retentionData: Array,
    geographicData: Array,
    subscriptionData: Array,
    posthogEvents: Array,
    posthogConversion: Object
  }

  connect() {
    console.log("Admin Analytics Controller connected")
    
    // Initialize charts only if data is available
    this.initializeCharts()
    
    // Track page view
    this.trackAnalyticsView()
    
    // Set up auto-refresh
    this.setupAutoRefresh()
  }

  disconnect() {
    // Clean up charts and intervals
    this.destroyCharts()
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  }

  initializeCharts() {
    // Initialize charts only when data is available
    this.initializeSignupsChart()
    if (this.topPagesDataValue.length > 0) this.initializeTopPagesChart()
    if (this.conversionDataValue.length > 0) this.initializeConversionChart()
    if (this.platformDataValue.length > 0) this.initializePlatformChart()
    this.initializeRevenueChart()
    if (this.retentionDataValue.length > 0) this.initializeRetentionChart()
    if (this.geographicDataValue.length > 0) this.initializeGeographicChart()
    if (this.subscriptionDataValue.length > 0) this.initializeSubscriptionChart()
  }

  initializeSignupsChart() {
    if (!this.hasSignupsChartTarget || this.signupsDataValue.length === 0) return

    const ctx = this.signupsChartTarget.getContext('2d')
    
    this.signupsChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.signupsDataValue.map(d => d.label),
        datasets: [{
          label: 'Daily Signups',
          data: this.signupsDataValue.map(d => d.signups),
          borderColor: '#3B82F6',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          borderWidth: 3,
          fill: true,
          tension: 0.4,
          pointBackgroundColor: '#3B82F6',
          pointBorderColor: '#ffffff',
          pointBorderWidth: 2,
          pointRadius: 4,
          pointHoverRadius: 6
        }, {
          label: 'Cumulative Signups',
          data: this.signupsDataValue.map(d => d.cumulative),
          borderColor: '#10B981',
          backgroundColor: 'rgba(16, 185, 129, 0.05)',
          borderWidth: 2,
          fill: false,
          tension: 0.4,
          pointBackgroundColor: '#10B981',
          pointBorderColor: '#ffffff',
          pointBorderWidth: 2,
          pointRadius: 3,
          pointHoverRadius: 5,
          yAxisID: 'y1'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          legend: {
            display: true,
            position: 'top',
            labels: {
              usePointStyle: true,
              padding: 20
            }
          },
          tooltip: {
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            titleColor: '#fff',
            bodyColor: '#fff',
            borderColor: '#3B82F6',
            borderWidth: 1
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: '#6B7280'
            }
          },
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            beginAtZero: true,
            grid: {
              color: '#F3F4F6'
            },
            ticks: {
              color: '#6B7280'
            }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            beginAtZero: true,
            grid: {
              drawOnChartArea: false,
            },
            ticks: {
              color: '#6B7280'
            }
          }
        }
      }
    })
  }

  initializeTopPagesChart() {
    if (!this.hasTopPagesChartTarget || this.topPagesDataValue.length === 0) return

    const ctx = this.topPagesChartTarget.getContext('2d')
    
    this.topPagesChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: this.topPagesDataValue.map(d => d.page),
        datasets: [{
          label: 'Page Views',
          data: this.topPagesDataValue.map(d => d.views),
          backgroundColor: 'rgba(59, 130, 246, 0.8)',
          borderColor: '#3B82F6',
          borderWidth: 1,
          borderRadius: 4
        }, {
          label: 'Unique Users',
          data: this.topPagesDataValue.map(d => d.unique_users),
          backgroundColor: 'rgba(16, 185, 129, 0.8)',
          borderColor: '#10B981',
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: true,
            position: 'top'
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: '#6B7280',
              maxRotation: 45
            }
          },
          y: {
            beginAtZero: true,
            grid: {
              color: '#F3F4F6'
            },
            ticks: {
              color: '#6B7280'
            }
          }
        }
      }
    })
  }

  initializeConversionChart() {
    if (!this.hasConversionChartTarget || this.conversionDataValue.length === 0) return

    const ctx = this.conversionChartTarget.getContext('2d')
    
    this.conversionChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: this.conversionDataValue.map(d => d.stage),
        datasets: [{
          label: 'Users',
          data: this.conversionDataValue.map(d => d.count),
          backgroundColor: [
            'rgba(59, 130, 246, 0.8)',
            'rgba(16, 185, 129, 0.8)'
          ],
          borderColor: [
            '#3B82F6',
            '#10B981'
          ],
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              afterLabel: (context) => {
                const percentage = this.conversionDataValue[context.dataIndex].percentage
                return `${percentage}% of total`
              }
            }
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: '#6B7280'
            }
          },
          y: {
            beginAtZero: true,
            grid: {
              color: '#F3F4F6'
            },
            ticks: {
              color: '#6B7280'
            }
          }
        }
      }
    })
  }

  initializePlatformChart() {
    if (!this.hasPlatformChartTarget || this.platformDataValue.length === 0) return

    const ctx = this.platformChartTarget.getContext('2d')
    
    this.platformChart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: this.platformDataValue.map(d => d.platform),
        datasets: [{
          data: this.platformDataValue.map(d => d.count),
          backgroundColor: this.platformDataValue.map(d => d.color),
          borderColor: '#ffffff',
          borderWidth: 2,
          hoverBorderWidth: 3
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              padding: 20,
              usePointStyle: true
            }
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const total = this.platformDataValue.reduce((sum, d) => sum + d.count, 0)
                const percentage = ((context.parsed / total) * 100).toFixed(1)
                return `${context.label}: ${context.parsed} (${percentage}%)`
              }
            }
          }
        }
      }
    })
  }

  initializeRevenueChart() {
    if (!this.hasRevenueChartTarget || this.revenueDataValue.length === 0) return

    const ctx = this.revenueChartTarget.getContext('2d')
    
    this.revenueChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.revenueDataValue.map(d => d.label),
        datasets: [{
          label: 'Daily Revenue ($)',
          data: this.revenueDataValue.map(d => d.revenue),
          borderColor: '#10B981',
          backgroundColor: 'rgba(16, 185, 129, 0.1)',
          borderWidth: 3,
          fill: true,
          tension: 0.4,
          pointBackgroundColor: '#10B981',
          pointBorderColor: '#ffffff',
          pointBorderWidth: 2,
          pointRadius: 4,
          pointHoverRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                return `Revenue: $${context.parsed.y.toFixed(2)}`
              }
            }
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: '#6B7280'
            }
          },
          y: {
            beginAtZero: true,
            grid: {
              color: '#F3F4F6'
            },
            ticks: {
              color: '#6B7280',
              callback: function(value) {
                return '$' + value.toFixed(0)
              }
            }
          }
        }
      }
    })
  }

  initializeRetentionChart() {
    if (!this.hasRetentionChartTarget || this.retentionDataValue.length === 0) return

    const ctx = this.retentionChartTarget.getContext('2d')
    
    this.retentionChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: this.retentionDataValue.map(d => d.week),
        datasets: [{
          label: 'Initial Users',
          data: this.retentionDataValue.map(d => d.initial_users),
          backgroundColor: 'rgba(156, 163, 175, 0.6)',
          borderColor: '#9CA3AF',
          borderWidth: 1
        }, {
          label: 'Retained Users',
          data: this.retentionDataValue.map(d => d.retained_users),
          backgroundColor: 'rgba(59, 130, 246, 0.8)',
          borderColor: '#3B82F6',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: true,
            position: 'top'
          },
          tooltip: {
            callbacks: {
              afterBody: (context) => {
                const index = context[0].dataIndex
                const retentionRate = this.retentionDataValue[index].retention_rate
                return `Retention Rate: ${retentionRate}%`
              }
            }
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: '#6B7280'
            }
          },
          y: {
            beginAtZero: true,
            grid: {
              color: '#F3F4F6'
            },
            ticks: {
              color: '#6B7280'
            }
          }
        }
      }
    })
  }

  initializeGeographicChart() {
    if (!this.hasGeographicChartTarget || this.geographicDataValue.length === 0) return

    const ctx = this.geographicChartTarget.getContext('2d')
    
    this.geographicChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: this.geographicDataValue.map(d => `${d.flag} ${d.country}`),
        datasets: [{
          label: 'Users',
          data: this.geographicDataValue.map(d => d.users),
          backgroundColor: 'rgba(99, 102, 241, 0.8)',
          borderColor: '#6366F1',
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const percentage = this.geographicDataValue[context.dataIndex].percentage
                return `${context.parsed.x} users (${percentage}%)`
              }
            }
          }
        },
        scales: {
          x: {
            beginAtZero: true,
            grid: {
              color: '#F3F4F6'
            },
            ticks: {
              color: '#6B7280'
            }
          },
          y: {
            grid: {
              display: false
            },
            ticks: {
              color: '#6B7280'
            }
          }
        }
      }
    })
  }

  initializeSubscriptionChart() {
    if (!this.hasSubscriptionChartTarget || this.subscriptionDataValue.length === 0) return

    const ctx = this.subscriptionChartTarget.getContext('2d')
    
    this.subscriptionChart = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: this.subscriptionDataValue.map(d => d.status),
        datasets: [{
          data: this.subscriptionDataValue.map(d => d.count),
          backgroundColor: this.subscriptionDataValue.map(d => d.color),
          borderColor: '#ffffff',
          borderWidth: 2,
          hoverBorderWidth: 3
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              padding: 20,
              usePointStyle: true
            }
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const percentage = this.subscriptionDataValue[context.dataIndex].percentage
                return `${context.label}: ${context.parsed} users (${percentage}%)`
              }
            }
          }
        }
      }
    })
  }

  // Filter handling
  filterByDate() {
    const dateRange = this.dateFilterTarget.value
    this.trackFilterChange('date', dateRange)
    
    // Reload page with new date filter
    const url = new URL(window.location)
    url.searchParams.set('date_range', dateRange)
    window.location.href = url.toString()
  }

  filterByRole() {
    const role = this.roleFilterTarget.value
    this.trackFilterChange('role', role)
    
    const url = new URL(window.location)
    url.searchParams.set('role_filter', role)
    window.location.href = url.toString()
  }

  filterByPlatform() {
    const platform = this.platformFilterTarget.value
    this.trackFilterChange('platform', platform)
    
    const url = new URL(window.location)
    url.searchParams.set('platform_filter', platform)
    window.location.href = url.toString()
  }

  // Data refresh
  refreshData() {
    this.trackRefresh()
    location.reload()
  }

  exportData() {
    this.trackExport()
    
    // Create CSV export of current data
    const csvData = this.generateCSVData()
    const blob = new Blob([csvData], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `analytics-export-${new Date().toISOString().split('T')[0]}.csv`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
  }

  // Auto-refresh setup
  setupAutoRefresh() {
    // Auto-refresh every 5 minutes
    this.refreshInterval = setInterval(() => {
      this.updateLiveMetrics()
    }, 5 * 60 * 1000)
  }

  updateLiveMetrics() {
    // Update real-time metrics without full page reload
    fetch('/admin/analytics.json')
      .then(response => response.json())
      .then(data => {
        this.updateMetricCards(data)
        this.trackAutoRefresh()
      })
      .catch(error => {
        console.error('Auto-refresh failed:', error)
      })
  }

  updateMetricCards(data) {
    // Update the metric cards with new data
    // This would update the DOM elements with new values
    console.log('Updating metrics with:', data)
  }

  // Chart cleanup
  destroyCharts() {
    if (this.signupsChart) this.signupsChart.destroy()
    if (this.topPagesChart) this.topPagesChart.destroy()
    if (this.conversionChart) this.conversionChart.destroy()
    if (this.platformChart) this.platformChart.destroy()
    if (this.revenueChart) this.revenueChart.destroy()
    if (this.retentionChart) this.retentionChart.destroy()
    if (this.geographicChart) this.geographicChart.destroy()
    if (this.subscriptionChart) this.subscriptionChart.destroy()
  }

  // Utility methods
  generateCSVData() {
    const headers = ['Date', 'Signups', 'Revenue', 'Active Subscriptions']
    const rows = this.signupsDataValue.map((signup, index) => {
      const revenue = this.revenueDataValue[index]?.revenue || 0
      return `${signup.date},${signup.signups},${revenue},${signup.cumulative}`
    })
    
    return [headers.join(','), ...rows].join('\n')
  }

  // PostHog Analytics Tracking
  trackAnalyticsView() {
    if (window.posthog) {
      posthog.capture('admin_analytics_dashboard_viewed', {
        page_location: 'admin_analytics_dashboard',
        user_role: 'admin',
        has_data: this.signupsDataValue.length > 0,
        platform_count: this.platformDataValue.length,
        data_points: this.signupsDataValue.length
      })
    }
  }

  trackFilterChange(filterType, value) {
    if (window.posthog) {
      posthog.capture('admin_analytics_filter_changed', {
        filter_type: filterType,
        filter_value: value,
        page_location: 'admin_analytics_dashboard'
      })
    }
  }

  trackRefresh() {
    if (window.posthog) {
      posthog.capture('admin_analytics_refreshed', {
        refresh_type: 'manual',
        page_location: 'admin_analytics_dashboard'
      })
    }
  }

  trackAutoRefresh() {
    if (window.posthog) {
      posthog.capture('admin_analytics_auto_refreshed', {
        refresh_type: 'automatic',
        page_location: 'admin_analytics_dashboard'
      })
    }
  }

  trackExport() {
    if (window.posthog) {
      posthog.capture('admin_analytics_exported', {
        export_format: 'csv',
        data_range: this.dateFilterTarget?.value || '30',
        page_location: 'admin_analytics_dashboard'
      })
    }
  }
} 