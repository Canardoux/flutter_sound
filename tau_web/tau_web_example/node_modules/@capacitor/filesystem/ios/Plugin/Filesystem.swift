import Foundation

@objc public class Filesystem: NSObject {

    public enum FilesystemError: LocalizedError {
        case noParentFolder, noSave, failEncode, noAppend, notEmpty

        public var errorDescription: String? {
            switch self {
            case .noParentFolder:
                return "Parent folder doesn't exist"
            case .noSave:
                return "Unable to save file"
            case .failEncode:
                return "Unable to encode data to utf-8"
            case .noAppend:
                return "Unable to append file"
            case .notEmpty:
                return "Folder is not empty"
            }
        }
    }

    public func readFile(at fileUrl: URL, with encoding: String?) throws -> String {
        if encoding != nil {
            let data = try String(contentsOf: fileUrl, encoding: .utf8)
            return data
        } else {
            let data = try Data(contentsOf: fileUrl)
            return data.base64EncodedString()
        }
    }

    public func writeFile(at fileUrl: URL, with data: String, recursive: Bool, with encoding: String?) throws -> String {
        if !FileManager.default.fileExists(atPath: fileUrl.deletingLastPathComponent().path) {
            if recursive {
                try FileManager.default.createDirectory(at: fileUrl.deletingLastPathComponent(), withIntermediateDirectories: recursive, attributes: nil)
            } else {
                throw FilesystemError.noParentFolder
            }
        }
        if encoding != nil {
            try data.write(to: fileUrl, atomically: false, encoding: .utf8)
        } else {
            if let base64Data = Data.capacitor.data(base64EncodedOrDataUrl: data) {
                try base64Data.write(to: fileUrl)
            } else {
                throw FilesystemError.noSave
            }
        }
        return fileUrl.absoluteString
    }

    @objc public func appendFile(at fileUrl: URL, with data: String, recursive: Bool, with encoding: String?) throws {
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            let fileHandle = try FileHandle.init(forWritingTo: fileUrl)
            var writeData: Data?
            if encoding != nil {
                guard let userData = data.data(using: .utf8) else {
                    throw FilesystemError.failEncode
                }
                writeData = userData
            } else {
                if let base64Data = Data.capacitor.data(base64EncodedOrDataUrl: data) {
                    writeData = base64Data
                } else {
                    throw FilesystemError.noAppend
                }
            }
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(writeData!)
        } else {
            _ = try writeFile(at: fileUrl, with: data, recursive: recursive, with: encoding)
        }
    }

    @objc func deleteFile(at fileUrl: URL) throws {
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            try FileManager.default.removeItem(atPath: fileUrl.path)
        }
    }

    @objc public func mkdir(at fileUrl: URL, recursive: Bool) throws {
        try FileManager.default.createDirectory(at: fileUrl, withIntermediateDirectories: recursive, attributes: nil)
    }

    @objc public func rmdir(at fileUrl: URL, recursive: Bool) throws {
        let directoryContents = try FileManager.default.contentsOfDirectory(at: fileUrl, includingPropertiesForKeys: nil, options: [])
        if directoryContents.count != 0 && !recursive {
            throw FilesystemError.notEmpty
        }
        try FileManager.default.removeItem(at: fileUrl)
    }

    public func readdir(at fileUrl: URL) throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: fileUrl, includingPropertiesForKeys: nil, options: [])
    }

    func stat(at fileUrl: URL) throws -> [FileAttributeKey: Any] {
        return try FileManager.default.attributesOfItem(atPath: fileUrl.path)
    }

    @objc public func rename(at srcURL: URL, to dstURL: URL) throws {
        try _copy(at: srcURL, to: dstURL, doRename: true)
    }

    @objc public func copy(at srcURL: URL, to dstURL: URL) throws {
        try _copy(at: srcURL, to: dstURL, doRename: false)
    }

    /**
     * Copy or rename a file or directory.
     */
    private func _copy(at srcURL: URL, to dstURL: URL, doRename: Bool) throws {
        if srcURL == dstURL {
            return
        }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: dstURL.path, isDirectory: &isDir) {
            if !isDir.boolValue {
                try? FileManager.default.removeItem(at: dstURL)
            }
        }

        if doRename {
            try FileManager.default.moveItem(at: srcURL, to: dstURL)
        } else {
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        }

    }

    /**
     * Get the SearchPathDirectory corresponding to the JS string
     */
    public func getDirectory(directory: String?) -> FileManager.SearchPathDirectory? {
        if let directory = directory {
            switch directory {
            case "CACHE":
                return .cachesDirectory
            default:
                return .documentDirectory
            }
        }
        return nil
    }

    /**
     * Get the URL for this file, supporting file:// paths and
     * files with directory mappings.
     */
    @objc public func getFileUrl(at path: String, in directory: String?) -> URL? {
        if let directory = getDirectory(directory: directory) {
            guard let dir = FileManager.default.urls(for: directory, in: .userDomainMask).first else {
                return nil
            }

            return dir.appendingPathComponent(path)
        } else {
            return URL(string: path)
        }
    }
}
