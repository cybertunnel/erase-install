//
//  EraseView.swift
//  Shredder
//
//  Created by Arnold Nefkens on 02/10/2018.
//  Copyright © 2019 Pro Warehouse.
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
import Foundation

class EraseView: NSBox {
    @IBOutlet var eraseMessage: NSTextField!
    @IBOutlet var selectedInstallerImage: NSImageView!
    @IBOutlet var spinner: NSProgressIndicator!

    func displayEraseView(icon: NSImage, limit: Double) {
        self.isHidden = false

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(displayMessage(notification:)),
                                               name: NSNotification.Name(rawValue: displayMessageInUINotificationName),
                                               object: nil)

        spinner.startAnimation(spinner)
        let messageValue = NSLocalizedString("headerTitleEraseIsRunning", comment: "Preparing")
        eraseMessage.stringValue = "\(messageValue)..."
        selectedInstallerImage.image = icon
    }

    @objc func displayMessage(notification: Notification) {
        if let userInfo = notification.userInfo, let message = userInfo[logEntryKey] as? String {
            eraseMessage.stringValue = message
        }
    }
}
