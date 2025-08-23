//
//  LandingView.swift
//  Daliant Commission Tool
//
//  Created by Fred Dox on 8/23/25.
//

import SwiftUI

struct LandingView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "lightbulb")  // temporary logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96)
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)

                Text("Daliant Commission Tool")
                    .font(.title).bold()
                    .multilineTextAlignment(.center)

                Text("Commission Pod4 fixtures over Bluetooth.\nAssign DALI short addresses quickly—no site DALI loop.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                NavigationLink("Continue", destination: ProjectsPlaceholderView())
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

struct ProjectsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Projects")
                .font(.title2).bold()
            Text("This page will list your projects and let you create a new one.\nWe’ll wire it up in the next step.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding()
        }
        .padding()
    }
}
