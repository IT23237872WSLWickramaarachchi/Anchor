//
//  ParkingAnnotationView.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI

public struct ParkingAnnotationView: View {
    public var title: String?

    public init(title: String? = nil) {
        self.title = title
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let title = title, !title.isEmpty {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                    .padding(.bottom, 4)
            }

            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 5, x: 0, y: 2)

                Circle()
                    .strokeBorder(Color.white, lineWidth: 2.5)
                    .frame(width: 44, height: 44)

                Image(systemName: "car.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }

            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.accentColor)
                .frame(width: 12, height: 10)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title != nil ? "Parked car at \(title!)" : "Parked car location")
    }
}

#Preview {
    ParkingAnnotationView(title: "Level 2 • Bay 4B")
        .padding()
}
