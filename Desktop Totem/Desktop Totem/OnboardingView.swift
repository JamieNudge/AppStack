//
//  OnboardingView.swift
//  Desktop Totem
//
//  A very lightweight first-run overview for new users.
//

import SwiftUI

struct OnboardingView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Welcome to AppStack")
                    .font(.title2.bold())
                Spacer()
            }
            
            Text("A small companion that quietly surfaces the apps you actually use.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "list.number")
                        .foregroundColor(.yellow)
                    Text("The pole shows your most-used apps, updated as you work.")
                        .font(.footnote)
                }
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "pin")
                        .foregroundColor(.blue)
                    Text("Open the Desktop Window from the ☀️ menu bar icon and tap the pin to keep it on top.")
                        .font(.footnote)
                }
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "rectangle.3.offgrid")
                        .foregroundColor(.orange)
                    Text("Use “Hide others” to clear your screen and keep only AppStack visible.")
                        .font(.footnote)
                }
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .foregroundColor(.green)
                    Text("Add a quick note next to an app to remember what you meant to work on.")
                        .font(.footnote)
                }
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Got it") {
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380, height: 340)
    }
}


