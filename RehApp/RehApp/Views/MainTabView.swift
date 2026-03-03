import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel
    @Query private var profiles: [InjuryProfile]
    @Query private var roadmaps: [RecoveryRoadmap]
    init(repository: RecoveryRepositoryProtocol) {
        _viewModel = State(initialValue: DashboardViewModel(repository: repository))
    }
    
    var body: some View {
        TabView {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "bolt.ring.closed")
                }
            
            RecoveryPlanView(viewModel: viewModel)
                .tabItem {
                    Label("Mi Plan", systemImage: "figure.walk.motion")
                }
            
            if let profile = viewModel.selectedProfile, let roadmap = viewModel.currentRoadmap {
                RecoveryReportView(profile: profile, roadmap: roadmap)
                    .tabItem {
                        Label("Informe", systemImage: "doc.plaintext.fill")
                    }
            } else {
                ContentUnavailableView("Sin Datos", systemImage: "doc.text", description: Text("Completa una rehabilitación para generar informes."))
                    .tabItem {
                        Label("Informe", systemImage: "doc.plaintext.fill")
                    }
            }
            
            SettingsView(selectedProfile: viewModel.selectedProfile, repository: viewModel.repository)
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.athleteOrange)
        .onAppear {
            // Standard appearance settings for a professional look
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor(AppTheme.deepSlate)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
