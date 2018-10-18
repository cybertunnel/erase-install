//
//  ValidationHelper.swift
//  Shredder
//
//  Created by Arnold Nefkens on 03/10/2018.
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
}
