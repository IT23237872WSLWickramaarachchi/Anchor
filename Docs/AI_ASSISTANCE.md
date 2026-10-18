# Anchor — AI Assistance & Academic Integrity Disclosure

**Project**: Anchor (iOS Parking Reminder Utility)  
**Student ID**: IT23237872  
**Purpose**: Transparently disclose AI-assisted pair-programming contributions, prompts provided, tools utilized, and code areas requiring student personal review and viva defense.

---

## 1. Summary of Prompts & Work Performed

### Interaction History:
- **Phase 1: Initial Implementation**:
  - Implemented Core Data schema (`ParkingSession`) with single-active-session invariant.
  - Implemented MapKit integration and one-shot Core Location request.
  - Built MVVM layer (`CurrentParkingViewModel`, `SaveParkingViewModel`, `HistoryViewModel`).
  - Added unit test suite with in-memory persistence.
- **Phase 2: Visual Polish, Design System, & Branding**:
  - Defined teal accent in asset catalog (`AccentColor.colorset`) with dual-mode light/dark support.
  - Implemented custom reusable SwiftUI component `ParkingInfoCard` and custom button styles `PrimaryActionButtonStyle` / `SecondaryActionButtonStyle`.
  - Added original 1024x1024 `AppIcon.png` in `AppIcon.appiconset`.
  - Enhanced accessibility: Dynamic Type support, VoiceOver labels, and Reduce Motion handling.
- **Phase 3: Verification & Assignment Readiness**:
  - Added isolated SQLite disk persistence integration test.
  - Verified 13 unit/persistence tests in `AnchorTests`.
  - Fixed SwiftUI sheet `@StateObject` lifecycle bug using `.sheet(item: $viewModel.activeSheetItem)`.
  - Authored complete project documentation (`README.md`, `USER_GUIDE.md`, `TECHNICAL_REPORT.md`, `TEST_RESULTS.md`, `DEMO_SCRIPT.md`, `REQUIREMENTS_CHECKLIST.md`).

---

## 2. Breakdown of AI vs. Student Responsibility

| Component | AI Assistance Role | Student Responsibility (Must Personally Review) |
|:---|:---|:---|
| **Core Data Schema** | Generated entity definition and NSManagedObject subclass. | Verify attributes match assignment brief; explain manual code generation in viva. |
| **Location & Maps** | Structured one-shot `CLLocationManager` wrapper and `MKMapItem` handoff. | Understand `NSLocationWhenInUseUsageDescription` privacy policy and test on physical device. |
| **Design System** | Implemented `ParkingInfoCard` and `PrimaryActionButtonStyle`. | Review visual aesthetics, padding tokens, and contrast ratios in Xcode Previews. |
| **Persistence Tests** | Wrote automated test methods and temporary disk file test. | Execute `xcodebuild test` independently and understand assertions. |
| **Viva Defense** | Prepared talking points and architecture diagram. | Present live demonstration and answer examiner questions in your own words. |

---

## 3. Official Apple Documentation References

The implementation adheres to Apple's official documentation and design guidance:

1. **MapKit**:
   - [`MKMapItem.openInMaps(launchOptions:)`](https://developer.apple.com/documentation/mapkit/mkmapitem/1452299-openinmaps) — Launching Apple Maps with pedestrian walking directions.
   - [`MapReader`](https://developer.apple.com/documentation/mapkit/mapreader) — Translating screen touch points to geographic coordinates.
2. **Core Location**:
   - [`CLLocationManager.requestLocation()`](https://developer.apple.com/documentation/corelocation/cllocationmanager/1620548-requestlocation) — Requesting one-time location updates.
   - [`CLLocationManager.requestWhenInUseAuthorization()`](https://developer.apple.com/documentation/corelocation/cllocationmanager/1620562-requestwheninuseauthorization) — Requesting foreground location permissions.
3. **SwiftUI**:
   - [`EnvironmentValues.accessibilityReduceMotion`](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion) — Querying user motion preference.
   - [`DynamicTypeSize`](https://developer.apple.com/documentation/swiftui/dynamictypesize) — Adapting layout geometry for accessibility font scales.
4. **Core Data**:
   - [`NSPersistentContainer`](https://developer.apple.com/documentation/coredata/nspersistentcontainer) — Managing Core Data stack and store descriptions.
   - [`NSMergeByPropertyObjectTrumpMergePolicy`](https://developer.apple.com/documentation/coredata/nsmergebypropertyobjecttrumpmergepolicy) — Conflict resolution policy.
