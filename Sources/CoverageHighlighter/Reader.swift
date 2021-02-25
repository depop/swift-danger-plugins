//
//  Reader.swift
//  
//
//  Created by Pablo Carrascal on 25/02/2021.
//

import Foundation

public protocol Reader {
    var fileName: String { get }

    func readFile() -> Data?
}

public class DefaultReader: Reader {
    public let fileName: String

    public init(fileName: String) {
        self.fileName = fileName
    }

    public func readFile() -> Data? {
        let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        guard let fileURL = URL(string: fileName, relativeTo: currentDirectoryURL) else {
            print("file not found: \(currentDirectoryURL.path)/\(fileName)")
            return Data()
        }
        do {
            return try String(contentsOf: fileURL).data(using: .utf8)
        } catch {
            print(" DefaultReader - Error: \(error)")
            return Data()
        }
    }
}
