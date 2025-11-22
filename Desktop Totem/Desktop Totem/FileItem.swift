//
//  FileItem.swift
//  Desktop Totem
//
//  Created by Jamie on 16/11/2025.
//

import Foundation
import AppKit

struct FileItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let icon: NSImage
    var accessCount: Int
    var lastAccessed: Date
    
    init(url: URL, accessCount: Int = 1) {
        self.url = url
        self.name = url.lastPathComponent
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
        self.accessCount = accessCount
        self.lastAccessed = Date()
    }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }
}

