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
        case exact(String)
        case contains(String)
        case sufix(String)
        case prefix(String)

        func compare(with stringToCompare: String) -> Bool {
            switch self {
            case .exact(let string):
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
        let nameFilter: FilterType
        let functionsFilters: [FilterType]?

        public init(nameFilter: FilterType, functionsFilters: [FilterType]? = nil) {
            self.nameFilter = nameFilter
            self.functionsFilters = functionsFilters
        }
    }

    let inclusionType: InclusionType

    public init(inclusionType: InclusionType) {
        self.inclusionType = inclusionType
    }
}
