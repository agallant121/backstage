import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["summary", "full", "expandAction", "collapseAction", "mediaTemplate", "mediaContainer"]
  static values = { loaded: Boolean }

  expand() {
    this.summaryTarget.classList.add("d-none")
    this.fullTarget.classList.remove("d-none")
    this.expandActionTarget.classList.add("d-none")
    this.collapseActionTarget.classList.remove("d-none")

    if (!this.loadedValue && this.hasMediaTemplateTarget) {
      this.mediaContainerTarget.append(this.mediaTemplateTarget.content.cloneNode(true))
      this.loadedValue = true
    }

    this.mediaContainerTarget.classList.remove("d-none")
  }

  collapse() {
    this.summaryTarget.classList.remove("d-none")
    this.fullTarget.classList.add("d-none")
    this.expandActionTarget.classList.remove("d-none")
    this.collapseActionTarget.classList.add("d-none")
    this.mediaContainerTarget.classList.add("d-none")
  }
}
