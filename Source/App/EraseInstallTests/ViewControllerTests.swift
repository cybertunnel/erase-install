//
//  ViewControllerTests.swift
//  EraseInstallTests
//
//  Created by Arnold Nefkens on 17/10/2018.
//  Copyright © 2018 Pro Warehouse. All rights reserved.
//

import XCTest
@testable import EraseInstall

class ViewControllerTests: XCTestCase {

    let storyBoard = NSStoryboard(name: "Main", bundle: nil)
    var sut: ViewController!

    override func setUp() {
        sut = storyBoard.instantiateController(withIdentifier: "mainViewController") as? ViewController
    }

    override func tearDown() {
        sut = nil
    }

    func testShouldNotBeNil() {
        // Verify
        XCTAssertNotNil(sut)
    }
}
