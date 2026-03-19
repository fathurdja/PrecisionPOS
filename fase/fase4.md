# Phase 4: State Management, Printing & Final Polish

## 🎯 Objective
Menyempurnakan alur aplikasi agar reaktif, memastikan konsistensi desain "Architectural Layering", dan mengintegrasikan *hardware* kasir.

## 🛠️ Tasks
- [ ] **Global State Syncing:**
  - Implementasi State Management (misal: `Riverpod` atau `Provider`) di seluruh aplikasi.
  - Pastikan saat transaksi baru dibuat di Tab 0, grafik di Tab 2 (Reports) dan list di Tab 1 (History) langsung ter-update tanpa perlu *restart* aplikasi.
- [ ] **Thermal Printer Integration:**
  - Integrasi package `blue_thermal_printer` atau `print_bluetooth_thermal`.
  - Buat logika pencarian (*scan*) device bluetooth di `settings_screen.dart`.
  - Hubungkan tombol "Print Receipt" dengan printer thermal 58mm untuk mencetak struk fisik.
- [ ] **UI/UX Refinement:**
  - Audit seluruh halaman untuk memastikan tidak ada *solid borders* (1px line) sesuai filosofi "No-Line".
  - Ganti *border* dengan *Tonal Shifts* (`surfaceContainerLowest` ke `surfaceContainerHighest`).
  - Pastikan *Keyboard padding* tertangani dengan baik saat input angka agar UI tidak tertutup keyboard.

## 🏁 Definition of Done (DoD)
- UI sangat mulus, responsif, dan data sinkron di semua halaman.
- Aplikasi dapat terkoneksi dengan printer bluetooth dan mencetak struk fisik.
- Kode bersih (`flutter analyze` nol isu).