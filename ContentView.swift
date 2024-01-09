//
//  ContentView.swift
//  BarAdding
//
//  Created by yz on 2024/1/2.
//
import PhotosUI
import SwiftUI
import UIKit
import Photos
import CoreLocation

struct ContentView: View {
    @State private var inputImage: UIImage?
    @State private var showingImagePicker = false  // State variable to control the image picker presentation
    @State private var showAlert = false
    @State private var alertMessage = ""
    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    Rectangle().fill(.secondary)
                    Text("Tap to select a picture")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    if let inputImage = inputImage {
                        Image(uiImage: inputImage)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .onTapGesture {
                    showingImagePicker = true  // Show the image picker when tapped
                }
                .navigationTitle("Watermark Photo")
                if inputImage != nil {
                    Button("Save to Photo Library") {
                        saveImage()
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage) { pickedImage in
                inputImage = pickedImage
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Photo Library"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    func saveImage() {
        guard let inputImage = inputImage else { return }
        saveImageToPhotoLibrary(inputImage) { error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                alertMessage = "Image saved successfully"
                showAlert = true
            }
        }
    }
}

#Preview {
    ContentView()
}
