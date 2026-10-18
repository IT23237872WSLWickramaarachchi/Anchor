//
//  SaveParkingViewModel.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit
import Combine

@MainActor
public final class SaveParkingViewModel: ObservableObject {
    @Published public var selectedCoordinate: CLLocationCoordinate2D?
    @Published public var title: String = ""
    @Published public var floor: String = ""
    @Published public var bay: String = ""
    @Published public var note: String = ""

    @Published public var isLocating: Bool = false
    @Published public var isSaving: Bool = false
    @Published public var errorMessage: String?
    @Published public var showErrorAlert: Bool = false
    @Published public var showSettingsAlert: Bool = false

    // Map viewport camera position (viewing position only; not a selection until explicitly tapped or located)
    @Published public var mapCameraPosition: MapCameraPosition

    public let isEditing: Bool
    private let sessionToEdit: ParkingSession?
    private let parkingService: ParkingServiceProtocol
    private let locationService: LocationServiceProtocol

    // Tracks user-initiated manual changes so older asynchronous location requests do not overwrite newer manual choices
    private var selectionTimestamp: Date = .distantPast

    public init(
        sessionToEdit: ParkingSession? = nil,
        parkingService: ParkingServiceProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.sessionToEdit = sessionToEdit
        self.isEditing = sessionToEdit != nil
        self.parkingService = parkingService
        self.locationService = locationService

        if let session = sessionToEdit {
            self.title = session.title ?? ""
            self.floor = session.floor ?? ""
            self.bay = session.bay ?? ""
            self.note = session.note ?? ""
            let coord = session.coordinate
            self.selectedCoordinate = coord
            self.mapCameraPosition = .region(
                MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        } else {
            // Default viewing position (e.g. San Francisco or neutral center).
            // This is ONLY a viewport position, not a selected coordinate!
            let defaultCenter = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            self.selectedCoordinate = nil
            self.mapCameraPosition = .region(
                MKCoordinateRegion(
                    center: defaultCenter,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                )
            )
        }
    }

    public convenience init(
        sessionToEdit: ParkingSession? = nil,
        parkingService: ParkingServiceProtocol
    ) {
        self.init(
            sessionToEdit: sessionToEdit,
            parkingService: parkingService,
            locationService: LocationService()
        )
    }

    public var canSave: Bool {
        selectedCoordinate != nil && !isSaving && !isLocating
    }

    public func selectManualCoordinate(_ coordinate: CLLocationCoordinate2D) {
        // Enforce valid geographic bounds
        guard coordinate.latitude.isFinite && coordinate.longitude.isFinite &&
              coordinate.latitude >= -90.0 && coordinate.latitude <= 90.0 &&
              coordinate.longitude >= -180.0 && coordinate.longitude <= 180.0 else {
            return
        }

        selectionTimestamp = Date()
        selectedCoordinate = coordinate
    }

    public func requestCurrentLocation() {
        guard !isLocating else { return }

        isLocating = true
        let requestInitiatedAt = Date()

        Task {
            do {
                let coordinate = try await locationService.requestOneShotLocation()

                // Rule: Do not overwrite a newer manual selection when an older location request finishes
                if self.selectionTimestamp <= requestInitiatedAt {
                    self.selectedCoordinate = coordinate
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.mapCameraPosition = .region(
                            MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                            )
                        )
                    }
                }
                self.isLocating = false
            } catch let error as AnchorError {
                self.isLocating = false
                if error == .locationPermissionDenied {
                    self.errorMessage = error.errorDescription
                    self.showSettingsAlert = true
                } else {
                    self.errorMessage = error.errorDescription
                    self.showErrorAlert = true
                }
            } catch {
                self.isLocating = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }

    public func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    public func save() async -> Bool {
        guard canSave, let coordinate = selectedCoordinate else {
            errorMessage = AnchorError.noCoordinateSelected.localizedDescription
            showErrorAlert = true
            return false
        }

        isSaving = true

        do {
            if isEditing, let existing = sessionToEdit {
                try parkingService.updateActiveSession(
                    session: existing,
                    coordinate: coordinate,
                    title: title,
                    floor: floor,
                    bay: bay,
                    note: note
                )
            } else {
                _ = try parkingService.createActiveSession(
                    coordinate: coordinate,
                    title: title,
                    floor: floor,
                    bay: bay,
                    note: note,
                    parkedAt: Date()
                )
            }
            isSaving = false
            return true
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
            showErrorAlert = true
            return false
        }
    }
}
