import SwiftUI
import MapKit
import PhotosUI

struct ReportView: View {
    @State private var currentMapCenter = CLLocationCoordinate2D(latitude: 33.88056, longitude: -117.88528)
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var commentText = ""
    @State private var reportPin: CLLocationCoordinate2D? = nil
    @State private var step: Int = 0
    @State private var showConfirmation = false

    var body: some View {
        ZStack {
            MapViewRepresentable(currentCenter: $currentMapCenter)
                //.ignoresSafeArea()

            if step == 1 {
                Image(systemName: "mappin.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                    .shadow(radius: 4)
            }

            VStack {
                HStack {
                    if step > 0 && step < 3 {
                        Button(action: {
                            step = 0
                            reportPin = nil
                            selectedItems.removeAll()
                            selectedImages.removeAll()
                            commentText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }

                Spacer()

                if step == 0 {
                    HStack {
                        Spacer()
                        Button(action: {
                            step = 1
                            reportPin = nil
                        }) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }

                if step == 1 {
                    Button("Confirm Location") {
                        reportPin = currentMapCenter
                        step = 2
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
            }

            .sheet(isPresented: Binding(get: { step == 2 }, set: { _ in })) {
                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            step = 1
                            selectedItems.removeAll()
                            selectedImages.removeAll()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.blue)
                        }
                        Spacer()
                    }

                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 1,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Upload Image")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .onChange(of: selectedItems) {
                        Task {
                            selectedImages.removeAll()
                            for item in selectedItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    selectedImages.append(image)
                                }
                            }
                            step = 3
                        }
                    }

                    Button(action: {
                        showCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Take Photo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .sheet(isPresented: $showCamera) {
                        ImagePicker(image: $selectedImages, step: $step)
                    }
                }
                .padding()
                .background(Color.white) // ensures opaque background
                .presentationDetents([.height(240)]) // 👈 Custom height
                .presentationDragIndicator(.visible)
            }

            .sheet(isPresented: Binding(get: { step == 3 }, set: { _ in })) {
                VStack(spacing: 20) {
                    // Back button row
                    HStack {
                        Button(action: {
                            step = 2
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.blue)
                        }
                        Spacer()
                    }

                    if let image = selectedImages.first {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 250)
                            .cornerRadius(8)
                    }

                    TextField("Give detailed description...", text: $commentText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button("Submit") {
                        reportPin = nil
                        selectedImages.removeAll()
                        selectedItems.removeAll()
                        commentText = ""
                        step = 0

                        showConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            showConfirmation = false
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.white)
                .presentationDetents([.height(540)])
                .presentationDragIndicator(.visible)
            }

            if showConfirmation {
                VStack {
                    Spacer()
                    Text("✅ Report Submitted")
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding(.bottom, 60)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showConfirmation)
            }
        }
    }
    
}



#Preview {
    ReportView()
}

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var currentCenter: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(
            MKCoordinateRegion(
                center: currentCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ),
            animated: false
        )
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.currentCenter = mapView.centerCoordinate
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @Binding var image: [UIImage]
    @Binding var step: Int

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = [uiImage]
                parent.step = 3
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
