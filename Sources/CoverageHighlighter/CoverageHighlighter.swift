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
    // This represent the criteria that a file must meet to be displayed.
    public struct FilterFile {
        public let nameSuffix: String
        public let functionPrefix: String?
    }
    public var filesToFilter: [FilterFile]
    public var filesToExclude: [FilterFile]

    public init(filesToFilter: [FilterFile], filesToExclude: [FilterFile]) {
        self.filesToFilter = filesToFilter
        self.filesToExclude = filesToExclude
    }
}

extension Filter {
    var allFileNameSuffixesToInclude: [String] { filesToFilter.map { $0.nameSuffix } }
    var allFileNameSuffixesToExclude: [String]  { filesToExclude.map { $0.nameSuffix } }
}

public class CoverageHighlighter {

    public static func hightlight(filter: Filter) -> Void {

        let danger = Danger()

        let filename = "results.json"

        let parser = Parser()

        let allFileNameSuffixesToInclude = filter.allFileNameSuffixesToInclude
        let allFileNameSuffixesToExclude = filter.allFileNameSuffixesToExclude

        let result = parser.parse(filename, shouldPrint: false)

        // This give a list of the files from the project filtered with the ones
        // that we want to include and removing the one we want to exclude.
        let filesToHighlightCoverage = result?.targets.map { $0.files }.flatMap { $0 }.filter { codeFile in
            allFileNameSuffixesToInclude.contains(where: { codeFile.name.contains($0) }) &&
                !allFileNameSuffixesToExclude.contains(where: { codeFile.name.contains($0) })
        }.sorted(by: { $0.lineCoverage > $1.lineCoverage }).map { $0 } ?? [File]()

        // All Modified filenames
        let modifiedFilesNames = (danger.git.modifiedFiles + danger.git.createdFiles).compactMap { $0.components(separatedBy: "/").last }

        // This filters from the ones we want to hightlight which onces have been modified.
        let modifiedFilesToHightLight = filesToHighlightCoverage.filter { file in
            modifiedFilesNames.contains(file.path.components(separatedBy: "/").last!)
        }

        modifiedFilesToHightLight.forEach { file in

            typealias ResultFilter = (functions: [Filter.FilterFile], files: [Filter.FilterFile])

            var result: ResultFilter  = ([],[])

            // This give as two list one with the files names we want to highlight and another one
            // with the function names that we want to highlight.
            result = filter.filesToFilter.reduce(result) { (result, filterFile) -> ResultFilter in
                var functions = result.functions
                var files = result.files
                if filterFile.functionPrefix != nil  && file.name.contains(filterFile.nameSuffix) {
                    functions.append(filterFile)
                } else {
                    files.append(filterFile)
                }
                return (functions, files)
            }

            // This search in the file for the functions that meet the criteria.
            result.functions.forEach { function in
                file.functions.filter { $0.name.contains(function.functionPrefix!) }
                    .forEach {
                        let finalMessage = String(format: "%@: %.3f%%", $0.name.components(separatedBy: ".").last!.padding(toLength: 50, withPad: " ", startingAt: 0), $0.lineCoverage * 100)
                        if $0.lineCoverage * 100 < 90 {
                            warn("Function without test " + finalMessage)
                        } else {
                            message("Good test coverage " + finalMessage)
                        }
                }
            }

            // This prints the coverage of the filtered file
            let finalMessage = String(format: "%@: %.3f%%", file.path.components(separatedBy: "/").last!.padding(toLength: 50, withPad: " ", startingAt: 0), file.lineCoverage * 100)
            if file.lineCoverage * 100 < 70 {
                warn("Low test coverage " + finalMessage)
            } else {
                message("Good test coverage " + finalMessage)
            }

        }
    }

}
