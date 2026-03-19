# Phase 1: Data Foundation & Local Persistence (Offline-First)

## 🎯 Objective
Membangun fondasi data lokal agar aplikasi dapat berjalan sepenuhnya offline sesuai spesifikasi "Precision POS", serta menyiapkan model data utama.

## 🛠️ Tasks
- [ ] **Setup Data dummy lewat json local :** - Integrasi package `sqflite` atau `isar` untuk penyimpanan data offline.
 - data dummy ada di folder data/product.json
  - Buat skema tabel/koleksi untuk: `Products`, `Transactions`, dan `OrderItems`.
- [ ] **Data Modeling (Entities):**
  - Buat class `ProductModel` (id, nama, harga, stok).
  - Buat class `TransactionModel` (receipt_id, tanggal, total_harga, status).
  - Buat class `OrderItemModel` (product_id, qty, subtotal).
- [ ] **Auto-Generation Logic:**
  - Buat *helper function* untuk men-generate Nomor Struk secara otomatis (Format: `INV-YYYYMMDD-XXXX`).
  - Buat *helper* untuk mendapatkan *current timestamp* saat form order dibuka.
- [ ] **Repository Pattern:**
  - Implementasi fungsi dasar CRUD di level *repository* untuk interaksi dengan database lokal tanpa menyentuh UI.

## 🏁 Definition of Done (DoD)
- Database berhasil diinisialisasi saat aplikasi berjalan (`main.dart`).
- Data dummy bisa dimasukkan dan dibaca melalui *debug console*.