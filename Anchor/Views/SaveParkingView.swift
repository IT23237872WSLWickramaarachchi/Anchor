//
//  SaveParkingView.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI
import MapKit

public struct SaveParkingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var viewModel: SaveParkingViewModel
    private let onSaved: () -> Void

    public init(
        sessionToEdit: ParkingSession? = nil,
        parkingService: ParkingServiceProtocol,
        locationService: LocationServiceProtocol,
        onSaved: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: SaveParkingViewModel(
                sessionToEdit: sessionToEdit,
                parkingService: parkingService,
                locationService: locationService
            )
        )
        self.onSaved = onSaved
    }

    public init(
        sessionToEdit: ParkingSession? = nil,
        parkingService: ParkingServiceProtocol,
        onSaved: @escaping () -> Void = {}
    ) {
        #if DEBUG
        if CommandLine.arguments.contains("-UITesting") || CommandLine.arguments.contains("-UITestLocation") {
            self.init(
                sessionToEdit: sessionToEdit,
                parkingService: parkingService,
                locationService: TestLocationService(),
                onSaved: onSaved
            )
            return
        }
        #endif
        self.init(
            sessionToEdit: sessionToEdit,
            parkingService: parkingService,
            locationService: LocationService(),
            onSaved: onSaved
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // SECTION 1: Location Selection
                    locationSection

                    // SECTION 2: Spot Details (Title, Floor, Bay)
                    spotDetailsSection

                    // SECTION 3: Notes
                    notesSection
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(viewModel.isEditing ? "Edit Parking" : "Save Parking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("save_cancel_button")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            let success = await viewModel.save()
                            if success {
                                onSaved()
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(Color.accentColor)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityIdentifier("save_submit_button")
                }
            }
            .alert("Location Access Required", isPresented: $viewModel.showSettingsAlert) {
                Button("Open Settings") {
                    viewModel.openSystemSettings()
                }
                Button("Choose on Map", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Location access is denied. You can tap anywhere directly on the map to set your spot, or enable location in Settings.")
            }
            .alert("Notice", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred.")
            }
        }
    }

    // MARK: - Section 1: Location Selection

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("LOCATION SELECTION", systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.selectedCoordinate != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("Spot selected")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(Color.accentColor)
                } else {
                    Text("Required")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            ZStack(alignment: .topTrailing) {
                MapReader { proxy in
                    Map(position: $viewModel.mapCameraPosition) {
                        if let coordinate = viewModel.selectedCoordinate {
                            Annotation("Parked Spot", coordinate: coordinate) {
                                ParkingAnnotationView(title: viewModel.floorAndBayHint)
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .onTapGesture { screenPoint in
                        if let tappedCoordinate = proxy.convert(screenPoint, from: .local) {
                            viewModel.selectManualCoordinate(tappedCoordinate)
                        }
                    }
                }

                // Current Location Button
                Button {
                    viewModel.requestCurrentLocation()
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isLocating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.accentColor)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.footnote.weight(.semibold))
                        }
                        Text(viewModel.isLocating ? "Locating..." : "Use current location")
                            .font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .disabled(viewModel.isLocating)
                .padding(12)
                .accessibilityIdentifier("save_current_location_button")
                .accessibilityLabel(viewModel.isLocating ? "Locating current position" : "Use current GPS location")
            }

            // Brief Manual Selection Explanation
            HStack(spacing: 6) {
                Image(systemName: "hand.tap")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text(viewModel.selectedCoordinate == nil
                     ? "Tap anywhere on the map to pin your car's spot."
                     : "Tap anywhere on the map to reposition your pin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            // Inline error notification near control
            if let error = viewModel.errorMessage, !viewModel.showErrorAlert, !viewModel.showSettingsAlert {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    // MARK: - Section 2: Spot Details

    private var spotDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SPOT DETAILS")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            // Title Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Location or Garage Name")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                TextField("e.g. Shopping Mall, Downtown Garage", text: $viewModel.title)
                    .textInputAutocapitalization(.words)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
                    .accessibilityIdentifier("save_title_field")
            }

            // Floor & Bay Fields
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    floorField
                    bayField
                }
            } else {
                HStack(spacing: 12) {
                    floorField
                    bayField
                }
            }

            // Garage Guidance
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 1)
                    .accessibilityHidden(true)

                Text("GPS identifies the lot entrance. Floor and bay are essential for multi-level garages.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        )
    }

    private var floorField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Floor (Optional)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            TextField("e.g. 3, B2", text: $viewModel.floor)
                .textInputAutocapitalization(.characters)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
                .accessibilityIdentifier("save_floor_field")
        }
    }

    private var bayField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bay (Optional)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            TextField("e.g. 42B, Blue", text: $viewModel.bay)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
                .accessibilityIdentifier("save_bay_field")
        }
    }

    // MARK: - Section 3: Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PARKING NOTES")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes (Optional)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                TextField("e.g. Next to pillar 14, near entrance C elevator", text: $viewModel.note, axis: .vertical)
                    .lineLimit(3...5)
                    .textInputAutocapitalization(.sentences)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
                    .accessibilityIdentifier("save_note_field")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        )
    }
}

private extension SaveParkingViewModel {
    var floorAndBayHint: String? {
        let f = floor.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = bay.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (!f.isEmpty, !b.isEmpty) {
        case (true, true): return "F\(f) • B\(b)"
        case (true, false): return "Floor \(f)"
        case (false, true): return "Bay \(b)"
        default: return nil
        }
    }
}

#Preview {
    SaveParkingView(parkingService: ParkingService(persistenceController: .preview))
}
