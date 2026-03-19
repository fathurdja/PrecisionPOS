# Phase 2: Core Order Management & Interactivity

## 🎯 Objective
Mengubah `order_input_screen.dart` dan `transaction_history_screen.dart` menjadi fungsional, menghubungkan UI "No-Line" dengan data lokal dari Phase 1.

## 🛠️ Tasks
- [ ] **Order Input Logic (Real-time Calculation):**
  - Implementasi *dropdown* atau *searchable list* untuk memilih barang.
  - Otomatisasi pengisian harga satuan saat barang dipilih.
  - Buat logika kalkulasi: `Subtotal = Harga * Qty` dan otomatisasi `Grand Total`.
- [ ] **Checkout Process (Create):**
  - Hubungkan tombol "Process Payment" untuk menyimpan `TransactionModel` dan `OrderItemModel` ke database.
  - Tambahkan notifikasi/snackbar sukses dengan *tonal background* (tanpa border).
- [ ] **Transaction History (Read):**
  - Gunakan `FutureBuilder` atau implementasi State Management untuk menampilkan daftar transaksi dari database ke `transaction_history_screen.dart`.
  - Pastikan fitur *search* dan filter tanggal berfungsi.
- [ ] **Transaction Management (Update/Delete):**
  - Tambahkan fungsi *Void* (batalkan pesanan) pada transaksi yang berstatus "Pending".

## 🏁 Definition of Done (DoD)
- Pengguna bisa membuat pesanan baru dan angka total terhitung akurat.
- Pesanan yang berhasil disimpan muncul di layar History.