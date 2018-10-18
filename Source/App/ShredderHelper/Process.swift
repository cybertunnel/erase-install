//
//  Process.swift
//  ShredderHelper
//
//  Created by Arnold Nefkens on 08/08/2018.
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
import NotificationCenter

struct CliCommand {
    let launchPath: String
    let arguments: [String]?
}

protocol ProcessHelperProtocol: class {
    /// Callback to inform delegate of updated log entry
    ///
    /// - Parameter value: log entry
    func didReceiveLogEntry(value: String)

    /// Callback to inform delegate of error output.
    ///
    /// - Parameter value: error content.
    func didReceiveErrorOutput(value: String)

    /// Callback to inform when the app is terminated.
    ///
    /// - Returns: True is exit 0 else false.
    func didTerminateApp(normal: Bool)
}

class ProcessHelper: NSObject {
    private var task: Process?
    weak var delegate: ProcessHelperProtocol?

    init(command: CliCommand) {
        super.init()

        if task != nil {
            task?.terminate()
            task = nil
        }

        task = self.generateTask(command: command)
    }

    // MARK: - Public
    func execute() {
        delegate?.didReceiveLogEntry(value: "Helper: Command starting Execution")
        let output = Pipe()
        let outputHandle = output.fileHandleForReading
        outputHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                // Update your view with the new text here
                self.delegate?.didReceiveLogEntry(value: line)
            } else {
                self.delegate?.didReceiveLogEntry(value: "Error decoding data: \(pipe.availableData)")
            }
        }
        task?.standardOutput = output

        let errorOutput = Pipe()
        let errorhandle = errorOutput.fileHandleForReading
        errorhandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                // Update your view with the new text here
                let message: String = "Error:\(line)"
                self.delegate?.didReceiveLogEntry(value: message)
            } else {
                self.delegate?.didReceiveLogEntry(value: "Error decoding data: \(pipe.availableData)")
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
        task.terminationHandler = { process in
            if process.terminationStatus == 0 {
                self.delegate?.didTerminateApp(normal: true)
            } else {
                self.delegate?.didTerminateApp(normal: false)
            }
        }
        return task
    }
}
