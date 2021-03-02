import Danger
import Foundation
import DangerShellExecutor

public class CoverageHighlighter {

    private let danger: DangerDSL
    private let reader: Reader
    private let filter: Filter

    lazy var modifiedFilesNames = {
        (danger.git.modifiedFiles + danger.git.createdFiles).compactMap { $0.components(separatedBy: "/").last }
    }()

    public init(reader: Reader = DefaultReader(fileName: "results.json"), filter: Filter, danger: DangerDSL = Danger()) {
        self.reader = reader
        self.filter = filter
        self.danger = danger
    }

    public func highlight() -> Void {
        do {
            let filesToHighlightCoverage = try filesToHighlight()

            filesToHighlightCoverage.forEach { file in
                let functionsToHighlight = file.functions.filter({ filter.isIncluded(functionName: $0.name, in: file.name)})
                functionsToHighlight.forEach({
                    let finalMessage = String(format: "%@: %.3f%%", $0.name.components(separatedBy: ".").last!.padding(toLength: 50, withPad: " ", startingAt: 0), $0.lineCoverage * 100)
                    if $0.lineCoverage * 100 < 90 {
                        danger.warn("Function without test " + finalMessage)
                    } else {
                        danger.message("Good test coverage " + finalMessage)
                    }
                })

                // This prints the coverage of the filtered file
                let finalMessage = String(format: "%@: %.3f%%", file.path.components(separatedBy: "/").last!.padding(toLength: 50, withPad: " ", startingAt: 0), file.lineCoverage * 100)
                if file.lineCoverage * 100 < 70 {
                    danger.warn("Low test coverage " + finalMessage)
                } else {
                    danger.message("Good test coverage " + finalMessage)
                }
            }

        } catch let error as CoverageHighlighterError {
            print(error.errorDescription ?? "Unknown")
        } catch {
            print("Unknown")
        }
    }

    func filesToHighlight() throws -> [File] {
        guard let coverage = Parser.parse(reader: reader, shouldPrint: true) else {
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
        return isCreatedOrModified(filename: filename) && filter.isIncluded(fileName: filename)
    }

    func isCreatedOrModified(filename: String) -> Bool {
        guard modifiedFilesNames.contains(filename) else {
            return false
        }

        return true
    }
}
