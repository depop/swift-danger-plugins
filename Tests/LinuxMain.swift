import XCTest

import CoverageHighlighterTests

var tests = [XCTestCaseEntry]()
tests += CoverageHighlighterTests.allTests()
XCTMain(tests)
