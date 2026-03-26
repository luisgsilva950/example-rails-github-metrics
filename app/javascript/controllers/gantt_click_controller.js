import { Controller } from "@hotwired/stimulus"

// Shows a popover with available deliverables when clicking an empty Gantt cell.
// On filled cells, shows an "unforeseen" popover to log execution overrides.
export default class extends Controller {
  static values = {
    cycleId: String,
    entriesUrl: String,
    deliverables: Array // [{ id, title, color }]
  }

  connect() {
    this.popover = null
    this.boundClose = this.closePopover.bind(this)
    this.dragHappened = false
    this.dragStartX = 0
    this.dragStartY = 0

    this.element.addEventListener("mousedown", (e) => {
      this.dragHappened = false
      this.dragStartX = e.clientX
      this.dragStartY = e.clientY
    })

    this.element.addEventListener("mousemove", (e) => {
      const dx = Math.abs(e.clientX - this.dragStartX)
      const dy = Math.abs(e.clientY - this.dragStartY)
      if (dx > 4 || dy > 4) this.dragHappened = true
    })
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

  filledCellClicked(event) {
    // Skip if a drag just happened (resize handles, etc.)
    if (this.dragHappened) return

    const cell = event.target.closest("td[data-day]")
    if (!cell) return
    if (event.detail === 0) return

    // Don't interfere with resize handles
    if (event.target.closest(".gantt__resize-handle")) return

    const day = cell.dataset.day
    const deliverableId = cell.dataset.deliverableId
    const row = cell.closest("tr")
    const developerId = row?.dataset.developerId
    if (!day || !deliverableId || !developerId) return

    this.removePopover()
    const context = { deliverable_id: deliverableId, developer_id: developerId }

    if (cell.dataset.unforeseenId) {
      this.showExistingUnforeseenPopover(cell, day, context)
    } else {
      this.showUnforeseenPopover(cell, day, context)
    }
  }

  operationalCellClicked(event) {
    if (this.dragHappened) return

    const cell = event.target.closest("td[data-day]")
    if (!cell) return
    if (event.detail === 0) return

    const day = cell.dataset.day
    const row = cell.closest("tr")
    const developerId = row?.dataset.developerId || cell.dataset.developerId
    if (!day || !developerId) return

    this.removePopover()
    const context = { developer_id: developerId, cycle_id: this.cycleIdValue }

    if (cell.dataset.unforeseenId) {
      this.showExistingUnforeseenPopover(cell, day, context)
    } else {
      this.showUnforeseenPopover(cell, day, context)
    }
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

  showUnforeseenPopover(anchorCell, day, context) {
    const REASONS = [
      { label: "Bug", icon: "🐛", hours: 8 },
      { label: "Other Bet", icon: "🔀", hours: 8 },
      { label: "Unexpected Absence", icon: "🚫", hours: 8 },
      { label: "Partial (custom hours)", icon: "⏱", hours: null }
    ]

    const popover = document.createElement("div")
    popover.className = "gantt-popover gantt-popover--unforeseen"

    const header = document.createElement("div")
    header.className = "gantt-popover__header"
    header.textContent = `Unforeseen Event · ${this.formatDate(day)}`
    popover.appendChild(header)

    const list = document.createElement("div")
    list.className = "gantt-popover__list"

    REASONS.forEach(reason => {
      const item = document.createElement("button")
      item.className = "gantt-popover__item"
      item.type = "button"
      item.innerHTML = `<span class="gantt-popover__icon">${reason.icon}</span>${reason.label}`

      if (reason.hours !== null) {
        item.addEventListener("click", () => {
          this.saveUnforeseen(day, reason.hours, reason.label, context)
          this.removePopover()
        })
      } else {
        item.addEventListener("click", () => {
          this.showCustomHoursInput(popover, day, context)
        })
      }
      list.appendChild(item)
    })

    popover.appendChild(list)
    this.positionPopover(popover, anchorCell)
  }

  showExistingUnforeseenPopover(anchorCell, day, context) {
    const entryId = anchorCell.dataset.unforeseenId
    const note = anchorCell.dataset.unforeseenNote || ""
    const hours = anchorCell.dataset.unforeseenHours || "0"

    const popover = document.createElement("div")
    popover.className = "gantt-popover gantt-popover--unforeseen"

    const header = document.createElement("div")
    header.className = "gantt-popover__header"
    header.textContent = `Unforeseen Event · ${this.formatDate(day)}`
    popover.appendChild(header)

    const detail = document.createElement("div")
    detail.className = "gantt-popover__detail"
    detail.innerHTML = `
      <div class="gantt-popover__detail-row">
        <span class="gantt-popover__detail-label">Reason</span>
        <span class="gantt-popover__detail-value">${this.escapeHtml(note)}</span>
      </div>
      <div class="gantt-popover__detail-row">
        <span class="gantt-popover__detail-label">Hours</span>
        <span class="gantt-popover__detail-value">${hours}h</span>
      </div>
    `
    popover.appendChild(detail)

    const actions = document.createElement("div")
    actions.className = "gantt-popover__actions"

    const changeBtn = document.createElement("button")
    changeBtn.type = "button"
    changeBtn.className = "gantt-popover__action-btn gantt-popover__action-btn--edit"
    changeBtn.textContent = "Change"
    changeBtn.addEventListener("click", () => {
      this.removePopover()
      this.showUnforeseenPopover(anchorCell, day, { ...context, _entryId: entryId })
    })

    const removeBtn = document.createElement("button")
    removeBtn.type = "button"
    removeBtn.className = "gantt-popover__action-btn gantt-popover__action-btn--delete"
    removeBtn.textContent = "Remove"
    removeBtn.addEventListener("click", () => {
      this.deleteUnforeseen(entryId)
      this.removePopover()
    })

    actions.appendChild(changeBtn)
    actions.appendChild(removeBtn)
    popover.appendChild(actions)

    this.positionPopover(popover, anchorCell)
  }

  async deleteUnforeseen(entryId) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const url = `${this.entriesUrlValue}/${entryId}`

    try {
      const response = await fetch(url, {
        method: "DELETE",
        headers: { "X-CSRF-Token": csrfToken, Accept: "application/json" }
      })

      if (response.ok || response.status === 204) {
        this.saveScrollPosition()
        window.location.reload()
      } else {
        alert("Failed to remove unforeseen")
      }
    } catch (error) {
      console.warn("unforeseen: delete error", error)
    }
  }

  showCustomHoursInput(popover, day, context) {
    const list = popover.querySelector(".gantt-popover__list")
    list.innerHTML = ""

    const form = document.createElement("div")
    form.className = "gantt-popover__form"
    form.innerHTML = `
      <label class="gantt-popover__field-label">Hours actually worked</label>
      <input type="number" min="0" max="8" step="0.5" value="4" class="gantt-popover__input" />
      <label class="gantt-popover__field-label">Note (optional)</label>
      <input type="text" placeholder="Reason…" class="gantt-popover__input gantt-popover__input--text" />
      <button type="button" class="gantt-popover__save-btn">Save</button>
    `

    const hoursInput = form.querySelector("input[type='number']")
    const noteInput = form.querySelector("input[type='text']")
    form.querySelector("button").addEventListener("click", () => {
      const hours = parseFloat(hoursInput.value) || 0
      const note = noteInput.value || "Partial day"
      this.saveUnforeseen(day, hours, note, context)
      this.removePopover()
    })

    list.appendChild(form)
  }

  positionPopover(popover, anchorCell) {
    document.body.appendChild(popover)

    const rect = anchorCell.getBoundingClientRect()
    const popoverWidth = 240
    let left = rect.left + window.scrollX
    let top = rect.bottom + window.scrollY + 4

    if (left + popoverWidth > window.innerWidth) {
      left = window.innerWidth - popoverWidth - 8
    }

    popover.style.left = `${left}px`
    popover.style.top = `${top}px`

    this.popover = popover

    requestAnimationFrame(() => {
      document.addEventListener("mousedown", this.boundClose)
    })
  }

  async saveUnforeseen(day, hoursBurned, note, context) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const entryId = context._entryId
    const { _entryId, ...params } = context
    const url = entryId ? `${this.entriesUrlValue}/${entryId}` : this.entriesUrlValue
    const method = entryId ? "PATCH" : "POST"

    try {
      const response = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          Accept: "application/json"
        },
        body: JSON.stringify({
          burndown_entry: {
            ...params,
            date: day,
            hours_burned: hoursBurned,
            note: note
          }
        })
      })

      if (response.ok) {
        this.saveScrollPosition()
        window.location.reload()
      } else {
        const data = await response.json().catch(() => ({}))
        const msg = (data.errors || []).join(", ") || "Failed to save"
        alert(msg)
      }
    } catch (error) {
      console.warn("unforeseen: save error", error)
    }
  }

  saveScrollPosition() {
    const ganttWrap = this.element
    sessionStorage.setItem("gantt-scroll-x", ganttWrap.scrollLeft)
    sessionStorage.setItem("gantt-scroll-y", document.documentElement.scrollTop || document.body.scrollTop)
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
