import SwiftUI

struct SignInView: View {
    var onSignedIn: (_ userId: String, _ displayName: String?) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 56))
            Text("Daliant Commission Tool")
                .font(.title.bold())
            Text("Sign in placeholder — taps 'Continue' to proceed.")
                .foregroundStyle(.secondary)
            Button(action: { onSignedIn(UUID().uuidString, "Tester") }) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview { SignInView { _,_ in } }
