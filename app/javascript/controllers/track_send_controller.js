import { Controller } from "@hotwired/stimulus"

// Mencatat bahwa tagihan dikirim lewat WhatsApp tanpa menahan link wa.me.
export default class extends Controller {
  static values = { url: String }

  track() {
    const token = document.querySelector("meta[name='csrf-token']")?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": token },
      credentials: "same-origin",
      keepalive: true
    })
  }
}
