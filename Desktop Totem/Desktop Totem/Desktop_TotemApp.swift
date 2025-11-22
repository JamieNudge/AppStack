//
//  Desktop_TotemApp.swift
//  Desktop Totem
//
//  Created by Jamie on 16/11/2025.
//

import SwiftUI
import AppKit

// GLOBAL STATIC - Can NEVER be deallocated
private var globalMenuBarManager: MenuBarManager?

@main
struct Desktop_TotemApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    // Keep invisible window to prevent macOS from hiding status item
    var invisibleWindow: NSWindow?
    var desktopWindow: NSWindow?
    var onboardingWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create invisible window to keep app "alive"
        // This prevents macOS from hiding the status bar item
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.alphaValue = 0  // Completely invisible
        window.orderBack(nil)  // Put it in the back
        invisibleWindow = window
        
        // Set up as menu bar only app (no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Create menu bar manager and store in GLOBAL variable
        let manager = MenuBarManager()
        globalMenuBarManager = manager
        manager.setupMenuBar()
        
        // Listen for desktop window toggle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toggleDesktopWindow),
            name: NSNotification.Name("ToggleDesktopWindow"),
            object: nil
        )
        
        // Listen for window level updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateDesktopWindowLevel(_:)),
            name: NSNotification.Name("UpdateDesktopWindowLevel"),
            object: nil
        )
        
        // Monitor workspace to keep pinned window on top
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        // First-run onboarding
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "hasSeenOnboarding_v1") {
            showOnboarding()
        }
    }
    
    @objc func applicationDidActivate(_ notification: Notification) {
        // Keep desktop window on top if it's pinned - this fires for ANY app activation
        guard let window = desktopWindow,
              window.isVisible else { return }
        
        let isPinned = UserDefaults.standard.bool(forKey: "desktopAlwaysOnTop")
        
        if isPinned {
            // Get info about what app was activated
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                print("🔄 \(app.localizedName ?? "App") activated - re-ordering pinned Desktop Totem to front")
            }
            
            // Force the window back to the very front
            DispatchQueue.main.async {
                window.orderFrontRegardless()
            }
        }
    }
    
    private func showOnboarding() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Welcome to AppStack"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.contentView = NSHostingView(
            rootView: OnboardingView {
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding_v1")
                window.close()
            }
        )
        onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc func toggleDesktopWindow() {
        print("🪟 toggleDesktopWindow called")
        
        if let window = desktopWindow, window.isVisible {
            print("   Closing existing window")
            // Hide desktop window and go back to menu bar only
            window.close()
            desktopWindow = nil
            NSApp.setActivationPolicy(.accessory)
        } else {
            print("   Creating new window")
            // Switch to regular app to show desktop window properly
            NSApp.setActivationPolicy(.regular)
            print("   Switched to .regular policy")
            
            // Create and show desktop window
            let alwaysOnTop = UserDefaults.standard.bool(forKey: "desktopAlwaysOnTop")
            
            let window = NSWindow(
                contentRect: NSRect(x: 100, y: 100, width: 150, height: 640),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "AppStack"
            window.contentView = NSHostingView(rootView: DesktopTotemView())
            window.isReleasedWhenClosed = false
            
            print("   Window created, title: \(window.title)")
            
            // Set initial level based on saved preference
            if alwaysOnTop {
                window.level = .statusBar
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
                print("   Set to statusBar (pinned)")
            } else {
                window.level = .normal
                window.collectionBehavior = [.canJoinAllSpaces]
                print("   Set to normal (unpinned)")
            }
            
            // Activate the app to bring window to front
            NSApp.activate(ignoringOtherApps: true)
            
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            print("   Called makeKeyAndOrderFront + orderFrontRegardless")
            print("   Window isVisible: \(window.isVisible)")
            print("   Window isKeyWindow: \(window.isKeyWindow)")
            print("   Window frame: \(window.frame)")
            
            desktopWindow = window
            print("   ✅ Desktop window set")
        }
    }
    
    @objc func updateDesktopWindowLevel(_ notification: Notification) {
        print("📌 updateDesktopWindowLevel called")
        
        guard let window = desktopWindow else {
            print("   ❌ No desktop window")
            return
        }
        
        guard let userInfo = notification.userInfo else {
            print("   ❌ No userInfo")
            return
        }
        
        guard let alwaysOnTop = userInfo["alwaysOnTop"] as? Bool else {
            print("   ❌ No alwaysOnTop in userInfo")
            return
        }
        
        print("   Setting window to alwaysOnTop: \(alwaysOnTop)")
        
        if alwaysOnTop {
            print("   Setting to .statusBar level (stays above all normal windows)")
            window.level = .statusBar
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            print("   ✅ Window pinned")
        } else {
            print("   Setting to .normal level")
            window.level = .normal
            window.collectionBehavior = [.canJoinAllSpaces]
            print("   ✅ Window unpinned")
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
