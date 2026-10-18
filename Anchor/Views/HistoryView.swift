//
//  HistoryView.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI

public struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel

    public init(parkingService: ParkingServiceProtocol) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(parkingService: parkingService))
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.completedSessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(Color.accentColor.opacity(0.8))
                            .accessibilityHidden(true)

                        VStack(spacing: 6) {
                            Text("No parking history yet.")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)

                            Text("Completed parking sessions will appear here.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("history_empty_view")
                } else {
                    List {
                        ForEach(viewModel.completedSessions, id: \.sessionID) { session in
                            NavigationLink(destination: HistoricalDetailsView(session: session)) {
                                HistoryRowView(session: session)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.promptDelete(session: session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("History")
            .onAppear {
                viewModel.loadHistory()
            }
            .confirmationDialog(
                "Delete Parking Record",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Record", role: .destructive) {
                    viewModel.confirmDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove this completed parking record? This cannot be undone.")
            }
            .alert("Notice", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred.")
            }
        }
    }
}

private struct HistoryRowView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let session: ParkingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    titleAndFloor
                    durationBadge
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    titleAndFloor
                    Spacer(minLength: 8)
                    durationBadge
                }
            }

            // Date and Time
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(session.sessionParkedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("•")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(session.sessionParkedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }

    private var titleAndFloor: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(session.displayTitle)
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let summary = session.floorAndBaySummary {
                Text(summary)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    @ViewBuilder
    private var durationBadge: some View {
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

    private var accessibleRowSummary: String {
        var summary = "\(session.displayTitle)."
        if let fb = session.floorAndBaySummary {
            summary += " \(fb)."
        }
        summary += " Parked on \(session.sessionParkedAt.formatted(date: .abbreviated, time: .shortened))."
        if let duration = session.formattedDuration {
            summary += " Duration: \(duration)."
        }
        return summary
    }
}

#Preview {
    HistoryView(parkingService: ParkingService(persistenceController: .preview))
}
