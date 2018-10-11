//
//  PickInstallerItem.swift
//  Shredder
//
//  Created by Arnold Nefkens on 25/09/2018.
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

import Cocoa

class PickInstallerItem: NSCollectionViewItem {
    private let selectedBorderWidth: CGFloat = 0.5
    private let borderWidthNone: CGFloat = 0.0
    private let selectedCornerRadius: CGFloat = 5.0

    func setupItem(installer: InstallerApp) {
        imageView?.image = installer.icon
        let displayName = "\(installer.displayName) (\(installer.version)) \n\(installer.path)"
        textField?.stringValue = displayName
    }

    override var isSelected: Bool {
        didSet {
            let borderColor = NSColor.init(named: "itemBorderColor")?.cgColor
            view.layer?.borderWidth = isSelected ? selectedBorderWidth : borderWidthNone
            view.layer?.borderColor = borderColor
            let selectedBGColor = NSColor.init(named: "itemBackgroundColor")?.cgColor
            view.layer?.backgroundColor = isSelected ? selectedBGColor : CGColor.clear
            view.layer?.cornerRadius = selectedCornerRadius
        }
    }
}
