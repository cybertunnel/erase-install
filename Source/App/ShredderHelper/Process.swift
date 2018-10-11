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

class ProcessHelper {
    private var task: Process?

    init(command: CliCommand) {
        if task != nil {
            task?.terminate()
            task = nil
        }

        task = generateTask(command: command)
    }

    // MARK: - Public
    func execute() {
        task?.launch()
    }

    // MARK: - Private
    private func generateTask(command: CliCommand) -> Process {
        let task = Process()
        task.launchPath = command.launchPath
        if let arguments = command.arguments {
            task.arguments = arguments
        }
        return task
    }
}
