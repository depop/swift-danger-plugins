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
            return "Couldn't get the coverage from the desired file"
        case .noGitChanges:
            return "No git changes"
        case .noFilesToShowCoverage:
            return "There aren't modified/created files with coverage"
        case .unknown:
            return "unknown"
        }
    }
}
