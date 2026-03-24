# 🔄 Alur Kerja Laravel + Flutter — Precision POS

## 1. Arsitektur Keseluruhan

```
┌───────────────────────────────────────────────────────────────────┐
│                        ARSITEKTUR SISTEM                          │
│                                                                   │
│   ┌─────────────────────┐         ┌─────────────────────────┐    │
│   │   📱 FLUTTER APP     │  REST   │   🖥️ LARAVEL SERVER      │    │
│   │   (Kasir Mobile)     │◄──API──►│   (Backend + Dashboard)  │    │
│   │                      │         │                          │    │
│   │  • Offline-first     │  WS     │  • Filament Admin Panel  │    │
│   │  • sqflite local DB  │◄──────►│  • REST API v1           │    │
│   │  • UI kasir          │ Reverb  │  • MySQL Database        │    │
│   └─────────┬────────────┘         │  • Xendit Integration    │    │
│             │                      └───────────┬──────────────┘    │
│             │                                  │                   │
│             │         ┌────────────────┐       │                   │
│             └────────►│  💰 XENDIT API  │◄──────┘                   │
│              (QRIS)   │  (Payment)     │  (Webhook)               │
│                       └────────────────┘                           │
└───────────────────────────────────────────────────────────────────┘
```

### Siapa pakai apa?

| Pengguna | Aplikasi | Fungsi |
|----------|----------|--------|
| **Store Manager / Owner** | 🖥️ Laravel Filament (`/admin`) | Kelola produk, lihat laporan, monitor semua kasir |
| **Kasir** | 📱 Flutter App | Input order, proses pembayaran, lihat history |
| **Xendit** | 🔔 Webhook | Konfirmasi pembayaran QRIS otomatis |

---

## 2. User Flow — Kasir (Flutter)

### 2.1 Login & Setup

```mermaid
sequenceDiagram
    participant K as 📱 Kasir (Flutter)
    participant S as 🖥️ Server (Laravel)
    participant DB as 💾 MySQL

    Note over K: Buka app pertama kali
    K->>K: Tampilkan Login Screen
    K->>S: POST /api/v1/auth/login<br/>{email, password, device_name}
    S->>DB: Cek credentials
    DB-->>S: User valid ✅
    S->>DB: Create/Find Device record
    S->>S: Generate Sanctum Token
    S-->>K: {token, user, device, store}
    K->>K: Simpan token ke SecureStorage
    K->>K: Simpan store config (tax_rate, dll)
    K->>K: Navigate → Dashboard
```

### 2.2 Sync Produk (Pertama Kali / Refresh)

```mermaid
sequenceDiagram
    participant K as 📱 Flutter
    participant S as 🖥️ Laravel
    
    Note over K: Setelah login / buka app
    K->>S: GET /api/v1/products
    S-->>K: List semua produk aktif
    K->>K: Simpan ke sqflite lokal
    
    Note over K: Selanjutnya (sync incremental)
    K->>S: GET /api/v1/products?updated_since=2026-03-24T00:00:00
    S-->>K: Hanya produk yang berubah
    K->>K: Update sqflite lokal
```

### 2.3 Buat Transaksi (Cash)

```mermaid
sequenceDiagram
    participant K as 📱 Kasir
    participant SQ as 📂 sqflite
    participant S as 🖥️ Laravel
    participant K2 as 📱 Kasir Lain
    
    Note over K: 1. Pilih produk dari list
    K->>SQ: Baca data produk lokal
    SQ-->>K: Produk + harga + stok
    
    Note over K: 2. Atur qty, pilih metode bayar
    K->>K: Hitung subtotal, tax, total
    K->>K: Input nominal bayar → hitung kembalian
    
    Note over K: 3. Konfirmasi pembayaran
    
    alt 📶 ONLINE
        K->>S: POST /api/v1/transactions<br/>{items, payment_method: "cash", ...}
        S->>S: Save order + reduce stock
        S->>S: Broadcast TransactionCreated event
        S-->>K: {receipt_number, status: "completed"}
        S-->>K2: 📡 WebSocket: new transaction
    else 📴 OFFLINE
        K->>SQ: Simpan transaksi lokal (sync_status: pending)
        K->>K: Tampilkan success (offline mode)
        Note over K: Nanti saat online → bulk sync
    end
    
    K->>K: Navigate → Payment Success Screen
    K->>K: Tampilkan resi digital
```

### 2.4 Pembayaran QRIS

```mermaid
sequenceDiagram
    participant K as 📱 Kasir
    participant S as 🖥️ Laravel
    participant X as 💳 Xendit
    participant C as 👤 Customer

    K->>S: POST /api/v1/payments/qris/create<br/>{receipt_number, amount}
    S->>X: POST /v2/invoices (create invoice)
    X-->>S: {invoice_id, qr_string, invoice_url}
    S->>S: Save XenditPayment (PENDING)
    S-->>K: {qr_string, expires_at}
    
    K->>K: Tampilkan QR Code di layar
    K->>K: Connect WebSocket → channel "payment.{receipt}"
    
    Note over C: Customer scan QR & bayar
    C->>X: Scan QR → Bayar via e-wallet/bank
    X->>S: POST /webhook/xendit {status: "PAID"}
    S->>S: Update payment → PAID
    S->>S: Update order → completed
    S->>S: Reduce stock
    S->>S: Broadcast QrisPaymentConfirmed
    S-->>K: 📡 WebSocket: "qris_paid" ✅
    
    K->>K: Auto-navigate → Payment Success! 🎉
```

### 2.5 Transaksi Bon/Kredit

```mermaid
sequenceDiagram
    participant K as 📱 Kasir
    participant S as 🖥️ Laravel
    
    K->>K: Pilih metode: Bon/Kredit
    K->>K: Isi: nama customer, no HP, jatuh tempo
    K->>S: POST /api/v1/transactions<br/>{payment_method: "bon", customer_name, due_date}
    S->>S: Save order (status: "pending")
    S->>S: Stok BELUM dikurangi
    S-->>K: {receipt_number, status: "pending"}
    K->>K: Tampilkan nota kredit
    
    Note over K: === Suatu hari, customer bayar ===
    
    K->>S: PUT /api/v1/transactions/{receipt}/pay-bon
    S->>S: Update status → "completed"
    S->>S: Kurangi stok SEKARANG
    S-->>K: {message: "Bon marked as paid"}
```

### 2.6 Sync Offline → Online

```mermaid
sequenceDiagram
    participant K as 📱 Flutter
    participant SQ as 📂 sqflite
    participant S as 🖥️ Laravel

    Note over K: App detect koneksi kembali online
    K->>SQ: Query transaksi dengan sync_status = "pending"
    SQ-->>K: [{order1}, {order2}, {order3}]
    
    K->>S: POST /api/v1/sync/upload<br/>{device_id, orders: [...]}
    S->>S: Loop: skip duplicate, save baru
    S->>S: Reduce stock per order
    S->>S: Log sync activity
    S-->>K: {synced: 3, failed: 0, server_time: "..."}
    
    K->>SQ: Update sync_status → "synced"
    
    Note over K: Download data baru dari server
    K->>S: GET /api/v1/sync/download?since=last_sync_time
    S-->>K: {products: [...], orders: [...]}
    K->>SQ: Update produk & transaksi lokal
```

---

## 3. User Flow — Store Manager (Filament Dashboard)

```mermaid
flowchart TD
    A["🔑 Login Filament<br/>/admin/login"] --> B["📊 Dashboard"]
    
    B --> C["📈 Sales Overview Widget<br/>Total hari ini, orders, avg ticket"]
    B --> D["📉 Hourly Performance Chart<br/>Bar chart per jam"]
    B --> E["🔴 Live Transaction Feed<br/>Real-time via WebSocket"]
    B --> F["⚠️ Low Stock Alert<br/>Produk hampir habis"]
    
    B --> G["📦 Kelola Produk<br/>CRUD produk + kategori"]
    B --> H["🧾 Lihat Semua Order<br/>Filter, search, detail"]
    B --> I["💰 Xendit Payment<br/>Generate QRIS dari dashboard"]
    
    H --> J["Void Order<br/>Restore stok"]
    H --> K["Lihat Detail + Print"]
    
    style E fill:#ff6b6b,color:white
    style F fill:#ffa502,color:white
```

---

## 4. Diagram Alur Data Lengkap

```mermaid
flowchart LR
    subgraph Flutter["📱 Flutter App"]
        F1["Login"] --> F2["Sync Products"]
        F2 --> F3["Order Input"]
        F3 --> F4{"Payment Method?"}
        F4 -->|Cash| F5["Cash Entry"]
        F4 -->|QRIS| F6["QR Code Screen"]
        F4 -->|Bon| F7["Bon/Kredit Form"]
        F5 --> F8["Success Screen"]
        F6 --> F8
        F7 --> F8
        F8 --> F9["History / Dashboard"]
    end
    
    subgraph API["🔌 REST API v1"]
        A1["POST /auth/login"]
        A2["GET /products"]
        A3["POST /transactions"]
        A4["POST /payments/qris/create"]
        A5["GET /analytics/*"]
        A6["POST /sync/upload"]
    end
    
    subgraph Laravel["🖥️ Laravel Server"]
        L1["Sanctum Auth"]
        L2["MySQL DB"]
        L3["Events + Reverb"]
        L4["Filament Dashboard"]
    end
    
    subgraph Xendit["💳 Xendit"]
        X1["Create Invoice"]
        X2["Webhook Callback"]
    end
    
    F1 -.->|REST| A1
    F2 -.->|REST| A2
    F3 -.->|REST| A3
    F6 -.->|REST| A4
    F9 -.->|REST| A5
    
    A1 --> L1
    A2 --> L2
    A3 --> L2
    A4 --> X1
    X2 --> L2
    L3 -.->|WebSocket| F6
    L3 -.->|WebSocket| F9
    L2 --> L4
```

---

## 5. Tabel Mapping: Screen Flutter ↔ API Endpoint

| Flutter Screen | API Endpoint | Method | Kapan Dipanggil |
|----------------|-------------|--------|-----------------|
| **Login** | `/auth/login` | POST | Saat user login |
| **Dashboard** | `/analytics/daily` | GET | Saat buka dashboard |
| **Dashboard** | `/analytics/top-products` | GET | Widget top produk |
| **Order Input** | `/products` | GET | Load list produk |
| **Cash Entry** | `/transactions` | POST | Konfirmasi bayar cash |
| **QRIS Screen** | `/payments/qris/create` | POST | Generate QR code |
| **QRIS Screen** | WebSocket `payment.{id}` | WS | Listen konfirmasi bayar |
| **Bon/Kredit** | `/transactions` | POST | Simpan bon |
| **History** | `/transactions` | GET | Load riwayat transaksi |
| **History** | `/transactions/{id}/void` | PUT | Void transaksi |
| **History** | `/transactions/{id}/pay-bon` | PUT | Bayar bon |
| **Daily Report** | `/analytics/daily` | GET | Ringkasan harian |
| **Daily Report** | `/analytics/hourly` | GET | Grafik per jam |
| **Settings** | `/auth/me` | GET | Info user + store |
| **Background** | `/sync/upload` | POST | Sync offline → server |
| **Background** | `/sync/download` | GET | Sync server → lokal |

---

## 6. Offline-First Strategy

```
┌──────────────────────────────────────────────────┐
│                 OFFLINE-FIRST FLOW                │
│                                                    │
│  📶 ONLINE MODE                                   │
│  ┌───────────┐    REST API    ┌──────────────┐   │
│  │  Flutter   │──────────────►│  Laravel API  │   │
│  │  App       │◄──────────────│  (MySQL)      │   │
│  └─────┬─────┘               └──────────────┘   │
│        │                                          │
│        ▼                                          │
│  ┌───────────┐                                    │
│  │  sqflite   │  ← Cache produk & transaksi       │
│  │  (lokal)   │                                    │
│  └───────────┘                                    │
│                                                    │
│  📴 OFFLINE MODE                                  │
│  ┌───────────┐         ❌ No Internet              │
│  │  Flutter   │──────X──────                      │
│  │  App       │                                   │
│  └─────┬─────┘                                    │
│        │                                          │
│        ▼                                          │
│  ┌───────────┐                                    │
│  │  sqflite   │  ← Simpan transaksi offline       │
│  │  (lokal)   │    sync_status = "pending"         │
│  └───────────┘                                    │
│        │                                          │
│        │  Saat online kembali...                   │
│        ▼                                          │
│  POST /sync/upload → Bulk kirim ke server         │
└──────────────────────────────────────────────────┘
```

### Rules Offline:
1. **Produk** → selalu dibaca dari sqflite lokal (di-sync periodik)
2. **Transaksi Cash & Bon** → bisa disimpan offline, sync nanti
3. **Transaksi QRIS** → ❌ TIDAK bisa offline (butuh Xendit API)
4. **Stok** → dikurangi di lokal dulu, server adjust saat sync
5. **Konflik** → Server selalu menang (server as source of truth)
