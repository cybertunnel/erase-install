//
//  CwlCollectionTests.swift
//  CwlUtils
//
//  Created by Matt Gallagher on 2015/02/03.
//  Copyright © 2015 Matt Gallagher ( https://www.cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Foundation
import XCTest
import CwlUtils

class CollectionTests: XCTestCase {
	func testIsNil() {
		let a = Optional<Optional<Bool>>.some(nil)
		XCTAssert(a.isNil == false)
		XCTAssert(a?.isNil == true)
	}
	func testAtCollection() {
		let a = 7..<9
		let at_0 = a.at(7)
		let at_2 = a.at(9)
		let at_1 = a.at(-1)
		XCTAssert(at_0! == 7 && at_1 == nil && at_2 == nil)
	}
	func testRangeAtCollection() {
		let a = 7..<29
		let at_1 = a.at(5..<6 as Range<Int>)
		let at_2 = a.at(5..<7 as Range<Int>)
		let at_3 = a.at(5..<8 as Range<Int>)
		let at_4 = a.at(12..<15 as Range<Int>)
		let at_5 = a.at(5..<30 as Range<Int>)
		let at_6 = a.at(28..<30 as Range<Int>)
		let at_7 = a.at(29..<30 as Range<Int>)
		let at_8 = a.at(30..<30 as Range<Int>)
		XCTAssert(at_1 == 7..<7)
		XCTAssert(at_2 == 7..<7)
		XCTAssert(at_3 == 7..<8)
		XCTAssert(at_4 == 12..<15)
		XCTAssert(at_5 == 7..<29)
		XCTAssert(at_6 == 28..<29)
		XCTAssert(at_7 == 29..<29)
		XCTAssert(at_8 == 29..<29)
	}
	func testCountableRangeAtCollection() {
		let a = 7..<29
		let at_1 = a.at(5..<6 as CountableRange<Int>)
		let at_2 = a.at(5..<7 as CountableRange<Int>)
		let at_3 = a.at(5..<8 as CountableRange<Int>)
		let at_4 = a.at(12..<15 as CountableRange<Int>)
		let at_5 = a.at(5..<30 as CountableRange<Int>)
		let at_6 = a.at(28..<30 as CountableRange<Int>)
		let at_7 = a.at(29..<30 as CountableRange<Int>)
		let at_8 = a.at(30..<30 as CountableRange<Int>)
		XCTAssert(at_1 == 7..<7)
		XCTAssert(at_2 == 7..<7)
		XCTAssert(at_3 == 7..<8)
		XCTAssert(at_4 == 12..<15)
		XCTAssert(at_5 == 7..<29)
		XCTAssert(at_6 == 28..<29)
		XCTAssert(at_7 == 29..<29)
		XCTAssert(at_8 == 29..<29)
	}
}
