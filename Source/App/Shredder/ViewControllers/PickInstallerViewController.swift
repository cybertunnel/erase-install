//
//  PickInstallerViewController.swift
//  Shredder
//
//  Created by Arnold Nefkens on 25/09/2018.
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

import Cocoa

protocol PickInstallerViewControllerProtocol: class {
    /// Callback to inform delegate that the button has been animated.
    func didAnimateButtons()
}

class PickInstallerViewController: NSViewController {

    weak var delegate: PickInstallerViewControllerProtocol?

    // MARK: - Properties
    @IBOutlet private var continueLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var quitButton: NSButton!
    @IBOutlet private var continueButton: NSButton!
    @IBOutlet private var headerTitle: NSTextField!
    @IBOutlet private var pickerCollectionView: NSCollectionView!
    var foundInstallers: [InstallerApp] = []
    private var selected: InstallerApp?
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        headerTitle.stringValue = NSLocalizedString("pickerTitleKey", comment: "Select an Installer")
        continueButton.title = NSLocalizedString("continueButtonKey", comment: "Continue Button")
        quitButton.title = NSLocalizedString("quitKey", comment: "Quit Button")
        configureCollectionView()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        continueButton.isEnabled = false
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.pickerCollectionView.reloadData()

        let duration = 0.6
        let timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeIn)
        let leadingConstant: CGFloat = ContinueButtonLeading.animationConstraintConstant.rawValue

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = timingFunction
            context.allowsImplicitAnimation = true

            self.quitButton.isHidden = true
            self.continueLeadingConstraint.animator().constant = leadingConstant
        }, completionHandler: {
            self.delegate?.didAnimateButtons()
        })

    }

    // MARK: - IBActions
    @IBAction func continueAction(_ sender: Any) {
        let customWindow = self.view.window?.windowController as? MainWindowController
        if let validationViewController = customWindow?.validationViewController as? ValidationViewController {
            validationViewController.selectedInstaller = selected
            validationViewController.updateInstallerLabel()
            validationViewController.displayValidationAnimation = true
            self.switchViewController(toDisplayViewController: validationViewController)
        }
    }

    // MARK: - Private Functions
    private func configureCollectionView() {

        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 250.0, height: 200.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 40.0, left: 50.0, bottom: 30.0, right: 50.0)
        flowLayout.minimumInteritemSpacing = 50.0
        flowLayout.minimumLineSpacing = 50.0
        flowLayout.scrollDirection = .horizontal
        pickerCollectionView.collectionViewLayout = flowLayout
    }
}

extension PickInstallerViewController: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return foundInstallers.count
    }

    func collectionView(_ collectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        let identfier = NSUserInterfaceItemIdentifier(rawValue: "PickInstallerItem")
        let item = pickerCollectionView.makeItem(withIdentifier: identfier,
                                                 for: indexPath)
        guard let pickItem = item as? PickInstallerItem else { return item }
        let installer = foundInstallers[indexPath.item]
        pickItem.setupItem(installer: installer)
        return item
    }
}

extension PickInstallerViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPathSelected = indexPaths.first {
            let selectedInstaller = foundInstallers[indexPathSelected.item]
            selected = selectedInstaller
            continueButton.isEnabled = true
        }
    }
}
