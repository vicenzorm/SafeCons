# SafeCons 🛡️

SafeCons is a secure, offline-first iOS messaging application built for extreme privacy. It abandons centralized authentication servers and phone numbers in favor of local cryptographic identity generation and physical, out-of-band key exchanges.

## 📱 Philosophy

Following the Unix philosophy—doing one thing and doing it well—SafeCons provides a minimalist, terminal-inspired interface. It ensures that your cryptographic keys never leave your device unless explicitly shared in person via QR code.

## ✨ Core Features

* **Local Identity Forging:** Generates a secure P256 cryptographic key pair directly within the device's Secure Enclave.
* **Out-of-Band Key Exchange:** Establishes secure connections by scanning a peer's public key via an embedded, VisionKit-powered QR code scanner.
* **Zero-Knowledge Architecture:** No central servers. Your identity, contacts, and encrypted messages (AES-GCM) live entirely within your local SwiftData container.
* **Strict Data Integrity:** Cascading deletion rules ensure no orphaned data remains when a connection is severed.

## 🛠 Tech Stack

* **Platform:** iOS 26.0+
* **Framework:** SwiftUI
* **Architecture:** MVVM with Dependency Injection
* **Persistence:** SwiftData (`@Model`, `@Query`, `#Predicate`)
* **Security:** `CryptoKit` (P256 Key Agreement, AES-GCM)
* **Vision & CoreImage:** `VisionKit` (`DataScannerViewController`) for scanning, `CoreImage` for QR generation.

## 🚀 Getting Started

### Prerequisites
* Xcode 15.0 or later.
* An actual iOS device (Camera access is required for the QR Scanner; the iOS Simulator does not support rear camera hardware).
