# BookXpert_SwiftUI
# 📱 iOS Developer Assignment – BookXpert App

## 🚀 Objective
A Swift-based iOS app that demonstrates user authentication, offline data persistence using Core Data, local notifications, image handling (camera/gallery), and an integrated PDF viewer.

---

## ✅ Features

### 🔐 User Authentication
- Google Sign-In using Firebase Authentication
- Store authenticated user data in Core Data

### 📄 PDF Viewer
- Displays PDF report using in-app viewer  
- [View Sample PDF](https://fssservices.bookxpert.co/GeneratedPDF/Companies/nadc/2024-2025/BalanceSheet.pdf)

### 📷 Image Capture & Gallery Selection
- Capture image via device camera
- Select image from photo gallery
- Preview selected image in the app

### 🗂 Core Data Integration with API
- API: [https://api.restful-api.dev/objects](https://api.restful-api.dev/objects)
- Fetch, store, update, and delete data locally using Core Data
- Input validations and error handling

### 🔔 Local Notifications
- Send a local notification when an item is deleted
- Notification includes details of the deleted item
- Option to enable/disable notifications

---

## 🛠 Technical Stack

- **Language**: Swift with SwiftUI framework
- **Architecture**: MVVM
- **Persistence**: Core Data
- **Authentication**: Firebase (Google Sign-In)
- **PDF Viewing**: `PDFKit` / `PDFView` or any supported third-party library
- **Notifications**: UNUserNotificationCenter
- **UI/UX**: Modern SwiftUI layout
- **Theming**: Light & Dark mode support
- **Permissions**: Runtime camera and photo library access

---

## 📸 Screenshots
*(Add screenshots of the app once ready)*

---

## 📦 Installation

1. Clone the repo:
   ```bash
   git clone https://github.com/yourusername/BookXpert-iOS-App.git
   cd BookXpert-iOS-App
