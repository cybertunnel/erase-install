//
//  ValidationChecklistView.swift
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

protocol ValidationCheckListViewProtocol: class {
    /// Callback to inform the delegate that the animation is done.
    func didAnimate()
}

enum LabelType: Int {
    case installer
    case network
    case findMyMac
}

class ValidationChecklistView: NSBox {

    weak var delegate: ValidationCheckListViewProtocol?

    @IBOutlet private var searchProgressLabel: NSTextField!
    @IBOutlet private var searchLabelWidthContraint: NSLayoutConstraint!
    @IBOutlet private var checkNetworkLabel: NSTextField!
    @IBOutlet private var checkNetworkWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var checkFindMyMacLabel: NSTextField!
    @IBOutlet private var findMyMacWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var checkMarkSearchInstaller: NSImageView!
    @IBOutlet private var checkMarkCheckNetwork: NSImageView!
    @IBOutlet private var checkMarkFindMyMac: NSImageView!
    @IBOutlet private var checklistContainer: NSBox!

    /// Starts the animation in the view.
    func animate() {
        self.isHidden = false
        let widthConstant: CGFloat = 250.0
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = animationTimingFunction
            self.checkMarkSearchInstaller.isHidden = false
            self.searchLabelWidthContraint.animator().constant = widthConstant
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = animationDuration
                context.timingFunction = animationTimingFunction
                self.checkMarkFindMyMac.isHidden = false
                self.findMyMacWidthConstraint.animator().constant = widthConstant
            }, completionHandler: {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = animationDuration
                    context.timingFunction = animationTimingFunction
                    self.checkMarkCheckNetwork.isHidden = false
                    self.checkNetworkWidthConstraint.animator().constant = widthConstant
                }, completionHandler: {
                    self.delegate?.didAnimate()
                })
            })
        })
    }

    /// Helper to set the correct values in the labels in the view
    ///
    /// - Parameters:
    ///   - labelType: Type that detirmins which label to set
    ///   - error: Bool used to diff between error state
    ///   - installerName: Optional String to display the selected Installer.
    func setLabel(labelType: LabelType, error: Bool = false, installerName: String? = "") {
        let errorImage = NSImage(named: "Warning")
        switch labelType {
        case .installer:
            if error {
                checkMarkSearchInstaller.image = errorImage
                searchProgressLabel.stringValue = NSLocalizedString("searchProgressNoInstallerFound",
                                                                    comment: "No Installer Found")
            } else {
                searchProgressLabel.stringValue = installerName ?? ""
            }
        case .findMyMac:
            if error {
                checkMarkFindMyMac.image = errorImage
                checkFindMyMacLabel.stringValue = NSLocalizedString("findMyMacEnabledMessageKey",
                                                                    comment: "Find My Mac Enabled")
            } else {
                checkFindMyMacLabel.stringValue = NSLocalizedString("findMyMacDisableMessageKey",
                                                                    comment: "Find My Mac Disabled")
            }
        case .network:
            if error {
                checkMarkCheckNetwork.image = errorImage
                checkNetworkLabel.stringValue = NSLocalizedString("noNetworkMessageKey",
                                                                  comment: "There is no active network found key.")
            } else {
                checkNetworkLabel.stringValue = NSLocalizedString("checkNetworkFoundKey",
                                                                  comment: "There is an active network found key.")
            }
        }
    }
}
