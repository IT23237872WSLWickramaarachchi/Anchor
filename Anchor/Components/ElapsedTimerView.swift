//
//  ElapsedTimerView.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI

public struct ElapsedTimerView: View {
    public let parkedAt: Date

    public init(parkedAt: Date) {
        self.parkedAt = parkedAt
    }

    public var body: some View {
        TimelineView(.periodic(from: parkedAt, by: 60)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(parkedAt))
            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text(formattedElapsed(seconds: elapsed))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Elapsed parking time: \(formattedElapsed(seconds: elapsed))")
        }
    }

    private func formattedElapsed(seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        if totalMinutes < 1 {
            return "Just parked"
        } else if totalMinutes < 60 {
            return "Parked \(totalMinutes)m ago"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "Parked \(hours)h ago"
            } else {
                return "Parked \(hours)h \(minutes)m ago"
            }
        }
    }
}

#Preview {
    ElapsedTimerView(parkedAt: Date().addingTimeInterval(-3700))
        .padding()
}
