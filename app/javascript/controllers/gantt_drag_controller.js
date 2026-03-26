import { Controller } from "@hotwired/stimulus"

// Enables resizing deliverable allocations in the Gantt chart by dragging edges.
// Drag the left handle to change start_date, right handle to change end_date.
// Dragging from the middle moves the entire allocation.
export default class extends Controller {
  static values = { cycleId: String, cycleStart: String, cycleEnd: String }

  connect() {
    this.dragging = false
    this.boundMouseMove = this.onMouseMove.bind(this)
    this.boundMouseUp = this.onMouseUp.bind(this)
    this.restoreScroll()
  }

  restoreScroll() {
    const scrollY = sessionStorage.getItem("gantt-scroll-y")
    const scrollX = sessionStorage.getItem("gantt-scroll-x")

    if (scrollY !== null) {
      window.scrollTo(0, parseInt(scrollY, 10))
      sessionStorage.removeItem("gantt-scroll-y")
    }
    if (scrollX === null) {
      this.scrollToToday()
    } else {
      this.element.scrollLeft = parseInt(scrollX, 10)
      sessionStorage.removeItem("gantt-scroll-x")
    }
  }

  scrollToToday() {
    const todayCol = this.element.querySelector(".gantt__day-col--today")
    if (!todayCol) return

    const wrapWidth = this.element.clientWidth
    const colLeft = todayCol.offsetLeft
    const colWidth = todayCol.offsetWidth
    this.element.scrollLeft = colLeft - (wrapWidth / 2) + (colWidth / 2)
  }

  startDrag(event) {
    if (event.button !== 0) return

    const cell = event.target.closest("td[data-allocation-id]")
    if (!cell) return

    // Detect which edge was grabbed
    const handle = event.target.closest("[data-edge]")
    if (handle) {
      this.mode = handle.dataset.edge // "start" or "end"
      // Only preventDefault for resize handles — they need to suppress click
      event.preventDefault()
    } else {
      this.mode = "move"
      // Don't preventDefault here — allow click events to fire for non-drag clicks
    }

    this.dragging = true
    this.actualDragStarted = false
    this.lastOffset = null
    this.allocId = cell.dataset.allocationId
    this.origStart = cell.dataset.allocStart
    this.origEnd = cell.dataset.allocEnd
    this.grabDay = cell.dataset.day
    this.row = cell.closest("tr")

    this.allocCells = [...this.row.querySelectorAll(`td[data-allocation-id="${this.allocId}"]`)]
    this.dayCells = [...this.row.querySelectorAll("td[data-day]")]

    document.addEventListener("mousemove", this.boundMouseMove)
    document.addEventListener("mouseup", this.boundMouseUp)
  }

  onMouseMove(event) {
    if (!this.dragging) return

    // Apply drag styling on first actual move
    if (!this.actualDragStarted) {
      this.actualDragStarted = true
      this.allocCells.forEach(c => c.classList.add("gantt__cell--dragging"))
      document.body.classList.add("gantt-dragging")
    }

    const el = document.elementFromPoint(event.clientX, event.clientY)
    const hoverCell = el?.closest("td[data-day]")

    this.dayCells.forEach(c => {
      c.classList.remove("gantt__cell--drop-preview")
      c.classList.remove("gantt__cell--drop-remove")
    })

    if (!hoverCell || !this.row.contains(hoverCell)) return

    const offsetDays = this.calendarDaysBetween(this.grabDay, hoverCell.dataset.day)
    if (offsetDays === 0) {
      this.lastOffset = null
      return
    }

    const { start: newStart, end: newEnd } = this.computeNewDates(offsetDays)
    if (newStart > newEnd) return

    // Store last valid offset for mouseUp
    this.lastOffset = offsetDays

    this.dayCells.forEach(c => {
      const d = c.dataset.day
      const isInOriginal = c.dataset.allocationId === this.allocId
      const isInPreview = d >= newStart && d <= newEnd

      if (isInPreview && !isInOriginal) {
        c.classList.add("gantt__cell--drop-preview")
      } else if (isInOriginal && !isInPreview) {
        c.classList.add("gantt__cell--drop-remove")
      }
    })
  }

  onMouseUp(event) {
    if (!this.dragging) return

    document.removeEventListener("mousemove", this.boundMouseMove)
    document.removeEventListener("mouseup", this.boundMouseUp)
    document.body.classList.remove("gantt-dragging")

    this.allocCells.forEach(c => c.classList.remove("gantt__cell--dragging"))
    this.dayCells.forEach(c => {
      c.classList.remove("gantt__cell--drop-preview")
      c.classList.remove("gantt__cell--drop-remove")
    })

    // Use the last valid offset from mouseMove, or try resolving from drop cell
    let offsetDays = this.lastOffset

    if (offsetDays === null || offsetDays === undefined) {
      const el = document.elementFromPoint(event.clientX, event.clientY)
      const dropCell = el?.closest("td[data-day]")
      if (!dropCell || !this.row.contains(dropCell)) {
        this.dragging = false
        return
      }
      offsetDays = this.calendarDaysBetween(this.grabDay, dropCell.dataset.day)
    }

    if (offsetDays === 0) {
      this.dragging = false
      return
    }

    const { start: newStart, end: newEnd } = this.computeNewDates(offsetDays)
    if (newStart > newEnd) {
      this.dragging = false
      return
    }

    this.dragging = false
    this.patchAllocation(this.allocId, newStart, newEnd)
  }

  computeNewDates(offsetDays) {
    let start, end

    switch (this.mode) {
      case "start":
        start = this.addDays(this.origStart, offsetDays)
        end = this.origEnd
        break
      case "end":
        start = this.origStart
        end = this.addDays(this.origEnd, offsetDays)
        break
      default: // move
        start = this.addDays(this.origStart, offsetDays)
        end = this.addDays(this.origEnd, offsetDays)
        break
    }

    // Clamp to cycle boundaries
    const cycleStart = this.cycleStartValue
    const cycleEnd = this.cycleEndValue

    if (this.mode === "move") {
      if (start < cycleStart) {
        const shift = this.calendarDaysBetween(start, cycleStart)
        start = this.addDays(start, shift)
        end = this.addDays(end, shift)
      }
      if (end > cycleEnd) {
        const shift = this.calendarDaysBetween(cycleEnd, end)
        start = this.addDays(start, -shift)
        end = this.addDays(end, -shift)
      }
    } else {
      if (start < cycleStart) start = cycleStart
      if (end > cycleEnd) end = cycleEnd
    }

    return { start, end }
  }

  async patchAllocation(id, startDate, endDate) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const url = `/planning/cycles/${this.cycleIdValue}/cycle_allocations/${id}`

    const response = await fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({
        deliverable_allocation: { start_date: startDate, end_date: endDate }
      })
    })

    if (response.ok) {
      sessionStorage.setItem("gantt-scroll-x", this.element.scrollLeft)
      sessionStorage.setItem("gantt-scroll-y", document.documentElement.scrollTop || document.body.scrollTop)
      window.location.reload()
    } else {
      const data = await response.json().catch(() => ({}))
      const msg = data.error || "Failed to update allocation"
      alert(msg)
    }
  }

  // ── Helpers ──

  calendarDaysBetween(dateStrA, dateStrB) {
    const a = new Date(dateStrA + "T00:00:00")
    const b = new Date(dateStrB + "T00:00:00")
    return Math.round((b - a) / 86400000)
  }

  addDays(dateStr, days) {
    const d = new Date(dateStr + "T00:00:00")
    d.setDate(d.getDate() + days)
    return d.toISOString().slice(0, 10)
  }
}
