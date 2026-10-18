//
//  AnchorTests.swift
//  AnchorTests
//
//  Created by IM Student on 2026-10-17.
//

import XCTest
import CoreLocation
@testable import Anchor

@MainActor
final class AnchorTests: XCTestCase {
    private var persistenceController: PersistenceController!
    private var parkingService: ParkingService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Use an isolated in-memory store for unit tests
        persistenceController = PersistenceController.inMemory()
        parkingService = ParkingService(persistenceController: persistenceController)
    }

    override func tearDownWithError() throws {
        persistenceController = nil
        parkingService = nil
        try super.tearDownWithError()
    }

    // MARK: - Requirement 1: A valid parking session can be created

    func testCreateActiveSessionSuccess() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let parkedAt = Date()

        let session = try parkingService.createActiveSession(
            coordinate: coordinate,
            title: "Union Square Garage",
            floor: "Level 4",
            bay: "Bay 42",
            note: "Near north elevators",
            parkedAt: parkedAt
        )

        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.displayTitle, "Union Square Garage")
        XCTAssertEqual(session.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(session.longitude, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(session.floor, "Level 4")
        XCTAssertEqual(session.bay, "Bay 42")
        XCTAssertEqual(session.note, "Near north elevators")
        XCTAssertEqual(session.parkedAt, parkedAt)
        XCTAssertNil(session.collectedAt)
        XCTAssertTrue(session.isActive)
        XCTAssertFalse(session.isCompleted)
    }

    // MARK: - Requirement 2: Creating a second active session is rejected

    func testAtMostOneActiveSessionEnforced() throws {
        let coord1 = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        _ = try parkingService.createActiveSession(coordinate: coord1, title: "First Spot", floor: nil, bay: nil, note: nil)

        let coord2 = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
        XCTAssertThrowsError(
            try parkingService.createActiveSession(coordinate: coord2, title: "Second Spot", floor: nil, bay: nil, note: nil)
        ) { error in
            XCTAssertEqual(error as? AnchorError, AnchorError.activeSessionAlreadyExists)
        }
    }

    // MARK: - Requirement 3: Editing preserves UUID and parkedAt

    func testUpdateActiveSessionPreservesIDAndParkedAt() throws {
        let originalParkedAt = Date(timeIntervalSince1970: 1700000000)
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        let session = try parkingService.createActiveSession(
            coordinate: coord,
            title: "Original Title",
            floor: "1",
            bay: "A",
            note: "Old Note",
            parkedAt: originalParkedAt
        )

        let originalID = session.sessionID

        let newCoord = CLLocationCoordinate2D(latitude: 37.7800, longitude: -122.4100)
        try parkingService.updateActiveSession(
            session: session,
            coordinate: newCoord,
            title: "Updated Title",
            floor: "2",
            bay: "B",
            note: "Updated Note"
        )

        XCTAssertEqual(session.sessionID, originalID, "Session UUID must be preserved upon editing")
        XCTAssertEqual(session.parkedAt, originalParkedAt, "ParkedAt timestamp must be preserved upon editing")
        XCTAssertEqual(session.displayTitle, "Updated Title")
        XCTAssertEqual(session.latitude, 37.7800, accuracy: 0.0001)
        XCTAssertEqual(session.floor, "2")
        XCTAssertEqual(session.bay, "B")
        XCTAssertEqual(session.note, "Updated Note")
    }

    // MARK: - Requirement 4: Collecting sets collectedAt and moves session out of active results

    func testMarkCollectedCompletesSession() throws {
        let parkedAt = Date(timeIntervalSince1970: 1700000000)
        let collectedAt = Date(timeIntervalSince1970: 1700001800) // 30 minutes later
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        let session = try parkingService.createActiveSession(
            coordinate: coord,
            title: "Airport Long Term",
            floor: "P3",
            bay: "14B",
            note: nil,
            parkedAt: parkedAt
        )

        XCTAssertTrue(session.isActive)

        try parkingService.markCollected(session: session, collectedAt: collectedAt)

        XCTAssertFalse(session.isActive)
        XCTAssertTrue(session.isCompleted)
        XCTAssertEqual(session.collectedAt, collectedAt)

        // Verify active session fetch returns nil now
        let active = try parkingService.fetchActiveSession()
        XCTAssertNil(active, "Active session query must return nil once collected")

        // Verify it appears in completed history
        let completed = try parkingService.fetchCompletedSessions()
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.displayTitle, "Airport Long Term")
    }

    // MARK: - Requirement 5: Collecting an already completed session does not rewrite its completion time

    func testCannotCollectAlreadyCompletedSessionAndPreservesTimestamp() throws {
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let initialCollectedAt = Date(timeIntervalSince1970: 1700001000)

        let session = try parkingService.createActiveSession(coordinate: coord, title: "Test", floor: nil, bay: nil, note: nil)
        try parkingService.markCollected(session: session, collectedAt: initialCollectedAt)

        let laterAttempt = Date(timeIntervalSince1970: 1700009999)
        XCTAssertThrowsError(
            try parkingService.markCollected(session: session, collectedAt: laterAttempt)
        ) { error in
            XCTAssertEqual(error as? AnchorError, AnchorError.sessionAlreadyCollected)
        }

        // Original completion timestamp must remain unmodified
        XCTAssertEqual(session.collectedAt, initialCollectedAt, "Original completion time must not be rewritten")
    }

    // MARK: - Requirement 6: Completed history is ordered newest first

    func testCompletedHistoryOrderedNewestFirst() throws {
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        // Session 1: Completed earlier (T1)
        let session1 = try parkingService.createActiveSession(coordinate: coord, title: "First Session", floor: nil, bay: nil, note: nil)
        let t1 = Date(timeIntervalSince1970: 1700001000)
        try parkingService.markCollected(session: session1, collectedAt: t1)

        // Session 2: Completed later (T2 > T1)
        let session2 = try parkingService.createActiveSession(coordinate: coord, title: "Second Session", floor: nil, bay: nil, note: nil)
        let t2 = Date(timeIntervalSince1970: 1700005000)
        try parkingService.markCollected(session: session2, collectedAt: t2)

        let history = try parkingService.fetchCompletedSessions()
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].sessionID, session2.sessionID, "Newest completed session should appear first")
        XCTAssertEqual(history[1].sessionID, session1.sessionID, "Older completed session should appear second")
    }

    // MARK: - Requirement 7: Deleting a completed session does not affect the active session

    func testDeleteCompletedSessionSucceedsAndPreservesActiveSession() throws {
        let coord1 = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let historicalSession = try parkingService.createActiveSession(coordinate: coord1, title: "Old Park", floor: nil, bay: nil, note: nil)
        try parkingService.markCollected(session: historicalSession, collectedAt: Date().addingTimeInterval(-1000))

        // Create a new active session
        let coord2 = CLLocationCoordinate2D(latitude: 37.7800, longitude: -122.4100)
        let activeSession = try parkingService.createActiveSession(coordinate: coord2, title: "Active Park", floor: nil, bay: nil, note: nil)

        // Delete the historical session
        try parkingService.deleteCompletedSession(session: historicalSession)

        // Completed history should now be empty
        let completed = try parkingService.fetchCompletedSessions()
        XCTAssertEqual(completed.count, 0)

        // Active session must remain completely intact
        let currentActive = try parkingService.fetchActiveSession()
        XCTAssertNotNil(currentActive)
        XCTAssertEqual(currentActive?.sessionID, activeSession.sessionID)
        XCTAssertEqual(currentActive?.displayTitle, "Active Park")
    }

    func testCannotDeleteActiveSessionFromHistory() throws {
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let activeSession = try parkingService.createActiveSession(coordinate: coord, title: "Active Park", floor: nil, bay: nil, note: nil)

        XCTAssertThrowsError(
            try parkingService.deleteCompletedSession(session: activeSession)
        ) { error in
            XCTAssertEqual(error as? AnchorError, AnchorError.cannotDeleteActiveSession)
        }
    }

    // MARK: - Requirement 8: Blank titles normalize to 'Parked car'

    func testBlankTitleDefaultsToParkedCar() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)

        let sessionWhitespace = try parkingService.createActiveSession(
            coordinate: coordinate,
            title: "   \n\t  ",
            floor: nil,
            bay: nil,
            note: nil
        )
        XCTAssertEqual(sessionWhitespace.displayTitle, "Parked car")
        try parkingService.markCollected(session: sessionWhitespace)

        let sessionNil = try parkingService.createActiveSession(
            coordinate: coordinate,
            title: nil,
            floor: nil,
            bay: nil,
            note: nil
        )
        XCTAssertEqual(sessionNil.displayTitle, "Parked car")
    }

    // MARK: - Requirement 9: Invalid/non-finite coordinates rejected, (0,0) accepted

    func testRejectInvalidCoordinatesAndAcceptsZeroZero() throws {
        let invalidLat = CLLocationCoordinate2D(latitude: 95.0, longitude: 0.0)
        XCTAssertThrowsError(
            try parkingService.createActiveSession(coordinate: invalidLat, title: nil, floor: nil, bay: nil, note: nil)
        ) { error in
            guard case AnchorError.invalidCoordinates = error else {
                XCTFail("Expected invalidCoordinates error, got \(error)")
                return
            }
        }

        let invalidLon = CLLocationCoordinate2D(latitude: 0.0, longitude: -185.0)
        XCTAssertThrowsError(
            try parkingService.createActiveSession(coordinate: invalidLon, title: nil, floor: nil, bay: nil, note: nil)
        ) { error in
            guard case AnchorError.invalidCoordinates = error else {
                XCTFail("Expected invalidCoordinates error, got \(error)")
                return
            }
        }

        let nanCoord = CLLocationCoordinate2D(latitude: Double.nan, longitude: 0.0)
        XCTAssertThrowsError(
            try parkingService.createActiveSession(coordinate: nanCoord, title: nil, floor: nil, bay: nil, note: nil)
        )

        // Explicitly selected (0.0, 0.0) (Null Island) is a valid geographic coordinate and must be accepted
        let zeroZero = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let validZeroSession = try parkingService.createActiveSession(
            coordinate: zeroZero,
            title: "Equator & Prime Meridian",
            floor: nil,
            bay: nil,
            note: nil
        )
        XCTAssertEqual(validZeroSession.latitude, 0.0)
        XCTAssertEqual(validZeroSession.longitude, 0.0)
    }

    // MARK: - Requirement 10: Active and completed durations use correct timestamps

    func testActiveAndCompletedDurationsUseCorrectTimestamps() throws {
        let baseTime = Date(timeIntervalSince1970: 1700000000)
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        let session = try parkingService.createActiveSession(
            coordinate: coord,
            title: "Duration Test",
            floor: nil,
            bay: nil,
            note: nil,
            parkedAt: baseTime
        )

        // Deterministic active elapsed time test with controlled clock input
        let checkTime = baseTime.addingTimeInterval(3600 + 1440) // 1h 24m later
        let activeElapsed = session.activeElapsedTime(at: checkTime)
        XCTAssertEqual(activeElapsed, 5040, accuracy: 0.1)

        // Complete the session at checkTime
        try parkingService.markCollected(session: session, collectedAt: checkTime)

        guard let completedDuration = session.completedDuration else {
            XCTFail("Expected non-nil completedDuration after collecting session")
            return
        }
        XCTAssertEqual(completedDuration, 5040, accuracy: 0.1)
        XCTAssertEqual(session.formattedDuration, "1h 24m")
    }

    // MARK: - Requirement 11: Floor & Bay Summary Formatting

    func testFloorAndBaySummaryFormatting() throws {
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        let sessionBoth = try parkingService.createActiveSession(coordinate: coord, title: "Test", floor: "2", bay: "10", note: nil)
        XCTAssertEqual(sessionBoth.floorAndBaySummary, "Floor 2 • Bay 10")
        try parkingService.markCollected(session: sessionBoth)

        let sessionFloorOnly = try parkingService.createActiveSession(coordinate: coord, title: "Test", floor: "3", bay: nil, note: nil)
        XCTAssertEqual(sessionFloorOnly.floorAndBaySummary, "Floor 3")
        try parkingService.markCollected(session: sessionFloorOnly)

        let sessionBayOnly = try parkingService.createActiveSession(coordinate: coord, title: "Test", floor: nil, bay: "B4", note: nil)
        XCTAssertEqual(sessionBayOnly.floorAndBaySummary, "Bay B4")
        try parkingService.markCollected(session: sessionBayOnly)

        let sessionNeither = try parkingService.createActiveSession(coordinate: coord, title: "Test", floor: "", bay: "  ", note: nil)
        XCTAssertNil(sessionNeither.floorAndBaySummary)
    }

    // MARK: - Requirement 12: Isolated Temporary On-Disk Persistence Integration Test

    func testPersistenceDiskIntegration() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let storeURL = tempDir.appendingPathComponent("AnchorIntegrationTest.sqlite")

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        var savedID: UUID?

        // Phase 1: Write session to temporary SQLite store
        do {
            let stack1 = PersistenceController(storeURL: storeURL)
            let service1 = ParkingService(persistenceController: stack1)

            let session = try service1.createActiveSession(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                title: "Persistent Garage",
                floor: "Level 3",
                bay: "Bay 12",
                note: "Stored on disk across relaunches",
                parkedAt: Date(timeIntervalSince1970: 1700000000)
            )
            savedID = session.sessionID
            XCTAssertNotNil(savedID)
        }

        // Phase 2: Tear down stack1 completely, re-initialize new stack2 pointing to the same SQLite store
        do {
            let stack2 = PersistenceController(storeURL: storeURL)
            let service2 = ParkingService(persistenceController: stack2)

            let retrievedActive = try service2.fetchActiveSession()
            XCTAssertNotNil(retrievedActive, "Active session must survive complete stack teardown and relaunch")
            XCTAssertEqual(retrievedActive?.sessionID, savedID)
            XCTAssertEqual(retrievedActive?.displayTitle, "Persistent Garage")
            XCTAssertEqual(retrievedActive?.floor, "Level 3")
            XCTAssertEqual(retrievedActive?.bay, "Bay 12")
            XCTAssertEqual(retrievedActive?.note, "Stored on disk across relaunches")
            XCTAssertEqual(retrievedActive?.latitude ?? 0, 37.7749, accuracy: 0.0001)
            XCTAssertEqual(retrievedActive?.longitude ?? 0, -122.4194, accuracy: 0.0001)
        }
    }
}
