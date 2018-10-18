//
//  LogViewController.swift
//  Shredder
//
//  Created by Arnold Nefkens on 15/10/2018.
//  Copyright © 2018 Pro Warehouse.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
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

class LogViewController: NSViewController {

    private let logContentStore = LogContent.current
    @IBOutlet private var logContent: NSTextView!
    @IBOutlet private var logContainer: NSScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        logContent.string = logContentStore.entries

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(addEntryToLogWindow(notification:)),
                                               name: NSNotification.Name(rawValue: logEntryChangedNotificationName),
                                               object: nil)
    }

    @objc func addEntryToLogWindow(notification: Notification) {
        if let userInfo = notification.userInfo, let message = userInfo[logEntryKey] as? String {
            let attributes = [NSAttributedString.Key.foregroundColor: NSColor.textColor]
            let value = NSAttributedString(string: message, attributes: attributes)
            logContent.textStorage?.append(value)
            var point: NSPoint

            if (logContainer.documentView?.isFlipped)!, let maxY = logContainer.documentView?.frame.maxY {
                point = NSPoint(x: 0.0, y: maxY - logContainer.contentView.bounds.height)
            } else {
                point = NSPoint(x: 0.0, y: 0.0)
            }

            logContainer.documentView?.scroll(point)
        }
    }
}
