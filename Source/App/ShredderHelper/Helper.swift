//
//  Helper.swift
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
import Security
import ServiceManagement

class Helper: NSObject, HelperAppProtocol, NSXPCListenerDelegate {
    var listener: NSXPCListener
    var connectionToMain: NSXPCConnection?
    let outputPipe = Pipe()
    var activeProcessHelper: ProcessHelper?

    override init() {
        self.listener = NSXPCListener(machServiceName: HelperConstants.helperServiceName)
        super.init()
        self.listener.delegate = self
    }

    /// Starts the helper daemon
    func run() {
        self.listener.resume()
        RunLoop.current.run()
    }

    func getHelperVersion() {
        if let versionToSend = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            let xpcService = connectionToMain?.remoteObjectProxyWithErrorHandler { error -> Void in
                NSLog("XPC error: \(error)")
                } as? MainAppProtocol
            xpcService?.didReceiveVersionOfHelper(version: versionToSend)
        }
    }

    func runCommand(path: String, arguments: [String]?) {
        let command = CliCommand(launchPath: path, arguments: arguments)
        if activeProcessHelper != nil {
            activeProcessHelper = nil
        }
        activeProcessHelper = ProcessHelper.init(command: command)
        activeProcessHelper!.execute()
        let xpcService = connectionToMain?.remoteObjectProxyWithErrorHandler { error -> Void in
            NSLog("XPC error: \(error)")
            } as? MainAppProtocol
        xpcService?.didStartWithCommand(command: "path: \(path), arguments: \(String(describing: arguments))")
    }

    // MARK: - NSXPCListenerDelegate
// swiftlint:disable colon
    func listener(_ listener:NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connectionToMain = connection
        connectionToMain?.exportedInterface = NSXPCInterface(with: HelperAppProtocol.self)
        connectionToMain?.remoteObjectInterface = NSXPCInterface(with: MainAppProtocol.self)
        connectionToMain?.exportedObject = self
        connectionToMain?.resume()
        return true
    }
// swiftlint:enable colon
}
