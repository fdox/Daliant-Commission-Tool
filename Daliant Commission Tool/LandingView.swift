import SwiftUI

struct LandingView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "lightbulb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96)
                    .foregroundStyle(.yellow)

                Text("Daliant Commission Tool")
                    .font(.title).bold()
                    .multilineTextAlignment(.center)

                Text("Commission Pod4 fixtures over Bluetooth.\nAssign DALI short addresses quickly—no site DALI loop.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                NavigationLink("Continue", destination: Text("Projects (coming soon)"))
                    .buttonStyle(.borderedProminent)

                Spacer()
                Text("v0.1 • draft")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
# Optional preview for Xcode canvas
# struct LandingView_Previews: PreviewProvider {
#     static var previews: some View { LandingView() }
# }
