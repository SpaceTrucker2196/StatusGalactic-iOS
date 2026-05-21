import Foundation
import CryptoKit

/// Disk-backed, content-addressed image cache.
///
/// Keys are SHA-256 hashes of the source URL string; cached bytes live under
/// `Caches/StatusGalacticImageCache/<sha>`. Read hits bump the file's
/// modification date so the 90-day TTL counts from last access (LRU-ish).
///
/// All disk I/O happens off the main actor via the global executor.
actor ImageCache {
    static let shared = ImageCache()

    static let ttl: TimeInterval = 90 * 24 * 60 * 60     // 90 days
    static let dirName = "StatusGalacticImageCache"

    private let fileManager = FileManager.default
    private lazy var directory: URL = {
        let root = fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let dir = root.appendingPathComponent(Self.dirName, isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// Returns the bytes for `url`. Cache-first; on miss, fetches and stores.
    func data(for url: URL, session: URLSession = .shared) async throws -> Data {
        let path = filePath(for: url)
        if let cached = try? Data(contentsOf: path) {
            try? fileManager.setAttributes(
                [.modificationDate: Date()], ofItemAtPath: path.path
            )
            return cached
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        try? data.write(to: path, options: [.atomic])
        return data
    }

    /// Sweep cached files older than `Self.ttl` since last access.
    func purgeExpired(now: Date = Date()) {
        let entries = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        for entry in entries {
            let mod = (try? entry.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? .distantPast
            if now.timeIntervalSince(mod) > Self.ttl {
                try? fileManager.removeItem(at: entry)
            }
        }
    }

    func clear() {
        let entries = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for entry in entries { try? fileManager.removeItem(at: entry) }
    }

    private func filePath(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(hex)
    }
}
