import SwiftUI
import SwiftData

@main
struct RehApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            InjuryProfile.self,
            RecoveryRoadmap.self,
            RecoveryPhase.self,
            Exercise.self,
            DailyRoutine.self,
            Milestone.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var sharedRepository: RecoveryRepository {
        RecoveryRepository(context: sharedModelContainer.mainContext)
    }

    @State private var settings = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainContentView(repository: sharedRepository)
            }
            .environment(settings)
            .preferredColorScheme(settings.selectedTheme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}

struct MainContentView: View {
    @Query private var profiles: [InjuryProfile]
    let repository: RecoveryRepositoryProtocol
    
    var body: some View {
        if profiles.isEmpty {
            OnboardingView(isSimplified: false, repository: repository)
        } else {
            MainTabView(repository: repository)
        }
    }
}
