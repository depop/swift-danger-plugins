//
//  File.swift
//  
//
//  Created by Pablo Carrascal on 24/02/2021.
//

import Foundation

public struct Filter {
    public enum InclusionType {
        case included([File])
        case excluded([File])
    }

    public enum FilterType {
        case equal(String)
        case contains(String)
        case sufix(String)
        case prefix(String)

        func compare(with stringToCompare: String) -> Bool {
            switch self {
            case .equal(let string):
                return stringToCompare == string
            case .contains(let string):
                return stringToCompare.contains(string)
            case .sufix(let sufix):
                return stringToCompare.hasSuffix(sufix)
            case .prefix(let prefix):
                return stringToCompare.hasPrefix(prefix)
            }
        }
    }

    public struct File {
        let name: FilterType
        let functions: [FilterType]?

        public init(name nameFilter: FilterType, functions functionsFilters: [FilterType]? = nil) {
            self.name = nameFilter
            self.functions = functionsFilters
        }
    }

    private let included: [File]
    private let excluded: [File]

    public init(included: [File] = [], excluded: [File] = []) {
        self.included = included
        self.excluded = excluded
    }

    func isIncluded(fileName: String) -> Bool {
        return included.contains(where: { $0.name.compare(with: fileName) }) && !isExcluded(fileName: fileName)
    }

    func isExcluded(fileName: String) -> Bool {
        return excluded.contains(where: { $0.name.compare(with: fileName) })
    }

    func isIncluded(functionName: String, in fileName: String) -> Bool {
        let includedFileFilter = included.first(where: {$0.name.compare(with: fileName)})
        let excludedFileFilter = excluded.first(where: {$0.name.compare(with: fileName)})

        return includedFileFilter?.functions?.contains(where: {$0.compare(with: functionName)}) ?? false &&
            !(excludedFileFilter?.functions?.contains(where: {$0.compare(with: functionName)}) ?? false)
    }
}
