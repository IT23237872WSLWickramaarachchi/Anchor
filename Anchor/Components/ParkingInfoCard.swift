//
//  ParkingInfoCard.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI

/// Reusable card displaying saved parking location metadata, emphasizing floor, bay,
/// timing, and optional notes. Designed for both active parking sessions and historical inspection.
public struct ParkingInfoCard<TrailingContent: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public let title: String
    public let parkedAt: Date
    public let collectedAt: Date?
    public let floor: String?
    public let bay: String?
    public let note: String?
    public let duration: String?
    public let trailingContent: TrailingContent

    public init(
        title: String,
        parkedAt: Date,
        collectedAt: Date? = nil,
        floor: String? = nil,
        bay: String? = nil,
        note: String? = nil,
        duration: String? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.title = title
        self.parkedAt = parkedAt
        self.collectedAt = collectedAt
        self.floor = floor
        self.bay = bay
        self.note = note
        self.duration = duration
        self.trailingContent = trailingContent()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Section: Title & Trailing status
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    titleAndTimestamp
                    trailingContent
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    titleAndTimestamp
                    Spacer()
                    trailingContent
                }
            }

            // Floor and Bay Badges (Prominently styled when present)
            if hasFloorOrBay {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        floorAndBayBadges
                    }
                } else {
                    HStack(spacing: 8) {
                        floorAndBayBadges
                        Spacer()
                    }
                }
            }

            // Optional Note
            if let cleanNote = cleanNote {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 2)
                        .accessibilityHidden(true)

                    Text(cleanNote)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                )
            }

            // Historical timestamps (if collectedAt is present)
            if let collectedAt = collectedAt {
                Divider()
                    .padding(.vertical, 2)

                VStack(spacing: 8) {
                    timeRow(
                        label: "Parked",
                        systemImage: "arrow.down.circle.fill",
                        date: parkedAt
                    )
                    timeRow(
                        label: "Collected",
                        systemImage: "checkmark.circle.fill",
                        date: collectedAt
                    )

                    if let duration = duration {
                        HStack {
                            Label("Total Duration", systemImage: "clock.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(duration)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("parking_info_card")
    }

    // MARK: - Subviews

    private var titleAndTimestamp: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.isEmpty ? "Parked car" : title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 4) {
                Text(collectedAt == nil ? "Saved at" : "Parked on")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if collectedAt != nil {
                    Text(parkedAt, style: .date)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(parkedAt, style: .time)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
    }

    @ViewBuilder
    private var floorAndBayBadges: some View {
        if let f = cleanFloor {
            DetailBadge(icon: "stairs", label: "Floor", value: f)
        }
        if let b = cleanBay {
            DetailBadge(icon: "parkingsign", label: "Bay", value: b)
        }
    }

    private func timeRow(label: String, systemImage: String, date: Date) -> some View {
        HStack {
            Label(label, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(date, style: .date)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(date, style: .time)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Computed Properties

    private var cleanFloor: String? {
        guard let floor = floor?.trimmingCharacters(in: .whitespacesAndNewlines), !floor.isEmpty else {
            return nil
        }
        return floor
    }

    private var cleanBay: String? {
        guard let bay = bay?.trimmingCharacters(in: .whitespacesAndNewlines), !bay.isEmpty else {
            return nil
        }
        return bay
    }

    private var cleanNote: String? {
        guard let note = note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty else {
            return nil
        }
        return note
    }

    private var hasFloorOrBay: Bool {
        cleanFloor != nil || cleanBay != nil
    }

    private var accessibleSummary: String {
        var parts: [String] = []
        let displayTitle = title.isEmpty ? "Parked car" : title
        parts.append("Location: \(displayTitle).")

        if let f = cleanFloor, let b = cleanBay {
            parts.append("Floor \(f), Bay \(b).")
        } else if let f = cleanFloor {
            parts.append("Floor \(f).")
        } else if let b = cleanBay {
            parts.append("Bay \(b).")
        }

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = collectedAt != nil ? .medium : .none
        parts.append("Parked at \(timeFormatter.string(from: parkedAt)).")

        if let collected = collectedAt {
            parts.append("Collected at \(timeFormatter.string(from: collected)).")
        }

        if let dur = duration {
            parts.append("Total duration: \(dur).")
        }

        if let note = cleanNote {
            parts.append("Note: \(note).")
        }

        return parts.joined(separator: " ")
    }
}

public extension ParkingInfoCard where TrailingContent == EmptyView {
    init(
        title: String,
        parkedAt: Date,
        collectedAt: Date? = nil,
        floor: String? = nil,
        bay: String? = nil,
        note: String? = nil,
        duration: String? = nil
    ) {
        self.init(
            title: title,
            parkedAt: parkedAt,
            collectedAt: collectedAt,
            floor: floor,
            bay: bay,
            note: note,
            duration: duration,
            trailingContent: { EmptyView() }
        )
    }

    init(session: ParkingSession) {
        self.init(
            title: session.displayTitle,
            parkedAt: session.sessionParkedAt,
            collectedAt: session.collectedAt,
            floor: session.displayFloor,
            bay: session.displayBay,
            note: session.displayNote,
            duration: session.formattedDuration,
            trailingContent: { EmptyView() }
        )
    }
}
