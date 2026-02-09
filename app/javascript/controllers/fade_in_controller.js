import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add("animate-fade-in")
          this.observer.unobserve(entry.target)
        }
      })
    }, { threshold: 0.1 })

    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
