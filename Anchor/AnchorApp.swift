//
//  AnchorApp.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI

@main
struct AnchorApp: App {
    private let persistenceController: PersistenceController
    private let parkingService: ParkingServiceProtocol

    init() {
        #if DEBUG
        if CommandLine.arguments.contains("-UITesting") {
            let controller = PersistenceController.inMemory()
            self.persistenceController = controller
            self.parkingService = ParkingService(persistenceController: controller)
            return
        }
        #endif
        let controller = PersistenceController.shared
        self.persistenceController = controller
        self.parkingService = ParkingService(persistenceController: controller)
    }

    var body: some Scene {
        WindowGroup {
            AnchorTabView(parkingService: parkingService)
        }
    }
}
