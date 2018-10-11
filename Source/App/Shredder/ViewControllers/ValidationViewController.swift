//
//  ValidationViewController.swift
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

import Foundation
import AppKit
import Cocoa
import QuartzCore

enum ProgressState: Int {
    case checkForNetwork = 0
    case checkingForFindMyMac
    case searchingForInstaller
    case startEraseInstall
    case quit
}

let animationDuration: Double = 0.6
let animationTimingFunction: CAMediaTimingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeIn)

class ValidationViewController: NSViewController {

    // MARK: - Properties
    @IBOutlet private var continueButton: NSButton!
    @IBOutlet private var quitButton: NSButton!
    @IBOutlet private var headerTitle: NSTextField!
    @IBOutlet private var validationContainer: ValidationChecklistView!
    @IBOutlet private var eraseContainer: EraseView!
    @IBOutlet var continueLeadingConstraint: NSLayoutConstraint!

    // Helper Properties
    private let searchInstaller: SearchInstallers = SearchInstallers()
    private var progressState: ProgressState = ProgressState.checkingForFindMyMac
    private let xpcClient: XPCServiceClient = XPCServiceClient()
    private let validationHelper: ValidationHelper = ValidationHelper()

    // ValidationStore
    private var hasNoNetwork: Bool = false
    private var hasFindMyMacEnabled: Bool = false
    private var hasNoInstallerFound: Bool = false
    private var isEraseCommandRunning: Bool = false

    // Public Properties
    var selectedInstaller: InstallerApp?
    var displayValidationAnimation: Bool = false

    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        xpcClient.clientDelegate = self
        validationContainer.delegate = self
        searchInstaller.delegate = self
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        if progressState == ProgressState.checkingForFindMyMac {
            executeChecks()
        }

        if displayValidationAnimation {
            displayValidationAnimation = false

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = animationDuration
                context.timingFunction = animationTimingFunction
                context.allowsImplicitAnimation = true

                self.quitButton.isHidden = false
                self.continueLeadingConstraint.animator().constant = 86.0
            }, completionHandler: {
                self.executeChecks()
            })
        }
    }

    // MARK: - IB Actions
    @IBAction func continueAction(_ sender: Any) {
        var alertText = NSLocalizedString("areYouSureToEraseAndInstallMessageKey",
                                          comment: "Are you sure to erase")
        if !xpcClient.checkIfHelperInstalled() {
           alertText = NSLocalizedString("areYouSureToEraseAndInstallHelperMessageKey",
                                         comment: "Continue with installing Helper")
        }
        // Display Action Sheet with final warning
        let buttonLabels = [NSLocalizedString("startEraseAndInstallButtonKey",
                                              comment: "Start Erase & Install"),
                            NSLocalizedString("cancelButtonKey",
                                              comment: "Cancel")]
        let alert = customAlert(messageText: NSLocalizedString("warningKey",
                                                               comment: "Warning"),
                                buttonLabels: buttonLabels)
        alert.informativeText = alertText
        alert.beginSheetModal(for: self.view.window!) { (response) in
            if response.rawValue == 1001 {
                self.moveToStartState()
            } else {
                if self.xpcClient.checkIfHelperInstalled() {
                    self.xpcClient.getVersionOfHelper()
                } else {
                    self.xpcClient.installHelperDaemon()
                }
            }
        }
    }

    @IBAction func quitAction(_ sender: Any) {
        progressState = .quit
        executeChecks()
    }

    // MARK: - Public Functions
    func updateInstallerLabel() {
        if let selected = selectedInstaller {
            let displayName = "\(selected.displayName) (\(selected.version))"
            validationContainer.setLabel(labelType: .installer, error: false, installerName: displayName)
        }
    }

    // MARK: - Private Functions
    private func setupUI() {
        continueButton.title = NSLocalizedString("continueButtonKey", comment: "Continue Button")
        quitButton.title = NSLocalizedString("quitKey", comment: "Quit Button")
        headerTitle.stringValue = NSLocalizedString("headerTitleChecklist", comment: "Checklist")
        validationContainer.isHidden = true
    }

    private func prepareAndExecuteCommand() {
        if let installerSelected = selectedInstaller {
            let completeCommandPath = "\(installerSelected.path)/Contents/Resources/startosinstall"
            let command = CommandToSend(launchPath: completeCommandPath,
                                        launchArguments: ["--agreetolicense", "--eraseinstall"])
//            let command = CommandToSend(launchPath: "/usr/sbin/systemsetup", launchArguments: ["-getremotelogin"])
            self.xpcClient.sendCommandToHelper(command: command)
            self.continueButton.isHidden = true
            self.validationContainer.isHidden = true
            self.headerTitle.stringValue = NSLocalizedString("headerTitleEraseIsRunning", comment: "Erase is active")
            self.eraseContainer.displayEraseView(icon: installerSelected.icon)
            self.quitButton.isHidden = true
            self.isEraseCommandRunning = true
        }
    }

    // Validation steps.
    private func executeChecks() {
        self.continueButton.isEnabled = false
        switch progressState {
        case .checkingForFindMyMac:
            if validationHelper.checkFindMyMac() {
                hasFindMyMacEnabled = true
                validationContainer.setLabel(labelType: .findMyMac, error: true)
                progressState = ProgressState.checkForNetwork
                self.executeChecks()
            } else {
                // Move to next phase
                progressState = ProgressState.checkForNetwork
                validationContainer.setLabel(labelType: .findMyMac, error: false)
                self.executeChecks()
            }
        case .checkForNetwork:
            if validationHelper.checkNetworkConnection() {
                validationContainer.setLabel(labelType: .network, error: false)
            } else {
                hasNoNetwork = true
                validationContainer.setLabel(labelType: .network, error: true)
            }
            progressState = ProgressState.searchingForInstaller
            self.executeChecks()
        case .searchingForInstaller:
            // Start Searching
            searchInstaller.searchForInstallerApp()
        case .startEraseInstall:
            validationContainer.animate()
        case .quit:
            NSApp.terminate(self)
        }
    }

    // MARK: - Private Functions
    /// Displays an Sheet with an alert. It will inform the user which checks failed.
    private func displayErrorAlert() {
        var errorMessage = ""
        let newLines = "\n\n"
        if hasNoInstallerFound {
            errorMessage = NSLocalizedString("noInstallerFoundErrorMessageKey",
                                             comment: "No Installer Found")
        }
        if hasNoNetwork {
            errorMessage += newLines + NSLocalizedString("noNetworkMessageKey",
                                                         comment: "No Network")
        }
        if hasFindMyMacEnabled {
            errorMessage += newLines + NSLocalizedString("findMyMacContentLabelKey",
                                                         comment: "Find My Mac Disabled")
        }

        let alert = customAlert(messageText: NSLocalizedString("sorryKey",
                                                               comment: "Sorry"),
                                buttonLabels: [NSLocalizedString("quitKey",
                                                                 comment: "Quit")])
        alert.informativeText = errorMessage
        alert.beginSheetModal(for: self.view.window!) { (response) in
            self.progressState = ProgressState.quit
            self.executeChecks()
        }
    }

    private func moveToStartState() {
        let customWindow = self.view.window?.windowController as? MainWindowController
        if let mainViewController = customWindow?.mainViewController {
            self.switchViewController(toDisplayViewController: mainViewController)
        }
    }

    private func displayInstallUodatedVersionOfHelperAlert() {
        let buttonLabels: [String] = [NSLocalizedString("installHelperButtonKey",
                                                        comment: "Install Helper")]
        let alert = customAlert(messageText: NSLocalizedString("sorryKey",
                                                               comment: "Sorry"),
                                buttonLabels: buttonLabels)
        alert.informativeText = NSLocalizedString("messeageInstallHelperAlertKey",
                                                  comment: "Install Updated Helper")
        alert.beginSheetModal(for: self.view.window!) { (response) in
            self.xpcClient.installHelperDaemon()
        }
    }

    private func customAlert(messageText: String, buttonLabels: [String]) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.alertStyle = .critical
        for buttonLabel in buttonLabels {
            alert.addButton(withTitle: buttonLabel)
        }
        return alert
    }
}

extension ValidationViewController: XPCServiceClientProtocol {
    func connectionLost() {
        // Try again
        NSLog("Send the command again.")
        prepareAndExecuteCommand()
    }

    func didReceiveVersion(value: String) {
        let localVersion = xpcClient.versionOfInstalledDeamon()
        if value == localVersion {
            self.prepareAndExecuteCommand()
        } else {
            self.displayInstallUodatedVersionOfHelperAlert()
        }
    }

    func didInstallHelper() {
        prepareAndExecuteCommand()
    }
}

extension ValidationViewController: ValidationCheckListViewProtocol {
    func didAnimate() {
        if hasNoInstallerFound || hasNoNetwork || hasFindMyMacEnabled {
            displayErrorAlert()
            continueButton.isEnabled = false
        } else {
            continueButton.isEnabled = true
        }
    }
}

extension ValidationViewController: PickInstallerViewControllerProtocol {
    func didAnimateButtons() {
        quitButton.isHidden = true
        continueLeadingConstraint.constant = 17.0
    }
}

extension ValidationViewController: SearchInstallersProtocol {
    func didFindInstallers(installers: [InstallerApp]) {
        progressState = ProgressState.startEraseInstall
        if installers.count == 0 {
            hasNoInstallerFound = true
            validationContainer.setLabel(labelType: .installer, error: true, installerName: "")
            executeChecks()
        } else if installers.count == 1, let installer = installers.first {
            let displayName: String = "\(installer.displayName) (\(installer.version))"
            validationContainer.setLabel(labelType: .installer, error: false, installerName: displayName)
            selectedInstaller = installer
            executeChecks()
        } else {
            // We have found more then one installer
            // display Picker
            let customWindow = self.view.window?.windowController as? MainWindowController
            if let pickerViewController = customWindow?.pickerViewController as? PickInstallerViewController {
                pickerViewController.foundInstallers = installers
                pickerViewController.delegate = self
                self.switchViewController(toDisplayViewController: pickerViewController)
            }
        }
    }
}
