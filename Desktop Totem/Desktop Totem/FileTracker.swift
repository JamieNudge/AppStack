//
//  FileTracker.swift
//  Desktop Totem
//
//  Created by Jamie on 16/11/2025.
//

import Foundation
import AppKit
import Combine

class FileTracker: ObservableObject {
    @Published var recentFiles: [FileItem] = []
    
    private let maxItems = 10
    private var refreshTimer: Timer?
    private var activationObserver: Any?
    private let trackingStartKey = "trackingStartDate_v1"
    private let notesKey = "appNotesByPath"
    
    init() {
        // One-time migration so this new version starts everyone from a clean slate.
        // This ensures that on install/update, any old counts are wiped and the totem
        // starts EMPTY until we begin tracking from this version onward.
        let defaults = UserDefaults.standard
        let migrationKey = "hasResetInitialFileCounts_v2"
        if !defaults.bool(forKey: migrationKey) {
            defaults.removeObject(forKey: "fileCounts")
            defaults.set(true, forKey: migrationKey)
        }
        
        // Ensure we have a tracking start date for strict "new usage only" behavior.
        if defaults.object(forKey: trackingStartKey) == nil {
            defaults.set(Date(), forKey: trackingStartKey)
            defaults.removeObject(forKey: "fileCounts")
        }
        
        loadRecentFiles()
        
        // Start automatic refresh so the pole can populate over time
        // without the user having to manually tap Refresh. Refresh every 2 minutes.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            self?.loadRecentFiles()
        }
        
        // Observe app activation so we can bump counts whenever the user
        // actively switches to an app (including ones that were already open).
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            
            let defaults = UserDefaults.standard
            var itemCounts: [String: Int] = defaults.dictionary(forKey: "fileCounts") as? [String: Int] ?? [:]
            
            // Apply the same filters as elsewhere.
            let excludedApps = [
                "Print Center", "Print Centre", "Keychain Access", "Activity Monitor",
                "Console", "Terminal", "System Settings", "System Preferences",
                "Disk Utility", "Migration Assistant", "Archive Utility",
                "Bluetooth File Exchange", "ColorSync Utility", "Digital Colour Meter",
                "Grapher", "Screenshot", "VoiceOver Utility", "AirPort Utility"
            ]
            
            guard app.activationPolicy == .regular,
                  app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
            
            let appName = app.localizedName ?? ""
            guard !appName.contains("Desktop Totem"),
                  !appName.contains("Desktop_Totem"),
                  !excludedApps.contains(where: { appName.contains($0) }) else { return }
            
            guard let appURL = app.bundleURL else { return }
            let path = appURL.path
            
            guard !path.contains("Desktop Totem"),
                  !path.contains("Desktop_Totem") else { return }
            
            let currentCount = itemCounts[path] ?? 0
            itemCounts[path] = currentCount + 2 // +2 each time user activates the app
            defaults.set(itemCounts, forKey: "fileCounts")
            
            // Refresh the pole to reflect the new counts.
            self.loadRecentFiles()
        }
    }
    
    deinit {
        if let observer = activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        refreshTimer?.invalidate()
    }
    
    func loadRecentFiles() {
        var items: [FileItem] = []
        let defaults = UserDefaults.standard
        
        // Strict fresh start: only count usage that happens AFTER a tracking
        // start date. Anything that happened before install/reset is ignored.
        let trackingStartDate: Date
        if let stored = defaults.object(forKey: trackingStartKey) as? Date {
            trackingStartDate = stored
        } else {
            let now = Date()
            trackingStartDate = now
            // New install/reset: clear any old counts and start from zero now.
            defaults.removeObject(forKey: "fileCounts")
            defaults.set(now, forKey: trackingStartKey)
        }
        
        var itemCounts: [String: Int] = defaults.dictionary(forKey: "fileCounts") as? [String: Int] ?? [:]
        
        // System utilities to exclude (these run but users don't actively use them)
        let excludedApps = [
            "Print Center", "Print Centre", "Keychain Access", "Activity Monitor",
            "Console", "Terminal", "System Settings", "System Preferences",
            "Disk Utility", "Migration Assistant", "Archive Utility",
            "Bluetooth File Exchange", "ColorSync Utility", "Digital Colour Meter",
            "Grapher", "Screenshot", "VoiceOver Utility", "AirPort Utility"
        ]
        
        // Clean up any Desktop Totem entries AND excluded system apps
        itemCounts = itemCounts.filter { path, _ in
            let url = URL(fileURLWithPath: path)
            let name = url.deletingPathExtension().lastPathComponent
            
            let isDesktopTotem = name.contains("Desktop Totem") || 
                                 name.contains("Desktop_Totem") ||
                                 path.contains("Desktop_Totem") ||
                                 path.contains("Desktop Totem")
            
            let isExcluded = excludedApps.contains { name.contains($0) }
            
            return !isDesktopTotem && !isExcluded
        }
        defaults.set(itemCounts, forKey: "fileCounts")
        
        // 1. Count ONLY the actively used app (frontmost), not every running app.
        // This approximates "next interaction" – an app only gets counted when
        // the user actually brings it to the front after tracking has started.
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.activationPolicy == .regular,
           frontmost.bundleIdentifier != Bundle.main.bundleIdentifier,
           let appName = frontmost.localizedName,
           !appName.contains("Desktop Totem"),
           !appName.contains("Desktop_Totem"),
           !excludedApps.contains(where: { appName.contains($0) }),
           let appURL = frontmost.bundleURL {
            
            let path = appURL.path
            
            // Double-check: don't add if it contains "Desktop Totem" in path
            if !path.contains("Desktop Totem") && !path.contains("Desktop_Totem") {
                let currentCount = itemCounts[path] ?? 0
                itemCounts[path] = currentCount + 2 // Small bonus for being actively used
            }
        }
        
        // 2. Get recent documents from macOS (only those accessed after trackingStartDate)
        // 2. Get recent documents from macOS (only those accessed after trackingStartDate)
        let recentDocuments = NSDocumentController.shared.recentDocumentURLs
        for docURL in recentDocuments.prefix(10) {
            let path = docURL.path
            
            // Only count documents accessed after trackingStartDate
            if let values = try? docURL.resourceValues(forKeys: [.contentAccessDateKey]),
               let accessDate = values.contentAccessDate,
               accessDate >= trackingStartDate {
                let currentCount = itemCounts[path] ?? 0
                itemCounts[path] = currentCount + 5 // Higher weight for actual document use
            }
        }
        
        // Save updated counts
        defaults.set(itemCounts, forKey: "fileCounts")
        
        // Convert to FileItems (only real user-facing apps!)
        for (path, count) in itemCounts {
            let url = URL(fileURLWithPath: path)
            let fileName = url.lastPathComponent
            let fileExtension = url.pathExtension
            let appName = url.deletingPathExtension().lastPathComponent
            
            // Skip Desktop Totem
            if path.contains("Desktop Totem") || 
               path.contains("Desktop_Totem") ||
               fileName.contains("Desktop Totem") ||
               fileName.contains("Desktop_Totem") {
                continue
            }
            
            // Skip non-.app files (bundles, XPC services, etc.)
            if fileExtension != "app" {
                continue
            }
            
            // Skip Helper apps and background processes
            if fileName.contains("Helper") ||
               fileName.contains("Agent") ||
               fileName.contains("Service") ||
               fileName.contains("Daemon") {
                continue
            }
            
            // Skip excluded system utilities
            if excludedApps.contains(where: { appName.contains($0) }) {
                continue
            }
            
            if FileManager.default.fileExists(atPath: path) {
                let item = FileItem(url: url, accessCount: count)
                items.append(item)
            }
        }
        
        // Sort by access count (real usage!)
        let sortedItems = items.sorted { $0.accessCount > $1.accessCount }.prefix(maxItems).map { $0 }
        
        // Update UI on main thread
        DispatchQueue.main.async { [weak self] in
            self?.recentFiles = sortedItems
        }
    }
    
    func openFile(_ item: FileItem) {
        // Use NSWorkspace.openApplication for all apps, then explicitly activate any
        // running instances we find. This keeps behavior consistent across apps that
        // behave differently with Spaces (like Xcode) without special-casing them.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let targetURL = item.url
            let path = targetURL.path
            print("🚀 AppStack openFile -> \(item.name) at \(path)")
            
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            
            NSWorkspace.shared.openApplication(at: targetURL, configuration: config) { app, error in
                if let error = error {
                    print("❌ Error opening app: \(error.localizedDescription)")
                } else if let runningApp = app {
                    print("✅ NSWorkspace opened or found running app: \(runningApp.localizedName ?? item.name)")
                } else {
                    print("⚠️ NSWorkspace.openApplication returned nil app for \(item.name)")
                }
                
                // Extra activation pass to help with full-screen / multi-Space cases.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let runningApps = NSWorkspace.shared.runningApplications
                    let matches = runningApps.filter { $0.bundleURL == targetURL }
                    
                    if matches.isEmpty {
                        print("⚠️ No runningApplications match for \(item.name) at \(targetURL.path)")
                    } else {
                        for match in matches {
                            print("🔁 Activating \(match.localizedName ?? item.name)")
                            match.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
                        }
                    }
                }
            }
        }
        
        // Increment access count and save
        var itemCounts: [String: Int] = UserDefaults.standard.dictionary(forKey: "fileCounts") as? [String: Int] ?? [:]
        let path = item.url.path
        itemCounts[path] = (itemCounts[path] ?? 0) + 3 // +3 for manual open
        UserDefaults.standard.set(itemCounts, forKey: "fileCounts")
        
        // Update local array
        if let index = recentFiles.firstIndex(where: { $0.id == item.id }) {
            recentFiles[index].accessCount += 3
            recentFiles[index].lastAccessed = Date()
            
            // Re-sort by access count
            recentFiles.sort { $0.accessCount > $1.accessCount }
        }
    }
    
    // MARK: - Quick Notes
    
    func note(for item: FileItem) -> String? {
        let path = item.url.path
        let notes = UserDefaults.standard.dictionary(forKey: notesKey) as? [String: String] ?? [:]
        guard let note = notes[path], !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return note
    }
    
    func hasNote(for item: FileItem) -> Bool {
        return note(for: item) != nil
    }
    
    func setNote(_ text: String?, for item: FileItem) {
        let path = item.url.path
        var notes = UserDefaults.standard.dictionary(forKey: notesKey) as? [String: String] ?? [:]
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if trimmed.isEmpty {
            // Remove note
            notes.removeValue(forKey: path)
        } else {
            notes[path] = trimmed
        }
        
        UserDefaults.standard.set(notes, forKey: notesKey)
    }
    
    func refresh() {
        loadRecentFiles()
    }
    
    func resetCounts() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "fileCounts")
        defaults.set(Date(), forKey: "trackingStartDate_v1")
        
        DispatchQueue.main.async { [weak self] in
            self?.recentFiles = []
        }
        
        loadRecentFiles()
    }
}

