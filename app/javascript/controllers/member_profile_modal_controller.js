import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "frame"]

  connect() {
    this.handleBeforeCache = () => this.close()
    this.handleBeforeRender = () => this.cleanup()
    this.handleHidden = () => this.cleanup()
    document.addEventListener("turbo:before-cache", this.handleBeforeCache)
    document.addEventListener("turbo:before-render", this.handleBeforeRender)
    this.modalTarget?.addEventListener("hidden.bs.modal", this.handleHidden)
    this.cleanup()
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.handleBeforeCache)
    document.removeEventListener("turbo:before-render", this.handleBeforeRender)
    this.modalTarget?.removeEventListener("hidden.bs.modal", this.handleHidden)
  }

  open(event) {
    event?.preventDefault()
    if (typeof bootstrap === "undefined") return
    if (event?.currentTarget?.href) {
      this.frameTarget.src = event.currentTarget.href
    }
    this.modalInstance ||= new bootstrap.Modal(this.modalTarget)
    this.modalInstance.show()
  }

  close() {
    if (!this.modalInstance) return
    this.modalInstance.hide()
  }

  cleanup() {
    document.body.classList.remove("modal-open")
    document.body.style.removeProperty("padding-right")
    this.modalTarget?.classList.remove("show")
    this.modalTarget?.setAttribute("aria-hidden", "true")
    this.modalTarget?.style.removeProperty("display")
    document.querySelectorAll(".modal-backdrop").forEach((backdrop) => backdrop.remove())
  }
}
