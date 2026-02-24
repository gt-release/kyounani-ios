#if canImport(SwiftUI)
import SwiftUI
import UniformTypeIdentifiers

public extension UTType {
    static let kyounaniBackup = UTType(exportedAs: "dev.kyounani.backup", conformingTo: .data)
}

public struct BackupFileDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.kyounaniBackup] }
    public static var writableContentTypes: [UTType] { [.kyounaniBackup] }

    public var data: Data

    public init(data: Data = Data()) {
        self.data = data
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
#endif
