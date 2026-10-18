//
//  AnchorUITests.swift
//  AnchorUITests
//
//  Created by IM Student on 2026-10-17.
//

import XCTest

final class AnchorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchAndEmptyStateNavigation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()

        // 1. Verify Current Parking screen empty state
        XCTAssertTrue(app.navigationBars["Anchor"].exists)
        XCTAssertTrue(app.staticTexts["Remember where you parked."].exists)
        XCTAssertTrue(app.staticTexts["Save your spot and find your way back."].exists)
        let saveButton = app.buttons["parking_save_button"]
        XCTAssertTrue(saveButton.exists)

        // 2. Open Save Parking sheet
        saveButton.tap()
        XCTAssertTrue(app.navigationBars["Save Parking"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["save_current_location_button"].exists)
        XCTAssertTrue(app.textFields["save_title_field"].exists)
        XCTAssertTrue(app.textFields["save_floor_field"].exists)
        XCTAssertTrue(app.textFields["save_bay_field"].exists)

        // Verify Save is disabled initially (no coordinate selected)
        let submitButton = app.buttons["save_submit_button"]
        XCTAssertFalse(submitButton.isEnabled)

        // Cancel and return
        let cancelButton = app.buttons["save_cancel_button"]
        cancelButton.tap()
        XCTAssertTrue(app.navigationBars["Anchor"].waitForExistence(timeout: 3))

        // 3. Switch to History Tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["No parking history yet."].exists)
        XCTAssertTrue(app.staticTexts["Completed parking sessions will appear here."].exists)

        // Return to Parking tab
        let parkingTab = app.tabBars.buttons["Parking"]
        parkingTab.tap()
        XCTAssertTrue(app.navigationBars["Anchor"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCompleteParkingLifecycleWorkflow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()

        // Step 1: Start from clean empty state
        let saveCTA = app.buttons["parking_save_button"]
        XCTAssertTrue(saveCTA.waitForExistence(timeout: 3))
        saveCTA.tap()

        // Step 2: Supply deterministic test location via TestLocationService fixture
        let locationButton = app.buttons["save_current_location_button"]
        XCTAssertTrue(locationButton.waitForExistence(timeout: 3))
        locationButton.tap()

        // Step 3: Enter Spot Details
        let titleField = app.textFields["save_title_field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("University Garage")

        let floorField = app.textFields["save_floor_field"]
        floorField.tap()
        floorField.typeText("3")

        let bayField = app.textFields["save_bay_field"]
        bayField.tap()
        bayField.typeText("42B")

        let noteField = app.textFields["save_note_field"]
        noteField.tap()
        noteField.typeText("Near north elevator")

        // Step 4: Save and verify active screen
        let submitButton = app.buttons["save_submit_button"]
        XCTAssertTrue(submitButton.isEnabled)
        submitButton.tap()

        // Active screen verification
        XCTAssertTrue(app.staticTexts["University Garage"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["3"].exists)
        XCTAssertTrue(app.staticTexts["42B"].exists)
        XCTAssertTrue(app.staticTexts["Near north elevator"].exists)
        XCTAssertTrue(app.buttons["parking_walk_button"].exists)

        // Step 5: Edit parking note
        let editButton = app.buttons["parking_edit_button"]
        XCTAssertTrue(editButton.exists)
        editButton.tap()

        XCTAssertTrue(app.navigationBars["Edit Parking"].waitForExistence(timeout: 3))
        let editNoteField = app.textFields["save_note_field"]
        XCTAssertTrue(editNoteField.waitForExistence(timeout: 2))
        editNoteField.tap()
        editNoteField.typeText(" - Section C")

        let saveEditButton = app.buttons["save_submit_button"]
        saveEditButton.tap()

        // Verify edited note on active screen
        let activeUpdatedNote = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Section C'")).firstMatch
        XCTAssertTrue(activeUpdatedNote.waitForExistence(timeout: 5))

        // Step 6: Mark car as collected
        let collectedButton = app.buttons["parking_collected_button"]
        XCTAssertTrue(collectedButton.exists)
        collectedButton.tap()

        // Confirm collection dialog
        let confirmCollected = app.buttons["Mark as Collected"]
        XCTAssertTrue(confirmCollected.waitForExistence(timeout: 2))
        confirmCollected.tap()

        // Empty state is restored immediately
        XCTAssertTrue(app.staticTexts["Remember where you parked."].waitForExistence(timeout: 3))

        // Step 7: Open History tab and verify completed entry
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3))
        let historyRowTitle = app.staticTexts["University Garage"]
        XCTAssertTrue(historyRowTitle.waitForExistence(timeout: 3))

        // Inspect historical details
        historyRowTitle.tap()
        XCTAssertTrue(app.navigationBars["Parking Record"].waitForExistence(timeout: 3))
        let detailUpdatedNote = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Section C'")).firstMatch
        XCTAssertTrue(detailUpdatedNote.exists)
    }
}
