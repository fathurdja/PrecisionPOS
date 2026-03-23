# Implementation Plan: Payment Gateway — Precision POS
**Design System:** The Architectural Point of Sale (The Precision Atelier)  
**Versi:** 1.0  
**Tanggal:** Oktober 2024  
**Status:** Siap untuk Development

---

## 1. Ringkasan Eksekutif

Halaman Payment Gateway adalah penambahan kritis pada aplikasi Precision POS yang saat ini belum memiliki alur pembayaran lengkap. Sistem ini menghubungkan **Sales Screen** (order sudah siap) ke **History** (transaksi tercatat) melalui empat halaman baru yang menangani tiga metode pembayaran: **Cash, Bon/Kredit, dan QRIS**.

### Halaman Baru yang Dibutuhkan

| # | Nama Halaman | Prioritas | Kompleksitas |
|---|---|---|---|
| 1 | Payment Method Screen | 🔴 Kritis | Rendah |
| 2 | Cash Entry Screen | 🔴 Kritis | Sedang |
| 3 | Bon / Kredit Screen | 🟠 Tinggi | Sedang |
| 4 | QRIS Screen | 🟠 Tinggi | Tinggi |
| 5 | Payment Success Screen | 🔴 Kritis | Rendah |

---

## 2. User Flow Lengkap

```
Sales Screen
    │
    │  [Tap "Process Payment"]
    ▼
① Payment Method Screen  ──────────────────────────────────┐
    │                                                        │
    ├──[Cash]──────────────────────────────────────────┐    │
    │                                                   │    │
    ├──[QRIS]──────────────────────────────────────┐   │    │
    │                                               │   │    │
    └──[Bon/Kredit]────────────────────────────┐   │   │    │
                                               │   │   │    │
② Bon/Kredit Screen   ◄────────────────────────┘   │   │    │
    │                                               │   │    │
    │  [Simpan & Cetak Bon]                         │   │    │
    │                                               │   │    │
④ QRIS Screen  ◄────────────────────────────────────┘   │    │
    │                                                   │    │
    │  [QRIS Paid confirmed]                            │    │
    │                                                   │    │
③ Cash Entry Screen  ◄──────────────────────────────────┘    │
    │                                                        │
    │  [Konfirmasi Pembayaran]                               │
    │                                                        │
    ▼                                                        │
⑤ Payment Success Screen  ◄──────────────────────────────────┘
    │
    ├──[WhatsApp Share]
    ├──[Print / Export PDF]
    └──[Transaksi Baru] → kembali ke Sales Screen
                       → data masuk ke History
```

---

## 3. Spesifikasi Halaman

---

### ① Payment Method Screen

**Fungsi:** Pintu masuk alur pembayaran. Menampilkan ringkasan order dan meminta operator memilih metode pembayaran sebelum melanjutkan.

**Trigger:** Tombol "Process Payment" / "Complete Sale" di Sales Screen.

#### Komponen UI

**A. Header**
- Tombol back (←) ke Sales Screen
- Label halaman: "Pilih Metode Bayar"

**B. Ringkasan Pesanan (Order Summary Card)**
- Background: `surface-container-lowest` (#ffffff), `border-radius: 14px`
- Label section: `label-sm`, uppercase, `on_surface_variant`
- Daftar item: nama item + qty + harga (maks. 3 item tampil, sisanya collapsed)
- Divider: whitespace (`spacing-4`), bukan garis
- Baris subtotal dan tax: `body-md`, warna `on_surface_variant`
- Baris total: `display-sm` bold, warna `primary` (#001e40)

**C. Pilihan Metode Pembayaran**
- Tiga kartu selectable, masing-masing: ikon + nama + deskripsi singkat
- State default: border `outline_variant` 15% opacity
- State selected: border `primary` 2px + checkmark hijau
- Kartu **Bon/Kredit**: tambahkan badge "PIUTANG" (amber) di kanan
- Desain kartu: `surface-container-lowest`, `border-radius: 14px`, padding `spacing-4`

**D. CTA Button**
- "Lanjutkan Pembayaran →"
- Gradient: `primary` (#001e40) → `primary_container` (#003366)
- Disabled state saat belum ada metode dipilih
- `border-radius: 14px`, full width

#### Logika
- Jika tidak ada metode dipilih, CTA di-disable
- Saat tap CTA, navigasi ke halaman sesuai metode yang dipilih
- Data order (items, subtotal, tax, total) diteruskan ke halaman berikutnya via state/props

---

### ② Cash Entry Screen

**Fungsi:** Operator memasukkan nominal uang yang diterima dari pelanggan. Sistem otomatis menghitung kembalian.

**Trigger:** Memilih metode "Tunai (Cash)" di Payment Method Screen.

#### Komponen UI

**A. Header**
- Tombol back ke Payment Method Screen
- Label: "Pembayaran Tunai"
- Badge status: "CASH" (biru muda)

**B. Display Total Tagihan**
- Background: `primary` (#001e40), `border-radius: 16px`
- Label "TOTAL TAGIHAN": `label-sm`, warna putih 50% opacity
- Nominal: `display-md`, warna putih, rata kanan
- Tidak bisa diubah (read-only)

**C. Input Nominal Diterima**
- Label floating: "NOMINAL YANG DITERIMA"
- Input field: background `surface-container-lowest`, border `primary` saat fokus
- Prefix `$` / `Rp` sesuai setting currency
- Nilai default: 0 (atau auto-fill ke nominal pas jika tersedia)
- Keyboard: numeric pad

**D. Display Kembalian (real-time)**
- Background: `#e8f8ee` (hijau muda)
- Label: "KEMBALIAN", warna `secondary` (#50C878) dark
- Nominal kembalian: `display-sm`, warna hijau tua
- Ikon receipt di kanan
- Update real-time setiap perubahan input
- Jika nominal kurang: tampilkan "KURANG: $X.XX" dengan warna merah

**E. Shortcut Nominal Cepat**
- 3 tombol: $20 / $50 / $100 (atau Rp 50rb / 100rb / 200rb)
- Tap otomatis mengisi input nominal
- Background `surface-container-low`, border tipis

**F. CTA Button**
- "✓ Konfirmasi Pembayaran"
- Gradient `secondary` (#50C878) → green gelap
- Disabled jika nominal kurang dari total tagihan

#### Logika
```
kembalian = nominal_diterima - total_tagihan

if nominal_diterima < total_tagihan:
    tampilkan "KURANG: $X.XX" (merah)
    disable CTA button

if nominal_diterima >= total_tagihan:
    tampilkan kembalian (hijau)
    enable CTA button

on [Konfirmasi]:
    simpan transaksi ke database
    navigasi ke Payment Success Screen
    payload: { method: "cash", received: X, change: Y }
```

---

### ③ Bon / Kredit Screen

**Fungsi:** Mencatat transaksi sebagai piutang. Operator mengisi data pelanggan dan jatuh tempo. Uang belum diterima saat ini.

**Trigger:** Memilih metode "Bon / Kredit" di Payment Method Screen.

#### Komponen UI

**A. Header**
- Tombol back ke Payment Method Screen
- Label: "Catat Bon / Piutang"
- Badge: "BON" (amber)

**B. Warning Banner**
- Background `#fff8e6`, ikon ⚠️
- Teks: "Transaksi ini akan dicatat sebagai piutang. Pembayaran belum diterima."
- Warna teks amber gelap, `body-sm`

**C. Ringkasan Total**
- Card kecil: label "Total Tagihan" + nominal `display-sm`

**D. Form Data Pelanggan**
- **Nama Pelanggan** *(required)*: text input
- **No. Telepon** *(opsional)*: numeric input, format otomatis
- **Jatuh Tempo** *(required)*: date picker
  - Shortcut cepat: tombol "7 hari" / "14 hari" / "30 hari"
  - Default: 7 hari dari sekarang
- **Catatan** *(opsional)*: textarea, placeholder "Pesanan reguler..."

**E. Styling Form**
- Label: `label-md` semi-bold, warna `on_surface_variant`
- Input: background `surface-container-lowest`, no border default
- Input fokus: ghost border `primary` 40% opacity + soft glow 2px
- Date picker: gunakan native date input, custom styling

**F. CTA Button**
- "📋 Simpan & Cetak Bon"
- Gradient `primary` → `primary_container`
- Disabled jika nama atau jatuh tempo belum diisi

#### Logika
```
validasi:
    nama_pelanggan: required, min 2 karakter
    jatuh_tempo: required, harus >= hari ini

on [Simpan & Cetak Bon]:
    simpan ke tabel piutang/bon:
        { order_id, customer_name, phone, due_date, notes, amount, status: "unpaid" }
    navigasi ke Payment Success Screen
    payload: { method: "bon", customer: X, due_date: Y }

on Payment Success:
    status transaksi di History = "Bon / Belum Lunas"
    tampil badge kuning, bukan hijau
```

---

### ④ QRIS Screen

**Fungsi:** Menampilkan QR code untuk pembayaran digital. Sistem polling status hingga terkonfirmasi lunas atau timeout.

**Trigger:** Memilih metode "QRIS" di Payment Method Screen.

#### Komponen UI

**A. Header**
- Tombol back (membatalkan QRIS sesi)
- Label: "Scan untuk Bayar"
- Badge: "QRIS"

**B. Total Display**
- Nominal besar di atas QR, `display-md`, warna `primary`

**C. QR Code Area**
- White card, padding generous, `border-radius: 16px`
- QR code: minimum 200×200px, dengan quiet zone
- Label di bawah: "Scan dengan aplikasi e-wallet atau m-banking"
- Timer countdown: "Berlaku XX:XX" — countdown dari 5 menit
- Jika timeout: tampilkan tombol "Generate Ulang QR"

**D. Status Indicator**
- State menunggu: spinner + teks "Menunggu pembayaran..."
- State sukses: ikon ✓ hijau + "QRIS Paid!" — auto-navigate ke Success Screen
- State expired: ikon ⚠ + "QR Kedaluwarsa" + tombol refresh

**E. Info Bank / NMID**
- NMID (Nomor Merchant ID) di bawah QR, `label-sm`
- Nama merchant sesuai setting

#### Logika
```
on mount:
    generate QR code dengan amount embedded
    mulai timer 5 menit
    mulai polling setiap 3 detik ke payment gateway API

polling loop:
    GET /payment/status/{transaction_id}
    
    if status == "paid":
        stop polling
        simpan transaksi
        navigasi ke Success Screen

    if status == "pending":
        lanjut polling

    if timer habis:
        stop polling
        tampilkan state "expired"

on [back button]:
    stop polling
    batalkan transaksi (atau biarkan pending)
    kembali ke Payment Method Screen
```

---

### ⑤ Payment Success Screen

**Fungsi:** Konfirmasi visual bahwa transaksi selesai. Menampilkan struk digital lengkap dan opsi distribusi (print, share, export).

**Trigger:** Konfirmasi berhasil dari Cash, QRIS, atau Bon screen.

#### Komponen UI

**A. Hero Section**
- Ikon centang dalam lingkaran `secondary` (#50C878), ukuran 64px
- Judul: "Pembayaran Berhasil!" — `headline-lg`, `on_surface`
- Sub: info metode + kembalian (khusus cash) — `body-md`, `on_surface_variant`

**B. Struk Digital (Receipt Card)**
- Background `surface-container-lowest`, `border-radius: 16px`
- Logo & nama merchant di atas
- Nomor invoice + tanggal/jam
- Daftar item: nama × qty → harga
- Subtotal, Tax, (Service charge jika ada)
- Total besar: `display-sm`, `primary`
- Khusus cash: baris "Cash diterima" + "Kembalian" (hijau)
- Khusus QRIS: label "✓ QRIS Paid"
- Khusus bon: label "📋 Dicatat sebagai Bon · Jatuh tempo: [tanggal]" (amber)

**C. Action Buttons**

| Tombol | Warna | Aksi |
|---|---|---|
| Share WhatsApp | #25D366 (WhatsApp green) | Generate pesan teks + struk |
| Print / Export PDF | Surface putih, border tipis | Print native / export PDF |

**D. Primary CTA**
- "+ Transaksi Baru"
- Gradient `primary` → `primary_container`
- Reset state, navigasi ke Sales Screen
- Data transaksi otomatis tersimpan ke History

#### Logika
```
on mount:
    simpan transaksi final ke database
    update History dengan status sesuai metode:
        cash → "Completed" (hijau)
        qris → "Completed" (hijau)
        bon  → "Bon / Belum Lunas" (amber)

on [Share WhatsApp]:
    generate teks struk yang ringkas
    buka WhatsApp dengan deeplink wa.me/?text=...

on [Print / PDF]:
    render receipt component ke PDF
    trigger print dialog atau download

on [Transaksi Baru]:
    clear cart/order state
    navigasi ke Sales Screen
```

---

## 4. Design Tokens & Panduan Visual

Seluruh halaman payment mengikuti design system **The Architectural Point of Sale**:

### Warna
| Token | Hex | Penggunaan |
|---|---|---|
| `primary` | `#001e40` | Header bar, CTA utama, total amount |
| `primary_container` | `#003366` | Gradient end untuk CTA |
| `secondary` | `#50C878` | Sukses, kembalian, QRIS confirmed, Cash CTA |
| `on_surface` | `#1a1c1f` | Semua teks body |
| `surface` | `#f9f9fe` | App canvas |
| `surface-container-low` | `#f4f3f8` | Background halaman |
| `surface-container-lowest` | `#ffffff` | Cards, input fields |
| Amber | `#fdf1e0` / `#b07000` | Badge bon/piutang, warning |
| Red | `#fce8e8` / `#cc0000` | Error state, nominal kurang |

### Tipografi
- **Total Amount:** `display-sm` atau `display-md`, letter-spacing `-0.02em`
- **Section Label:** `label-sm`, uppercase, letter-spacing `0.08em`, warna `on_surface_variant`
- **Body / Form:** `body-md`, line-height `1.5`
- **Button:** `label-lg` semi-bold, warna putih

### Shape & Spacing
- Page margin: `spacing-10` (2.25rem) horizontal
- Card radius: `14px` – `16px` (rounded-md ke rounded-lg)
- Button radius: `14px`
- Gap antar card: `spacing-3` (0.75rem)
- Tidak ada border 1px solid — gunakan tonal shift antar surface

### Shadow (hanya jika floating)
```css
box-shadow: 0 6px 40px -4px rgba(26, 28, 31, 0.06);
```

---

## 5. Integrasi dengan Halaman Existing

### Sales Screen (existing)
- Tombol "Process Payment" / "Complete Sale" → navigasi ke **① Payment Method Screen**
- Teruskan state: `{ items[], subtotal, tax, total, receipt_number }`

### History Screen (existing)
- Setelah transaksi sukses, data muncul otomatis di History
- Status badge:
  - Cash/QRIS → badge hijau "Completed"
  - Bon → badge amber "Bon · Belum Lunas"
- Receipt Detail (existing) tetap bisa dibuka dari History

### Reports Screen (existing)
- Bon yang belum lunas **tidak** dihitung di "Total Sales" harian
- Bon yang sudah lunas dihitung saat pembayaran diterima

---

## 6. Status Transaksi di History

| Metode | Status Awal | Badge | Bisa Berubah ke |
|---|---|---|---|
| Cash | Completed | 🟢 Hijau | — |
| QRIS | Completed | 🟢 Hijau | — |
| Bon | Bon · Belum Lunas | 🟡 Amber | Lunas (setelah konfirmasi bayar) |
| Bon (expired) | Jatuh Tempo | 🔴 Merah | Lunas |

---

## 7. Urutan Pengerjaan (Development Phases)

### Phase 1 — Core Payment Flow (MVP)
1. Payment Method Screen (tanpa QRIS dulu)
2. Cash Entry Screen + kalkulasi kembalian
3. Payment Success Screen
4. Integrasi ke Sales Screen & History

### Phase 2 — Bon / Piutang
5. Bon / Kredit Screen + form validasi
6. Modul tracking piutang di History
7. Notifikasi jatuh tempo

### Phase 3 — QRIS
8. QRIS Screen + QR generator
9. Integrasi payment gateway API (Midtrans / Xendit / dll)
10. Polling status real-time

### Phase 4 — Enhancement
11. Split payment (cash + QRIS sebagian)
12. Riwayat bon pelanggan
13. Export laporan piutang

---

## 8. Catatan Tambahan

- **Offline mode:** Cash dan Bon harus tetap bisa digunakan tanpa koneksi internet. QRIS memerlukan koneksi.
- **Currency:** Semua format angka mengikuti setting currency di Settings Screen (IDR / USD).
- **Receipt number:** Format `INV/YYYYMMDD/XXX` — auto-increment per hari.
- **Keamanan:** Proses konfirmasi QRIS harus divalidasi server-side, tidak hanya client polling.
- **Aksesibilitas:** Semua tombol minimal 44×44px touch target. Kembalian dibaca ulang dengan screen reader.

---

*Dokumen ini adalah panduan implementasi untuk tim design & development Precision POS. Semua komponen mengikuti design system "The Precision Atelier" yang telah ditetapkan.*
