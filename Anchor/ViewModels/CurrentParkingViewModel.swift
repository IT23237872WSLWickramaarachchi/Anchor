//
//  CurrentParkingViewModel.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

public struct ParkingSheetItem: Identifiable {
    public let id = UUID()
    public let session: ParkingSession?

    public init(session: ParkingSession? = nil) {
        self.session = session
    }
}

@MainActor
public final class CurrentParkingViewModel: ObservableObject {
    @Published public private(set) var activeSession: ParkingSession?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var showErrorAlert: Bool = false
    @Published public var showCollectedConfirmation: Bool = false
    @Published public var activeSheetItem: ParkingSheetItem?

    public var showSaveSheet: Bool {
        get { activeSheetItem != nil }
        set {
            if !newValue {
                activeSheetItem = nil
            } else if activeSheetItem == nil {
                activeSheetItem = ParkingSheetItem(session: nil)
            }
        }
    }

    public var sessionToEdit: ParkingSession? {
        get { activeSheetItem?.session }
        set { activeSheetItem = ParkingSheetItem(session: newValue) }
    }

    private let parkingService: ParkingServiceProtocol
    private let directionsService: DirectionsServiceProtocol

    public init(
        parkingService: ParkingServiceProtocol,
        directionsService: DirectionsServiceProtocol
    ) {
        self.parkingService = parkingService
        self.directionsService = directionsService
    }

    public convenience init(parkingService: ParkingServiceProtocol) {
        self.init(parkingService: parkingService, directionsService: DirectionsService())
    }

    public func loadActiveSession() {
        isLoading = true
        objectWillChange.send()
        do {
            activeSession = try parkingService.fetchActiveSession()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        isLoading = false
    }

    public func walkToCar() {
        guard let session = activeSession else { return }
        let success = directionsService.openWalkingDirections(to: session.coordinate, name: session.displayTitle)
        if !success {
            errorMessage = AnchorError.directionsHandoffFailed.localizedDescription
            showErrorAlert = true
        }
    }

    public func confirmCollectedCar() {
        guard let session = activeSession else { return }
        do {
            try parkingService.markCollected(session: session, collectedAt: Date())
            activeSession = nil
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    public func startNewParking() {
        activeSheetItem = ParkingSheetItem(session: nil)
    }

    public func editCurrentParking() {
        guard let session = activeSession else { return }
        activeSheetItem = ParkingSheetItem(session: session)
    }
}
