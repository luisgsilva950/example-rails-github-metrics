import { Controller } from "@hotwired/stimulus"

// Shows a popover with available deliverables when clicking an empty Gantt cell.
// Selecting a deliverable creates an allocation for that developer + day via POST.
export default class extends Controller {
  static values = {
    cycleId: String,
    deliverables: Array // [{ id, title, color }]
  }

  connect() {
    this.popover = null
    this.boundClose = this.closePopover.bind(this)
  }

  disconnect() {
    this.removePopover()
  }

  cellClicked(event) {
    const cell = event.target.closest("td[data-day]")
    if (!cell) return

    // Don't open popover if a drag just ended
    if (event.detail === 0) return

    const day = cell.dataset.day
    const row = cell.closest("tr")
    const developerId = row?.dataset.developerId
    if (!developerId || !day) return

    this.removePopover()
    this.showPopover(cell, developerId, day)
  }

  showPopover(anchorCell, developerId, day) {
    const popover = document.createElement("div")
    popover.className = "gantt-popover"

    const header = document.createElement("div")
    header.className = "gantt-popover__header"
    header.textContent = `Assign to ${this.formatDate(day)}`
    popover.appendChild(header)

    const list = document.createElement("div")
    list.className = "gantt-popover__list"

    if (this.deliverablesValue.length === 0) {
      const empty = document.createElement("div")
      empty.className = "gantt-popover__empty"
      empty.textContent = "No deliverables in this cycle"
      list.appendChild(empty)
    } else {
      this.deliverablesValue.forEach(del => {
        const item = document.createElement("button")
        item.className = "gantt-popover__item"
        item.type = "button"
        item.innerHTML = `<span class="gantt-popover__swatch" style="background:${del.color}"></span>${this.escapeHtml(del.title)}`
        item.addEventListener("click", () => {
          this.createAllocation(developerId, del.id, day)
          this.removePopover()
        })
        list.appendChild(item)
      })
    }

    popover.appendChild(list)
    document.body.appendChild(popover)

    // Position near the cell
    const rect = anchorCell.getBoundingClientRect()
    const popoverWidth = 220
    let left = rect.left + window.scrollX
    let top = rect.bottom + window.scrollY + 4

    // Keep within viewport
    if (left + popoverWidth > window.innerWidth) {
      left = window.innerWidth - popoverWidth - 8
    }

    popover.style.left = `${left}px`
    popover.style.top = `${top}px`

    this.popover = popover

    // Close on outside click (defer to avoid immediate close)
    requestAnimationFrame(() => {
      document.addEventListener("mousedown", this.boundClose)
    })
  }

  closePopover(event) {
    if (this.popover && !this.popover.contains(event.target)) {
      this.removePopover()
    }
  }

  removePopover() {
    document.removeEventListener("mousedown", this.boundClose)
    if (this.popover) {
      this.popover.remove()
      this.popover = null
    }
  }

  async createAllocation(developerId, deliverableId, day) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const url = `/planning/cycles/${this.cycleIdValue}/cycle_allocations`

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({
        deliverable_allocation: {
          developer_id: developerId,
          deliverable_id: deliverableId,
          start_date: day,
          end_date: day
        }
      })
    })

    if (response.ok) {
      const ganttWrap = this.element
      sessionStorage.setItem("gantt-scroll-x", ganttWrap.scrollLeft)
      sessionStorage.setItem("gantt-scroll-y", document.documentElement.scrollTop || document.body.scrollTop)
      window.location.reload()
    } else {
      const data = await response.json().catch(() => ({}))
      const msg = data.error || "Failed to create allocation"
      alert(msg)
    }
  }

  // ── Helpers ──

  formatDate(dateStr) {
    const [, m, d] = dateStr.split("-")
    return `${d}/${m}`
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
