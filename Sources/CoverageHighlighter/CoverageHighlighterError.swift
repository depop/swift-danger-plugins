//
//  File.swift
//  
//
//  Created by Pablo Carrascal on 24/02/2021.
//

import Foundation

public enum CoverageHighlighterError: Error {
    case noCoverageAvailable
    case noGitChanges
    case noFilesToShowCoverage
    case unknown
}

extension CoverageHighlighterError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noCoverageAvailable:
            return "noCoverageAvailable"
        case .noGitChanges:
            return "noGitChanges"
        case .noFilesToShowCoverage:
            return "noFilesToShowCoverage"
        case .unknown:
            return "unknown"
        }
    }
}
