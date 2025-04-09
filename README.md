# QR Secure Scan Application

A Flutter-based mobile application that enhances cybersecurity by scanning QR codes and detecting malicious URLs using integrated threat intelligence APIs and a custom malicious URL database.

## 📱 Overview

QR Secure Scan is designed to help users safely scan QR codes, identify potential threats, and report suspicious content. With real-time analysis through the VirusTotal API and community-driven URL reporting, the app provides a powerful shield against phishing and malware attacks via QR codes.

---

## 📸 Screenshots

- [Click here to view Screenshots](screenshots/app-images)

----

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

## 🧱 Prerequisite

- **Frontend:** Flutter
- **Backend:** Firebase (Realtime Database)
- **Programming Language:** Dart
- **Security & Threat Analysis:** VirusTotal API
- **IDE:** Android Studio / Visual Studio Code

---

## 🛠️ Project Setup

### 🔨 Initial Setup

1. Create New Flutter Project on Android Studio or Visual Studio Code and name it 'qr_secure_scan'.

2. Clone this repository or download zip file:
   ```bash
   git clone https://github.com/aivxx02/qr-secure-scan.git

3. Extract the Zip file and copy the files and paste/replace it on 'qr_secure_scan' project file.

4. Install dependencies:
   ```bash
   flutter pub get

5. [Line 72 & 73](lib/SMTPEmail.dart/)
    ```bash 
    const String username = ''; // insert your gmail
    const String password = ''; // Use an App Password, NOT your Gmail password

### 🔥 Firebase Setup

1. Set up Firebase and Intergrate with Flutter by OWN.

2. Firestore Database
   - [Check Out the Screenshots](screenshots/firebase-setup/firestore-database/)

   - *IMPORTANT*⚠️ Create collection called "maliciousURL".

   - Document and Field dont fill up anything, code handles it.

   - Make sure add the rules.

3. Authentication
   - [Check Out the Screenshots](screenshots/firebase-setup/authentication/)

   - Add new user by random email / own email for admin login.

4. Storage
   - [Check Out the Screenshots](screenshots/firebase-setup/storage/)
   
   - *IMPORTANT*⚠️ This is where images stored, create an folder "reports/". 

   - Make sure add the rules.




4. Add your VirusTotal API key in the config file:
   ```bash
   const String virusTotalApiKey = "YOUR_API_KEY";

5. Run the app:
   ```bash
   flutter run
