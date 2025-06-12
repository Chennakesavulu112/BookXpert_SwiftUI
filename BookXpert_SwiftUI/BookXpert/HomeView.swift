//
//  HomeView.swift
//  BookXpert
//
//  Created by peoplelink on 10/06/25.
//

import SwiftUI
import CoreData
import FirebaseAuth
import AVFoundation
import Photos

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authState: AuthState
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.timestamp, ascending: false)],
        animation: .default)
    private var users: FetchedResults<User>
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showPDF = false
    @State private var isLoading = false
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var showCameraPermissionAlert = false
    
    @State private var showingPDFViewer = false
    @State private var selectedPDFURL: URL?
    
    private let pdfURL = URL(string: "https://fssservices.bookxpert.co/GeneratedPDF/Companies/nadc/2024-2025/BalanceSheet.pdf")!
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                    // Content Layer
                    VStack(spacing: 0) {
                        // Main Content
                        ProductListView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.clear)
                        
                        // Bottom Buttons
                        HStack(spacing: 12) {
                            // PDF Button
                            Button(action: {
                                showPDF = true
                            }) {
                                VStack {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 24))
                                    Text("View PDF")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
            }
            .navigationBarItems(
                leading: profileButton,
                trailing: NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                }
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: sourceType)
                    .onDisappear {
                        if let image = selectedImage,
                           let imageData = image.jpegData(compressionQuality: 0.8),
                           let currentUser = users.first {
                            currentUser.profileImage = imageData
                            try? viewContext.save()
                        }
                    }
            }
            .sheet(isPresented: $showPDF) {
                PDFView(url: pdfURL)
            }
            .alert("Permission Required", isPresented: $showPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            } message: {
                Text(permissionAlertMessage)
            }
            .alert("Camera Access", isPresented: $showCameraPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Allow") {
                    requestCameraPermission()
                }
            } message: {
                Text("This app needs access to your camera to take photos. Would you like to allow camera access?")
            }
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    sourceType = .camera
                    showImagePicker = true
                } else {
                    permissionAlertMessage = "Camera access is required to take photos. Please enable it in Settings."
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func checkPhotoLibraryPermission() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            sourceType = .photoLibrary
            showImagePicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    } else {
                        permissionAlertMessage = "Photo library access is required to select photos. Please enable it in Settings."
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            permissionAlertMessage = "Photo library access is required to select photos. Please enable it in Settings."
            showPermissionAlert = true
        case .limited:
            sourceType = .photoLibrary
            showImagePicker = true
        @unknown default:
            break
        }
    }
    
    private var profileButton: some View {
        HStack {
            if let currentUser = users.first {
                Button {
                    showActionSheet = true
                } label: {
                    HStack {
                        if let imageData = currentUser.profileImage,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else if let photoURL = currentUser.photoURL,
                                  let url = URL(string: photoURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentUser.name ?? "No Name")
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Text(currentUser.email ?? "No Email")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .confirmationDialog("Choose Image Source", isPresented: $showActionSheet) {
            Button("Camera") {
                showCameraPermissionAlert = true
            }
            Button("Photo Library") {
                checkPhotoLibraryPermission()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthState())
}
