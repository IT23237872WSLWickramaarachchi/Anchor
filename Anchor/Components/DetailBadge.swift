//
//  DetailBadge.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI

public struct DetailBadge: View {
    public let icon: String
    public let label: String
    public let value: String

    public init(icon: String, label: String, value: String) {
        self.icon = icon
        self.label = label
        self.value = value
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(label.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    HStack {
        DetailBadge(icon: "stairs", label: "Floor", value: "3")
        DetailBadge(icon: "parkingsign", label: "Bay", value: "B12")
    }
    .padding()
}
