//
//  XPCService.swift
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
import Security
import ServiceManagement
import XPC

struct CommandToSend {
    let launchPath: String
    let launchArguments: [String]
}

class XPCServiceClient: NSObject {

    private var installingHelper: Bool = false
    private var connection: NSXPCConnection?
    weak var clientDelegate: XPCServiceClientProtocol?

    private let logStore = LogContent.current

    // MARK: - Public Functions
    func getVersionOfHelper() {
        let xpcService = prepareConnection()?.remoteObjectProxyWithErrorHandler { _ -> Void in
        } as? HelperAppProtocol
        xpcService?.getHelperVersion()
    }

    func sendCommandToHelper(command: CommandToSend) {
        let service = prepareConnection()?.remoteObjectProxyWithErrorHandler { _ -> Void in
            } as? HelperAppProtocol
        service?.runCommand(path: command.launchPath, arguments: command.launchArguments)
    }

    /// Check if Helper daemon exists
    func checkIfHelperInstalled() -> Bool {
        let pathToHelper = "/Library/PrivilegedHelperTools/\(HelperConstants.helperServiceName)"
        let fileManager = FileManager()
        return fileManager.fileExists(atPath: pathToHelper)
    }

    func versionOfInstalledDeamon() -> String {
        let helperInfo = helperBundleInfoInAppBundle() as NSDictionary
        if let version = helperInfo["CFBundleVersion"] as? String {
            return version
        }
        return ""
    }

    /// Install new helper daemon
    func installHelperDaemon() {
        installingHelper = true
        // Create authorization reference for the user
        var authRef: AuthorizationRef?
        var authStatus = AuthorizationCreate(nil, nil, [], &authRef)

        // Check if the reference is valid
        guard authStatus == errAuthorizationSuccess else {
            return
        }

        // Ask user for the admin privileges to install the
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: nil, flags: 0)
        var authRights = AuthorizationRights(count: 1, items: &authItem)
        let flags: AuthorizationFlags = [[], .interactionAllowed, .extendRights, .preAuthorize]
        authStatus = AuthorizationCreate(&authRights, nil, flags, &authRef)

        // Check if the authorization went succesfully
        guard authStatus == errAuthorizationSuccess else {
            return
        }

        // Launch the privileged helper using SMJobBless tool
        var error: Unmanaged<CFError>?

        if SMJobBless(kSMDomainSystemLaunchd, HelperConstants.helperServiceName as CFString, authRef, &error) == false {
            let blessError = error!.takeRetainedValue() as Error
            print(blessError.localizedDescription)
        } else {
            log(message: "Helper installed.")
        }

        // Release the Authorization Reference
        AuthorizationFree(authRef!, [])
        clientDelegate?.didInstallHelper()
    }

    // MARK: - Private Functions
    private func prepareConnection() -> NSXPCConnection? {
        if connection == nil {
            connection = NSXPCConnection(machServiceName: HelperConstants.helperServiceName,
                                         options: NSXPCConnection.Options.privileged)
            connection?.remoteObjectInterface = NSXPCInterface(with: HelperAppProtocol.self)
            connection?.exportedInterface = NSXPCInterface(with: MainAppProtocol.self)
            connection?.exportedObject = self
            connection?.invalidationHandler = {
                self.connection?.invalidationHandler = nil
                OperationQueue.main.addOperation {
                    self.connection = nil
                    self.log(message: "Connection to helper lost")
                    if self.installingHelper {
                        self.clientDelegate?.connectionLostWhileInstallingHelper()
                        self.installingHelper = false
                    } else {
                         self.clientDelegate?.connectionLost()
                    }

                }
            }
            connection?.resume()
        }

        return connection
    }

    private func helperBundleInfoInAppBundle() -> CFDictionary {
        let pathComponent = "Contents/Library/LaunchServices/\(HelperConstants.helperServiceName)"
        let bundleURL = Bundle.main.bundleURL
        let helperURL = bundleURL.appendingPathComponent(pathComponent) as CFURL
        return CFBundleCopyInfoDictionaryForURL(helperURL)
    }
}

extension XPCServiceClient: MainAppProtocol, Logging {
    func didReceiveErrorOutput(value: String) {
        OperationQueue.main.addOperation {
            self.log(message: value)
        }
    }

    func didTerminateHelper(normal: Bool) {
        OperationQueue.main.addOperation {
            self.clientDelegate?.taskIsTerminated(normal: normal)
        }
    }

    func didReceiveLog(value: String) {
        OperationQueue.main.addOperation {
            self.log(message: value)
        }
    }

    func didStartWithCommand(command: String) {
        OperationQueue.main.addOperation {
            self.log(message: command)
        }
    }

    func didReceiveVersionOfHelper(version: String) {
        OperationQueue.main.addOperation {
            self.clientDelegate?.didReceiveVersion(value: version)
        }
    }
}
