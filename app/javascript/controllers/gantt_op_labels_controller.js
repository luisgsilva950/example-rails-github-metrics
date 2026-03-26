import { Controller } from "@hotwired/stimulus"

// Positions operational activity labels as floating overlays above the table cells.
// This avoids browser limitations with overflow on <td> elements.
export default class extends Controller {
  connect() {
    requestAnimationFrame(() => this.positionLabels())
    this._resizeObserver = new ResizeObserver(() => this.positionLabels())
    this._resizeObserver.observe(this.element)
    this._boundReposition = () => this.positionLabels()
    this.element.addEventListener("scroll", this._boundReposition)
  }

  disconnect() {
    this.removeLabels()
    this._resizeObserver?.disconnect()
    this.element.removeEventListener("scroll", this._boundReposition)
  }

  positionLabels() {
    this.removeLabels()

    const firstCells = this.element.querySelectorAll(".gantt__cell--op-first")
    const wrapRect = this.element.getBoundingClientRect()
    const scrollLeft = this.element.scrollLeft
    const scrollTop = this.element.scrollTop

    firstCells.forEach((cell) => {
      const labelData = cell.dataset.opLabel
      const labelColor = cell.dataset.opColor
      if (!labelData) return

      const consecutiveCells = this.countConsecutiveOpCells(cell)
      const cellRect = cell.getBoundingClientRect()

      const overlay = document.createElement("span")
      overlay.className = "gantt__op-label-overlay"
      overlay.textContent = labelData
      overlay.style.color = labelColor || "inherit"
      overlay.style.top = `${cellRect.top - wrapRect.top + scrollTop + cellRect.height / 2}px`
      overlay.style.left = `${cellRect.left - wrapRect.left + scrollLeft + 4}px`
      overlay.style.maxWidth = `${consecutiveCells * cellRect.width - 8}px`

      this.element.appendChild(overlay)
    })
  }

  removeLabels() {
    this.element.querySelectorAll(".gantt__op-label-overlay").forEach((el) => el.remove())
  }

  countConsecutiveOpCells(startCell) {
    let count = 1
    let sibling = startCell.nextElementSibling
    while (sibling && sibling.classList.contains("gantt__cell--operational")) {
      count++
      sibling = sibling.nextElementSibling
    }
    return count
  }
}
