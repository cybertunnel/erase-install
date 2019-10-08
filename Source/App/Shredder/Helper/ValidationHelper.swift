//
//  ValidationHelper.swift
//  Shredder
//
//  Created by Arnold Nefkens on 03/10/2018.
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
import AppKit
import SystemConfiguration
import IOKit.ps

class ValidationHelper: NSObject, Logging {

    /// Checks the OS Version
    ///
    /// The OS Version needs to be above or equal to 10.13
    /// - Returns: Bool
    func checkOSVersion() -> Bool {
        log(message: "Validation Helper: OS Version Checked")
        let osversion = ProcessInfo.processInfo.operatingSystemVersion
        return osversion.minorVersion >= 13
    }

    /// Checks is the disk is formatted in APFS
    ///
    /// - Returns: Bool
    func checkForAPFS() -> Bool {
        log(message: "Validation Helper: APFS Checked")
        var fstype: NSString?
        NSWorkspace.shared.getFileSystemInfo(
            forPath: "/",
            isRemovable: nil,
            isWritable: nil,
            isUnmountable: nil,
            description: nil,
            type: &fstype
        )
        let safefstype = fstype ?? "unknown"
        return safefstype.lowercased == "apfs"
    }

    /// Checks if Find My Mac is enabled
    ///
    /// - Returns: Bool
    func checkFindMyMac() -> Bool {
        log(message: "Validation Helper: Find My Mac Checked")
        // create a process object with the command and arguments
        let task = Process()
        task.launchPath = "/usr/sbin/nvram"
        task.arguments = ["-x", "-p"]

        // create a Pipe (file handle) and attach to task's stdout
        let output = Pipe()
        task.standardOutput = output

        // start the task
        task.launch()

        // wait until output is complete
        let data = output.fileHandleForReading.readDataToEndOfFile()

        // create an XML decoder for a [String, Data] Dictionary
        let decoder = PropertyListDecoder()
        let nvram = try? decoder.decode(Dictionary<String, Data>.self, from: data)

        // get and decode the value
        if nvram?["fmm-mobileme-token-FMM"] != nil,
            let fmmNameData = nvram?["fmm-computer-name"],
            let fmmName = String(data: fmmNameData, encoding: String.Encoding.utf8) {
            print(fmmName)
            return true
        }
        return false
    }

    // MARK: - Power Based Checks
    /// Check if we the powersource is the battery
    ///
    /// - Returns: Bool
    func isRunningOnBattery() -> Bool {
        log(message: "Validation Helper: Running on Battery")
        if let powerSourceDescription = getPowerSourceDescription(),
            let powerSource = powerSourceDescription[kIOPSPowerSourceStateKey] as? String,
            powerSource == "Battery" {
            return true
        }
        return false
    }

    /// Retrieves current capacity of the battery
    ///
    /// - Returns: Capacity (Int)
    func currentBattryLevel() -> Int {
        log(message: "Validation Helper: Current Capacity of battery")
        if let powerSourceDescription = getPowerSourceDescription(),
            let capacity = powerSourceDescription[kIOPSCurrentCapacityKey] as? Int {
            return capacity
        }
        return 0
    }

    /// Gets the IOPSGetPowerSourceDescription
    ///
    /// - Returns: [String: Any] if found else nil
    private func getPowerSourceDescription() -> [String: Any]? {
        // swiftlint:disable line_length
        let powerSourceInformation = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let powerSourceList = IOPSCopyPowerSourcesList(powerSourceInformation).takeRetainedValue() as [CFTypeRef]
        // If we have an item we are on a MacBook.
        if powerSourceList.count > 0, let powerItem = powerSourceList.first {
            if let powerSourceDescription = IOPSGetPowerSourceDescription(powerSourceInformation, powerItem)?.takeUnretainedValue() as? [String: Any] {
                return powerSourceDescription
            }
        }
        return nil
        // swiftlint:enable line_length
    }

    // MARK: - Network Check
    // https://stackoverflow.com/questions/25398664/check-for-internet-connection-availability-in-swift#25774420

    /// Checks if we have an active network.
    ///
    /// - Returns: Bool
    func checkNetworkConnection() -> Bool {
        log(message: "Validation Helper: Network Connection")
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        if flags.isEmpty {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return (isReachable && !needsConnection)
    }

    /// Generates the Arguments to be send to the startosinstall command.
    ///
    /// Will search a fixed loction for .pkg files. When found any, they are added to the startosinstall command.
    /// Will always return always an array with the two minimum arguments to use: --agreetolicense & --eraseinstall
    ///
    /// - Returns: Array of Strings, that hold the additional arguments.
    func fetchStartOSInstallArguments() -> [String] {
        var argumentsForStartOSInstall: [String] = ["--agreetolicense", "--eraseinstall"]
        do {
            let pathForInstallersFolder: String = "/Library/Application Support/EraseInstall/Packages/"
            let URLFullPath: URL = URL(fileURLWithPath: pathForInstallersFolder)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: URLFullPath,
                                                                                includingPropertiesForKeys: nil,
                                                                                options: [])

            // Filtered on .pkg files
            let installersFound = directoryContents.filter { $0.pathExtension == "pkg" }
                                .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            if installersFound.count > 0 {
                log(message: "Packages found.")
                for installer in installersFound {
                    // validate the package
                    if validatePackage(path: installer.path) {
                        argumentsForStartOSInstall.append("--installpackage")
                        argumentsForStartOSInstall.append(installer.path)
                        log(message: "Package: \(installer.path)")
                    }
                }
            }
        } catch {
            log(message: "No Additional Packages found.")
        }

        return argumentsForStartOSInstall
    }

    /// Validats the found installer.
    ///
    /// - Parameter path: String to the package
    /// - Returns: True if package is correct.
    private func validatePackage(path: String) -> Bool {
        //Fetch URL of Validation Script
        let pathToPackageValidator = Bundle.main.path(forResource: "ValidatePackage", ofType: "sh")
        let task = Process()
        task.launchPath = pathToPackageValidator
        task.arguments = [path]
        task.launch()
        task.waitUntilExit()
        let status = task.terminationStatus
        if status == 0 {
            return true
        }

        return false
    }

    /// Validator for found scripts.
    ///
    /// - Parameter path: String path for file found.
    /// - Returns: True when file is executable, has root as owner, is readable and has posix permissions of 755.
    private func validateScript(path: String) -> Bool {
        let fileManager = FileManager.default
        do {
            // Get the permissions set.
            let itemAttributes = try fileManager.attributesOfItem(atPath: path)

            // If we find the owner and posixPermissions we move forward.
            if let owner = itemAttributes[FileAttributeKey.ownerAccountName] as? String,
                let posix = itemAttributes[FileAttributeKey.posixPermissions] as? NSNumber {

                // Convert posix Octal value to readable string
                let posixString = String(format: "%o", posix.int16Value)
                let isExecutable = fileManager.isExecutableFile(atPath: path)
                let isReadable = fileManager.isReadableFile(atPath: path)

                // Validate the attributes.
                if owner == "root" && isExecutable && isReadable &&  posixString == "755"{
                    return true
                }
            }
        } catch {
            log(message: "Script not valid: \(path)")
        }

        return false
    }
}
