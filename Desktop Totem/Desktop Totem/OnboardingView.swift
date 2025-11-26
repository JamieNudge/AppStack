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
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to Desktop Totem")
                    .font(.system(size: 32, weight: .bold))
                
                Text("A small companion that quietly surfaces the apps you actually use.")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            
            // How it works section
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Building Your History")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Desktop Totem starts tracking from the moment you install it. As you use apps, it learns your patterns and builds a ranking. Your totem will populate as you work!")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                        .resizable()
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Find It in Your Menu Bar")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Look for this icon in your top menu bar (top-right corner). Click it to open the Desktop Window, or check the Dock for the full app.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "list.number")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Most-Used Apps")
                            .font(.system(size: 16, weight: .semibold))
                        Text("The totem pole shows your most-used apps, ranked by frequency. It updates automatically as you work.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "pin")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Always on Top")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Tap the pin icon to keep the Desktop Window visible above all other windows. Perfect for quick access!")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Got it!") {
                    onDismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
        .padding(40)
        .frame(width: 800, height: 600)
    }
}


