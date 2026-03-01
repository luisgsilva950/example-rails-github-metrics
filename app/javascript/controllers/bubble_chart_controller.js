import { Controller } from "@hotwired/stimulus"

// Renders a horizontal bar chart for JIRA bug category counts.
// Data is passed via data-* attributes from the server.
// Chart.js UMD is loaded via a <script> tag → window.Chart.
export default class extends Controller {
  static targets = ["canvas"]
  static values = { labels: Array, counts: Array, title: String }

  connect () {
    this.renderChart()
  }

  disconnect () {
    this.destroyChart()
  }

  renderChart () {
    const ChartJS = window.Chart
    if (!ChartJS) {
      console.error("bar-chart: Chart.js not loaded on window.Chart")
      return
    }

    const labels = this.labelsValue
    const counts = this.countsValue
    if (!labels.length || !counts.length) return
    if (!this.hasCanvasTarget) return

    this.destroyChart()

    this.chart = new ChartJS(this.canvasTarget.getContext("2d"), {
      type: "bar",
      data: {
        labels,
        datasets: [{
          label: this.titleValue || "Count",
          data: counts,
          backgroundColor: "rgba(37, 99, 235, 0.7)",
          borderColor: "rgb(37, 99, 235)",
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: {
        indexAxis: "y",
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: ctx => {
                const v = ctx.parsed.x
                return `${v} bug${v === 1 ? "" : "s"}`
              }
            }
          }
        },
        scales: {
          x: {
            beginAtZero: true,
            ticks: { precision: 0 },
            grid: { drawBorder: false }
          },
          y: {
            grid: { display: false },
            ticks: { font: { size: 11 } }
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
}
