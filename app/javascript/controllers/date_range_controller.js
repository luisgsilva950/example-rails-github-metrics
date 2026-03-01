import { Controller } from "@hotwired/stimulus"

// Combines two hidden date inputs into a single visual date-range picker.
// Click the display to open the start picker; once start is chosen the
// end picker opens automatically. The display shows "Mar 02 – Mar 13".
export default class extends Controller {
  static targets = ["startDate", "endDate", "display"]

  connect() {
    this.updateDisplay()
  }

  openStart() {
    this.startDateTarget.showPicker()
  }

  startChanged() {
    if (this.startDateTarget.value > this.endDateTarget.value) {
      this.endDateTarget.value = this.startDateTarget.value
    }
    this.endDateTarget.min = this.startDateTarget.value
    this.updateDisplay()

    requestAnimationFrame(() => this.endDateTarget.showPicker())
  }

  endChanged() {
    this.updateDisplay()
  }

  updateDisplay() {
    const start = this.startDateTarget.value
    const end = this.endDateTarget.value

    if (start && end) {
      this.displayTarget.textContent = `${this.formatDate(start)} – ${this.formatDate(end)}`
      this.displayTarget.classList.remove("planning-date-range__display--placeholder")
    } else {
      this.displayTarget.textContent = "Select dates…"
      this.displayTarget.classList.add("planning-date-range__display--placeholder")
    }
  }

  formatDate(iso) {
    const [y, m, d] = iso.split("-")
    const date = new Date(Number(y), Number(m) - 1, Number(d))
    return date.toLocaleDateString("en-US", { month: "short", day: "2-digit" })
  }
}
