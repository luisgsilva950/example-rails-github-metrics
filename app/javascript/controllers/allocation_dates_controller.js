import { Controller } from "@hotwired/stimulus"

// Blocks dates on native <input type="date"> where the selected developer
// is already allocated to another deliverable in the same cycle.
//
// When the user picks a blocked date the input is immediately reverted
// to its previous value and setCustomValidity shows the browser's native
// validation tooltip explaining which period is blocked.
export default class extends Controller {
  static targets = ["developer", "startDate", "endDate"]
  static values = {
    allocations: Object, // { developer_id: [{ start_date, end_date, deliverable_id }] }
    deliverable: String  // current deliverable id (to exclude self)
  }

  connect() {
    this.previousStart = this.startDateTarget.value
    this.previousEnd   = this.endDateTarget.value
  }

  // Called when a developer is selected (create form).
  // Validates the current dates against the new developer's allocations.
  developerChanged() {
    this.validateAndRevert(this.startDateTarget)
    this.validateAndRevert(this.endDateTarget)
  }

  // Called on every `input` event of a date field.
  checkDate(event) {
    this.validateAndRevert(event.target)
  }

  // ── private ──

  validateAndRevert(input) {
    const devId = this.developerTarget.value
    if (!devId) { this.clearValidity(); return }

    const allocs = (this.allocationsValue[devId] || [])
      .filter(a => a.deliverable_id !== this.deliverableValue)

    if (allocs.length === 0) { this.clearValidity(); return }

    const startVal = this.startDateTarget.value
    const endVal   = this.endDateTarget.value
    if (!startVal || !endVal) return

    const overlap = allocs.find(a => startVal <= a.end_date && endVal >= a.start_date)

    if (overlap) {
      const msg = `Blocked: developer allocated ${this.fmt(overlap.start_date)} – ${this.fmt(overlap.end_date)}`

      // Revert the input that just changed to its previous safe value
      if (input === this.startDateTarget) {
        this.startDateTarget.value = this.previousStart
      } else {
        this.endDateTarget.value = this.previousEnd
      }

      input.setCustomValidity(msg)
      input.reportValidity()

      // Clear after a tick so the user can try again
      setTimeout(() => input.setCustomValidity(""), 0)
    } else {
      this.clearValidity()
      // Store new safe values
      this.previousStart = this.startDateTarget.value
      this.previousEnd   = this.endDateTarget.value
    }
  }

  clearValidity() {
    this.startDateTarget.setCustomValidity("")
    this.endDateTarget.setCustomValidity("")
  }

  fmt(dateStr) {
    const [, m, d] = dateStr.split("-")
    return `${d}/${m}`
  }
}
