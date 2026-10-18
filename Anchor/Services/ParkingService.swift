//
//  ParkingService.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import Foundation
import CoreData
import CoreLocation

public protocol ParkingServiceProtocol: Sendable {
    func fetchActiveSession() throws -> ParkingSession?
    func fetchCompletedSessions() throws -> [ParkingSession]
    func createActiveSession(
        coordinate: CLLocationCoordinate2D,
        title: String?,
        floor: String?,
        bay: String?,
        note: String?,
        parkedAt: Date
    ) throws -> ParkingSession
    func updateActiveSession(
        session: ParkingSession,
        coordinate: CLLocationCoordinate2D,
        title: String?,
        floor: String?,
        bay: String?,
        note: String?
    ) throws
    func markCollected(session: ParkingSession, collectedAt: Date) throws
    func deleteCompletedSession(session: ParkingSession) throws
}

public final class ParkingService: ParkingServiceProtocol, @unchecked Sendable {
    private let persistenceController: PersistenceController

    public init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    nonisolated deinit {}

    private var context: NSManagedObjectContext {
        persistenceController.viewContext
    }

    public func fetchActiveSession() throws -> ParkingSession? {
        let request = NSFetchRequest<ParkingSession>(entityName: "ParkingSession")
        request.predicate = NSPredicate(format: "collectedAt == nil")
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            throw AnchorError.persistenceFetchFailed(error.localizedDescription)
        }
    }

    public func fetchCompletedSessions() throws -> [ParkingSession] {
        let request = NSFetchRequest<ParkingSession>(entityName: "ParkingSession")
        request.predicate = NSPredicate(format: "collectedAt != nil")
        request.sortDescriptors = [NSSortDescriptor(key: "collectedAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            throw AnchorError.persistenceFetchFailed(error.localizedDescription)
        }
    }

    public func createActiveSession(
        coordinate: CLLocationCoordinate2D,
        title: String?,
        floor: String?,
        bay: String?,
        note: String?,
        parkedAt: Date = Date()
    ) throws -> ParkingSession {
        // Coordinate validation
        try validateCoordinate(coordinate)

        // At most one active session rule
        if let existing = try fetchActiveSession() {
            throw AnchorError.activeSessionAlreadyExists
        }

        let session = ParkingSession(context: context)
        session.id = UUID()
        session.latitude = coordinate.latitude
        session.longitude = coordinate.longitude
        session.parkedAt = parkedAt
        session.collectedAt = nil

        let trimmedTitle = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        session.title = trimmedTitle.isEmpty ? "Parked car" : trimmedTitle

        let trimmedFloor = (floor ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        session.floor = trimmedFloor.isEmpty ? nil : trimmedFloor

        let trimmedBay = (bay ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        session.bay = trimmedBay.isEmpty ? nil : trimmedBay

        let trimmedNote = (note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        session.note = trimmedNote.isEmpty ? nil : trimmedNote

        try persistenceController.saveContext()
        return session
    }

    public func updateActiveSession(
        session: ParkingSession,
        coordinate: CLLocationCoordinate2D,
        title: String?,
        floor: String?,
        bay: String?,
        note: String?
    ) throws {
        // Verify session is still active
        guard session.isActive else {
            throw AnchorError.activeSessionNotFound
        }

        // Coordinate validation
        try validateCoordinate(coordinate)

        // Preserve UUID and parkedAt
        session.latitude = coordinate.latitude
        session.longitude = coordinate.longitude

        let trimmedTitle = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        session.title = trimmedTitle.isEmpty ? "Parked car" : trimmedTitle

        let trimmedFloor = (floor ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        session.floor = trimmedFloor.isEmpty ? nil : trimmedFloor

        let trimmedBay = (bay ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        session.bay = trimmedBay.isEmpty ? nil : trimmedBay

        let trimmedNote = (note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        session.note = trimmedNote.isEmpty ? nil : trimmedNote

        try persistenceController.saveContext()
    }

    public func markCollected(session: ParkingSession, collectedAt: Date = Date()) throws {
        guard session.isActive else {
            throw AnchorError.sessionAlreadyCollected
        }

        session.collectedAt = collectedAt
        try persistenceController.saveContext()
    }

    public func deleteCompletedSession(session: ParkingSession) throws {
        // Enforce rule: Deleting completed history must never delete or modify an active session.
        guard session.isCompleted else {
            throw AnchorError.cannotDeleteActiveSession
        }

        context.delete(session)
        try persistenceController.saveContext()
    }

    private func validateCoordinate(_ coordinate: CLLocationCoordinate2D) throws {
        guard coordinate.latitude.isFinite,
              coordinate.longitude.isFinite,
              coordinate.latitude >= -90.0, coordinate.latitude <= 90.0,
              coordinate.longitude >= -180.0, coordinate.longitude <= 180.0 else {
            throw AnchorError.invalidCoordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
    }
}
