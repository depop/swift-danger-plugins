import Danger
import Foundation

protocol Coverable: Decodable {
    var executableLines: Int { get }
    var coveredLines: Int { get }
    var lineCoverage: Double { get }
}

protocol NamedCoverable: Coverable {
    var name: String { get }
}

public struct Filter {
    struct FilterFile {
        let nameSuffix: String
        let functionPrefix: String?
    }
    var filesToFilter: [FilterFile]
    var filesToExclude: [FilterFile]
}

extension Filter {
    var include: [String] { filter.filesToFilter.map { $0.nameSuffix } }
    var exclude: [String]  { filter.filesToExclude.map { $0.nameSuffix } }
}
public class CoverageHighlighter {

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

    public static func hightlight(filter: Filter) -> Void {

        let danger = Danger()
        let filename = "results.json"
        let parser = Parser()

        let include = filter.include
        let exclude = filter.exclude
        let result = parser.parse(filename, shouldPrint: false)

        let filesToHighlightCoverage = result?.targets.map { $0.files }.flatMap { $0 }.filter { codeFile in
            include.contains(where: { codeFile.name.contains($0) }) &&
            !exclude.contains(where: { codeFile.name.contains($0) })
        }.sorted(by: { $0.lineCoverage > $1.lineCoverage }).map { $0 } ?? [File]()

        let modifiedFilesNames = (danger.git.modifiedFiles + danger.git.createdFiles).compactMap { $0.components(separatedBy: "/").last }

        let modifiedFilesToHightLight = filesToHighlightCoverage.filter { file in
            modifiedFilesNames.contains(file.path.components(separatedBy: "/").last!)
        }

        modifiedFilesToHightLight.forEach { file in

            typealias ResultFilter = (functions: [Filter.FilterFile], files: [Filter.FilterFile])

            let result: ResultFilter  = ([],[])

            let functions: ResultFilter = filter.filesToFilter.reduce(result) { (result, filterFile) -> ResultFilter in
                var functions = result.functions
                var files = result.files
                if filterFile.functionPrefix != nil  && file.name.contains(filterFile.nameSuffix) {
                    functions.append(filterFile)
                } else {
                    files.append(filterFile)
                }
                return (functions, files)
            }

            functions.functions.forEach { function in
                file.functions.filter { $0.name.contains(function.functionPrefix!) }.forEach {
                    let finalMessage = String(format: "%@: %.3f%%", $0.name.components(separatedBy: ".").last!.padding(toLength: 50, withPad: " ", startingAt: 0), $0.lineCoverage * 100)
                    if $0.lineCoverage * 100 < 90 {
                        warn("Function without test " + finalMessage)
                    } else {
                        message("Good test coverage " + finalMessage)
                    }
                }
            }

            let finalMessage = String(format: "%@: %.3f%%", file.path.components(separatedBy: "/").last!.padding(toLength: 50, withPad: " ", startingAt: 0), file.lineCoverage * 100)
            if file.lineCoverage * 100 < 70 {
                warn("Low test coverage " + finalMessage)
            } else {
                message("Good test coverage " + finalMessage)
            }

        }
    }

}
