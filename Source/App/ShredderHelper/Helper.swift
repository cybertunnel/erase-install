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
        sendMessageToMain(value: "Helper Version asked.")
        if let versionToSend = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            mainAppService()?.didReceiveVersionOfHelper(version: versionToSend)
        }
    }

    func runCommand(path: String, arguments: [String]?) {
        sendMessageToMain(value: "Command Runs: path: \(path)")
        let command = CliCommand(launchPath: path, arguments: arguments)
        if activeProcessHelper != nil {
            activeProcessHelper = nil
        }
        activeProcessHelper = ProcessHelper.init(command: command)
        activeProcessHelper?.delegate = self
        activeProcessHelper!.execute()
        mainAppService()?.didStartWithCommand(command: "path: \(path), arguments: \(String(describing: arguments))")
    }

    func sendMessageToMain(value: String) {
        mainAppService()?.didReceiveLog(value: value)
    }

    func mainAppService() -> MainAppProtocol? {
        let xpcService = connectionToMain?.remoteObjectProxyWithErrorHandler { error -> Void in
            NSLog("XPC error: \(error)")
            } as? MainAppProtocol
        return xpcService
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

extension Helper: ProcessHelperProtocol {
    func didTerminateApp(normal: Bool) {
        // sever the active process helper
        activeProcessHelper = nil
        // inform delegate
        mainAppService()?.didTerminateHelper(normal: normal)
    }

    func didReceiveErrorOutput(value: String) {
        mainAppService()?.didReceiveErrorOutput(value: value)
    }

    func didReceiveLogEntry(value: String) {
        sendMessageToMain(value: value)
    }
}
