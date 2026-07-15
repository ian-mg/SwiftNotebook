import SwiftUI

@main
struct SwiftNotebookApp: App {
    @State private var storeManager = JournalStoreManager()
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if let persistence = storeManager.persistence {
                    ContentView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                        .environment(appState)
                } else {
                    WelcomeView {
                        storeManager.chooseFolder()
                    }
                }
            }
            .frame(minWidth: 1120, minHeight: 720)
        }
        .defaultSize(width: 1200, height: 780)
    }
}
