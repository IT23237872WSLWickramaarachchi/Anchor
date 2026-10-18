//
//  LocationService.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import Foundation
import CoreLocation

public protocol LocationServiceProtocol: AnyObject, Sendable {
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestOneShotLocation() async throws -> CLLocationCoordinate2D
}

public final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager: CLLocationManager
    private let lock = NSLock()
    private var activeContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var isAwaitingAuthorization = false

    public init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    public var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    public func requestOneShotLocation() async throws -> CLLocationCoordinate2D {
        guard CLLocationManager.locationServicesEnabled() else {
            throw AnchorError.locationServicesDisabled
        }

        let status = manager.authorizationStatus
        switch status {
        case .restricted, .denied:
            throw AnchorError.locationPermissionDenied
        case .notDetermined:
            return try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                if activeContinuation != nil {
                    lock.unlock()
                    continuation.resume(throwing: AnchorError.locationUnavailable("A location request is already in progress."))
                    return
                }
                activeContinuation = continuation
                isAwaitingAuthorization = true
                lock.unlock()

                // Request When In Use authorization only
                DispatchQueue.main.async { [weak self] in
                    self?.manager.requestWhenInUseAuthorization()
                }

                setupTimeoutTask()
            }
        case .authorizedWhenInUse, .authorizedAlways:
            return try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                if activeContinuation != nil {
                    lock.unlock()
                    continuation.resume(throwing: AnchorError.locationUnavailable("A location request is already in progress."))
                    return
                }
                activeContinuation = continuation
                isAwaitingAuthorization = false
                lock.unlock()

                DispatchQueue.main.async { [weak self] in
                    self?.manager.requestLocation()
                }

                setupTimeoutTask()
            }
        @unknown default:
            throw AnchorError.locationUnavailable("Unknown location authorization state.")
        }
    }

    private func setupTimeoutTask() {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 12 * 1_000_000_000) // 12 seconds timeout
            self?.handleTimeout()
        }
    }

    private func handleTimeout() {
        lock.lock()
        guard let continuation = activeContinuation else {
            lock.unlock()
            return
        }
        activeContinuation = nil
        isAwaitingAuthorization = false
        lock.unlock()

        continuation.resume(throwing: AnchorError.locationRequestTimedOut)
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        lock.lock()
        guard isAwaitingAuthorization, let _ = activeContinuation else {
            lock.unlock()
            return
        }

        let status = manager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            isAwaitingAuthorization = false
            lock.unlock()
            DispatchQueue.main.async { [weak self] in
                self?.manager.requestLocation()
            }
        case .denied, .restricted:
            isAwaitingAuthorization = false
            let cont = activeContinuation
            activeContinuation = nil
            lock.unlock()
            cont?.resume(throwing: AnchorError.locationPermissionDenied)
        case .notDetermined:
            lock.unlock()
        @unknown default:
            isAwaitingAuthorization = false
            let cont = activeContinuation
            activeContinuation = nil
            lock.unlock()
            cont?.resume(throwing: AnchorError.locationUnavailable("Unexpected authorization response."))
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lock.lock()
        guard let continuation = activeContinuation else {
            lock.unlock()
            return
        }

        // Find a recent location with valid horizontal accuracy
        let validLocation = locations.reversed().first { location in
            location.horizontalAccuracy >= 0 &&
            abs(location.timestamp.timeIntervalSinceNow) < 60.0
        }

        if let valid = validLocation {
            activeContinuation = nil
            isAwaitingAuthorization = false
            lock.unlock()
            continuation.resume(returning: valid.coordinate)
        } else {
            // Keep waiting or if this was the terminal update with invalid data:
            if let last = locations.last, last.horizontalAccuracy >= 0 {
                activeContinuation = nil
                isAwaitingAuthorization = false
                lock.unlock()
                continuation.resume(returning: last.coordinate)
            } else {
                lock.unlock()
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lock.lock()
        guard let continuation = activeContinuation else {
            lock.unlock()
            return
        }

        if let clError = error as? CLError {
            if clError.code == .locationUnknown {
                // Temporary inability, CLLocationManager continues or will time out
                lock.unlock()
                return
            } else if clError.code == .denied {
                activeContinuation = nil
                isAwaitingAuthorization = false
                lock.unlock()
                continuation.resume(throwing: AnchorError.locationPermissionDenied)
                return
            }
        }

        activeContinuation = nil
        isAwaitingAuthorization = false
        lock.unlock()
        continuation.resume(throwing: AnchorError.locationUnavailable(error.localizedDescription))
    }
}

#if DEBUG
public final class TestLocationService: LocationServiceProtocol, @unchecked Sendable {
    public var authorizationStatus: CLAuthorizationStatus { .authorizedWhenInUse }
    private let coordinate: CLLocationCoordinate2D

    public init(coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)) {
        self.coordinate = coordinate
    }

    public func requestOneShotLocation() async throws -> CLLocationCoordinate2D {
        return coordinate
    }
}
#endif
