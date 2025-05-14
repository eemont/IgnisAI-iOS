import SwiftUI
import MapKit
import CoreLocation
import Charts

struct FireLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let risk: String
    let humidity: String
    let dryness: String
    let probability: Double
}

struct FireStat: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

struct PredictionView: View {
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.88056, longitude: -117.88528),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )

    @State private var fireLocations: [FireLocation] = []
    @State private var selectedFire: FireLocation? = nil

    @State private var currentZip: String = "Loading..."
    @State private var zipInput: String = ""
    @State private var zipCoordinate: CLLocationCoordinate2D? = nil

    private let geocoder = CLGeocoder()

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(fireLocations) { location in
                    Annotation("Fire", coordinate: location.coordinate) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                            .shadow(radius: 2)
                            .onTapGesture {
                                selectedFire = location
                                withAnimation {
                                    cameraPosition = .region(
                                        MKCoordinateRegion(
                                            center: CLLocationCoordinate2D(
                                                latitude: location.coordinate.latitude - 0.002, // slight downward shift
                                                longitude: location.coordinate.longitude
                                            ),
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        )
                                    )
                                }
                            }

                    }
                }
            }
            .ignoresSafeArea()
            .onChange(of: cameraPosition) { _ in
                updateZipCodeFromMap()
            }

            VStack(spacing: 10) {
                HStack {
                    TextField("Enter ZIP", text: $zipInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)

                    Button("Go") {
                        updateMapFromZip()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .padding(.top, 50)

                Text("ZIP Code: \(currentZip)")
                    .font(.caption)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)

                Spacer()

                Button(action: {
                    generatePrediction()
                }) {
                    Text("Generate Prediction")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }

            // Fire detail sheet
            if let fire = selectedFire {
                fireDetailTab(for: fire)
            }
        }
        .onAppear {
            updateZipCodeFromMap()
        }
    }

    private func fireDetailTab(for fire: FireLocation) -> some View {
        let statValues = [
            FireStat(label: "Risk", value: levelToValue(fire.risk)),
            FireStat(label: "Humidity", value: levelToValue(fire.humidity)),
            FireStat(label: "Dryness", value: levelToValue(fire.dryness)),
            FireStat(label: "Probability", value: Int(fire.probability))
        ]

        return VStack {
            Spacer()
            VStack(spacing: 12) {
                Text("Fire Prediction Details")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    Text("🔥 Risk: \(fire.risk)")
                    Text("💧 Humidity: \(fire.humidity)")
                    Text("🌵 Dryness: \(fire.dryness)")
                    Text("🎯 Probability: \(Int(fire.probability))%")
                }

                Chart(statValues) {
                    LineMark(
                        x: .value("Metric", $0.label),
                        y: .value("Value", $0.value)
                    )
                }
                .frame(height: 200)

                Button("Close") {
                    selectedFire = nil
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
    }

    private func levelToValue(_ level: String) -> Int {
        switch level {
        case "Low": return 30
        case "Medium": return 60
        case "High": return 90
        default: return 50
        }
    }

    private func updateZipCodeFromMap() {
        if let region = cameraPosition.region {
            let center = region.center
            let location = CLLocation(latitude: center.latitude, longitude: center.longitude)

            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let zip = placemarks?.first?.postalCode {
                    currentZip = zip
                    zipInput = zip
                } else {
                    currentZip = "Unknown"
                }
            }
        }
    }

    private func updateMapFromZip() {
        geocoder.geocodeAddressString(zipInput) { placemarks, error in
            if let location = placemarks?.first?.location {
                let coordinate = location.coordinate
                zipCoordinate = coordinate
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                }
            }
        }
    }

    private func generatePrediction() {
        let baseCoord = zipCoordinate ?? CLLocationCoordinate2D(latitude: 33.88056, longitude: -117.88528)

        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: baseCoord,
                    span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                )
            )
        }

        let levels = ["Low", "Medium", "High"]
        var newFires: [FireLocation] = []

        for _ in 0..<5 {
            let latOffset = Double.random(in: -0.05...0.05)
            let lonOffset = Double.random(in: -0.05...0.05)
            let newCoord = CLLocationCoordinate2D(
                latitude: baseCoord.latitude + latOffset,
                longitude: baseCoord.longitude + lonOffset
            )
            let fire = FireLocation(
                coordinate: newCoord,
                risk: levels.randomElement()!,
                humidity: levels.randomElement()!,
                dryness: levels.randomElement()!,
                probability: Double(Int.random(in: 50...95))
            )
            newFires.append(fire)
        }

        fireLocations = newFires
    }
}

#Preview {
    PredictionView()
}
