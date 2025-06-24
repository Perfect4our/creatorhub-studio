import { Controller } from "@hotwired/stimulus"
import { Chart } from "chart.js/auto"

export default class extends Controller {
  static targets = ["performanceChart", "engagementChart", "audienceChart", "viewsCount", "likesCount", "commentsCount", "sharesCount"]

  connect() {
    if (this.hasPerformanceChartTarget) {
      this.initPerformanceChart()
    }
    
    if (this.hasEngagementChartTarget) {
      this.initEngagementChart()
    }
    
    if (this.hasAudienceChartTarget) {
      this.initAudienceChart()
    }
  }

  initPerformanceChart() {
    const ctx = this.performanceChartTarget.getContext('2d')
    
    // Generate dates for x-axis (last 30 days)
    const dates = this.generateDates(30)
    
    // Generate random data
    const viewsData = this.generateRandomTrendData(30, 1000, 300, 10)
    
    this.performanceChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: dates,
        datasets: [{
          label: 'Views',
          data: viewsData,
          borderColor: 'rgba(255, 99, 132, 1)',
          backgroundColor: 'rgba(255, 99, 132, 0.2)',
          tension: 0.4,
          fill: true
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
            display: false
          },
          tooltip: {
            mode: 'index',
            intersect: false
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            }
          },
          y: {
            beginAtZero: true,
            grid: {
              borderDash: [2, 2]
            }
          }
        }
      }
    })
  }

  initEngagementChart() {
    const ctx = this.engagementChartTarget.getContext('2d')
    
    this.engagementChart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Likes', 'Comments', 'Shares', 'Saves'],
        datasets: [{
          data: [65, 15, 12, 8],
          backgroundColor: [
            'rgba(255, 99, 132, 0.8)',
            'rgba(54, 162, 235, 0.8)',
            'rgba(255, 206, 86, 0.8)',
            'rgba(75, 192, 192, 0.8)'
          ],
          borderColor: [
            'rgba(255, 99, 132, 1)',
            'rgba(54, 162, 235, 1)',
            'rgba(255, 206, 86, 1)',
            'rgba(75, 192, 192, 1)'
          ],
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom'
          }
        }
      }
    })
  }

  initAudienceChart() {
    const ctx = this.audienceChartTarget.getContext('2d')
    
    this.audienceChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['13-17', '18-24', '25-34', '35-44', '45-54', '55+'],
        datasets: [{
          label: 'Age Distribution',
          data: [5, 35, 25, 20, 10, 5],
          backgroundColor: 'rgba(54, 162, 235, 0.8)',
          borderColor: 'rgba(54, 162, 235, 1)',
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
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            }
          },
          y: {
            beginAtZero: true,
            grid: {
              borderDash: [2, 2]
            },
            ticks: {
              callback: function(value) {
                return value + '%'
              }
            }
          }
        }
      }
    })
  }

  // Generate dates for x-axis
  generateDates(days) {
    const dates = []
    for (let i = days; i >= 0; i--) {
      const date = new Date()
      date.setDate(date.getDate() - i)
      dates.push(date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }))
    }
    return dates
  }

  // Generate random data with trend
  generateRandomTrendData(days, startValue, volatility, trend) {
    const data = []
    let currentValue = startValue
    
    for (let i = 0; i <= days; i++) {
      data.push(Math.floor(currentValue))
      // Add random volatility and trend
      const change = (Math.random() * 2 - 1) * volatility + trend
      currentValue = Math.max(0, currentValue + change)
    }
    
    return data
  }

  // Update view count animation
  updateCount(target, newValue, duration = 1000) {
    const element = this[`${target}CountTarget`]
    if (!element) return
    
    const startValue = parseInt(element.textContent.replace(/,/g, ''))
    const startTime = performance.now()
    
    const updateAnimation = (currentTime) => {
      const elapsedTime = currentTime - startTime
      const progress = Math.min(elapsedTime / duration, 1)
      
      const currentValue = Math.floor(startValue + (newValue - startValue) * progress)
      element.textContent = new Intl.NumberFormat().format(currentValue)
      
      if (progress < 1) {
        requestAnimationFrame(updateAnimation)
      }
    }
    
    requestAnimationFrame(updateAnimation)
  }
}
