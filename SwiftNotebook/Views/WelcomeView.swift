import SwiftUI

struct WelcomeView: View {
    let onChooseFolder: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)

            Text("Welcome to SwiftNotebook")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.inkPrimary)

            Text("Choose a folder where your journal will live. Entries are stored in a local database inside that folder — nothing leaves your Mac.")
                .font(.system(size: 13))
                .foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Button("Choose Folder…", action: onChooseFolder)
                .buttonStyle(.borderedProminent)
                .tint(Palette.accent)
                .controlSize(.large)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.contentBackground)
    }
}
