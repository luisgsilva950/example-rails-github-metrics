import { Controller } from "@hotwired/stimulus"

// Manages a slide-over drawer that shows different content sections.
// Buttons trigger `open` with a key param to display the matching panel.
export default class extends Controller {
  static targets = ["drawer", "section", "title", "backdrop"]

  open(event) {
    const key = event.params.key
    const title = event.params.title || ""

    this.sectionTargets.forEach(s => s.style.display = "none")

    const section = this.sectionTargets.find(s => s.dataset.slideoutKey === key)
    if (section) section.style.display = "block"

    this.titleTarget.textContent = title
    this.drawerTarget.classList.add("slideout--open")
    this.backdropTarget.classList.add("slideout__backdrop--visible")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.drawerTarget.classList.remove("slideout--open")
    this.backdropTarget.classList.remove("slideout__backdrop--visible")
    document.body.style.overflow = ""
  }

  backdropClick(event) {
    if (event.target === this.backdropTarget) this.close()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
