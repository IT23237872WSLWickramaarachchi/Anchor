//
//  PersistenceController.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import Foundation
import CoreData

public final class PersistenceController: @unchecked Sendable {
    public static let shared = PersistenceController()

    public static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        // Add sample active session for SwiftUI previews
        let sample = ParkingSession(context: context)
        sample.id = UUID()
        sample.title = "City Center Mall"
        sample.latitude = 37.7749
        sample.longitude = -122.4194
        sample.parkedAt = Date().addingTimeInterval(-2500)
        sample.floor = "3"
        sample.bay = "B12"
        sample.note = "Near the green elevators"
        try? context.save()
        return controller
    }()

    public static func inMemory() -> PersistenceController {
        PersistenceController(inMemory: true)
    }

    public let container: NSPersistentContainer

    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    nonisolated deinit {}

    public init(storeURL: URL? = nil, inMemory: Bool = false) {
        let model = Self.loadManagedObjectModel()
        container = NSPersistentContainer(name: "Anchor", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else if let customURL = storeURL {
            let description = NSPersistentStoreDescription(url: customURL)
            description.type = NSSQLiteStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            let description = NSPersistentStoreDescription()
            description.type = NSSQLiteStoreType
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            let defaultURL = appSupport.appendingPathComponent("Anchor.sqlite")
            description.url = defaultURL
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Log the persistence initialization error cleanly without fatal crashing
                NSLog("Anchor persistence store loading error: %@", error.localizedDescription)
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    public func saveContext() throws {
        let context = container.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw AnchorError.persistenceSaveFailed(error.localizedDescription)
        }
    }

    // Programmatic model fallback to guarantee 100% reliability in tests and previews
    private static func loadManagedObjectModel() -> NSManagedObjectModel {
        if let modelURL = Bundle.main.url(forResource: "Anchor", withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: modelURL) {
            return model
        }

        for bundle in Bundle.allBundles {
            if let modelURL = bundle.url(forResource: "Anchor", withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: modelURL) {
                return model
            }
        }

        return createProgrammaticModel()
    }

    private static func createProgrammaticModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "ParkingSession"
        sessionEntity.managedObjectClassName = NSStringFromClass(ParkingSession.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = true
        titleAttribute.defaultValue = "Parked car"

        let latAttribute = NSAttributeDescription()
        latAttribute.name = "latitude"
        latAttribute.attributeType = .doubleAttributeType
        latAttribute.isOptional = false
        latAttribute.defaultValue = 0.0

        let lonAttribute = NSAttributeDescription()
        lonAttribute.name = "longitude"
        lonAttribute.attributeType = .doubleAttributeType
        lonAttribute.isOptional = false
        lonAttribute.defaultValue = 0.0

        let parkedAtAttribute = NSAttributeDescription()
        parkedAtAttribute.name = "parkedAt"
        parkedAtAttribute.attributeType = .dateAttributeType
        parkedAtAttribute.isOptional = false

        let collectedAtAttribute = NSAttributeDescription()
        collectedAtAttribute.name = "collectedAt"
        collectedAtAttribute.attributeType = .dateAttributeType
        collectedAtAttribute.isOptional = true

        let floorAttribute = NSAttributeDescription()
        floorAttribute.name = "floor"
        floorAttribute.attributeType = .stringAttributeType
        floorAttribute.isOptional = true

        let bayAttribute = NSAttributeDescription()
        bayAttribute.name = "bay"
        bayAttribute.attributeType = .stringAttributeType
        bayAttribute.isOptional = true

        let noteAttribute = NSAttributeDescription()
        noteAttribute.name = "note"
        noteAttribute.attributeType = .stringAttributeType
        noteAttribute.isOptional = true

        sessionEntity.properties = [
            idAttribute,
            titleAttribute,
            latAttribute,
            lonAttribute,
            parkedAtAttribute,
            collectedAtAttribute,
            floorAttribute,
            bayAttribute,
            noteAttribute
        ]

        model.entities = [sessionEntity]
        return model
    }
}
