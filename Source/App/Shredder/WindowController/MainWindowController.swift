//
//  MainWindowController.swift
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

var background: Background?

class MainWindowController: NSWindowController {

    // Properties
    // We hold on to the viewControlles used in the app.
    // This ensures we use the same instances of these view controllers when we switch from one to another.
    var mainViewController: NSViewController?
    var pickerViewController: NSViewController?
    var validationViewController: NSViewController?

    override func windowDidLoad() {
        super.windowDidLoad()

        // Create and store the pointers of the used viewControllers.
        mainViewController = window?.contentViewController
        pickerViewController = storyboard?.instantiateController(withIdentifier: "pickInstaller") as? NSViewController
        validationViewController = storyboard?.instantiateController(withIdentifier: "checklist") as? NSViewController

        window?.isMovable = false

        // We create an background window and place it behind the main window.
        background = storyboard?.instantiateController(withIdentifier: "Background") as? Background
        background?.showWindow(self)
        background?.sendToBackground()
        NSApp.windows[0].level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
    }
}
