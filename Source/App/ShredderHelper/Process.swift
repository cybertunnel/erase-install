//
//  Process.swift
//  ShredderHelper
//
//  Created by Arnold Nefkens on 08/08/2018.
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

import Foundation

class ProcessHelper: NSObject {
    private var task: Process?
    weak var delegate: ProcessHelperProtocol?

    init(command: CliCommand, delegateToSet: ProcessHelperProtocol) {
        delegate = delegateToSet

        super.init()

        if task != nil {
            task?.terminate()
            task = nil
        }

        task = self.generateTask(command: command)

    }

    // MARK: - Public
    func execute() {
        delegate?.didReceiveLogEntry(value: "Helper: Command starting Execution", forUI: false)
        let output = Pipe()
        let outputHandle = output.fileHandleForReading
        outputHandle.readabilityHandler = { [weak self] pipe in
            NSLog("Entering STD OUT")
            guard let weakSelf = self else {
                NSLog("Helper: In STD Out Handler: Helper is nil, returning")
                return
            }
            guard let weakDelegate = weakSelf.delegate else {
                NSLog("Helper: In STD Out Handler: Delegate is nil, returning")
                return
            }

           weakDelegate.didReceiveLogEntry(value: "Helper: In STD Out Handler", forUI: false)
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                // Update your view with the new text here
                weakDelegate.didReceiveLogEntry(value: line, forUI: false)
            } else {
                weakDelegate.didReceiveLogEntry(value: "Error decoding data: \(pipe.availableData)", forUI: false)
            }
        }
        task?.standardOutput = output

        let errorOutput = Pipe()
        let errorhandle = errorOutput.fileHandleForReading
        errorhandle.readabilityHandler = { [weak self] pipe in
            NSLog("Entering STD ERR")
            guard let weakSelf = self else {
                NSLog("Helper: In ERR Out Handler: Helper is nil, returning")
                return
            }
            guard let weakDelegate = weakSelf.delegate else {
                NSLog("Helper: In ERR Out Handler: Delegate is nil, returning")
                return
            }

            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                // Update your view with the new text here
                let message: String = "Error:\(line)"
                weakDelegate.didReceiveLogEntry(value: message, forUI: false)

            } else {
                weakDelegate.didReceiveLogEntry(value: "Error decoding data: \(pipe.availableData)", forUI: false)
            }
        }
        task?.standardError = errorOutput
        task?.launch()
    }

    // MARK: - Private
    private func generateTask(command: CliCommand) -> Process {
        let task = Process()
        task.launchPath = command.launchPath
        if let arguments = command.arguments {
            task.arguments = arguments
        }
        task.terminationHandler = { [weak self] process in
            NSLog("Entering TERM")
            guard let weakSelf = self else {
                NSLog("Helper: In TErmination Handler: Helper is nil, returning")
                return
            }
            guard let weakDelegate = weakSelf.delegate else {
                NSLog("Helper: In TERMINATION Out Handler: Delegate is nil, returning")
                return
            }
            if process.terminationStatus == 0 {
               weakDelegate.didTerminateApp(normal: true)
            } else {
                weakDelegate.didTerminateApp(normal: false)
            }

            // cleanup
            if let stderr = process.standardError as? Pipe {
                stderr.fileHandleForReading.readabilityHandler = nil
            }
            if let stdout = process.standardOutput as? Pipe {
                stdout.fileHandleForReading.readabilityHandler = nil
            }
            process.standardError = nil
            process.standardOutput = nil
            weakSelf.task = nil
        }
        return task
    }
}
