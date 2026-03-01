import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Renders a lightweight line chart that highlights monthly velocity trends.
export default class extends Controller {
  static targets = ["canvas"]

  connect () {
    this.renderChart()
  }

  disconnect () {
    this.destroyChart()
  }

  renderChart () {
    if (!this.hasCanvasTarget) return

    const labels = this.datasetArray("analyticsChartLabelsValue")
    const values = this.datasetArray("analyticsChartValuesValue")
    const title = this.element.dataset.analyticsChartTitleValue || "Monthly merge velocity"

    this.destroyChart()

    this.chart = new Chart(this.canvasTarget.getContext("2d"), {
      type: "line",
      data: {
        labels,
        datasets: [
          {
            label: title,
            data: values,
            fill: true,
            borderWidth: 2,
            tension: 0.35,
            borderColor: "rgb(37, 99, 235)",
            backgroundColor: "rgba(37, 99, 235, 0.15)",
            pointBackgroundColor: "rgb(37, 99, 235)",
            pointRadius: 3
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: context => {
                const value = context.parsed.y ?? 0
                const formatted = new Intl.NumberFormat().format(value)
                return `${formatted} merged PR${value === 1 ? "" : "s"}`
              }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: { drawBorder: false },
            ticks: {
              precision: 0,
              callback: value => new Intl.NumberFormat().format(value)
            }
          },
          x: {
            grid: { display: false }
          }
        }
      }
    })
  }

  destroyChart () {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  datasetArray (key) {
    const raw = this.element.dataset[key]
    if (!raw) return []

    try {
      const parsed = JSON.parse(raw)
      return Array.isArray(parsed) ? parsed : []
    } catch (error) {
      console.warn(`analytics-chart: unable to parse dataset for ${key}`, error)
      return []
    }
  }
}
