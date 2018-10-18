//
//  EraseView.swift
//  Shredder
//
//  Created by Arnold Nefkens on 02/10/2018.
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

class EraseView: NSBox {
    private let progressTimerInterval: TimeInterval = 1.0
    private let progressIncrement: Double = 1.0

    @IBOutlet var eraseProgressIndicator: NSProgressIndicator!
    @IBOutlet var eraseMessage: NSTextField!
    @IBOutlet var selectedInstallerImage: NSImageView!

    func displayEraseView(icon: NSImage, limit: Double) {
        self.isHidden = false
        eraseMessage.stringValue = NSLocalizedString("runningEraseCommandMessageKey", comment: "Erase Message")
        selectedInstallerImage.image = icon
        eraseProgressIndicator.increment(by: progressIncrement)
        eraseProgressIndicator.maxValue = limit
        Timer.scheduledTimer(withTimeInterval: progressTimerInterval, repeats: true) { (timer) in
            self.eraseProgressIndicator.increment(by: self.progressIncrement)
        }
    }
}
