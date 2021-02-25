import Danger
import Foundation
import DangerShellExecutor

public class CoverageHighlighter {

    private var danger: DangerDSL = Danger()
    private var filename: String
    private var filter: Filter

    lazy var modifiedFilesNames = {
        (danger.git.modifiedFiles + danger.git.createdFiles).compactMap { $0.components(separatedBy: "/").last }
    }()

    public init(source filename: String = "results.json", filter: Filter) {
        self.filename = filename
        self.filter = filter
    }

    public func highlight() -> Void {
         do {
             let filesToHighlightCoverage = try filesToHighlight()

             filesToHighlightCoverage.forEach { file in
                 let functionsToHighlight = file.functions.filter({ shouldHighlightFunction(name: $0.name, in: file)})
                 functionsToHighlight.forEach({
                     let finalMessage = String(format: "%@: %.3f%%", $0.name.components(separatedBy: ".").last!.padding(toLength: 50, withPad: " ", startingAt: 0), $0.lineCoverage * 100)
                     if $0.lineCoverage * 100 < 90 {
                         warn("Function without test " + finalMessage)
                     } else {
                         message("Good test coverage " + finalMessage)
                     }
                 })

                 // This prints the coverage of the filtered file
                 let finalMessage = String(format: "%@: %.3f%%", file.path.components(separatedBy: "/").last!.padding(toLength: 50, withPad: " ", startingAt: 0), file.lineCoverage * 100)
                 if file.lineCoverage * 100 < 70 {
                     warn("Low test coverage " + finalMessage)
                 } else {
                     message("Good test coverage " + finalMessage)
                 }
             }

         } catch let error as CoverageHighlighterError {
             print(error.errorDescription ?? "Unknown")
         } catch {
             print("Unknown")
         }
    }

    func filesToHighlight() throws -> [File] {
        let parser = Parser()
        guard let coverage = parser.parse(filename, shouldPrint: true) else {
            throw CoverageHighlighterError.noCoverageAvailable
        }

        let modifiedFilesNames = (danger.git.modifiedFiles + danger.git.createdFiles).compactMap { $0.components(separatedBy: "/").last }

        guard !modifiedFilesNames.isEmpty else {
            throw CoverageHighlighterError.noGitChanges
        }

        let filesToHighlightCoverage = coverage.targets
            .map { $0.files }
            .flatMap { $0 }
            .filter({ shouldHighlightFile(filename: $0.name) })
            .sorted(by: { $0.lineCoverage > $1.lineCoverage })

        guard !filesToHighlightCoverage.isEmpty else {
            throw CoverageHighlighterError.noFilesToShowCoverage
        }

        return filesToHighlightCoverage
    }

    // MARK: - File Filtering
    func shouldHighlightFile(filename: String) -> Bool {
        switch filter.inclusionType {
        case .excluded(let filters):
            return isCreatedOrModified(filename: filename) && !filters.contains(where: { $0.nameFilter.compare(with: filename) })
        case .included(let filters):
            return isCreatedOrModified(filename: filename) && filters.contains(where: { $0.nameFilter.compare(with: filename) })
        }
    }

    func shouldHighlightFunction(name: String, in file: File) -> Bool {
        switch filter.inclusionType {
        case .included(let fileFilters):
            let fileFilter = fileFilters.first(where: {$0.nameFilter.compare(with: file.name)})
            return fileFilter?.functionsFilters?.contains(where: {$0.compare(with: name)}) ?? false
        case .excluded(let fileFilters):
            let fileFilter = fileFilters.first(where: {$0.nameFilter.compare(with: file.name)})
            return !(fileFilter?.functionsFilters?.contains(where: {$0.compare(with: name)}) ?? true)
        }
    }

    func isCreatedOrModified(filename: String) -> Bool {
        guard modifiedFilesNames.contains(filename) else {
            return false
        }

        return true
    }
}
