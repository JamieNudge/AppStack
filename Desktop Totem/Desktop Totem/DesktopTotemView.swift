//
//  DesktopTotemView.swift
//  Desktop Totem
//
//  Created by Jamie on 19/11/2025.
//

import SwiftUI
import AppKit

struct DesktopTotemView: View {
    @StateObject private var tracker = FileTracker()
    @State private var alwaysOnTop = UserDefaults.standard.bool(forKey: "desktopAlwaysOnTop")
    @State private var noteEditorItem: FileItem?
    @State private var noteEditorText: String = ""
    @State private var isShowingNoteEditor = false
    @State private var activeNoteText: String?
    @State private var isShowingActiveNote = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Top cap with Desktop Totem icon (decorative only)
            VStack(spacing: 2) {
                Text("📚")
                    .font(.system(size: 46))
                    .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .accessibilityHidden(true) // Don't trap VoiceOver focus on the icon
            
            // Totem pole items
            VStack(spacing: 2) {
                ForEach(Array(tracker.recentFiles.enumerated()), id: \.element.id) { index, item in
                    DesktopTotemItemView(
                        item: item,
                        rank: index + 1,
                        hasNote: tracker.hasNote(for: item),
                        onOpen: {
                            if let note = tracker.note(for: item) {
                                activeNoteText = note
                                isShowingActiveNote = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    // Hide note after a short delay
                                    if activeNoteText == note {
                                        isShowingActiveNote = false
                                    }
                                }
                            }
                            tracker.openFile(item)
                        },
                        onEditNote: {
                            noteEditorItem = item
                            noteEditorText = tracker.note(for: item) ?? ""
                            isShowingNoteEditor = true
                        }
                    )
                }
            }
            .accessibilityElement(children: .contain) // Expose each row to VoiceOver
            .padding(.vertical, 4)
            .background(Color.clear)
            
            Spacer()
            
            // Totem Base
            VStack(spacing: 4) {
                // Always on Top toggle
                Button(action: { 
                    alwaysOnTop.toggle()
                    print("📌 Pin toggled to: \(alwaysOnTop)")
                    UserDefaults.standard.set(alwaysOnTop, forKey: "desktopAlwaysOnTop")
                    print("📌 Saved to UserDefaults")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UpdateDesktopWindowLevel"),
                        object: nil,
                        userInfo: ["alwaysOnTop": alwaysOnTop]
                    )
                    print("📌 Posted notification with alwaysOnTop: \(alwaysOnTop)")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: alwaysOnTop ? "pin.fill" : "pin")
                            .font(.system(size: 11))
                        Text(alwaysOnTop ? "Unpin Desktop Totem" : "Pin Desktop Totem")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(alwaysOnTop ? Color.blue.opacity(0.6) : Color.white.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(alwaysOnTop ? "Unpin Desktop Totem" : "Pin Desktop Totem")
                .accessibilityHint(alwaysOnTop ? "Allow other windows to cover Desktop Totem" : "Keep Desktop Totem on top of other windows")
                
                // Utility buttons
                HStack(spacing: 10) {
                    // Reset counts
                    Button(action: { tracker.resetCounts() }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("Reset All Counts")
                    .accessibilityLabel("Reset counts")
                    .accessibilityHint("Clear usage counts and restart tracking")
                    
                    // Hide all other apps / clear screen (including current frontmost app)
                    Button(action: {
                        // Safest system-supported path: make Desktop Totem active,
                        // then ask macOS to hide all other apps.
                        NSApp.activate(ignoringOtherApps: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            NSApp.hideOtherApplications(nil)
                        }
                    }) {
                        Image(systemName: "rectangle.3.offgrid")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .help("Hide all other apps")
                    .accessibilityLabel("Hide all other apps")
                    .accessibilityHint("Clear the screen and keep only AppStack visible")
                    
                    // Refresh
                    Button(action: { tracker.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 13))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        // Quick note editor sheet
        .sheet(isPresented: $isShowingNoteEditor) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Note")
                    .font(.headline)
                if let item = noteEditorItem {
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                TextField("What are you working on?", text: $noteEditorText)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Clear") {
                        if let item = noteEditorItem {
                            tracker.setNote(nil, for: item)
                        }
                        noteEditorText = ""
                        isShowingNoteEditor = false
                    }
                    Spacer()
                    Button("Cancel") {
                        isShowingNoteEditor = false
                    }
                    Button("Save") {
                        if let item = noteEditorItem {
                            tracker.setNote(noteEditorText, for: item)
                        }
                        isShowingNoteEditor = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .frame(width: 320)
        }
        // Active note overlay (gentle nudge)
        .overlay(
            Group {
                if isShowingActiveNote, let text = activeNoteText {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.white)
                            Text(text)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .truncationMode(.tail)
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 12)
                    }
                    .transition(.opacity)
                    // Don't let this temporary overlay interfere with VoiceOver focus
                    .accessibilityHidden(true)
                }
            }
        )
    }
}

struct DesktopTotemItemView: View {
    let item: FileItem
    let rank: Int
    let hasNote: Bool
    let onOpen: () -> Void
    let onEditNote: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 6) {
                // Rank indicator
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.4), radius: 1.5, x: 0, y: 1.5)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1)
                }
                
                // File icon
                Image(nsImage: item.icon)
                    .resizable()
                    .frame(width: 32, height: 32)
                
                // Quick note indicator
                Button(action: onEditNote) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(hasNote ? Color.yellow.opacity(0.95) : Color.clear)
                            .frame(width: 14, height: 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.7), lineWidth: hasNote ? 0 : 1)
                            )
                        Image(systemName: "note.text")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(hasNote ? .black : .white.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(hasNote ? "Edit note for \(item.name)" : "Add note for \(item.name)")
                .accessibilityHint("Store a short reminder for this app")
            }
            .padding(.horizontal, 10)
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
        .scaleEffect(isHovering ? 1.02 : 1.0)
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

