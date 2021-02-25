//
//  File.swift
//  
//
//  Created by Pablo Carrascal on 24/02/2021.
//

import Foundation
import DangerFixtures
import XCTest

@testable import CoverageHighlighter

final class CoverageHighlighterTests: XCTestCase {
    func testExample() {
        let filter = Filter(inclusionType: .included(
                                [.init(nameFilter: .sufix("Service")),
                                 .init(nameFilter: .sufix("Presenter")),
                                 .init(nameFilter: .sufix("Manager"))
                                ]))        
//        CoverageHighlighter
//        let filter = Filter(filesToFilter: [], filesToExclude: [])
//        CoverageHighlighter().hightlight(filter: )
//        XCTAssertEqual(CompilationTimePlugin().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
