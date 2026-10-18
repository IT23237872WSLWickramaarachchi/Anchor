//
//  CurrentParkingView.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI
import MapKit

public struct CurrentParkingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel: CurrentParkingViewModel
    private let parkingService: ParkingServiceProtocol

    public init(
        parkingService: ParkingServiceProtocol,
        directionsService: DirectionsServiceProtocol
    ) {
        self.parkingService = parkingService
        _viewModel = StateObject(
            wrappedValue: CurrentParkingViewModel(
                parkingService: parkingService,
                directionsService: directionsService
            )
        )
    }

    public init(parkingService: ParkingServiceProtocol) {
        #if DEBUG
        if CommandLine.arguments.contains("-UITesting") {
            self.init(parkingService: parkingService, directionsService: TestDirectionsService())
            return
        }
        #endif
        self.init(parkingService: parkingService, directionsService: DirectionsService())
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                if let session = viewModel.activeSession {
                    activeSessionContent(session: session)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                } else {
                    emptyStateContent
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.activeSession != nil)
            .navigationTitle("Anchor")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadActiveSession()
            }
            .sheet(item: $viewModel.activeSheetItem) { item in
                SaveParkingView(
                    sessionToEdit: item.session,
                    parkingService: parkingService,
                    onSaved: {
                        viewModel.loadActiveSession()
                    }
                )
            }
            .confirmationDialog(
                "Collected Car",
                isPresented: $viewModel.showCollectedConfirmation,
                titleVisibility: .visible
            ) {
                Button("Mark as Collected", role: .none) {
                    viewModel.confirmCollectedCar()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Have you returned to your car? This will complete your active session and move it to history.")
            }
            .alert("Notice", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred.")
            }
        }
    }

    // MARK: - Empty State (No Active Session)

    private var emptyStateContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // Parking Illustration Motif
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(Color.accentColor.opacity(0.25), lineWidth: 2)
                        .frame(width: 140, height: 140)

                    Image(systemName: "parkingsign.steeringwheel")
                        .font(.system(size: 60, weight: .regular))
                        .foregroundStyle(Color.accentColor)
                }
                .accessibilityHidden(true)
                .padding(.vertical, 8)

                VStack(spacing: 8) {
                    Text("Remember where you parked.")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text("Save your spot and find your way back.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)

                // Primary Action Button
                Button {
                    viewModel.startNewParking()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                        Text("Save parking")
                    }
                }
                .buttonStyle(.primaryAction(minHeight: 52))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .accessibilityIdentifier("parking_save_button")
            }
            .frame(maxWidth: .infinity, minHeight: 480)
        }
    }

    // MARK: - Active Session Content

    private func activeSessionContent(session: ParkingSession) -> some View {
        GeometryReader { geometry in
            let isCompactHeight = geometry.size.height < 620

            if isCompactHeight {
                // Scrollable layout for landscape or compact height
                ScrollView {
                    VStack(spacing: 16) {
                        mapView(for: session)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        sessionControls(session: session)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    }
                }
            } else {
                // Connected portrait layout: flexible map at top, anchored card drawer at bottom
                VStack(spacing: 0) {
                    mapView(for: session)
                        .frame(maxHeight: .infinity)

                    sessionControls(session: session)
                        .padding(16)
                        .background(Color(uiColor: .systemGroupedBackground))
                }
            }
        }
    }

    private func mapView(for session: ParkingSession) -> some View {
        Map(initialPosition: .region(
            MKCoordinateRegion(
                center: session.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        )) {
            Annotation("Parked Car", coordinate: session.coordinate) {
                ParkingAnnotationView(title: session.floorAndBaySummary)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .accessibilityLabel("Map showing parked car at \(session.displayTitle)")
    }

    private func sessionControls(session: ParkingSession) -> some View {
        VStack(spacing: 14) {
            // Reusable ParkingInfoCard with live elapsed timer
            ParkingInfoCard(
                title: session.displayTitle,
                parkedAt: session.sessionParkedAt,
                floor: session.displayFloor,
                bay: session.displayBay,
                note: session.displayNote
            ) {
                ElapsedTimerView(parkedAt: session.sessionParkedAt)
            }

            // Primary & Secondary Actions
            VStack(spacing: 10) {
                // Primary Action: Walk to car
                Button {
                    viewModel.walkToCar()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.headline.weight(.bold))
                        Text("Walk to car")
                    }
                }
                .buttonStyle(.primaryAction(minHeight: 48))
                .accessibilityIdentifier("parking_walk_button")

                // Secondary Action: Edit parking details
                Button {
                    viewModel.editCurrentParking()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.subheadline.weight(.semibold))
                        Text("Edit parking")
                    }
                }
                .buttonStyle(.secondaryAction)
                .accessibilityIdentifier("parking_edit_button")

                // Collected Car - Separated to avoid accidental activation
                Button {
                    viewModel.showCollectedConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.subheadline.weight(.medium))
                        Text("Collected car")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityIdentifier("parking_collected_button")
                .accessibilityHint("Completes this parking session and moves it to history")
                .padding(.top, 4)
            }
        }
    }
}

#Preview {
    CurrentParkingView(
        parkingService: ParkingService(persistenceController: .preview)
    )
}
