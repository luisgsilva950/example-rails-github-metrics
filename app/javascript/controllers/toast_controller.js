import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 3000 } }

  connect() {
    requestAnimationFrame(() => {
      this.element.classList.add("planning-toast--visible")
    })

    this.timeout = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.remove("planning-toast--visible")
    this.element.addEventListener("transitionend", () => {
      this.element.remove()
    }, { once: true })
  }
}
