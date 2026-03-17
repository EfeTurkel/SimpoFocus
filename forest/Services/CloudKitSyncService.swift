import Foundation
#if canImport(CloudKit)
import CloudKit
#endif

enum CloudKitSyncError: Error {
    case featureUnavailable
    case invalidPayload
}

actor CloudKitSyncService {
    static let shared = CloudKitSyncService()

    private init() {}

#if canImport(CloudKit)
    private let container = CKContainer.default()
    private let recordType = "UserState"
    private let recordName = "singleton"
#endif

    func push(snapshot: UserStateSnapshot) async throws {
#if canImport(CloudKit)
        let data = try JSONEncoder().encode(snapshot)
        let recordID = CKRecord.ID(recordName: recordName)
        let record = try await fetchRecordOrCreate(recordID: recordID)
        record["payload"] = data as NSData
        record["updatedAt"] = snapshot.updatedAt as NSDate
        record["deviceId"] = snapshot.deviceId as NSString
        _ = try await retry(maxAttempts: 3) {
            try await self.save(record: record)
        }
#else
        throw CloudKitSyncError.featureUnavailable
#endif
    }

    func pullLatest() async throws -> UserStateSnapshot? {
#if canImport(CloudKit)
        let recordID = CKRecord.ID(recordName: recordName)
        guard let record = try await retry(maxAttempts: 3, operation: { try await self.fetch(recordID: recordID) }) else {
            return nil
        }
        guard let data = record["payload"] as? Data else {
            return nil
        }
        return try JSONDecoder().decode(UserStateSnapshot.self, from: data)
#else
        return nil
#endif
    }
}

#if canImport(CloudKit)
private extension CloudKitSyncService {
    var database: CKDatabase {
        container.privateCloudDatabase
    }

    func fetchRecordOrCreate(recordID: CKRecord.ID) async throws -> CKRecord {
        if let existing = try await fetch(recordID: recordID) {
            return existing
        }
        return CKRecord(recordType: recordType, recordID: recordID)
    }

    func fetch(recordID: CKRecord.ID) async throws -> CKRecord? {
        try await withCheckedThrowingContinuation { continuation in
            database.fetch(withRecordID: recordID) { record, error in
                if let ckError = error as? CKError, ckError.code == .unknownItem {
                    continuation.resume(returning: nil)
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: record)
            }
        }
    }

    func save(record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            database.save(record) { saved, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let saved else {
                    continuation.resume(throwing: CloudKitSyncError.invalidPayload)
                    return
                }
                continuation.resume(returning: saved)
            }
        }
    }

    func retry<T>(maxAttempts: Int, operation: @escaping () async throws -> T) async throws -> T {
        var attempt = 0
        var lastError: Error?
        while attempt < maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                attempt += 1
                guard attempt < maxAttempts, shouldRetry(error: error) else {
                    throw error
                }
                let waitNs = UInt64(attempt * 300_000_000)
                try await Task.sleep(nanoseconds: waitNs)
            }
        }
        throw lastError ?? CloudKitSyncError.invalidPayload
    }

    func shouldRetry(error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        switch ckError.code {
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
            return true
        default:
            return false
        }
    }
}
#endif
