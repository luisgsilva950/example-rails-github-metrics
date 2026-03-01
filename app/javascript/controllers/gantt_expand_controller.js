import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["btn", "label"]

  toggle() {
    const section = this.element
    section.classList.toggle("pln-gantt-section--expanded")

    const expanded = section.classList.contains("pln-gantt-section--expanded")
    this.labelTarget.textContent = expanded ? "Collapse" : "Expand"

    const topbar = document.querySelector(".planning-topbar")
    if (expanded) {
      document.body.style.overflow = "hidden"
      if (topbar) topbar.style.display = "none"
    } else {
      document.body.style.overflow = ""
      if (topbar) topbar.style.display = ""
    }
  }

  async download() {
    const { default: html2canvas } = await import("html2canvas")
    const chartEl = this.element.querySelector(".gantt-wrap")
    if (!chartEl) return

    const canvas = await html2canvas(chartEl, {
      backgroundColor: "#0d1117",
      scale: 2,
      scrollX: 0,
      scrollY: 0,
      width: chartEl.scrollWidth,
      height: chartEl.scrollHeight,
      windowWidth: chartEl.scrollWidth,
      windowHeight: chartEl.scrollHeight
    })

    const link = document.createElement("a")
    link.download = "planning-chart.png"
    link.href = canvas.toDataURL("image/png")
    link.click()
  }

  disconnect() {
    document.body.style.overflow = ""
    const topbar = document.querySelector(".planning-topbar")
    if (topbar) topbar.style.display = ""
  }
}
