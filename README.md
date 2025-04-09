# QR Secure Scan App

A Flutter-based mobile application that enhances cybersecurity by scanning QR codes and detecting malicious URLs using integrated threat intelligence APIs and a custom malicious URL database.

## 📱 Overview

QR Secure Scan is designed to help users safely scan QR codes, identify potential threats, and report suspicious content. With real-time analysis through the VirusTotal API and community-driven URL reporting, the app provides a powerful shield against phishing and malware attacks via QR codes.

---

## 🚨 Key Features

- **Real-time QR Code Scanning**

  - Scan using the camera or import from the gallery
  - Detects and analyzes embedded URLs
- **Threat Detection**

  - Integration with [VirusTotal API](https://www.virustotal.com/)
  - Custom database for admin-verified malicious URLs
- **User Reporting System**

  - Submit suspicious URLs with optional screenshots and explanations
- **Admin Panel**

  - Manage reported URLs
  - Classify URLs as malicious or safe
  - Update the malicious URL database
- **Public Threat Awareness**

  - View a database of known malicious URLs

---

## 🧠 Technology Stack

- **Frontend:** Flutter
- **Backend:** Firebase (Realtime Database)
- **Programming Language:** Dart
- **Security & Threat Analysis:** VirusTotal API
- **IDE:** Android Studio

---

## 🛠️ Project Setup

### Prerequisites

- Flutter SDK
- Dart
- Android Studio / Visual Studio
- Firebase Console
- VirusTotal API key (free or premium)

### Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/qr-secure-scan.git
   cd qr-secure-scan

2. Install dependencies:
   ```bash
   flutter pub get

3. Set up Firebase:

   - Enable Authentication
   - Create a Realtime Database
   - Download and add your google-services.json to /android/app/

4. Add your VirusTotal API key in the config file:
   ```bash
   const String virusTotalApiKey = "YOUR_API_KEY";

5. Run the app:
   ```bash
   flutter run
