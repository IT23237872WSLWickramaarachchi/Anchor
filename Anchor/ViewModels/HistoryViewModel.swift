//
//  HistoryViewModel.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class HistoryViewModel: ObservableObject {
    @Published public private(set) var completedSessions: [ParkingSession] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var showErrorAlert: Bool = false
    @Published public var sessionToDelete: ParkingSession?
    @Published public var showDeleteConfirmation: Bool = false

    private let parkingService: ParkingServiceProtocol

    public init(parkingService: ParkingServiceProtocol) {
        self.parkingService = parkingService
    }

    public func loadHistory() {
        isLoading = true
        do {
            completedSessions = try parkingService.fetchCompletedSessions()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        isLoading = false
    }

    public func promptDelete(session: ParkingSession) {
        sessionToDelete = session
        showDeleteConfirmation = true
    }

    public func confirmDelete() {
        guard let session = sessionToDelete else { return }
        do {
            try parkingService.deleteCompletedSession(session: session)
            sessionToDelete = nil
            loadHistory()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
