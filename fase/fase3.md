# Phase 3: Reporting & Data Export (.PDF & .CSV)

## 🎯 Objective
Membangun fitur pelaporan analitik harian dan kapabilitas berbagi dokumen fisik/digital sesuai kebutuhan bisnis.

## 🛠️ Tasks
- [ ] **Daily Report Logic:**
  - Buat *query* database untuk menghitung "Total Sales" dan "Items Sold" pada hari ini.
  - Hubungkan data riil dengan grafik `fl_chart` untuk menampilkan performa per jam.
- [ ] **CSV Data Management (Import/Export):**
  - Integrasi package `csv` dan `path_provider`.
  - Buat fungsi *Export*: Konversi tabel transaksi hari ini menjadi file `report_YYYYMMDD.csv` dan simpan ke direktori perangkat.
  - Buat fungsi *Import*: Membaca file `.csv` untuk *restore* data (Backup Offline).
- [ ] **PDF Receipt Generation:**
  - Integrasi package `pdf` dan `printing`.
  - Desain layout PDF berukuran 58mm (Receipt style) yang memuat header toko, list barang, total, dan QR code tiruan.
- [ ] **WhatsApp Sharing Intent:**
  - Gunakan package `share_plus` atau `url_launcher`.
  - Hubungkan tombol "Share" di History Detail agar langsung mengirim file `.pdf` ke aplikasi WhatsApp.

## 🏁 Definition of Done (DoD)
- Grafik di Dashboard menampilkan data transaksi riil.
- File CSV bisa di-download ke perangkat.
- Struk format PDF berhasil di-generate dan *share dialog* WhatsApp terbuka.