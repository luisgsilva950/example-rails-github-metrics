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
    const captureEl = this.element.querySelector(".gantt-capture-area")
    if (!captureEl) return

    const ganttWrap = captureEl.querySelector(".gantt-wrap")
    if (ganttWrap) ganttWrap.style.overflow = "visible"

    const canvas = await html2canvas(captureEl, {
      backgroundColor: "#0d1117",
      scale: 2,
      scrollX: 0,
      scrollY: 0,
      width: captureEl.scrollWidth,
      height: captureEl.scrollHeight,
      windowWidth: captureEl.scrollWidth,
      windowHeight: captureEl.scrollHeight
    })

    if (ganttWrap) ganttWrap.style.overflow = ""

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
