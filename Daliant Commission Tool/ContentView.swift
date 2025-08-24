import SwiftUI
import SwiftData
import AuthenticationServices
import UIKit

// MARK: - Root

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Org.createdAt) private var orgs: [Org]

    // Store signed-in user id locally (simple; we can switch to Keychain later)
    @AppStorage("signedInUserID") private var signedInUserID: String = ""

    var body: some View {
        NavigationStack {
            if signedInUserID.isEmpty {
                SignInView { userId, _ in
                    signedInUserID = userId
                }
            } else if orgs.isEmpty {
                OrgOnboardingView()
            } else {
                ProjectsHomeView()
            }
        }
    }
}

// MARK: - Sign in

struct SignInView: View {
    var onSignedIn: (_ userId: String, _ displayName: String?) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            LogoView()

            Text("Daliant Commission Tool")
                .font(.title).bold()
                .multilineTextAlignment(.center)

            Text("Sign in to keep your projects organized and ready for service calls.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let auth):
                    if let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                        let id = cred.user
                        let nameParts = [cred.fullName?.givenName, cred.fullName?.familyName].compactMap { $0 }
                        let display = nameParts.isEmpty ? nil : nameParts.joined(separator: " ")
                        onSignedIn(id, display)
                    }
                case .failure:
                    break
                }
            }
            .frame(height: 44)
            .signInWithAppleButtonStyle(.black)

            // Optional: allow offline use for now
            NavigationLink("Continue without signing in") {
                ProjectsHomeView()
            }
            .buttonStyle(.bordered)

            Spacer()
            Text("v0.1 • draft")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Organization onboarding

struct OrgOnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Org.createdAt) private var orgs: [Org]

    @State private var orgName: String = ""
    @State private var joinCodeInput: String = ""
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Organization")
                    .font(.largeTitle).bold()

                Text("Create your organization (e.g., “Dox Electronics”) or join an existing one using a join code shared by a teammate.")
                    .foregroundStyle(.secondary)

                Group {
                    Text("Create Organization").font(.headline)
                    TextField("Organization Name", text: $orgName)
                        .textFieldStyle(.roundedBorder)
                    Button("Create") {
                        createOrg()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(orgName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Divider().padding(.vertical, 8)

                Group {
                    Text("Join Organization").font(.headline)
                    TextField("Join Code", text: $joinCodeInput)
                        .textFieldStyle(.roundedBorder)
                    Button("Join") {
                        joinOrg(with: joinCodeInput)
                    }
                    .buttonStyle(.bordered)
                    .disabled(joinCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let message {
                    Text(message).foregroundStyle(.secondary)
                }

                if !orgs.isEmpty {
                    Section {
                        ForEach(orgs) { o in
                            HStack {
                                Text(o.name).font(.headline)
                                Spacer()
                                Text("Code: \(o.joinCode)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Your organizations").font(.headline)
                    }
                }

                NavigationLink("Continue to Projects", destination: ProjectsHomeView())
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Organization")
    }

    private func createOrg() {
        let name = orgName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let slug = name.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let code = Self.makeJoinCode()
        let org = Org(name: name, slug: slug, joinCode: code)
        context.insert(org)
        message = "Created “\(name)”. Share join code: \(code)"
        orgName = ""
    }

    private func joinOrg(with code: String) {
        let codeTrim = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let found = orgs.first(where: { $0.joinCode.uppercased() == codeTrim }) {
            message = "Joined “\(found.name)”."
        } else {
            message = "No local organization found with that code (cloud sharing will come later)."
        }
        joinCodeInput = ""
    }

    private static func makeJoinCode(length: Int = 6) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") // no O/0 or I/1
        return String((0..<length).map { _ in alphabet.randomElement()! })
    }
}

// MARK: - Projects (unchanged list + seeded previews)

struct ProjectsHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Item.createdAt, order: .reverse) private var projects: [Item]
    @State private var newName: String = ""

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("New Project Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit(addProject)

                Button("Add") { addProject() }
                    .buttonStyle(.borderedProminent)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)

            List {
                ForEach(projects) { p in
                    NavigationLink {
                        ProjectDetailPlaceholder(project: p)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.name).font(.headline)
                            Text(p.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { idxSet in
                    for idx in idxSet { context.delete(projects[idx]) }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar { EditButton() }
    }

    private func addProject() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        context.insert(Item(name: name))
        newName = ""
    }
}

struct ProjectDetailPlaceholder: View {
    var project: Item
    var body: some View {
        VStack(spacing: 12) {
            Text("Project").font(.title2).bold()
            Text(project.name)
            Text("Address pool used: \(project.addressPoolUsed)")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(project.name)
    }
}

// MARK: - Branding

struct LogoView: View {
    var body: some View {
        if let ui = UIImage(named: "AppLogo") {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
                .frame(width: 96)
                .accessibilityLabel("Daliant logo")
        } else {
            Image(systemName: "lightbulb")
                .resizable()
                .scaledToFit()
                .frame(width: 96)
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

#Preview("Auth – Signed Out") {
    ContentView()
        .modelContainer(for: [Item.self, Org.self], inMemory: true)
}

@MainActor
private func previewSeededContainer() -> ModelContainer {
    let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: [Item.self, Org.self], configurations: cfg)
    let ctx = container.mainContext
    ctx.insert(Org(name: "Dox Electronics", slug: "dox-electronics", joinCode: "DX42K9"))
    ctx.insert(Item(name: "Smith Residence"))
    ctx.insert(Item(name: "Beach House"))
    return container
}

#Preview("Projects (Seeded)") {
    NavigationStack { ProjectsHomeView() }
        .modelContainer(previewSeededContainer())
}

#Preview("Org Onboarding (Seeded)") {
    NavigationStack { OrgOnboardingView() }
        .modelContainer(previewSeededContainer())
}
