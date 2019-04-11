//
//  InstallerApp.swift
//  Shredder
//
//  Created by Arnold Nefkens on 06/09/2018.
//  Copyright © 2018 Pro Warehouse.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation
import AppKit

struct InstallerApp {
    let name: String
    let path: String
    let version: String

    init(metadataItem: NSMetadataItem) {
        self.name = metadataItem.value(forAttribute: NSMetadataItemFSNameKey) as? String ?? ""
        self.path = metadataItem.value(forAttribute: NSMetadataItemPathKey) as? String ?? ""
        self.version = metadataItem.value(forAttribute: NSMetadataItemVersionKey) as? String ?? ""
    }

    var icon: NSImage {
        return NSWorkspace.shared.icon(forFile: self.path)
    }

    var canErase: Bool {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionValue = "\(osVersion.minorVersion).\(osVersion.patchVersion)"
        if osVersion.minorVersion >= 14
            && ( osVersion.minorVersion == 14 && osVersion.patchVersion >= 2 )
            && ( self.version < osVersionValue ) {
            return false
        }

        let value = (self.version > "13.4")
        return value
    }

    var displayName: String {
        if name.count < 4 {
            return name
        } else {
            let endIndex = name.index(name.endIndex, offsetBy: -4) // cuts off '.app'
            return String(name.prefix(upTo: endIndex))
        }
    }
}
