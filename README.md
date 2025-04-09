# QR Secure Scan Application

A Flutter-based mobile application that enhances cybersecurity by scanning QR codes and detecting malicious URLs using integrated threat intelligence APIs and a custom malicious URL database.

## 📱 Overview

QR Secure Scan is designed to help users safely scan QR codes, identify potential threats, and report suspicious content. With real-time analysis through the VirusTotal API and community-driven URL reporting, the app provides a powerful shield against phishing and malware attacks via QR codes.

---

## 📸 Screenshots

  - [Click here to View More Screenshots](screenshots/app-images/) <br />
  <img src="https://github.com/user-attachments/assets/79f83455-4044-44ff-b769-45c1af6980fd" alt="homepage" width="150"/>
  <img src="https://github.com/user-attachments/assets/837d7392-9003-4271-9663-aa19fdcaf88c" alt="scan_result" width="150"/>
  <img src="https://github.com/user-attachments/assets/76baef30-6998-47c7-985e-51ec375fb6db" alt="malicious_URL_database" width="150"/>
  <img src="https://github.com/user-attachments/assets/07d4f7f4-2caf-4897-a20a-0f411b79b7d2" alt="admin_login" width="150"/>
  <img src="https://github.com/user-attachments/assets/0c45a48a-bb3f-439f-833f-8084e7789414" alt="admin_homepage" width="150"/>
  
----

## 🚨 Key Features

- **Real-time QR Code Scanning**

  - Scan using the camera or import from the gallery
  - Detects and analyzes embedded URLs
- **Threat Detection**

  - Integration with VirusTotal API
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

- **Frontend:** [Flutter](https://docs.flutter.dev/get-started/install/windows/desktop/)
- **Backend:** [Firebase](https://firebase.google.com/) (Realtime Database)
- **Programming Language:** Dart
- **Security & Threat Analysis:** [VirusTotal API](https://www.virustotal.com/gui/home/upload/)
- **IDE:** [Android Studio](https://developer.android.com/studio/) / [Visual Studio Code](https://visualstudio.microsoft.com/downloads/)

---

## 🛠️ Project Setup

### 🔨 Initial Setup

1. Create New Flutter Project on Android Studio or Visual Studio Code and name it **'qr_secure_scan'**.

2. Clone this repository or download zip file:
   ```bash
   git clone https://github.com/aivxx02/qr-secure-scan.git

3. Extract the Zip file and **copy** the files and **paste/replace** it on **'qr_secure_scan'** project file.

4. Install dependencies:
   ```bash
   flutter pub get

5. Line 9, 10, 41, 42, 72 & 73 [lib/SMTPEmail.dart/](lib/SMTPEmail.dart/)
    ```bash 
    const String username = 'test@gmail.com'; // insert your gmail
    const String password = 'xx xx xx xx'; // Use an App Password, NOT your Gmail password

6. Line 120 [lib/pages/users/scan/scan_page.dart](lib/pages/users/scan/scan_page.dart/) && Line 122 [lib/pages/users/scan/image_select.dart](lib/pages/users/scan/image_select.dart/)
	```
	const apiKey = ''; // insert Virus Total API key

### 🔥 Firebase Setup

1. Set up Firebase and Intergrate with Flutter by OWN.

2. Firestore Database
   - <img src="https://github.com/user-attachments/assets/5d5b21b6-e4da-47b4-b317-9fe7ab366514" alt="firebase_database" width="300"/>
     <img src="https://github.com/user-attachments/assets/f63828a6-a0f1-4a3c-bdd4-050ea47c28b0" alt="firestore_rules" width="300"/> <br />

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


## License
This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE/) file for details.
