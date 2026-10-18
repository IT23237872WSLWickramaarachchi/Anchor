//
//  ParkingSession.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import Foundation
import CoreData
import CoreLocation

@objc(ParkingSession)
public class ParkingSession: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var parkedAt: Date?
    @NSManaged public var collectedAt: Date?
    @NSManaged public var floor: String?
    @NSManaged public var bay: String?
    @NSManaged public var note: String?

    public var sessionID: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }

    public var sessionParkedAt: Date {
        get { parkedAt ?? Date() }
        set { parkedAt = newValue }
    }

    /// A session is active when collectedAt is nil.
    public var isActive: Bool {
        collectedAt == nil
    }

    /// A session is completed when collectedAt is not nil.
    public var isCompleted: Bool {
        collectedAt != nil
    }

    /// Safe coordinate representation.
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Title with trimming and default fallback.
    public var displayTitle: String {
        let trimmed = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Parked car" : trimmed
    }

    /// Optional floor trimmed.
    public var displayFloor: String? {
        guard let floor = floor?.trimmingCharacters(in: .whitespacesAndNewlines), !floor.isEmpty else {
            return nil
        }
        return floor
    }

    /// Optional bay trimmed.
    public var displayBay: String? {
        guard let bay = bay?.trimmingCharacters(in: .whitespacesAndNewlines), !bay.isEmpty else {
            return nil
        }
        return bay
    }

    /// Optional note trimmed.
    public var displayNote: String? {
        guard let note = note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty else {
            return nil
        }
        return note
    }

    /// Combined floor and bay summary, e.g. "Floor 2 • Bay 42" or nil if neither is provided.
    public var floorAndBaySummary: String? {
        switch (displayFloor, displayBay) {
        case let (.some(f), .some(b)):
            return "Floor \(f) • Bay \(b)"
        case let (.some(f), .none):
            return "Floor \(f)"
        case let (.none, .some(b)):
            return "Bay \(b)"
        case (.none, .none):
            return nil
        }
    }

    /// Completed duration calculated from collectedAt minus parkedAt.
    public var completedDuration: TimeInterval? {
        guard let collected = collectedAt, let parked = parkedAt else { return nil }
        return max(0, collected.timeIntervalSince(parked))
    }

    /// Formatted completed duration string (e.g. "1h 24m" or "45m").
    public var formattedDuration: String? {
        guard let duration = completedDuration else { return nil }
        return Self.durationFormatter.string(from: duration)
    }

    /// Active elapsed time calculated from now minus parkedAt.
    public func activeElapsedTime(at currentDate: Date = Date()) -> TimeInterval {
        guard let parked = parkedAt else { return 0 }
        return max(0, currentDate.timeIntervalSince(parked))
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter
    }()
}
