//
//  PrimaryActionButtonStyle.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI

/// Reusable primary button style conforming to Anchor's design system.
/// Features a min height of at least 48 points (exceeding the 44pt touch target requirement),
/// teal accent background, high-contrast white text, continuous rounded corners,
/// and subtle press animation that respects the user's Reduce Motion accessibility preference.
public struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    private let minHeight: CGFloat

    public init(minHeight: CGFloat = 48) {
        self.minHeight = minHeight
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isEnabled ? Color.accentColor : Color.secondary.opacity(0.4))
            )
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Reusable secondary button style for secondary actions like editing parking details.
public struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    private let minHeight: CGFloat

    public init(minHeight: CGFloat = 44) {
        self.minHeight = minHeight
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemGroupedBackground))
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

public extension ButtonStyle where Self == PrimaryActionButtonStyle {
    static var primaryAction: PrimaryActionButtonStyle {
        PrimaryActionButtonStyle()
    }

    static func primaryAction(minHeight: CGFloat) -> PrimaryActionButtonStyle {
        PrimaryActionButtonStyle(minHeight: minHeight)
    }
}

public extension ButtonStyle where Self == SecondaryActionButtonStyle {
    static var secondaryAction: SecondaryActionButtonStyle {
        SecondaryActionButtonStyle()
    }
}
