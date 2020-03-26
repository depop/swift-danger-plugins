//
//  Parser.swift
//  
//
//  Created by Samuel Hervas on 26/03/2020.
//

import Foundation

class Parser {
    func parse(_ fileName: String, shouldPrint: Bool = true) -> Coverage? {
        guard let contents = readFile(fileName) else {
            print("Could not parse coverage structure from \(fileName)")
            return nil
        }
        let decoder = JSONDecoder()

        do {
            let coverage = try decoder.decode(Coverage.self, from: contents)
            if shouldPrint {
                printCoverage(coverage)
            }
            return coverage
        } catch {
            print("Error: \(error)")
            return nil
        }

    }

    private func readFile(_ fileName: String) -> Data? {
        let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        guard let fileURL = URL(string: fileName, relativeTo: currentDirectoryURL) else {
            print("file not found: \(currentDirectoryURL.path)/\(fileName)")
            return Data()
        }
        do {
            return try String(contentsOf: fileURL).data(using: .utf8)
        } catch {
            print("Error: \(error)")
            return Data()
        }
    }

    private func printCoverage(_ coverage: Coverage) {

        let nonTestTargets = coverage.targets.filter { target in
            return !target.name.contains(".xctest")
        }

        let nonPodsTargets = nonTestTargets.filter { target in
            return target.files.filter { file in
                return file.path.contains("/Pods/")
            }.count == 0
        }

        let maxLength = nonPodsTargets.reduce(0) { max($0, $1.name.count) }
        let title = "Total coverage"

        print(String(format: "%@: %.3f%%", title.padding(toLength: maxLength, withPad: " ", startingAt: 0), coverage.lineCoverage * 100))
        nonPodsTargets
            .sorted { $0.lineCoverage > $1.lineCoverage }
            .forEach { print(String(format: " %@: %.3f%%", $0.name.padding(toLength: maxLength, withPad: " ", startingAt: 0), $0.lineCoverage * 100)) }
    }
}

struct Coverage: Coverable {
    let executableLines: Int
    let coveredLines: Int
    let lineCoverage: Double

    let targets: [Target]
}

struct Target: NamedCoverable {
    let name: String
    let executableLines: Int
    let coveredLines: Int
    let lineCoverage: Double

    let buildProductPath: String
    let files: [File]
}

struct File: NamedCoverable {
    let name: String
    let executableLines: Int
    let coveredLines: Int
    let lineCoverage: Double

    let path: String
    let functions: [Function]
}

struct Function: NamedCoverable {
    let name: String
    let executableLines: Int
    let coveredLines: Int
    let lineCoverage: Double

    let lineNumber: Int
    let executionCount: Int
}