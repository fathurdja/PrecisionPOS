# SAPI Smart AI POS & Inventory - API Documentation

## Overview
This API uses **Laravel Sanctum** for authentication. Most endpoints require a `Bearer {token}` in the `Authorization` header.

Base URL: `http://{your-domain}/api`

---

## 1. Authentication (Mobile App)

### Login
- **Endpoint**: `POST /mobile/login`
- **Description**: Authenticate user and get a Bearer token.
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "yourpassword"
  }
  ```
- **Response**:
  ```json
  {
    "token": "...",
    "user": { "id": 1, "name": "...", "role": "..." },
    "tenant": { "id": 1, "name": "..." }
  }
  ```

### Logout
- **Endpoint**: `POST /mobile/logout`
- **Auth**: Required
- **Response**: `{"message": "Logout berhasil."}`

---

## 2. Self-Order (AI / External Integration)

### List Products
- **Endpoint**: `GET /products`
- **Auth**: Required
- **Description**: Get all active products with variants that have stock > 0. Used for AI context.
- **Response**:
  ```json
  {
    "data": [
      {
        "id": 1,
        "name": "Kopi Susu",
        "category": { "name": "Drink" },
        "variants": [
          { "id": 1, "name": "Normal", "price": 15000, "stock": 10 }
        ]
      }
    ]
  }
  ```

### Create Order
- **Endpoint**: `POST /orders`
- **Auth**: Required
- **Description**: Create a new self-order. Generates a Xendit invoice.
- **Request Body**:
  ```json
  {
    "items": [
      {
        "variant_id": 1,
        "variant_name": "Normal",
        "qty": 2,
        "modifiers": []
      }
    ],
    "customer_name": "Budi",
    "order_type": "dine_in",
    "table_number": "A1"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "transaction_code": "TRX-...",
    "invoice_url": "https://...",
    "total_amount": 30000
  }
  ```

### Update Fulfillment
- **Endpoint**: `PATCH /orders/{transaction_id}/fulfillment`
- **Auth**: Required
- **Description**: Advance order status: `waiting` → `preparing` → `ready` → `done`.

---

## 3. Mobile POS (In-Store)

### Tenant Profile
- **Endpoint**: `GET /mobile/tenant/profile`
- **Auth**: Required

### Checkout (Store Transaction)
- **Endpoint**: `POST /mobile/transactions`
- **Auth**: Required
- **Description**: Process a direct sale at the POS.
- **Request Body**:
  ```json
  {
    "items": [...],
    "payments": [
      { "payment_method_id": 1, "amount": 50000 }
    ],
    "order_type": "takeaway"
  }
  ```

### Get Receipt
- **Endpoint**: `GET /mobile/transactions/{id}/receipt`
- **Auth**: Required
- **Description**: Returns formatted data for printing receipts.

---

## 4. Webhooks

### Xendit Webhook
- **Endpoint**: `POST /xendit/webhook`
- **Auth**: Verifikasi via `x-callback-token` header.
- **Description**: Handles payment confirmation from Xendit. Updates transaction status to `PAID`.
