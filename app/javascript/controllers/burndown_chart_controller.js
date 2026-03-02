import { Controller } from "@hotwired/stimulus"

// Renders burndown charts for each deliverable in the cycle.
// Fetches data from the burndown JSON endpoint and builds one chart per deliverable.
// Chart.js UMD is loaded via importmap → available as window.Chart.
export default class extends Controller {
  static values = { url: String }
  static targets = ["container"]

  connect () {
    this.charts = []
    this.fetchAndRender()
  }

  disconnect () {
    this.destroyCharts()
  }

  async fetchAndRender () {
    await this.waitForChartJS()

    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) {
        this.showError("Failed to load burndown data.")
        return
      }

      const deliverables = await response.json()
      this.renderAll(deliverables)
    } catch (error) {
      console.warn("burndown-chart: failed to load data", error)
      this.showError("Failed to load burndown data.")
    }
  }

  renderAll (deliverables) {
    this.destroyCharts()
    this.containerTarget.innerHTML = ""

    if (deliverables.length === 0) {
      this.containerTarget.innerHTML = '<p class="burndown__empty">No deliverables in this cycle.</p>'
      return
    }

    deliverables.forEach(d => this.renderOne(d))
  }

  renderOne (deliverable) {
    const ChartJS = window.Chart
    if (!ChartJS) {
      console.warn("burndown-chart: Chart.js not loaded")
      return
    }

    const wrapper = document.createElement("div")
    wrapper.className = "burndown__card"

    const header = document.createElement("h4")
    header.className = "burndown__card-title"
    header.textContent = `${deliverable.title} (${deliverable.effort}h)`
    wrapper.appendChild(header)

    const canvasWrap = document.createElement("div")
    canvasWrap.className = "burndown__canvas-wrap"
    const canvas = document.createElement("canvas")
    canvasWrap.appendChild(canvas)
    wrapper.appendChild(canvasWrap)

    this.containerTarget.appendChild(wrapper)

    const labels = deliverable.planned.map(p => p.date)
    const plannedData = deliverable.planned.map(p => p.remaining)
    const idealData = deliverable.ideal.map(p => p.remaining)
    const executedData = this.buildExecutedData(deliverable.executed, labels)
    const hasExecution = executedData.some(v => v !== null)

    const datasets = [
      {
        label: "Ideal",
        data: idealData,
        borderColor: "rgba(88, 166, 255, 0.5)",
        borderDash: [6, 4],
        borderWidth: 2,
        pointRadius: 0,
        fill: false,
        tension: 0
      },
      {
        label: "Planned",
        data: plannedData,
        borderColor: "#3fb950",
        borderWidth: 2,
        pointRadius: 2,
        pointBackgroundColor: "#3fb950",
        fill: false,
        tension: 0.1
      }
    ]

    if (hasExecution) {
      datasets.push({
        label: "Executed",
        data: executedData,
        borderColor: "#d29922",
        borderWidth: 2.5,
        pointRadius: 3,
        pointBackgroundColor: "#d29922",
        fill: false,
        tension: 0.1,
        spanGaps: false
      })
    }

    const chart = new ChartJS(canvas.getContext("2d"), {
      type: "line",
      data: { labels, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: { color: "#c9d1d9", font: { size: 11 } }
          },
          tooltip: {
            callbacks: {
              label: ctx => `${ctx.dataset.label}: ${ctx.parsed.y.toFixed(1)}h`
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            title: { display: true, text: "Hours remaining", color: "#8b949e" },
            grid: { color: "rgba(48, 54, 61, 0.6)" },
            ticks: { color: "#8b949e" }
          },
          x: {
            title: { display: true, text: "Work day", color: "#8b949e" },
            grid: { display: false },
            ticks: {
              color: "#8b949e",
              maxRotation: 45,
              autoSkip: true,
              maxTicksLimit: 15
            }
          }
        }
      }
    })

    this.charts.push(chart)
  }

  // Returns executed data array, truncated to today. Future dates become null.
  buildExecutedData (executed, labels) {
    const today = new Date().toISOString().slice(0, 10)
    return labels.map((date, i) => {
      if (date > today) return null
      return executed[i]?.remaining ?? null
    })
  }

  waitForChartJS (attempts = 0) {
    return new Promise((resolve, reject) => {
      if (window.Chart) return resolve()
      if (attempts > 50) return reject(new Error("Chart.js not loaded"))

      setTimeout(() => this.waitForChartJS(attempts + 1).then(resolve, reject), 100)
    })
  }

  showError (message) {
    this.containerTarget.innerHTML = `<p class="burndown__empty">${message}</p>`
  }

  destroyCharts () {
    this.charts.forEach(c => c.destroy())
    this.charts = []
  }
}
