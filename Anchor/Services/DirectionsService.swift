//
//  DirectionsService.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import Foundation
import MapKit

public protocol DirectionsServiceProtocol: Sendable {
    @MainActor
    func openWalkingDirections(to coordinate: CLLocationCoordinate2D, name: String) -> Bool
}

public final class DirectionsService: DirectionsServiceProtocol, @unchecked Sendable {
    public nonisolated init() {}

    @MainActor
    public func openWalkingDirections(to coordinate: CLLocationCoordinate2D, name: String) -> Bool {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Parked car" : name

        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ]

        return mapItem.openInMaps(launchOptions: launchOptions)
    }
}

#if DEBUG
public final class TestDirectionsService: DirectionsServiceProtocol, @unchecked Sendable {
    public var lastOpenedCoordinate: CLLocationCoordinate2D?
    public var lastOpenedName: String?
    public nonisolated init() {}

    @MainActor
    public func openWalkingDirections(to coordinate: CLLocationCoordinate2D, name: String) -> Bool {
        self.lastOpenedCoordinate = coordinate
        self.lastOpenedName = name
        return true
    }
}
#endif
