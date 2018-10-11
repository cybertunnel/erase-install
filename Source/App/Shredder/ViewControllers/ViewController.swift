//
//  ViewController.swift
//  Shredder
//
//  Created by Arnold Nefkens on 07/08/2018.
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
import Cocoa
import SystemConfiguration

class ViewController: NSViewController {
    // MARK: - Outlets
    // Containers
    @IBOutlet private var explanationContainer: NSBox!

    // Explanation Container
    @IBOutlet private  var imageView: NSImageView!
    @IBOutlet private  var image: NSImageCell!
    @IBOutlet private  var explanationLabel: NSTextField!

    // Main Buttons and Header Label
    @IBOutlet private  var quitButton: NSButton!
    @IBOutlet private  var continueButton: NSButton!
    @IBOutlet private  var headerLabel: NSTextField!

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareUI()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        let validationHelper: ValidationHelper = ValidationHelper()
        if !validationHelper.checkOSVersion() || !validationHelper.checkForAPFS() {
            changeToQuitState(message: NSLocalizedString("CorrectOSorAPFSNotTrueKey",
                                                         comment: "Not Correct OS or APFS."))
        }
    }

    // MARK: - Actions
    @IBAction func continueAction(_ sender: Any) {
        let customWindow = self.view.window?.windowController as? MainWindowController
        if let checklistViewController = customWindow?.validationViewController as? ValidationViewController {
            self.switchViewController(toDisplayViewController: checklistViewController)
        }
    }

    @IBAction func quitAction(_ sender: Any) {
        NSApp.terminate(self)
    }

    func moveToStartState() {
        explanationContainer.isHidden = false
        headerLabel.stringValue = NSLocalizedString("headerTitleStart", comment: "Erase & Install")
        continueButton.isHidden = false
    }

    func changeToQuitState(message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("sorryKey", comment: "Sorry")
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: NSLocalizedString("quitKey", comment: "Quit"))
        alert.beginSheetModal(for: self.view.window!) { (response) in
            NSApp.terminate(self)
        }
    }

    // MARK: - Private Functions
    private func prepareUI() {
        //Containers
        explanationContainer.isHidden = false

        //Buttons
        continueButton.title = NSLocalizedString("continueButtonKey",
                                                 comment: "Continue Button")
        continueButton.alternateTitle = NSLocalizedString("continueButtonKey",
                                                          comment: "Continue Button")
        continueButton.image = NSImage(named: "next")
        continueButton.imagePosition = NSControl.ImagePosition.imageAbove
        quitButton.title = NSLocalizedString("quitKey",
                                             comment: "Quit")
        quitButton.image = NSImage(named: "cancel")
        quitButton.imagePosition = NSControl.ImagePosition.imageAbove

        explanationLabel.stringValue = NSLocalizedString("explanationAndPurposeOfAppKey",
                                                         comment: "Explanation Or Purpose of app.")
        headerLabel.stringValue = NSLocalizedString("headerTitleStart",
                                                    comment: "Erase & Install")
    }
}
