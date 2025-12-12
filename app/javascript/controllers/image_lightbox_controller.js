import { Controller } from "@hotwired/stimulus"

// Displays a larger preview of post images inside a Bootstrap modal.
export default class extends Controller {
  static targets = [
    "modal",
    "modalImage",
    "thumbnail",
    "modalTitle",
    "prevButton",
    "nextButton",
  ]

  connect() {
    if (typeof bootstrap !== "undefined") {
      this.modalInstance = new bootstrap.Modal(this.modalTarget)
    }
  }

  open(event) {
    event.preventDefault()
    this.gallery = this.thumbnailTargets.map((thumb) => ({
      src: thumb.dataset.imageLightboxFullUrl,
      alt: thumb.dataset.imageLightboxAlt || thumb.alt || "Full-size image",
    }))
    const clickedIndex = this.thumbnailTargets.indexOf(event.currentTarget)
    this.currentIndex = clickedIndex >= 0 ? clickedIndex : 0

    this.showImage(this.currentIndex)

    this.modalInstance ||= typeof bootstrap !== "undefined" ? new bootstrap.Modal(this.modalTarget) : null
    this.modalInstance?.show()
  }

  previous() {
    if (this.currentIndex > 0) {
      this.showImage(this.currentIndex - 1)
    }
  }

  next() {
    if (this.currentIndex < this.gallery.length - 1) {
      this.showImage(this.currentIndex + 1)
    }
  }

  showImage(index) {
    const { src, alt } = this.gallery[index]
    this.currentIndex = index

    this.modalImageTarget.src = src
    this.modalImageTarget.alt = alt
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = alt
    }

    this.updateNavigation()
  }

  updateNavigation() {
    const hasPrev = this.currentIndex > 0
    const hasNext = this.currentIndex < this.gallery.length - 1

    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = !hasPrev
    }

    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = !hasNext
    }
  }
}
