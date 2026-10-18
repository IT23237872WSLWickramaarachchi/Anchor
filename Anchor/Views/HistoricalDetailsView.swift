//
//  HistoricalDetailsView.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI
import MapKit
import CoreData

public struct HistoricalDetailsView: View {
    public let session: ParkingSession

    public init(session: ParkingSession) {
        self.session = session
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Read-only map
                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: session.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                )) {
                    Annotation("Parked Spot", coordinate: session.coordinate) {
                        ParkingAnnotationView(title: session.floorAndBaySummary)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .accessibilityLabel("Map showing historical parking spot at \(session.displayTitle)")

                // Reusable ParkingInfoCard for comprehensive historical metadata
                ParkingInfoCard(
                    title: session.displayTitle,
                    parkedAt: session.sessionParkedAt,
                    collectedAt: session.collectedAt,
                    floor: session.displayFloor,
                    bay: session.displayBay,
                    note: session.displayNote,
                    duration: session.formattedDuration
                ) {
                    if let duration = session.formattedDuration {
                        Text(duration)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.12))
                            )
                    }
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Parking Record")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let controller = PersistenceController.inMemory()
    let session = ParkingSession(context: controller.viewContext)
    session.id = UUID()
    session.title = "Grand Central Garage"
    session.latitude = 40.7527
    session.longitude = -73.9772
    session.parkedAt = Date().addingTimeInterval(-7200)
    session.collectedAt = Date()
    session.floor = "P2"
    session.bay = "42"
    session.note = "Near the east escalator exit"
    return NavigationStack {
        HistoricalDetailsView(session: session)
    }
}
