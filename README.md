# SafeCons 🛡️

SafeCons is a secure, offline-first iOS messaging application built for extreme privacy. It abandons centralized authentication servers and phone numbers in favor of local cryptographic identity generation and physical, out-of-band key exchanges.

## 📱 Philosophy

Following the Unix philosophy—doing one thing and doing it well—SafeCons provides a minimalist, terminal-inspired interface. It ensures that your cryptographic keys never leave your device unless explicitly shared in person via QR code.

## ✨ Core Features

* **Offline-First (BLE Mesh):** Communicate exclusively via Bluetooth Low Energy. No Wi-Fi or cellular data required. Perfect for off-grid environments, crowded events, or privacy-critical local meetings.
* **Local Identity Forging:** Generates a secure P256 cryptographic key pair directly within the device's hardware (Secure Enclave). No phone numbers or emails required.
* **Out-of-Band Key Exchange:** Establishes secure connections by scanning a peer's public key via an embedded, VisionKit-powered QR code scanner. Prevents Man-In-The-Middle (MITM) attacks.
* **Consent-Based "Intercom":** Built-in spam prevention. Unknown cryptographic handshakes are held in volatile RAM until explicitly approved by the user.
* **Anti-Replay Attack Mechanism:** Packets are injected with dynamic timestamps before encryption, rendering intercepted radio waves useless for future replay attacks.
* **Zero-Knowledge Architecture:** Your identity, contacts, and encrypted messages (AES-GCM) live entirely within your local SwiftData container. Messages are encrypted at rest
  
## 🛠 Tech Stack

* **Platform:** iOS 26.0+ (Requires Physical Device)
* **Framework:** SwiftUI
* **Architecture:** MVVM with Dependency Injection (`AppContainer`)
* **Persistence:** SwiftData (`@Model`, `@Query`, `#Predicate`)
* **Security & Cryptography:** `CryptoKit` (P256 Key Agreement, AES-GCM, SHA256 hashing) & `Security` (Keychain).
* **Networking:** `CoreBluetooth` (Dynamic MTU Chunking, Background Restoration).
* **Vision & CoreImage:** `VisionKit` (`DataScannerViewController`) for scanning, `CoreImage` for QR generation.
