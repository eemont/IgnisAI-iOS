import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
//            HomeView()
//                .tabItem {
//                    Image(systemName: "house.fill")
//                    Text("Home")
//                }
//            
            PredictionView()
                .tabItem {
                    Image(systemName: "binoculars.fill")
                    Text("Prediction")
                }

            ReportView()
                .tabItem {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text("Reports")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    ContentView()
}
