import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["all", "button", "group"]
  static values = {
    allLabel: { type: String, default: "All Groups" }
  }

  connect() {
    this.updateLabel()
  }

  toggleAll() {
    if (this.allTarget.checked) {
      this.groupTargets.forEach((checkbox) => {
        checkbox.checked = false
      })
    }

    this.updateLabel()
  }

  toggleGroup() {
    if (this.selectedGroups.length > 0) {
      this.allTarget.checked = false
    } else {
      this.allTarget.checked = true
    }

    this.updateLabel()
  }

  updateLabel() {
    const selectedGroups = this.selectedGroups
    this.allTarget.checked = selectedGroups.length === 0

    const selectedNames = selectedGroups.map((checkbox) => checkbox.dataset.groupName)
    this.buttonTarget.textContent = this.formatLabel(selectedNames)
  }

  formatLabel(selectedNames) {
    if (selectedNames.length === 0) return this.allLabelValue
    if (selectedNames.length === 1) return selectedNames[0]
    if (selectedNames.length === 2) return `${selectedNames[0]} and ${selectedNames[1]}`

    return `${selectedNames.slice(0, -1).join(", ")}, and ${selectedNames[selectedNames.length - 1]}`
  }

  get selectedGroups() {
    return this.groupTargets.filter((checkbox) => checkbox.checked)
  }
}
