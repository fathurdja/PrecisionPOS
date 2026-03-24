# 📘 Precision POS — API v1 Documentation (Postman)

**Base URL:** `http://localhost:8000/api/v1`  
**Auth:** Bearer Token (Laravel Sanctum)  
**Content-Type:** `application/json`

---

## 🔐 1. Auth

### POST `/auth/login`

> **Auth:** None (Public)

**Request Body:**
```json
{
  "email": "admin@example.com",
  "password": "password",
  "device_name": "Samsung A54",
  "platform": "android"
}
```

**Response 200:**
```json
{
  "token": "1|abc123def456ghi789...",
  "user": {
    "id": 1,
    "name": "Admin",
    "email": "admin@example.com",
    "role": "admin"
  },
  "device": {
    "id": 1,
    "device_name": "Samsung A54",
    "platform": "android"
  },
  "store": {
    "name": "Toko Precision",
    "address": "Jl. Contoh No. 1",
    "phone": "08123456789",
    "tax_rate": 11.00,
    "currency": "IDR",
    "store_code": "STORE-A"
  }
}
```

**Response 422 (Invalid Credentials):**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The provided credentials are incorrect."]
  }
}
```

---

### POST `/auth/logout`

> **Auth:** Bearer Token ✅

**Headers:**
```
Authorization: Bearer 1|abc123def456ghi789...
```

**Request Body:** _(empty)_

**Response 200:**
```json
{
  "message": "Logged out successfully"
}
```

---

### GET `/auth/me`

> **Auth:** Bearer Token ✅

**Response 200:**
```json
{
  "user": {
    "id": 1,
    "name": "Admin",
    "email": "admin@example.com",
    "role": "admin"
  },
  "store": {
    "name": "Toko Precision",
    "address": "Jl. Contoh No. 1",
    "phone": "08123456789",
    "tax_rate": 11.00,
    "currency": "IDR",
    "store_code": "STORE-A"
  }
}
```

---

### POST `/auth/register-device`

> **Auth:** Bearer Token ✅

**Request Body:**
```json
{
  "device_name": "iPad Kasir 2",
  "platform": "ios"
}
```

**Response 201:**
```json
{
  "message": "Device registered successfully",
  "device": {
    "id": 2,
    "user_id": 1,
    "device_name": "iPad Kasir 2",
    "platform": "ios",
    "is_active": true,
    "updated_at": "2026-03-24T23:30:00.000000Z",
    "created_at": "2026-03-24T23:30:00.000000Z"
  }
}
```

---

## 📦 2. Products

### GET `/products`

> **Auth:** Bearer Token ✅

**Query Parameters (optional):**
| Param | Type | Deskripsi |
|-------|------|-----------|
| `updated_since` | ISO8601 | Hanya produk yang diupdate setelah timestamp ini (untuk sync) |
| `category_id` | UUID | Filter by kategori |
| `search` | string | Cari berdasarkan nama |

**Contoh:** `GET /api/v1/products?search=kopi&category_id=xxx`

**Response 200:**
```json
{
  "data": [
    {
      "id": "9f1a2b3c-4d5e-6f7a-8b9c-0d1e2f3a4b5c",
      "name": "Espresso",
      "description": "Espresso shot single",
      "barcode": "8991234567890",
      "purchase_price": 8000.00,
      "price": 25000.00,
      "is_active": true,
      "image": null,
      "current_stock": 50,
      "category": {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "name": "Minuman"
      },
      "variants": [
        {
          "id": "v1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
          "name": "Large",
          "sku": "ESP-L",
          "additional_price": 5000.00
        }
      ],
      "created_at": "2026-03-20T10:00:00+08:00",
      "updated_at": "2026-03-24T15:30:00+08:00"
    }
  ]
}
```

---

### POST `/products`

> **Auth:** Bearer Token ✅ (Admin only)

**Request Body:**
```json
{
  "name": "Cafe Latte",
  "category_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "description": "Latte dengan susu segar",
  "barcode": "8991234567891",
  "purchase_price": 12000,
  "price": 35000,
  "is_active": true
}
```

**Response 201:**
```json
{
  "message": "Product created successfully",
  "data": {
    "id": "new-uuid-here",
    "name": "Cafe Latte",
    "price": 35000.00,
    "purchase_price": 12000.00,
    "current_stock": 0,
    "..."
  }
}
```

---

### PUT `/products/{product_id}`

> **Auth:** Bearer Token ✅ (Admin only)

**Contoh:** `PUT /api/v1/products/9f1a2b3c-4d5e-6f7a-8b9c-0d1e2f3a4b5c`

**Request Body:**
```json
{
  "name": "Espresso Double",
  "price": 30000
}
```

**Response 200:**
```json
{
  "message": "Product updated successfully",
  "data": { "..." }
}
```

---

### DELETE `/products/{product_id}`

> **Auth:** Bearer Token ✅ (Admin only)

**Response 200:**
```json
{
  "message": "Product deleted successfully"
}
```

---

## 💳 3. Transactions

### GET `/transactions`

> **Auth:** Bearer Token ✅

**Query Parameters:**
| Param | Type | Deskripsi |
|-------|------|-----------|
| `date` | YYYY-MM-DD | Filter tanggal spesifik |
| `from` | YYYY-MM-DD | Tanggal mulai range |
| `to` | YYYY-MM-DD | Tanggal akhir range |
| `status` | string | `pending`, `completed`, `canceled` |
| `payment_method` | string | `cash`, `qris`, `bon` |
| `per_page` | integer | Jumlah per halaman (default: 20) |

**Contoh:** `GET /api/v1/transactions?date=2026-03-24&status=completed`

**Response 200:**
```json
{
  "data": [
    {
      "id": "order-uuid-here",
      "receipt_number": "INV-20260324-A1B2",
      "status": "completed",
      "order_type": "take-away",
      "payment_method": "cash",
      "total_price": 64800.00,
      "tax_amount": 4800.00,
      "discount_amount": 0.00,
      "received_amount": 100000.00,
      "change_amount": 35200.00,
      "customer_name": null,
      "customer_phone": null,
      "due_date": null,
      "notes": null,
      "items": [
        {
          "id": "item-uuid",
          "product_id": "product-uuid",
          "product_name": "Espresso",
          "variant_id": null,
          "quantity": 1,
          "bonus_qty": 0,
          "unit_price": 25000.00,
          "subtotal": 25000.00
        },
        {
          "id": "item-uuid-2",
          "product_id": "product-uuid-2",
          "product_name": "Cafe Latte",
          "variant_id": null,
          "quantity": 1,
          "bonus_qty": 0,
          "unit_price": 35000.00,
          "subtotal": 35000.00
        }
      ],
      "xendit_status": null,
      "created_at": "2026-03-24T08:30:00+08:00",
      "updated_at": "2026-03-24T08:30:00+08:00"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 20,
    "total": 55
  }
}
```

---

### GET `/transactions/{receipt_number}`

> **Auth:** Bearer Token ✅

**Contoh:** `GET /api/v1/transactions/INV-20260324-A1B2`

**Response 200:**
```json
{
  "data": {
    "id": "order-uuid",
    "receipt_number": "INV-20260324-A1B2",
    "status": "completed",
    "payment_method": "cash",
    "total_price": 64800.00,
    "items": [ "..." ],
    "..."
  }
}
```

---

### POST `/transactions`

> **Auth:** Bearer Token ✅

**Request Body (Cash Payment):**
```json
{
  "order_type": "take-away",
  "payment_method": "cash",
  "total_price": 64800,
  "tax_amount": 4800,
  "discount_amount": 0,
  "received_amount": 100000,
  "change_amount": 35200,
  "items": [
    {
      "product_id": "9f1a2b3c-4d5e-6f7a-8b9c-0d1e2f3a4b5c",
      "quantity": 2,
      "bonus_qty": 0,
      "unit_price": 25000,
      "subtotal": 50000
    },
    {
      "product_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "quantity": 1,
      "bonus_qty": 1,
      "unit_price": 10000,
      "subtotal": 10000
    }
  ]
}
```

**Request Body (Bon/Kredit):**
```json
{
  "order_type": "take-away",
  "payment_method": "bon",
  "total_price": 150000,
  "tax_amount": 11000,
  "discount_amount": 0,
  "customer_name": "Pak Budi",
  "customer_phone": "081234567890",
  "due_date": "2026-04-07",
  "notes": "Ambil barang untuk warung",
  "items": [
    {
      "product_id": "product-uuid",
      "quantity": 5,
      "bonus_qty": 0,
      "unit_price": 30000,
      "subtotal": 150000
    }
  ]
}
```

**Response 201:**
```json
{
  "message": "Transaction created successfully",
  "data": {
    "id": "generated-uuid",
    "receipt_number": "INV-20260324-X9Y2",
    "status": "completed",
    "payment_method": "cash",
    "total_price": 64800.00,
    "items": [ "..." ],
    "..."
  }
}
```

---

### PUT `/transactions/{receipt_number}/void`

> **Auth:** Bearer Token ✅

**Contoh:** `PUT /api/v1/transactions/INV-20260324-A1B2/void`

**Request Body:** _(empty)_

**Response 200:**
```json
{
  "message": "Transaction voided successfully"
}
```

**Response 422 (Already voided):**
```json
{
  "message": "Transaction already voided"
}
```

---

### PUT `/transactions/{receipt_number}/pay-bon`

> **Auth:** Bearer Token ✅

**Contoh:** `PUT /api/v1/transactions/INV-20260324-B3C4/pay-bon`

**Request Body:** _(empty)_

**Response 200:**
```json
{
  "message": "Bon marked as paid successfully"
}
```

---

## 🔄 4. Sync

### POST `/sync/upload`

> **Auth:** Bearer Token ✅

**Request Body:**
```json
{
  "device_id": 1,
  "orders": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "receipt_number": "INV-20260324-0001",
      "status": "completed",
      "order_type": "take-away",
      "total_price": 60000,
      "tax_amount": 4800,
      "discount_amount": 0,
      "payment_method": "cash",
      "received_amount": 100000,
      "change_amount": 40000,
      "created_at": "2026-03-24T08:30:00+08:00",
      "items": [
        {
          "id": "660e8400-e29b-41d4-a716-446655440001",
          "product_id": "product-uuid-here",
          "product_name": "Espresso",
          "quantity": 1,
          "bonus_qty": 0,
          "unit_price": 25000,
          "subtotal": 25000
        },
        {
          "id": "660e8400-e29b-41d4-a716-446655440002",
          "product_id": "product-uuid-2",
          "product_name": "Cafe Latte",
          "quantity": 1,
          "bonus_qty": 0,
          "unit_price": 35000,
          "subtotal": 35000
        }
      ]
    }
  ]
}
```

**Response 200:**
```json
{
  "synced": 1,
  "failed": 0,
  "errors": [],
  "server_time": "2026-03-24T08:35:00+08:00"
}
```

**Response 200 (Partial):**
```json
{
  "synced": 3,
  "failed": 1,
  "errors": [
    {
      "receipt_number": "INV-20260324-0004",
      "error": "Integrity constraint violation: product_id not found"
    }
  ],
  "server_time": "2026-03-24T08:35:00+08:00"
}
```

---

### GET `/sync/download`

> **Auth:** Bearer Token ✅

**Query Parameters:**
| Param | Type | Deskripsi |
|-------|------|-----------|
| `since` | ISO8601 | Download data yang berubah sejak timestamp |
| `device_id` | integer | ID device untuk update last_synced_at |

**Contoh:** `GET /api/v1/sync/download?since=2026-03-24T00:00:00+08:00&device_id=1`

**Response 200:**
```json
{
  "products": [
    {
      "id": "product-uuid",
      "name": "Espresso",
      "price": 25000.00,
      "is_active": true,
      "..."
    }
  ],
  "orders": [
    {
      "id": "order-uuid",
      "receipt_number": "INV-20260324-0001",
      "..."
    }
  ],
  "server_time": "2026-03-24T15:30:00+08:00"
}
```

---

### GET `/sync/status`

> **Auth:** Bearer Token ✅

**Query Parameters:**
| Param | Type | Required |
|-------|------|----------|
| `device_id` | integer | ✅ |

**Contoh:** `GET /api/v1/sync/status?device_id=1`

**Response 200:**
```json
{
  "device_id": 1,
  "device_name": "Samsung A54",
  "last_synced_at": "2026-03-24T15:30:00+08:00",
  "recent_logs": [
    {
      "id": 1,
      "direction": "upload",
      "records_synced": 5,
      "status": "success",
      "error_message": null,
      "created_at": "2026-03-24T15:30:00.000000Z"
    }
  ],
  "server_time": "2026-03-24T16:00:00+08:00"
}
```

---

## 📊 5. Analytics

### GET `/analytics/daily`

> **Auth:** Bearer Token ✅

**Query Parameters:**
| Param | Type | Default |
|-------|------|---------|
| `date` | YYYY-MM-DD | Hari ini |

**Contoh:** `GET /api/v1/analytics/daily?date=2026-03-24`

**Response 200:**
```json
{
  "date": "2026-03-24",
  "total_sales": 4820500.00,
  "total_orders": 142,
  "items_sold": 432,
  "avg_ticket": 33948.00,
  "total_tax": 385640.00,
  "payment_breakdown": {
    "cash": { "count": 95, "total": 3200000.00 },
    "qris": { "count": 38, "total": 1320500.00 },
    "bon":  { "count": 9,  "total": 300000.00 }
  },
  "comparison_yesterday": {
    "sales_change_pct": 12.5
  }
}
```

---

### GET `/analytics/hourly`

> **Auth:** Bearer Token ✅

**Query Parameters:**
| Param | Type | Default |
|-------|------|---------|
| `date` | YYYY-MM-DD | Hari ini |

**Response 200:**
```json
{
  "date": "2026-03-24",
  "data": [
    { "hour": 8,  "label": "08:00", "orders": 5,  "sales": 250000.00 },
    { "hour": 9,  "label": "09:00", "orders": 12, "sales": 480000.00 },
    { "hour": 10, "label": "10:00", "orders": 18, "sales": 720000.00 },
    { "hour": 11, "label": "11:00", "orders": 22, "sales": 880000.00 },
    { "hour": 12, "label": "12:00", "orders": 30, "sales": 1200000.00 }
  ]
}
```

---

### GET `/analytics/summary`

> **Auth:** Bearer Token ✅

**Query Parameters:**
| Param | Type | Default |
|-------|------|---------|
| `period` | `week` \| `month` | `week` |

**Contoh:** `GET /api/v1/analytics/summary?period=month`

**Response 200:**
```json
{
  "period": "month",
  "start_date": "2026-03-01",
  "end_date": "2026-03-24",
  "total_sales": 85000000.00,
  "total_orders": 2450,
  "avg_ticket": 34693.88,
  "daily_data": [
    { "date": "2026-03-01", "orders": 120, "sales": 4200000.00 },
    { "date": "2026-03-02", "orders": 95,  "sales": 3100000.00 },
    "..."
  ]
}
```

---

### GET `/analytics/top-products`

> **Auth:** Bearer Token ✅

**Query Parameters:**
| Param | Type | Default |
|-------|------|---------|
| `limit` | integer | 10 |
| `date` | YYYY-MM-DD | Semua waktu |

**Contoh:** `GET /api/v1/analytics/top-products?limit=5&date=2026-03-24`

**Response 200:**
```json
{
  "data": [
    { "product_id": "uuid-1", "product_name": "Espresso",    "total_qty": 85, "total_revenue": 2125000.00 },
    { "product_id": "uuid-2", "product_name": "Cafe Latte",  "total_qty": 72, "total_revenue": 2520000.00 },
    { "product_id": "uuid-3", "product_name": "Cappuccino",  "total_qty": 60, "total_revenue": 1800000.00 },
    { "product_id": "uuid-4", "product_name": "Green Tea",   "total_qty": 45, "total_revenue": 1125000.00 },
    { "product_id": "uuid-5", "product_name": "Americano",   "total_qty": 38, "total_revenue": 760000.00 }
  ]
}
```

---

### GET `/analytics/bon-report`

> **Auth:** Bearer Token ✅

**Response 200:**
```json
{
  "total_outstanding": 2500000.00,
  "count": 8,
  "data": [
    {
      "receipt_number": "INV-20260320-B1C2",
      "customer_name": "Pak Budi",
      "customer_phone": "081234567890",
      "total_price": 500000.00,
      "due_date": "2026-04-03",
      "created_at": "2026-03-20T14:30:00+08:00",
      "is_overdue": false,
      "items_count": 3
    },
    {
      "receipt_number": "INV-20260315-D5E6",
      "customer_name": "Bu Sari",
      "customer_phone": "087654321098",
      "total_price": 750000.00,
      "due_date": "2026-03-22",
      "created_at": "2026-03-15T09:00:00+08:00",
      "is_overdue": true,
      "items_count": 5
    }
  ]
}
```

---

## 💰 6. QRIS Payment (Xendit)

### POST `/payments/qris/create`

> **Auth:** Bearer Token ✅

**Request Body:**
```json
{
  "receipt_number": "INV-20260324-A1B2",
  "amount": 64800,
  "description": "Order INV-20260324-A1B2 — 2 items"
}
```

**Response 200:**
```json
{
  "xendit_invoice_id": "inv_xnd_abc123",
  "qr_string": "00020101021226680014ID.CO.XENDIT...",
  "invoice_url": "https://checkout.xendit.co/web/inv_xnd_abc123",
  "expires_at": "2026-03-24T09:00:00+08:00",
  "status": "PENDING"
}
```

---

### GET `/payments/qris/{receipt_number}/status`

> **Auth:** Bearer Token ✅

**Contoh:** `GET /api/v1/payments/qris/INV-20260324-A1B2/status`

**Response 200:**
```json
{
  "receipt_number": "INV-20260324-A1B2",
  "xendit_invoice_id": "inv_xnd_abc123",
  "status": "PAID",
  "paid_at": "2026-03-24T08:55:30+08:00",
  "expires_at": "2026-03-24T09:00:00+08:00",
  "amount": 64800.00
}
```

---

## 🚚 7. Delivery

### POST `/delivery/start-shift`

> **Auth:** Bearer Token ✅ (role: delivery)

**Request Body:** _(empty)_

**Response 201:**
```json
{
  "message": "Shift delivery dimulai",
  "data": {
    "id": 1,
    "date": "2026-03-25",
    "status": "active",
    "started_at": "08:00:00",
    "ended_at": null,
    "total_orders": 0,
    "total_sales": 0.00,
    "total_collected": 0.00
  }
}
```

---

### POST `/delivery/end-shift`

> **Auth:** Bearer Token ✅ (role: delivery)

**Request Body:**
```json
{
  "notes": "Semua barang diantar, 2 retur ke gudang"
}
```

**Response 200:**
```json
{
  "message": "Shift delivery selesai",
  "data": {
    "id": 1,
    "date": "2026-03-25",
    "status": "completed",
    "started_at": "08:00:00",
    "ended_at": "16:30:00",
    "total_orders": 12,
    "total_sales": 1850000.00,
    "total_collected": 1200000.00
  }
}
```

---

### GET `/delivery/my-orders`

> **Auth:** Bearer Token ✅ (role: delivery)

**Query Parameters:**
| Param | Type | Default |
|-------|------|---------|
| `date` | YYYY-MM-DD | Hari ini |

**Contoh:** `GET /api/v1/delivery/my-orders?date=2026-03-25`

**Response 200:**
```json
{
  "date": "2026-03-25",
  "summary": {
    "total_orders": 5,
    "completed_orders": 3,
    "total_sales": 850000.00,
    "pending_orders": 1,
    "on_the_way": 1,
    "delivered": 3
  },
  "orders": [
    {
      "id": "order-uuid",
      "receipt_number": "INV-20260325-D1A2",
      "status": "completed",
      "total_price": 250000.00,
      "payment_method": "cash",
      "delivery_address": "Jl. Merdeka No. 10, RT 02",
      "delivery_status": "delivered",
      "customer_name": "Pak Agus",
      "customer_phone": "081234567890",
      "items_count": 3,
      "created_at": "2026-03-25T08:30:00+08:00"
    }
  ]
}
```

---

### PUT `/delivery/orders/{receipt_number}/status`

> **Auth:** Bearer Token ✅ (role: delivery)

**Contoh:** `PUT /api/v1/delivery/orders/INV-20260325-D1A2/status`

**Request Body:**
```json
{
  "delivery_status": "delivered"
}
```

**Values:** `pending`, `on_the_way`, `delivered`, `returned`

**Response 200:**
```json
{
  "message": "Status delivery diperbarui",
  "delivery_status": "delivered"
}
```

---

### GET `/delivery/performance`

> **Auth:** Bearer Token ✅ (role: delivery)

**Query Parameters:**
| Param | Type | Default |
|-------|------|---------|
| `period` | `today` \| `week` \| `month` | `today` |

**Contoh:** `GET /api/v1/delivery/performance?period=week`

**Response 200:**
```json
{
  "period": "week",
  "total_shifts": 5,
  "completed_shifts": 4,
  "total_orders": 48,
  "total_sales": 7250000.00,
  "total_collected": 5800000.00,
  "avg_orders_per_shift": 12.0,
  "bon_outstanding": 450000.00
}
```

---

## 📦 8. Stock Report

### GET `/stock-report/daily`

> **Auth:** Bearer Token ✅

**Query Parameters:**
| Param | Type | Default |
|-------|------|---------|
| `date` | YYYY-MM-DD | Hari ini |

**Contoh:** `GET /api/v1/stock-report/daily?date=2026-03-25`

**Response 200:**
```json
{
  "date": "2026-03-25",
  "source": "live",
  "data": [
    {
      "product_id": "product-uuid-1",
      "product_name": "Espresso",
      "opening_stock": 100,
      "closing_stock": 85,
      "sold_qty": 20,
      "added_qty": 5,
      "bonus_qty": 0,
      "net_change": -15
    },
    {
      "product_id": "product-uuid-2",
      "product_name": "Cafe Latte",
      "opening_stock": 50,
      "closing_stock": 38,
      "sold_qty": 12,
      "added_qty": 0,
      "bonus_qty": 0,
      "net_change": -12
    }
  ]
}
```

> **Note:** `source` bisa `"snapshot"` (data dari artisan command) atau `"live"` (kalkulasi real-time)

---

## 🔔 9. Webhook (Public)

### POST `/webhook/xendit`

> **Auth:** None — validated via `x-callback-token` header

**Headers:**
```
x-callback-token: your-xendit-callback-token
Content-Type: application/json
```

**Request Body (dari Xendit otomatis):**
```json
{
  "id": "inv_xnd_abc123",
  "external_id": "order-uuid-here",
  "status": "PAID",
  "amount": 64800,
  "paid_at": "2026-03-24T08:55:30+08:00",
  "payment_method": "QR_CODE",
  "payment_channel": "QRIS"
}
```

**Response 200:**
```json
{
  "message": "success"
}
```

---

## 🔑 Postman Setup Guide

### 1. Environment Variables
Buat environment di Postman:

| Variable | Value |
|----------|-------|
| `base_url` | `http://localhost:8000/api/v1` |
| `token` | _(kosong, di-set otomatis dari login)_ |

### 2. Auto-Set Token dari Login
Di tab **Tests** dari request Login, tambahkan script:

```javascript
if (pm.response.code === 200) {
    var json = pm.response.json();
    pm.environment.set("token", json.token);
}
```

### 3. Auth Header untuk semua request
Di setiap request yang perlu auth, set:
- **Auth Type:** Bearer Token
- **Token:** `{{token}}`

### 4. Collection Order Testing

**Kasir Flow:**
1. `POST /auth/login` → dapatkan token (role: kasir)
2. `GET /products` → lihat produk
3. `POST /transactions` → buat transaksi cash
4. `GET /transactions` → lihat list transaksi
5. `GET /analytics/daily` → lihat laporan harian
6. `PUT /transactions/{receipt}/void` → void transaksi
7. `POST /transactions` → buat transaksi bon
8. `PUT /transactions/{receipt}/pay-bon` → bayar bon
9. `POST /sync/upload` → test bulk sync
10. `POST /auth/logout` → logout

**Delivery Flow:**
1. `POST /auth/login` → login (role: delivery)
2. `POST /delivery/start-shift` → mulai shift delivery
3. `POST /transactions` → buat order delivery (with `delivery_user_id`, `delivery_address`)
4. `GET /delivery/my-orders` → lihat order saya hari ini
5. `PUT /delivery/orders/{receipt}/status` → update status → `on_the_way`
6. `PUT /delivery/orders/{receipt}/status` → update status → `delivered`
7. `GET /delivery/performance` → lihat performa
8. `POST /delivery/end-shift` → akhiri shift

**Stock Report:**
1. `GET /stock-report/daily` → lihat stok awal vs akhir hari ini

---

## ⚠️ Error Responses

### 401 Unauthorized
```json
{
  "message": "Unauthenticated."
}
```

### 404 Not Found
```json
{
  "message": "No query results for model [App\\Models\\Order]."
}
```

### 422 Validation Error
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email field is required."],
    "password": ["The password field is required."]
  }
}
```

### 500 Server Error
```json
{
  "message": "Failed to create transaction",
  "error": "SQLSTATE[23000]: Integrity constraint violation..."
}
```
