import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.messageTargets.forEach((msg, index) => {
      setTimeout(() => {
        msg.style.transition = "opacity 0.5s ease, transform 0.5s ease"
        msg.style.opacity = "0"
        msg.style.transform = "translateX(20px)"
        setTimeout(() => msg.remove(), 500)
      }, 4000 + index * 500)
    })
  }
}
