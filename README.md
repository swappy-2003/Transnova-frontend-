# Transnova Flutter Mobile App

Modern cross-platform mobile frontend for the Transnova Global Stablecoin & Payouts platform built with **Flutter 3.47** and **Dart 3.13**, fully integrated with the `transnova_backend` API.

---

## 🚀 Features & Backend Integrations

- **Authentication & User Management**:
  - Connects to `/api/v1/auth/me` and `/api/v1/auth/sync` with Bearer tokens.
  - Development sign-in and sign-up with Firebase REST API helpers (`/api/v1/dev/firebase-token`, `/api/v1/dev/firebase-signup`).
  - One-click **Demo Login** for quick local testing.
  - Dynamic API Base URL configuration switch.

- **Circle Developer-Controlled USDC Wallets**:
  - Auto-provisions Polygon Amoy testnet Smart Contract Accounts (`SCA`) via `/api/v1/wallets/circle`.
  - Real-time token balances and USDC tracking via `/api/v1/wallets/:walletId/balance`.
  - On-chain address validation via `/api/v1/wallets/validate-address`.
  - Interactive **Receive Modal** with generated QR code and clipboard copy.

- **USDC Transfers & Fee Estimation**:
  - Pre-transfer gas fee estimation (low, medium, high) via `/api/v1/transactions/estimate-fee`.
  - Direct Circle blockchain transfer execution via `/api/v1/transactions/circle-transfer`.
  - Sandbox transaction simulation via `/api/v1/transactions/simulate`.

- **On-ramp (Buy USDC)**:
  - Generates Transak on-ramp widget URLs via `/api/v1/onramp/widget-url`.
  - Direct in-app/external browser launcher using `url_launcher`.
  - Instant simulated deposit top-up for testnet balance credit.

- **Off-ramp (Cash Out to US Bank Account)**:
  - Create Crossmint ACH bank account payment method via `/api/v1/offramp/payment-methods`.
  - Submit off-ramp payout orders via `/api/v1/offramp/orders`.
  - Simulated cash-out execution for testing.

- **Activity & Transaction History**:
  - Real-time transaction list fetched from `/api/v1/transactions`.
  - Type-based filtering (Transfers, On-ramps, Cash-outs).
  - Detailed bottom sheet with Polygonscan Amoy explorer deep-links.

---

## 📱 Project Architecture

```
lib/
├── config/
│   ├── api_config.dart          # Base URL, endpoints, and storage persistence
│   └── theme.dart               # Dark slate fintech color palette & styling
├── models/
│   ├── user_model.dart          # MongoDB user schema model
│   ├── wallet_model.dart        # Circle wallet & token balance models
│   ├── transaction_model.dart   # Transaction model with Circle/Transak/Crossmint metadata
│   ├── fee_estimate_model.dart  # Circle fee estimate model
│   ├── onramp_order_model.dart  # Transak widget order model
│   └── offramp_model.dart       # Crossmint ACH beneficiary & order models
├── services/
│   ├── api_client.dart          # Dio client with Bearer auth token interceptor
│   ├── auth_service.dart        # Authentication & sync service
│   ├── wallet_service.dart      # Circle wallet management & balance queries
│   ├── transaction_service.dart # Circle transfer, simulation & history service
│   ├── onramp_service.dart      # Transak on-ramp integration
│   └── offramp_service.dart     # Crossmint off-ramp integration
├── providers/
│   ├── auth_provider.dart       # Authentication state management
│   ├── wallet_provider.dart     # Circle wallet state & balance management
│   └── transaction_provider.dart# Transaction history & transfer flows
├── screens/
│   ├── splash_screen.dart       # Session verification & routing
│   ├── auth/                    # Sign in, Sign up, and demo access
│   ├── main_navigation.dart     # Bottom navigation tabs
│   ├── home/                    # Balance card, QR modal, quick actions
│   ├── send/                    # Recipient validation, fee estimation & sending
│   ├── buy/                     # Fiat onramp with Transak
│   ├── cashout/                 # Crossmint ACH bank withdrawal
│   ├── activity/                # History with search and Polygonscan links
│   └── settings/                # Profile, wallet info & API server settings
└── main.dart
```

---

## 🛠️ Running the Application

### 1. Ensure `transnova_backend` is running
```bash
cd "../transnova_backend"
npm run dev
```

### 2. Run the Flutter App
```bash
cd transnova_flutter
flutter run
```
You can run it on iOS Simulator, Android Emulator, macOS Desktop, or Chrome Web.

*Note for Android Emulator*: The default URL automatically points to `http://10.0.2.2:5001`. For iOS Simulator and macOS/Web, it defaults to `http://localhost:5001`. You can edit this anytime in Settings.
