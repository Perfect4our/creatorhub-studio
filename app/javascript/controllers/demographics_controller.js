import { Controller } from "@hotwired/stimulus"
import { Chart } from "chart.js/auto"
import * as d3 from "d3"

export default class extends Controller {
  static targets = ["ageChart", "genderChart", "locationChart", "heatmap"]

  connect() {
    if (this.hasAgeChartTarget) {
      this.initAgeChart()
    }
    
    if (this.hasGenderChartTarget) {
      this.initGenderChart()
    }
    
    if (this.hasLocationChartTarget) {
      this.initLocationChart()
    }
    
    if (this.hasHeatmapTarget) {
      this.initHeatmap()
    }
  }

  initAgeChart() {
    const ctx = this.ageChartTarget.getContext('2d')
    
    this.ageChart = new Chart(ctx, {
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

  initGenderChart() {
    const ctx = this.genderChartTarget.getContext('2d')
    
    this.genderChart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Female', 'Male', 'Other'],
        datasets: [{
          data: [65, 30, 5],
          backgroundColor: [
            'rgba(255, 99, 132, 0.8)',
            'rgba(54, 162, 235, 0.8)',
            'rgba(75, 192, 192, 0.8)'
          ],
          borderColor: [
            'rgba(255, 99, 132, 1)',
            'rgba(54, 162, 235, 1)',
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

  initLocationChart() {
    const ctx = this.locationChartTarget.getContext('2d')
    
    this.locationChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['USA', 'UK', 'Canada', 'Australia', 'Germany', 'Other'],
        datasets: [{
          label: 'Audience Location',
          data: [40, 15, 10, 8, 7, 20],
          backgroundColor: 'rgba(153, 102, 255, 0.8)',
          borderColor: 'rgba(153, 102, 255, 1)',
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        indexAxis: 'y',
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          x: {
            beginAtZero: true,
            grid: {
              borderDash: [2, 2]
            },
            ticks: {
              callback: function(value) {
                return value + '%'
              }
            }
          },
          y: {
            grid: {
              display: false
            }
          }
        }
      }
    })
  }

  initHeatmap() {
    const margin = { top: 20, right: 30, bottom: 30, left: 40 }
    const width = this.heatmapTarget.clientWidth - margin.left - margin.right
    const height = 300 - margin.top - margin.bottom
    
    // Clear any existing SVG
    d3.select(this.heatmapTarget).selectAll("svg").remove()
    
    // Create SVG
    const svg = d3.select(this.heatmapTarget)
      .append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", `translate(${margin.left},${margin.top})`)
    
    // Days of week
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    
    // Hours of day
    const hours = Array.from({ length: 24 }, (_, i) => i)
    
    // Generate random data
    const data = []
    days.forEach(day => {
      hours.forEach(hour => {
        data.push({
          day: day,
          hour: hour,
          value: Math.random()
        })
      })
    })
    
    // X scale
    const x = d3.scaleBand()
      .domain(hours.map(h => h))
      .range([0, width])
      .padding(0.05)
    
    // Y scale
    const y = d3.scaleBand()
      .domain(days)
      .range([0, height])
      .padding(0.05)
    
    // Color scale
    const color = d3.scaleSequential()
      .interpolator(d3.interpolateInferno)
      .domain([0, 1])
    
    // Create heatmap cells
    svg.selectAll()
      .data(data)
      .enter()
      .append("rect")
      .attr("x", d => x(d.hour))
      .attr("y", d => y(d.day))
      .attr("width", x.bandwidth())
      .attr("height", y.bandwidth())
      .attr("class", "heatmap-cell")
      .style("fill", d => color(d.value))
      .on("mouseover", function(event, d) {
        // Create tooltip
        const tooltip = document.createElement('div')
        tooltip.className = 'heatmap-tooltip'
        tooltip.innerHTML = `${d.day} ${d.hour}:00 - ${d.hour + 1}:00<br>Engagement: ${Math.round(d.value * 100)}%`
        
        // Position tooltip
        tooltip.style.left = `${event.pageX}px`
        tooltip.style.top = `${event.pageY - 40}px`
        
        // Add to document
        document.body.appendChild(tooltip)
        
        // Store reference to tooltip
        this.tooltip = tooltip
      })
      .on("mousemove", function(event) {
        if (this.tooltip) {
          this.tooltip.style.left = `${event.pageX}px`
          this.tooltip.style.top = `${event.pageY - 40}px`
        }
      })
      .on("mouseout", function() {
        if (this.tooltip) {
          document.body.removeChild(this.tooltip)
          this.tooltip = null
        }
      })
    
    // Add X axis
    svg.append("g")
      .attr("transform", `translate(0,${height})`)
      .call(d3.axisBottom(x)
        .tickFormat(h => `${h}:00`)
        .tickValues(hours.filter(h => h % 3 === 0)))
      .selectAll("text")
      .style("text-anchor", "middle")
    
    // Add Y axis
    svg.append("g")
      .call(d3.axisLeft(y))
    
    // Add title
    svg.append("text")
      .attr("x", width / 2)
      .attr("y", -5)
      .attr("text-anchor", "middle")
      .style("font-size", "14px")
      .text("Best Posting Times (Engagement Rate)")
  }
}
