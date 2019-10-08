//
//  ProcessHelperProtocol.swift
//  Shredder
//
//  Created by Arnold Nefkens on 29/08/2019.
//  Copyright © 2019 Pro Warehouse. All rights reserved.
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

struct CliCommand {
    let launchPath: String
    let arguments: [String]?
}

protocol ProcessHelperProtocol: class {
    /// Callback to inform delegate of updated log entry
    ///
    /// - Parameter value: log entry
    /// - Parameter forUI: Bool indicator to define if the message needs to be displayed in UI Component.
    func didReceiveLogEntry(value: String, forUI: Bool)

    /// Callback to inform delegate of error output.
    ///
    /// - Parameter value: error content.
    func didReceiveErrorOutput(value: String)

    /// Callback to inform when the app is terminated.
    ///
    /// - Returns: True is exit 0 else false.
    func didTerminateApp(normal: Bool)
}
