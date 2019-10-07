//
//  ProcessPTY.swift
//  nl.prowarehouse.ShredderHelper
//
//  Created by Arnold Nefkens on 29/08/2019.
//  Copyright © 2019 Pro Warehouse. All rights reserved.
//

import Foundation

class ProcessPTYHelper: NSObject {
    private let commandToExecute: CliCommand
    weak var delegate: ProcessHelperProtocol?

    init(command: CliCommand, delegateToSet: ProcessHelperProtocol) {
        delegate = delegateToSet
        commandToExecute = command

        super.init()
    }

    // MARK: - Public
    func executePTY() {
        delegate?.didReceiveLogEntry(value: "Helper: Command starting PseudoTerminal Execution", forUI: false)
        let path = commandToExecute.launchPath
        var argumentsToUse = [path]
        if let argumentsReceived = commandToExecute.arguments {
            argumentsToUse.append(contentsOf: argumentsReceived)
        }

        guard let pseudoTerminal = PseudoTeletypewriter(path: commandToExecute.launchPath,
                                                        arguments: argumentsToUse,
                                                        environment: ["TERM=ansi"]) else {
            NSLog("Failed to create pseudo terminal")
            return
        }

        // Handling output
        // There is only one output handler in the pseudoTerminal, have to resort to string comparison.
        pseudoTerminal.masterFileHandle.readabilityHandler = { [weak self] output in

            guard let weakSelf = self else {
                NSLog("Helper: PTY Output Handler: Helper is nil, returning")
                return
            }
            guard let weakDelegate = weakSelf.delegate else {
                NSLog("Helper: PTY Out Handler: Delegate is nil, returning")
                return
            }

            let dataFromOutput = output.availableData
            if dataFromOutput.isEmpty {
                pseudoTerminal.masterFileHandle.readabilityHandler = nil
                weakSelf.exitPTY(inError: true)
            }
            guard let valueToPrint = String(data: dataFromOutput, encoding: .utf8) else {
                weakDelegate.didReceiveLogEntry(value: "Error: No Data that is UTF 8 String", forUI: false)
                weakSelf.exitPTY(inError: false)
                return
            }

            var needToDisplayInUI: Bool = false
            if valueToPrint.starts(with: "Prepa") {
                needToDisplayInUI = true
            }
            weakDelegate.didReceiveLogEntry(value: "\(valueToPrint)", forUI: needToDisplayInUI)

            if valueToPrint.starts(with: "Error:") {
                // We need to stop We have an error, log entry is already sent,
                // we now can quit the hanlder and exit application.
                pseudoTerminal.masterFileHandle.readabilityHandler = nil
                weakSelf.exitPTY(inError: true)
            }
        }
        RunLoop.main.run()
        pseudoTerminal.waitUntilChildProcessFinishes()
    }

    // MARK: - Private
    private func exitPTY(inError: Bool) {
        delegate?.didTerminateApp(normal: inError)
    }
}
