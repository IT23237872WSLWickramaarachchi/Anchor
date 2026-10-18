//
//  AnchorTabView.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI

public struct AnchorTabView: View {
    private let parkingService: ParkingServiceProtocol

    public init(parkingService: ParkingServiceProtocol) {
        self.parkingService = parkingService
    }

    public var body: some View {
        TabView {
            // Tab 1: Parking
            CurrentParkingView(parkingService: parkingService)
                .tabItem {
                    Label("Parking", systemImage: "car.fill")
                }
                .accessibilityIdentifier("tab_parking")

            // Tab 2: History
            HistoryView(parkingService: parkingService)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .accessibilityIdentifier("tab_history")
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    AnchorTabView(parkingService: ParkingService(persistenceController: .preview))
}
