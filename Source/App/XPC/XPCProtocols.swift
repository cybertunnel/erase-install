//
//  XPCProtocols.swift
//  Shredder
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
/// Protocol that exposes the functions on the Helper process.
/// This protocol performs as a proxy of the helper app in the main app.
/// When the proxy function is called, the actual implementation on the Helper App is called.
@objc(HelperAppProtocol)
protocol HelperAppProtocol {

    /// Tries to fetch the version of the helper CLI application
    func getHelperVersion()

    /// Execute the command in a elevated privelege level.
    ///
    /// - Parameters:
    ///   - path: The full path when the executable can be found on the system
    ///   - arguments: Optional array of arguments to send along with the executable.
    ///   - usePTY: Bool value to indicate if you want to use the PseudoTermninal to execute the command with.
    ///             (startosinstall uses the pty to display the output.)
    func runCommand(path: String, arguments: [String]?, usePTY: Bool)
}

/// Protocol to enable callbacks to the Main App. The protocol performs as a proxy of the main app in the helper app.
/// When the proxy function is called, the actual implementation on the Main App is called.
@objc(MainAppProtocol)
protocol MainAppProtocol {
    /// Callback interface for the retrivial of the version of the helper.
    ///
    /// - Parameter version: Version of the helper app installed.
    func didReceiveVersionOfHelper(version: String)

    /// Callback to inform the command is received and being executed
    ///
    /// - Parameter command: The command send to help.
    func didStartWithCommand(command: String)

    /// Callback to inform log entry is received.
    ///
    /// - Parameter value: String value of log entry,.
    /// - Parameter forUI: Bool val;ue to indicate if we want the value to be displayed in a UI Component..
    func didReceiveLog(value: String, forUI: Bool)

    /// Callback to inform error output is receieved.
    ///
    /// - Parameter value: String value of Error output.
    func didReceiveErrorOutput(value: String)

    /// Callback to inform task is terminated.
    ///
    /// - Returns: True if normal, false if not.
    func didTerminateHelper(normal: Bool)
}

/// Protocol to enable callbacks to inform the delegate, which will be the object you have setup as a XPC client.
protocol XPCServiceClientProtocol: class {
    /// Callback to inform delegate of requested version of helper.
    ///
    /// - Parameter value: Version of the Installed helper.
    func didReceiveVersion(value: String)

    /// Callback to inform delegate that the Helper is installed.
    func didInstallHelper()

    /// Callback to inform delegate that the connection with the helper is lost.
    func connectionLost()

    /// Callback to inform when installing helper connection is lost.
    func connectionLostWhileInstallingHelper()

    /// Callback to inform UI that task is exited.
    ///
    /// - Parameter normal: Bool: True when normal, else false.
    func taskIsTerminated(normal: Bool)
}

/// Conveniance Struct for the service names
#warning("Change the name to your chosen helper name.")
struct HelperConstants {
    static let helperServiceName = "nl.prowarehouse.ShredderHelper"
    static let mainServiceName = "nl.prowarehouse.Shredder"
}
