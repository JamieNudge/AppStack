//
//  MenuBarManager.swift
//  Desktop Totem
//
//  Created by Jamie on 19/11/2025.
//

import SwiftUI
import AppKit

class MenuBarManager {
    // CRITICAL: Strong references - never let these become nil
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var eventMonitor: Any?
    
    func setupMenuBar() {
        // Create status bar item with icon (square length keeps the icon a sensible size)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.isVisible = true
        
        if let button = statusItem?.button {
            // Use the app's icon in the menu bar for visual consistency
            button.image = NSApp.applicationIconImage
            // Explicitly size the image so it doesn't appear oversized in the menu bar
            button.image?.size = NSSize(width: 18, height: 18)
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.action = #selector(togglePopover)
            button.target = self
            button.isEnabled = true
            // Accessibility: make the menu bar icon discoverable to VoiceOver
            button.toolTip = "Desktop Totem — your most-used apps"
            button.setAccessibilityLabel("Desktop Totem")
            button.setAccessibilityHelp("Opens the Desktop Totem totem")
        }
        
        // Create popover with TotemView
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: TotemView())
        popover?.behavior = .transient
    }
    
    @objc func togglePopover() {
        // We only need to know that the button exists here; the popover position
        // is handled in showPopover().
        guard statusItem?.button != nil, let popover = popover else { return }
        
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // Start monitoring for clicks outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }
    
    private func closePopover() {
        popover?.performClose(nil)
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

