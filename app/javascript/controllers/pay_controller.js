import { Controller } from "@hotwired/stimulus"

// Membuat transaksi Snap lewat server, lalu membuka halaman bayar Midtrans.
export default class extends Controller {
  static values = { url: String }
  static targets = [ "button", "error" ]

  async start(event) {
    this.toggle(true)
    this.errorTarget.classList.add("hidden")

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        },
        credentials: "same-origin",
        body: JSON.stringify({ channel: event.params.channel })
      })
      const data = await response.json().catch(() => ({}))

      if (response.ok && data.redirect_url) {
        window.location.href = data.redirect_url
        return
      }

      this.showError(data.error || "Gagal membuat pembayaran. Coba lagi.")
    } catch {
      this.showError("Koneksi bermasalah. Coba lagi.")
    }
  }

  toggle(disabled) {
    this.buttonTargets.forEach((button) => { button.disabled = disabled })
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
    this.toggle(false)
  }
}
