//
//  TotemView.swift
//  Desktop Totem
//
//  Created by Jamie on 16/11/2025.
//

import SwiftUI
import AppKit

struct TotemView: View {
    @StateObject private var tracker = FileTracker()
    @State private var alwaysOnTop = UserDefaults.standard.bool(forKey: "alwaysOnTop")
    
    var body: some View {
        VStack(spacing: 0) {
            // Top cap with Desktop Totem icon
            VStack(spacing: 2) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.clear)
            
            // Totem pole items (show all 10 without scrolling)
            VStack(spacing: 4) {
                ForEach(Array(tracker.recentFiles.enumerated()), id: \.element.id) { index, item in
                    TotemItemView(
                        item: item,
                        rank: index + 1,
                        onActivate: {
                            // Open and activate target app using the same logic everywhere
                            tracker.openFile(item)
                        }
                    )
                }
            }
            .padding(.vertical, 8)
            .background(Color.clear)
            
            // Totem Base
            VStack(spacing: 6) {
                // Desktop Window toggle (full-width)
                Button(action: { toggleDesktopWindow() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 10))
                        Text("Desktop Window")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Show/Hide Desktop Window")
                .accessibilityLabel("Toggle desktop window")
                .accessibilityHint("Show or hide the full Desktop Totem window on the desktop")
                
                // Vertical utility buttons (icons only)
                VStack(alignment: .leading, spacing: 4) {
                    Button(action: { 
                        NSApplication.shared.terminate(nil)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 11))
                            Text("Quit")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Quit")
                    .accessibilityLabel("Quit Desktop Totem")
                    
                    Button(action: { tracker.resetCounts() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Reset counts")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Reset All Counts")
                    .accessibilityLabel("Reset counts")
                    .accessibilityHint("Clear usage counts and restart tracking")
                    
                    Button(action: {
                        // Try to aggressively hide all regular apps except Desktop Totem,
                        // and explicitly hide the current frontmost app as well.
                        let thisBundle = Bundle.main.bundleIdentifier
                        let workspace = NSWorkspace.shared
                        
                        if let front = workspace.frontmostApplication,
                           front.activationPolicy == .regular,
                           front.bundleIdentifier != thisBundle {
                            front.hide()
                        }
                        
                        for app in workspace.runningApplications {
                            guard app.activationPolicy == .regular else { continue }
                            if app.bundleIdentifier != thisBundle {
                                app.hide()
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.3.offgrid")
                                .font(.system(size: 11))
                            Text("Hide others")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Hide all other apps")
                    .accessibilityLabel("Hide all other apps")
                    .accessibilityHint("Clear the screen and keep only Desktop Totem visible")
                    
                    Button(action: { tracker.refresh() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                            Text("Refresh")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Refresh")
                    .accessibilityLabel("Refresh list")
                    .accessibilityHint("Update the stack based on recent usage")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.clear)
        }
        .frame(width: 80)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.18, blue: 0.45),
                    Color(red: 0.04, green: 0.08, blue: 0.24)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            // Set initial window level based on saved preference
            updateWindowLevel()
        }
    }
    
    private func updateWindowLevel() {
        // Access the NSWindow and set its level
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                if alwaysOnTop {
                    window.level = .floating
                    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                } else {
                    window.level = .normal
                    window.collectionBehavior = [.canJoinAllSpaces]
                }
            }
        }
    }
    
    private func toggleDesktopWindow() {
        // Post notification to AppDelegate to show/hide desktop window
        print("📢 Posting ToggleDesktopWindow notification")
        NotificationCenter.default.post(name: NSNotification.Name("ToggleDesktopWindow"), object: nil)
    }
}

struct TotemItemView: View {
    let item: FileItem
    let rank: Int
    let onActivate: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onActivate) {
            HStack(spacing: 8) {
                // Rank number (simple text)
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(rankColor)
                    .shadow(color: .black.opacity(0.5), radius: 1)
                    .frame(width: 20)
                
                // File icon
                Image(nsImage: item.icon)
                    .resizable()
                    .frame(width: 32, height: 32)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(Color.white.opacity(isHovering ? 0.1 : 0.0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .accessibilityLabel(Text("\(rank). \(item.name)"))
    }
    
    var rankColor: Color {
        switch rank {
        case 1:
            return Color.yellow // Gold
        case 2:
            return Color.gray // Silver
        case 3:
            return Color.orange // Bronze
        default:
            return Color.white.opacity(0.8)
        }
    }
}

#Preview {
    TotemView()
}

