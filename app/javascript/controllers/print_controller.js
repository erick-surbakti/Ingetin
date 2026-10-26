import { Controller } from "@hotwired/stimulus"

// Membuka dialog cetak browser, untuk menyimpan kuitansi sebagai PDF.
export default class extends Controller {
  print() {
    window.print()
  }
}
