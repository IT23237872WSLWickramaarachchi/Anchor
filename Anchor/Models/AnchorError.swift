//
//  AnchorError.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import Foundation

public enum AnchorError: LocalizedError, Equatable {
    case noCoordinateSelected
    case invalidCoordinates(latitude: Double, longitude: Double)
    case activeSessionAlreadyExists
    case activeSessionNotFound
    case sessionAlreadyCollected
    case cannotDeleteActiveSession
    case persistenceSaveFailed(String)
    case persistenceFetchFailed(String)
    case locationServicesDisabled
    case locationPermissionDenied
    case locationRequestTimedOut
    case locationUnavailable(String)
    case directionsHandoffFailed

    public var errorDescription: String? {
        switch self {
        case .noCoordinateSelected:
            return "Please choose a parking spot on the map."
        case let .invalidCoordinates(lat, lon):
            return "The selected location (\(lat), \(lon)) is outside valid geographic coordinates."
        case .activeSessionAlreadyExists:
            return "You already have an active parking session. Please collect your current car before saving a new one."
        case .activeSessionNotFound:
            return "No active parking session was found."
        case .sessionAlreadyCollected:
            return "This parking session has already been marked as collected."
        case .cannotDeleteActiveSession:
            return "Active parking sessions cannot be removed from history until collected."
        case let .persistenceSaveFailed(reason):
            return "Unable to save parking data: \(reason)"
        case let .persistenceFetchFailed(reason):
            return "Unable to load parking data: \(reason)"
        case .locationServicesDisabled:
            return "Location services are turned off on your device. You can still tap the map to choose your spot."
        case .locationPermissionDenied:
            return "Location access is denied. You can select your spot manually on the map or enable location in Settings."
        case .locationRequestTimedOut:
            return "Locating your position timed out. Please tap the map directly to choose your parking spot."
        case let .locationUnavailable(reason):
            return "Unable to retrieve your location: \(reason). You can still tap the map manually."
        case .directionsHandoffFailed:
            return "Unable to open walking directions in Apple Maps."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .noCoordinateSelected:
            return "Tap on the map or tap 'Use current location' to place your parking pin."
        case .locationPermissionDenied:
            return "Tap 'Open Settings' to grant location permission, or tap anywhere on the map to set your pin."
        case .activeSessionAlreadyExists:
            return "Return to the Parking tab and mark your current car as collected."
        default:
            return nil
        }
    }
}
