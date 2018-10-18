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

let animationDuration: Double = 0.6
let animationTimingFunction: CAMediaTimingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeIn)

class ValidationViewController: NSViewController, Logging {

    // MARK: - Properties
    @IBOutlet private var continueButton: NSButton!
    @IBOutlet private var quitButton: NSButton!
    @IBOutlet private var headerTitle: NSTextField!
    @IBOutlet private var validationContainer: ValidationChecklistView!
    @IBOutlet private var eraseContainer: EraseView!
    @IBOutlet var continueLeadingConstraint: NSLayoutConstraint!

    // Helper Properties
    private let searchInstaller: SearchInstallers = SearchInstallers()
    private var progressState: ValidationViewControllProgressState = ValidationViewControllProgressState.checkForBattery
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

        if progressState == ValidationViewControllProgressState.checkForBattery {
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
        let alert = customAlert(messageTitle: NSLocalizedString("warningKey",
                                                               comment: "Warning"),
                                buttonLabels: buttonLabels)
        alert.informativeText = alertText

        alert.beginSheetModal(for: self.view.window!) { (response) in
            let cancelButtonResponseID = 1001
            if response.rawValue == cancelButtonResponseID {
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
        moveToQuitApp()
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
        log(message: "Validation: Starting Command to send")
        if let installerSelected = selectedInstaller {

            let arguments: [String] = ["--agreetolicense", "--eraseinstall"]
            var limit: Double = 300.0
            if installerSelected.version >= "14.0" {
                limit = 600.0
            }

            let completeCommandPath = "\(installerSelected.path)/Contents/Resources/startosinstall"
            let command = CommandToSend(launchPath: completeCommandPath,
                                        launchArguments: arguments)
//            let command = CommandToSend(launchPath: "/usr/sbin/system_profiler", launchArguments: [])
            self.xpcClient.sendCommandToHelper(command: command)
            self.continueButton.isHidden = true
            self.validationContainer.isHidden = true
            self.headerTitle.stringValue = NSLocalizedString("headerTitleEraseIsRunning", comment: "Erase is active")

            self.eraseContainer.displayEraseView(icon: installerSelected.icon, limit: limit)
            self.quitButton.isHidden = true
            self.isEraseCommandRunning = true
        }
    }

    // Validation steps.
    private func executeChecks() {
        self.continueButton.isEnabled = false
        switch progressState {
        case .checkForBattery:
            log(message: "Validation: Battery Status")
            validateBattery()
        case .checkingForFindMyMac:
            log(message: "Validation: Find My Mac Status")
            validateFindMyMac()
        case .checkForNetwork:
            log(message: "Validation: Network Status")
            validateNetwork()
        case .searchingForInstaller:
             log(message: "Validation: Search for Installer Status")
            // Start Searching
            searchInstaller.searchForInstallerApp()
        case .startEraseInstall:
             log(message: "Validation: Start Erase & Install")
            validationContainer.animate()
        case .quit:
            NSApp.terminate(self)
        }
    }

    // MARK: - Private Functions
    private func validateFindMyMac() {
        if validationHelper.checkFindMyMac() {
            log(message: "Validation: Find My Mac Status: Fail")
            hasFindMyMacEnabled = true
            validationContainer.setLabel(labelType: .findMyMac, error: true)
            progressState = ValidationViewControllProgressState.checkForNetwork
            executeChecks()
        } else {
            // Move to next phase
            log(message: "Validation: Find My Mac Status: Pass")
            progressState = ValidationViewControllProgressState.checkForNetwork
            validationContainer.setLabel(labelType: .findMyMac, error: false)
            executeChecks()
        }
    }

    private func validateNetwork() {
        if validationHelper.checkNetworkConnection() {
            log(message: "Validation: Network Status: Pass")
            validationContainer.setLabel(labelType: .network, error: false)
        } else {
            log(message: "Validation: Network Status: Fail")
            hasNoNetwork = true
            validationContainer.setLabel(labelType: .network, error: true)
        }
        progressState = ValidationViewControllProgressState.searchingForInstaller
        executeChecks()
    }

    private func validateBattery() {
        let batteryCapacityTreshold = 50
        if validationHelper.isRunningOnBattery(), validationHelper.currentBattryLevel() < batteryCapacityTreshold {
            log(message: "Validation: Battery Status: Fail")
            displayBatteryErrorAlert()
        } else {
            log(message: "Validation: Battery Status: Pass")
            progressState = .checkingForFindMyMac
            executeChecks()
        }
    }

    private func displayBatteryErrorAlert() {
        let currentCapacity = validationHelper.currentBattryLevel()
        let quitButtonTitle = NSLocalizedString("quitKey",
                                                comment: "Quit")
        let errorTitle = NSLocalizedString("runningBatteryAlertTitleKey",
                                           comment: "Title when running on battery")
        let errorPrefix = NSLocalizedString("runningBatteryAlertMessageKey",
                                            comment: "Prefix message")
        let errorCurrentCapacity = NSLocalizedString("runningBatteryAlertCurrentCapacityKey",
                                                     comment: "Current Capacity Prefix")

        let errorMessage = "\(errorPrefix)\(errorCurrentCapacity) \(currentCapacity)%"

        let alert = customAlert(messageTitle: errorTitle, buttonLabels: [quitButtonTitle])
        alert.informativeText = errorMessage
        alert.beginSheetModal(for: self.view.window!) { (response) in
            self.moveToQuitApp()
        }
    }

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
            errorMessage += newLines + NSLocalizedString("findMyMacEnabledMessageKey",
                                                         comment: "Find My Mac Enabled")
        }

        let alert = customAlert(messageTitle: NSLocalizedString("sorryKey",
                                                               comment: "Sorry"),
                                buttonLabels: [NSLocalizedString("quitKey",
                                                                 comment: "Quit")])
        alert.informativeText = errorMessage
        alert.beginSheetModal(for: self.view.window!) { (response) in
            self.moveToQuitApp()
        }
    }

    private func moveToStartState() {
        let customWindow = self.view.window?.windowController as? MainWindowController
        if let mainViewController = customWindow?.mainViewController {
            self.switchViewController(toDisplayViewController: mainViewController)
        }
    }

    private func moveToQuitApp() {
        self.progressState = ValidationViewControllProgressState.quit
        self.executeChecks()
    }

    private func displayInstallUodatedVersionOfHelperAlert() {
        let buttonLabels: [String] = [NSLocalizedString("installHelperButtonKey",
                                                        comment: "Install Helper")]
        let alert = customAlert(messageTitle: NSLocalizedString("sorryKey",
                                                               comment: "Sorry"),
                                buttonLabels: buttonLabels)
        alert.informativeText = NSLocalizedString("messeageInstallHelperAlertKey",
                                                  comment: "Install Updated Helper")
        alert.beginSheetModal(for: self.view.window!) { (response) in
            self.xpcClient.installHelperDaemon()
        }
    }

    private func customAlert(messageTitle: String, buttonLabels: [String]) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = messageTitle
        alert.alertStyle = .critical
        for buttonLabel in buttonLabels {
            alert.addButton(withTitle: buttonLabel)
        }
        return alert
    }
}

extension ValidationViewController: XPCServiceClientProtocol {
    func taskIsTerminated(normal: Bool) {
        NSLog("Task Terminated: \(normal)")
    }

    func connectionLost() {
        // Try again
        log(message: "Validation: Helper Connection lost.")
    }

    func connectionLostWhileInstallingHelper() {
        log(message: "Validation: Helper Connection lost.")
        prepareAndExecuteCommand()
    }

    func didReceiveVersion(value: String) {
        let localVersion = xpcClient.versionOfInstalledDeamon()
        if value == localVersion {
            log(message: "Validation: Helper versions do match")
            self.prepareAndExecuteCommand()
        } else {
            log(message: "Validation: Helper versions do not match")
            self.displayInstallUodatedVersionOfHelperAlert()
        }
    }

    func didInstallHelper() {
        log(message: "Validation: Helper Installed")
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
        progressState = ValidationViewControllProgressState.startEraseInstall
        if installers.count == 0 {
            log(message: "Validation: Search for Installer Status: No Installer found.")
            hasNoInstallerFound = true
            validationContainer.setLabel(labelType: .installer, error: true, installerName: "")
            executeChecks()
        } else if installers.count == 1, let installer = installers.first {
            log(message: "Validation: Search for Installer Status: One installer found.")
            let displayName: String = "\(installer.displayName) (\(installer.version))"
            validationContainer.setLabel(labelType: .installer, error: false, installerName: displayName)
            selectedInstaller = installer
            executeChecks()
        } else {
            // We have found more then one installer
            log(message: "Validation: Search for Installer Status: Mulitple installers found.")
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
