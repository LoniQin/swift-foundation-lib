//
//  FileStorage.swift
//  
//
//  Created by lonnie on 2020/8/21.
//

import Foundation

public class FileStorage: DataStorage {
    
    fileprivate let jsonDecoder = JSONDecoder()

    fileprivate let jsonEncoder = JSONEncoder()
    
    public let path: String
    
    var dictionary = [String: Any]()
    
    private let lock = NSLock()
    
    var encodeOptions: ProcessOptions
    
    var decodeOptions: ProcessOptions
    
    var loadAndSaveImmediately: Bool
    
    var compresssionAlgorithm: CompressionAlogrithm?
    
    public init(path: String, encodeOptions: ProcessOptions = ProcessOptions(.none), decodeOptions: ProcessOptions = ProcessOptions(.none), loadAndSaveImmediately: Bool = false, compresssionAlgorithm: CompressionAlogrithm? = nil) throws {
        self.path = path
        self.encodeOptions = encodeOptions
        self.decodeOptions = decodeOptions
        self.loadAndSaveImmediately = loadAndSaveImmediately
        self.compresssionAlgorithm = compresssionAlgorithm
        if self.loadAndSaveImmediately {
            if FileManager.default.fileExists(atPath: path) {
                try self.load()
            }
        }
    }
    
    public func load() throws {
        try lock.tryLock { [unowned self] in
            if #available(iOS 9.0, OSX 10.11, *) {
                if let algorithm = compresssionAlgorithm {
                    if FileManager.default.fileExists(atPath: path) {
                        let tempPath = path + ".temp"
                        try FileManager.default.removeFileIfExist(tempPath)
                        let compressor = try Compressor(operation: .decode, algorithm: algorithm, sourcePath: path, destinationPath: tempPath)
                        try compressor.process()
                         try FileManager.default.removeFileIfExist(path)
                        try FileManager.default.moveItem(atPath: tempPath, toPath: path)
                    }
                }
            }
            let data = try Data(contentsOf: URL(fileURLWithPath: path)).process(self.decodeOptions)
            
            let dic = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            
            if dic is [String: Any] {
                self.dictionary = dic as! [String :Any]
            } else {
                throw FoundationError.invalidCoding
            }
        }
    }
    
    public func save() throws {
        try lock.tryLock { [unowned self] in
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted).process(self.encodeOptions)
            try FileManager.default.removeFileIfExist(path)
            FileManager.default.createFile(atPath: path, contents: data, attributes: .none)
            if #available(iOS 9.0, OSX 10.11, *) {
                if let algorithm = compresssionAlgorithm {
                    let tempPath = self.path + ".temp"
                    try FileManager.default.removeFileIfExist(tempPath)
                    let compressor = try Compressor(operation: .encode, algorithm: algorithm, sourcePath: path, destinationPath: tempPath)
                    try compressor.process()
                    try FileManager.default.removeFileIfExist(path)
                    try FileManager.default.moveItem(atPath: tempPath, toPath: path)
                }
            }
        }
    }
    
    public func get<T>(_ key: CustomStringConvertible) throws -> T where T : Decodable, T : Encodable {
        try lock.tryLock { [unowned self] in
            guard let value = self.dictionary[key.description] else {
                throw FoundationError.nilValue
            }
            if T.self == Int.self || T.self == Double.self || T.self == Float.self || T.self == String.self  {
                if let value =  value as? T { return value }
                throw FoundationError.nilValue
            }
            guard let base64EncodedString = value as? String else {
                throw FoundationError.nilValue
            }
            guard let data = Data(base64Encoded: base64EncodedString) else {
                throw FoundationError.invalidCoding
            }
            return try self.jsonDecoder.decode(T.self, from: data)
        }
    }
    
    public func set<T>(_ value: T?, for key: CustomStringConvertible) throws where T : Decodable, T : Encodable {
        try lock.tryLock { [unowned self] in
            if let value = value {
                if T.self == Int.self || T.self == Double.self || T.self == Float.self || T.self == String.self {
                    self.dictionary[key.description] = value
                } else {
                    self.dictionary[key.description] = try jsonEncoder.encode(value).base64EncodedString()
                }
            } else {
                self.dictionary.removeValue(forKey: key.description)
            }
        }
        if loadAndSaveImmediately {
            try save()
        }
    }
    
}
