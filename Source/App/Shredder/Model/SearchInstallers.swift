//
//  SearchInstallers.swift
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

protocol SearchInstallersProtocol: class {
    /// CallBack to inform delegate of found installlers
    ///
    /// - Parameter installers: Array of found installers, when no installers found; returns empty array.
    func didFindInstallers(installers: [InstallerApp])
}

class SearchInstallers: NSObject {

    weak var delegate: SearchInstallersProtocol?

    private let mdQuery = NSMetadataQuery()

    func searchForInstallerApp() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(queryNotificationHandler),
                                       name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                                       object: nil)

        //Prepare the query
        let searchPredicate = NSPredicate(format: "kMDItemCFBundleIdentifier like 'com.apple.InstallAssistant.*'")
        mdQuery.searchScopes = []
        mdQuery.predicate = searchPredicate
        mdQuery.start()
    }

    @objc private func queryNotificationHandler() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                                                  object: nil)
        mdQuery.stop()

        let results = mdQuery.results
        if results.count == 0 {
            delegate?.didFindInstallers(installers: [])
        } else {
            let foundInstallers = results.reduce(into: [InstallerApp]()) { (foundInstallers, result) in
                guard let item = result as? NSMetadataItem else { return }

                let installerApp = InstallerApp(metadataItem: item)
                if installerApp.canErase {
                    foundInstallers.append(installerApp)
                }
            }

            if foundInstallers.count == 0 {
                delegate?.didFindInstallers(installers: [])
            } else {
                delegate?.didFindInstallers(installers: foundInstallers)
            }
        }
    }
}
