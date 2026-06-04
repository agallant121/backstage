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
    const selectedNames = this.selectedGroups.map((checkbox) => checkbox.dataset.groupName)
    this.buttonTarget.textContent = selectedNames.length > 0 ? selectedNames.join(", ") : this.allLabelValue
  }

  get selectedGroups() {
    return this.groupTargets.filter((checkbox) => checkbox.checked)
  }
}
