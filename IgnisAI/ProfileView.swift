import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var name: String = "John Doe"
    @State private var phoneNumber: String = "123-456-7890"
    @State private var email: String = "john.doe@example.com"
    @State private var address: String = "1234 Main St, California"
    
    @State private var profileImage: UIImage? = nil
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    
    @State private var useAddressForAlerts: Bool = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Photo")) {
                    VStack {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(Text("Tap to add").foregroundColor(.gray))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .onTapGesture {
                        showPhotoPicker = true
                    }
                }
                
                Section(header: Text("General Information")) {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Address", text: $address)
                }

                Section {
                    Toggle(isOn: $useAddressForAlerts) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Alerts")
                                .font(.body)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        profileImage = image
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}

