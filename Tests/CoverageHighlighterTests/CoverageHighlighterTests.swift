//
//  CoverageHighlighterTests.swift
//  
//
//  Created by Pablo Carrascal on 24/02/2021.
//

import XCTest

@testable import Danger
@testable import DangerFixtures
@testable import CoverageHighlighter

final class CoverageHighlighterTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        resetDangerResults()
    }

    // MARK: - Filters
    func testFilter() {
        // Given some file filters
        let filter = Filter(included: [.init(name: .sufix("Class.swift")),
                                       .init(name: .contains("DidTap")),
                                       .init(name: .equal("init")),
                                       .init(name: .prefix("Prefix")),
                                       .init(name: .equal("ShouldBeExcluded.swift"))
                                        ], excluded: [
                                            .init(name: .prefix("test")),
                                            .init(name: .sufix("Test.swift")),
                                            .init(name: .contains("Hello")),
                                            .init(name: .equal("Excluded")),
                                            .init(name: .equal("ShouldBeExcluded.swift"))
                                        ])

        // Included
        XCTAssertTrue(filter.isIncluded(fileName: "SomeClass.swift"))
        XCTAssertTrue(filter.isIncluded(fileName: "someFunctionDidTapSomething"))
        XCTAssertTrue(filter.isIncluded(fileName: "init"))
        XCTAssertTrue(filter.isIncluded(fileName: "PrefixClass.swift"))
        XCTAssertFalse(filter.isIncluded(fileName: "OtherClassName"))
        XCTAssertFalse(filter.isIncluded(fileName: "otherInit"))

        // Excluded
        XCTAssertTrue(filter.isExcluded(fileName: "testSomethings.swift"))
        XCTAssertTrue(filter.isExcluded(fileName: "SomeClassTest.swift"))
        XCTAssertTrue(filter.isExcluded(fileName: "SomeHelloTestClass.swift"))
        XCTAssertTrue(filter.isExcluded(fileName: "Excluded"))

        // Included & Excluded (should be excluded)
        XCTAssertFalse(filter.isIncluded(fileName: "ShouldBeExcluded.swift"))
        XCTAssertTrue(filter.isExcluded(fileName: "ShouldBeExcluded.swift"))
    }

    // MARK: - CoverageHighlighter
    func testDanger() {
        let danger = githubWithFilesDSL(created: ["SomeClass.swift",
                                                  "File2.swift",
                                                  "File3.swift"],
                                        fileMap: ["SomeClass.swift": "{}", "File2.swift": "{}", "File3.swift": "{}"])

        let reader = TestsReader(fileName: "result")
        let filter = Filter(included: [.init(name: .sufix("Class.swift")),
                                       .init(name: .contains("2")),
                                       .init(name: .contains("3"))])

        let highlighter = CoverageHighlighter(reader: reader, filter: filter, danger: danger)
        highlighter.highlight()

        XCTAssertEqual(danger.messages.count, 2)
        XCTAssertEqual(danger.warnings.count, 1)
        XCTAssertEqual(danger.fails.count, 0)
    }

    func testDanger_OneModifiedFile() {
        let danger = githubWithFilesDSL(created: ["SomeClass.swift"],
                                        fileMap: ["SomeClass.swift": "{}", "File2.swift": "{}", "File3.swift": "{}"])

        let reader = TestsReader(fileName: "result")
        let filter = Filter(included: [.init(name: .sufix("Class.swift")),
                                       .init(name: .contains("2")),
                                       .init(name: .contains("3"))])

        let highlighter = CoverageHighlighter(reader: reader, filter: filter, danger: danger)
        highlighter.highlight()

        XCTAssertEqual(danger.messages.count, 1)
        XCTAssertEqual(danger.warnings.count, 0)
        XCTAssertEqual(danger.fails.count, 0)
    }

    func testDanger_FunctionNames() {
        let danger = githubWithFilesDSL(created: ["File2.swift"],
                                        fileMap: ["File2.swift": "{}"])

        let reader = TestsReader(fileName: "result")
        let filter = Filter(included: [.init(name: .contains("2"), functions: [.contains("function")])])

        let highlighter = CoverageHighlighter(reader: reader, filter: filter, danger: danger)
        highlighter.highlight()

        XCTAssertEqual(danger.messages.count, 2)
        XCTAssertEqual(danger.warnings.count, 1)
        XCTAssertEqual(danger.fails.count, 0)
    }

    func testFilesToHighlightWrongReader() {
        let filter = Filter()
        let danger = githubWithFilesDSL(created: ["SomeClass.swift"],
                                                     fileMap: ["SomeClass.swift": "{}"])
        let reader = TestsReader(fileName: "noFile")
        let highlighter = CoverageHighlighter(reader: reader, filter: filter, danger: danger)
        XCTAssertThrowsError(try highlighter.filesToHighlight(), "No Coverage") { (error) in
            guard let error = error as? CoverageHighlighterError else {
                XCTFail()
                return
            }

            guard error == CoverageHighlighterError.noCoverageAvailable else {
                XCTFail()
                return
            }
        }
    }

    func testFilesNoModifiedFiles() {
        let filter = Filter()
        let danger = githubWithFilesDSL(fileMap: ["SomeClass.swift": "{}"])
        let reader = TestsReader(fileName: "result")
        let highlighter = CoverageHighlighter(reader: reader, filter: filter, danger: danger)
        XCTAssertThrowsError(try highlighter.filesToHighlight(), "No git changes") { (error) in
            guard let error = error as? CoverageHighlighterError else {
                XCTFail()
                return
            }

            guard error == CoverageHighlighterError.noGitChanges else {
                XCTFail()
                return
            }
        }
    }

    func testFilesFilesToHighlight() {
        let filter = Filter()
        let danger = githubWithFilesDSL(created: ["AnonClass.swift"], fileMap: ["SomeClass.swift": "{}"])
        let reader = TestsReader(fileName: "result")
        let highlighter = CoverageHighlighter(reader: reader, filter: filter, danger: danger)
        XCTAssertThrowsError(try highlighter.filesToHighlight(), "No files to show coverage") { (error) in
            guard let error = error as? CoverageHighlighterError else {
                XCTFail()
                return
            }

            guard error == CoverageHighlighterError.noFilesToShowCoverage else {
                XCTFail()
                return
            }
        }
    }

    // MARK: - Helpers
    private func readDangerDSL(name: String) -> String? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else { return nil }
        return try? String(contentsOf: url)
    }

    private func readResultFile(name: String) -> String? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else { return nil }
        return try? String(contentsOf: url)
    }
}

class TestsReader: Reader {
    private (set) var fileName: String

    init(fileName: String) {
        self.fileName = fileName
    }

    func readFile() -> Data? {
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "json") else { return nil }
        return try? String(contentsOf: url).data(using: .utf8)
    }
}

class WrongReader: Reader {
    private (set) var fileName: String

    init() {
        self.fileName = ""
    }

    func readFile() -> Data? {
        return nil
    }
}
