import { Controller } from "@hotwired/stimulus"

// Menyalin teks (misalnya URL notifikasi Midtrans) ke clipboard.
export default class extends Controller {
  static targets = [ "source", "label" ]

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.textContent.trim())
      this.flash("Tersalin")
    } catch {
      this.flash("Gagal menyalin")
    }
  }

  flash(text) {
    const original = this.labelTarget.dataset.original || this.labelTarget.textContent
    this.labelTarget.dataset.original = original
    this.labelTarget.textContent = text
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => { this.labelTarget.textContent = original }, 2000)
  }
}
