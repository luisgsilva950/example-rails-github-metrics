import { Controller } from "@hotwired/stimulus"

// Toggles between "date_range" and "recurring" modes
// in the operational activity form.
export default class extends Controller {
  static targets = ["mode", "dateFields", "recurringField", "startDate", "endDate"]

  connect() {
    this.toggle()
  }

  toggle() {
    const mode = this.modeTarget.value

    if (mode === "recurring") {
      this.dateFieldsTarget.style.display = "none"
      this.recurringFieldTarget.style.display = ""
      this.startDateTarget.removeAttribute("required")
      this.endDateTarget.removeAttribute("required")
    } else {
      this.dateFieldsTarget.style.display = ""
      this.recurringFieldTarget.style.display = "none"
      this.startDateTarget.setAttribute("required", "")
      this.endDateTarget.setAttribute("required", "")
    }
  }
}
