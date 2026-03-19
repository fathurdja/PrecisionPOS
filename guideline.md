# Precision POS - Project Guideline

## 1. Project Overview
**Precision POS** is a high-end, premium mobile Point of Sale (POS) application designed with an "Architectural Layering" aesthetic. It transcends traditional utility software by focusing on editorial management and visual excellence.

- **Status:** Initial Build (MVP)
- **Framework:** Flutter (Android, iOS, Web)
- **Source Material:** 5 Mobile Design Mockups (HTML/CSS) + Design System Document

---

## 2. Tech Stack
- **Core:** Flutter SDK
- **Design System:** Material 3 (Customized)
- **Typography:** Inter (via `google_fonts: ^6.2.1`)
- **Charts:** `fl_chart: ^0.70.2` (for Hourly Performance)
- **Icons:** Material Symbols (Customized weights via Google Fonts API)

---

## 3. Design System (The Precision Atelier)
The project strictly follows the design principles defined in the original `DESIGN.md`:

### Color Theory
- **Primary:** Deep Navy `#001E40` (Trust & Authority)
- **Secondary:** Emerald Green `#50C878` (Growth & Action)
- **Active State:** Special Emerald pill background for the navigation bar
- **Surface Hierarchy:** Uses tonal shifts (`surfaceContainerLowest` to `surfaceContainerHighest`) instead of borders.

### The "No-Line" Philosophy
- Designers are prohibited from using 1px solid borders.
- Structural integrity is achieved through **Background Color Shifts** and **Ambient Shadows**.
- Whitespace tokens (`spacing-10` / 2.25rem) are used for "breathing room."

---

## 4. Features & Screens

### [Sales] Dashboard
- Daily performance stats (Sales, Orders).
- Quick Actions Bento Grid (New Order, Inventory, Customers).
- Recent transactions list with tonal alternating rows.

### [Order] Input Screen
- Receipt meta details (Receipt #, Issue Date).
- Current Order itemized list with quantity steppers.
- Asymmetric metrics cards (Loyalty Points, Stock Alert).
- Bottom checkout panel with Subtotal, Tax, and "Process Payment" button.

### [History] Transaction History
- Global search bar and date-based filtering.
- Transaction cards with status badges (Completed, Pending, Refunded).
- Expandable Refunded card with specialized action buttons (WhatsApp, Print).

### [Reports] Daily Report
- Live Hourly Performance bar chart.
- Summary grid (Total Sales, Items Sold, Avg Ticket).
- Detailed transaction table.
- "Manage Data" card for Export/Import actions.

### [Settings] Configuration
- Categorized settings (Account, Preferences, System).
- Clean editorial layout for configuration items.

---

## 5. Navigation & Routing
The app uses a `MainShell` structure with a persistent `BottomNavBar` wrapping an `IndexedStack`.

| Navigation Target | Description | Route Type |
|---|---|---|
| **Tab 0: Sales** | Main Dashboard | Tab (Home) |
| **Tab 1: History** | Transaction Logs | Tab |
| **Tab 2: Reports** | Analytical Data | Tab |
| **Tab 3: Settings** | App Configuration | Tab |
| **New Order** | Transaction Process | Named Route (`/order`) |
| **Receipt Preview** | Digital Invoice View | Named Route (`/receipt`) |

---

## 6. Project Structure
```
precision_pos/
├── lib/
│   ├── main.dart             # App Entry & Initial Configuration
│   ├── theme/
│   │   ├── app_colors.dart   # Design System Color Tokens
│   │   └── app_theme.dart    # Material 3 Theme Definition
│   ├── widgets/
│   │   ├── bottom_nav_bar.dart
│   │   └── top_app_bar.dart
│   └── screens/
│       ├── dashboard_screen.dart
│       ├── order_input_screen.dart
│       ├── receipt_preview_screen.dart
│       ├── transaction_history_screen.dart
│       ├── daily_report_screen.dart
│       └── settings_screen.dart
```

---

## 7. How to Run & Verify
1. **Dependencies:** `flutter pub get`
2. **Analysis:** `flutter analyze` (Zero issues found)
3. **Execution:**
   - Web: `flutter run -d chrome`
   - Mobile: `flutter run -d <device_id>`
