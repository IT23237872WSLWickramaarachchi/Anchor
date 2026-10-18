# Anchor — iOS Parking Reminder

Anchor is a focused, native iPhone utility designed to help university students and everyday drivers remember where they parked, navigate back to their car using Apple Maps walking directions, and maintain a lightweight history of completed parking sessions.

---

## Target Audience & Problem Statement
Finding your car in expansive university campus parking lots, airport long-term facilities, shopping mall garages, or crowded downtown multi-level parking structures is a frequent, stressful friction point. Standard outdoor GPS provides geographic coordinates to the building or lot entrance, but cannot identify the floor, pillar, or bay number. 

Anchor solves this by pairing MapKit geographic positioning with prominent indoor metadata (Floor, Bay, and Landmark Notes).

---

## Screen List & Implemented Features

1. **Current Parking Screen** (`CurrentParkingView`):
   - **Empty State**: Minimalist layout with parking symbol motif, clear guidance, and a prominent "Save parking" primary button.
   - **Active State**: Interactive `MapKit` map connected directly with a custom `ParkingInfoCard` displaying garage title, parking timestamp, live `ElapsedTimerView`, prominent floor/bay badges, and notes.
   - **Actions**:
     - *Primary*: "Walk to car" (hands off coordinate directly to Apple Maps walking directions via `MKMapItem`).
     - *Secondary*: "Edit parking" (updates existing active record).
     - *Separated*: "Collected car" (triggers a confirmation dialog, completes the session, and archives it to History).

2. **Save / Edit Screen** (`SaveParkingView`):
   - **Location Selection Section**: Map preview with pin annotation, "Use current location" button with activity spinner, tap-to-pin manual selection, and in-line permission/location guidance.
   - **Spot Details Section**: Explicit labels for Title (e.g. "Campus West Garage"), Floor (e.g. "Level 3"), and Bay (e.g. "Bay 42B").
   - **Parking Notes Section**: Multi-line text field for landmarks, pillar identifiers, or nearby elevator doors.

3. **Parking History Screen** (`HistoryView`):
   - Chronological list of completed sessions ordered newest first.
   - Clean rows displaying title, floor/bay summary, parking date/time, and formatted duration badge (e.g. "1h 24m").
   - Swipe-to-delete with native confirmation dialog.

4. **Historical Details Screen** (`HistoricalDetailsView`):
   - Read-only MapKit preview of the historical parking spot.
   - Reuses `ParkingInfoCard` to display complete session metrics: title, floor, bay, parked date/time, collected date/time, total duration, and saved notes.

---

## Technical Requirements & Environment

- **IDE**: Xcode 26.1 (Build 17B100)
- **SDK**: iOS 26.1 Simulator & Device SDK
- **Deployment Target**: iOS 26.1
- **Architectures**: Apple Silicon (`arm64`)
- **Frameworks**: SwiftUI, MapKit, CoreLocation, CoreData (no third-party dependencies)

---

## Build & Run Instructions

### Via Xcode:
1. Open `Anchor/Anchor.xcodeproj` in Xcode.
2. Select the `Anchor` scheme.
3. Select an iOS Simulator (e.g. **iPhone 17**).
4. Press **Cmd + R** to build and run.

### Via Command Line:
```bash
cd /Users/imstudent/Documents/IT23237872/Anchor/Anchor
xcodebuild -project Anchor.xcodeproj -scheme Anchor -destination "platform=iOS Simulator,name=iPhone 17" build
```

---

## Location Permission Setup
Anchor requests "When In Use" authorization only (`NSLocationWhenInUseUsageDescription`), configured in `project.pbxproj`:
> *"Anchor uses your location to pinpoint your parked car and provide walking directions back to your spot."*

### Testing Location in Simulator:
- **Simulator Menu**: In the Simulator menu bar, navigate to **Features > Location** and select **Apple** or **Custom Location** (e.g. Lat: 37.7749, Lon: -122.4194).
- **Manual Pin Selection**: If location permissions are denied, disabled, or unavailable, you can tap anywhere directly on the interactive map to place your parking pin manually.

---

## Automated Tests

Run the full automated test suite via the command line:
```bash
cd /Users/imstudent/Documents/IT23237872/Anchor/Anchor
xcodebuild test -project Anchor.xcodeproj -scheme Anchor -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:AnchorTests
```

### Test Coverage Summary:
- **Unit & Business Logic**: 13 automated tests verifying Core Data single-active-session invariant, coordinate bounds, duration formatting, title trimming, newest-first history sorting, and disk persistence survival.

---

## Known Limitations

1. **Indoor Floor Positioning**: GPS cannot resolve altitude or indoor floor levels inside concrete multi-level parking garages. Users must enter floor and bay notes manually.
2. **Turn-by-Turn Navigation**: Anchor delegates active walking navigation to Apple Maps via standard system URL schemes (`MKMapItem.openInMaps(launchOptions:)`) rather than re-implementing an in-app turn-by-turn routing engine.
