<h1 align="center">
  🚀 Precision POS
</h1>

<p align="center">
  <strong>Smart Point of Sale & Inventory Management System powered by AI</strong>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://laravel.com"><img src="https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white" alt="Laravel"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
  <a href="#"><img src="https://img.shields.io/badge/Status-Active-success?style=for-the-badge" alt="Status"></a>
</p>

---

## 📌 Overview

**Precision POS** is a modern, high-performance Point of Sale (POS) application built with **Flutter**. Designed to be an offline-first solution with robust local data persistence, it seamlessly syncs with a **Laravel API** backend. The system features a stunning UI, real-time reporting, and role-based access control (including delivery agents), making it the perfect solution for dynamic retail and food service environments.

Developed with the assistance of **AI Stitch** and **AntiGravity**, this project showcases rapid, high-quality full-stack development.

## ✨ Key Features & Recent Updates

- 🤖 **AI-STICH Integration (NEW):** Integrated prediction engine for Sales Forecasting and Smart Inventory recommendations to predict retail needs.
- 🏗️ **Robust Backend Architecture (NEW):** Designed for a Modular Monolith architecture, supporting modern tech stacks like Python (FastAPI), Node.js (NestJS), Golang, or PHP (Laravel).
- 📱 **Beautiful & Responsive UI:** Crafted pixel-perfect from design specifications for an optimal user experience.
- ⚡ **Offline-First Architecture:** Complete transaction capabilities using local database (`sqflite`) even without internet connectivity, utilizing smart batch Push/Pull synchronization.
- 🔄 **Real-Time Synchronization:** Seamlessly syncs local transactions, products, and inventory with the backend API.
- 📊 **Advanced Analytics & Reporting:** Real-time dashboard with sales summaries, hourly performance, and interactive traceback features.
- 👥 **Dynamic Role-Based Access Control (RBAC):** Distinct roles including Admins, Cashiers, Managers, and Delivery Drivers with tailored workflows and dynamic bottom navigation bars.
- 🖨️ **Smart Receipt Generation:** Auto-generates receipt numbers, timestamps, and calculates complex subtotal/grand total logic.
- 🚚 **Delivery Dashboard:** Built-in workflows and dedicated screens for delivery tracking and agent assignments.

## 📸 Screenshots

| Dashboard | Order Input | Transaction History |
| :---: | :---: | :---: |
| <img src="https://via.placeholder.com/300x600.png?text=Dashboard+Screen" alt="Dashboard" width="200"/> | <img src="https://via.placeholder.com/300x600.png?text=Order+Input+Screen" alt="Order Input" width="200"/> | <img src="https://via.placeholder.com/300x600.png?text=History+Screen" alt="Transaction History" width="200"/> |

*(Note: Replace placeholders with actual application screenshots when ready)*

## 🛠️ Tech Stack

### Frontend (Mobile App)
- **Framework:** [Flutter](https://flutter.dev/)
- **Language:** Dart
- **Local Database:** sqflite / shared_preferences
- **Architecture:** Repository Pattern with Clean Architecture principles

### Backend (API & Dashboard)
- **Primary Framework:** Python (FastAPI) *Recommended for AI integration*, or PHP (Laravel), Node.js (NestJS), Golang.
- **Database:** PostgreSQL (Recommended for ACID) / MySQL
- **Caching:** Redis (Session management & fast data retrieval)
- **Architecture:** Modular Monolith

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- Android Studio or VS Code with Flutter extensions
- Backend setup requires PHP, Composer, and a local server (e.g., Laragon, XAMPP, or Laravel Herd)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/fathurdja/APLIKASI-POS-dengan-AI-STICH-dan-AntiGravity-.git
   cd APLIKASI-POS-dengan-AI-STICH-dan-AntiGravity-/precision_pos
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

## 📂 Project Structure Overview

```text
lib/
├── assets/          # Static files, images, and dummy JSON data
├── core/            # Core utilities, theme, and constants
├── data/            # Local database config, models, and repositories
├── screens/         # UI Screens (Dashboard, OrderInput, DailyReport, etc.)
├── widgets/         # Reusable UI components
└── main.dart        # Application entry point
```

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
<p align="center">Built with ❤️ using Flutter and AI magic.</p>
