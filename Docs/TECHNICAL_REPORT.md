# Anchor — Technical Architecture & Implementation Report

**Course**: Mobile Application Development (iOS Assignment — Part A)  
**Author**: Student (IT23237872)  
**Target Platform**: iOS 26.1 / Xcode 26.1 / Swift 5  

---

## 1. Problem Definition & Intended Audience

Finding a parked vehicle in large university campuses, airport lots, or multi-level garages is a common frustration. Commercial navigation tools reliably guide users to a street address or parking facility entrance, but fail once inside a multi-level structure because GPS cannot determine floor level or stall number.

**Anchor** bridges this gap as a lightweight, focused iOS utility. It captures geographic coordinates via MapKit and Core Location while prioritizing structured interior metadata (Floor, Bay, Landmark Note), providing a frictionless round-trip: Save Spot $\to$ Walk to Car $\to$ Mark Collected $\to$ Review History.

---

## 2. Architecture & Data Model

Anchor follows the **MVVM (Model-View-ViewModel)** architectural pattern with protocol-oriented service abstractions to achieve testability and separation of concerns.

```
       ┌────────────────────────┐
       │      SwiftUI View      │
       └───────────┬────────────┘
                   │ Observes (@ObservedObject / @StateObject)
                   ▼
       ┌────────────────────────┐
       │       ViewModel        │
       └───────────┬────────────┘
                   │ Injects Protocols
                   ▼
┌──────────────────┴──────────────────┐
│              Services               │
├──────────────────┬──────────────────┤
│ ParkingService   │ LocationService  │
│ DirectionsService│                  │
└────────┬─────────┴──────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Core Data (NSPersistentContainer)   │
│ Entity: ParkingSession              │
└─────────────────────────────────────┘
```

### Core Data Schema: `ParkingSession`

| Attribute | Type | Optional | Default | Description |
|:---|:---|:---:|:---:|:---|
| `id` | UUID | No | — | Unique session identifier |
| `title` | String | Yes | "Parked car" | Human-readable garage or spot label |
| `latitude` | Double | No | 0.0 | Latitude coordinate in WGS 84 |
| `longitude`| Double | No | 0.0 | Longitude coordinate in WGS 84 |
| `parkedAt` | Date | No | Current Date | Timestamp when spot was saved |
| `collectedAt`| Date | Yes | nil | Timestamp when car was retrieved |
| `floor` | String | Yes | nil | Indoor garage level (e.g. "Level 3") |
| `bay` | String | Yes | nil | Stall or bay code (e.g. "42B") |
| `note` | String | Yes | nil | Landmarks or notes |

### The Single-Active-Session Invariant
A user only drives and parks one car at a time in this domain. An active session is defined strictly as `collectedAt == nil`. 
- `ParkingService.createActiveSession(...)` executes an explicit `NSFetchRequest` with `NSPredicate(format: "collectedAt == nil")`.
- If an active session exists, the method rejects creation with `AnchorError.activeSessionAlreadyExists`.
- Editing an active session preserves both the existing `id` (UUID) and the original `parkedAt` timestamp.

---

## 3. Framework Integration: MapKit & Core Location

Anchor integrates Apple's native location frameworks with deliberate privacy and battery efficiency:

1. **Battery-Preserving One-Shot Core Location**:
   - Continuous background GPS tracking (`startUpdatingLocation`) is unnecessary and drains battery.
   - Anchor uses `CLLocationManager.requestLocation()` (one-shot accuracy to nearest 10 meters).
   - Only "When In Use" authorization is requested (`NSLocationWhenInUseUsageDescription`).
   - If GPS times out (12-second safety timeout) or access is denied, the user can tap directly on the map via `MapReader`.

2. **MapKit Integration & Directions Handoff**:
   - `MapReader` converts local screen taps (`CGPoint`) directly into geographic coordinates (`CLLocationCoordinate2D`).
   - Custom `ParkingAnnotationView` renders a high-contrast teal pin with floor and bay callouts.
   - "Walk to car" constructs an `MKMapItem` with the parked coordinate and launches Apple Maps via `openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])`.

---

## 4. Custom SwiftUI Design System

Anchor implements a custom, unified design system without relying on third-party libraries:

1. **`ParkingInfoCard`**:
   - Genuinely reused across `CurrentParkingView` (active session with live `ElapsedTimerView`) and `HistoricalDetailsView` (completed session with duration pill).
   - Employs dynamic geometry adapting from side-by-side to stacked layout when Dynamic Type accessibility sizes are enabled.
   - Implements semantic container accessibility (`children: .contain`).

2. **`PrimaryActionButtonStyle` & `SecondaryActionButtonStyle`**:
   - Guaranteed minimum touch targets $\ge 48\text{ pt}$ for primary actions and $\ge 44\text{ pt}$ for secondary actions.
   - Micro-press scaling that automatically disables when `@Environment(\.accessibilityReduceMotion)` is active.

3. **Dual-Mode Semantic Teal Accent**:
   - Light mode sRGB: `#008080` (Teal).
   - Dark mode sRGB: `#2DD4BF` (Mint-teal, higher luminance for dark mode contrast).

---

## 5. Accessibility Implementation

- **VoiceOver**: Logical reading order with combined and contained labels. Core parking information is 100% audible without requiring visual map interpretation.
- **Dynamic Type**: All fonts scale natively; layouts adapt dynamically to avoid clipping or fixed-height card compression.
- **Reduce Motion**: Subtle scale transitions check `accessibilityReduceMotion` and default to gentle opacity fades.
- **Touch Target Sizing**: All interactive controls conform to Apple HIG minimum dimensions ($44 \times 44\text{ pt}$).

---

## 6. Challenges Encountered & Solutions

1. **Core Data Thread Isolation & Actor Concurrency**:
   - *Problem*: In Swift 5 with strict actor isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`), deallocating the Core Data stack during XCTest teardown triggered `swift_task_deinitOnExecutorImpl` assertion failures.
   - *Fix*: Marked `deinit` as `nonisolated` on `PersistenceController` and `ParkingService`, and isolated test cases to `@MainActor`.

2. **SwiftUI Sheet State Object Re-use**:
   - *Problem*: Presenting a sheet with `@StateObject` inside a boolean `.sheet(isPresented:)` reused the previous view model when toggling between new and edit sessions.
   - *Fix*: Refactored to `.sheet(item: $viewModel.activeSheetItem)` using an identifiable wrapper, ensuring fresh view model initialization and clean dismissal every time.

3. **Dynamic Type Badge Truncation**:
   - *Problem*: At accessibility font sizes, horizontal badge bars squeezed text.
   - *Fix*: Added `dynamicTypeSize.isAccessibilitySize` conditional layout that transforms badge layouts into vertical stacks.

---

## 7. Automated Test Results

- **Unit & Persistence Tests**: 13/13 passed (0.12s execution time on iPhone 17 Simulator).
- **Disk Persistence Integration**: Verified using an isolated temporary SQLite file that persists data across complete stack tear-down and re-initialization.

---

## 8. Known Limitations

- **Indoor Altitude / Floor Detection**: Core Location cannot determine multi-level garage floors. Manual floor input remains necessary.
- **External Navigation**: Turn-by-turn walking routes are handled by delegating to Apple Maps rather than hosting an in-app routing engine.

---

> [!NOTE]
> ### 9. Personal Reflection & Viva Preparation (To Be Completed by Student)
> *The following section requires your personal notes and reflection for viva defense:*
> - **Personal Reflection on Design Decisions**: [Record your reasoning on why you prioritized a minimal 2-tab utility over complex features].
> - **Viva Discussion Point**: [Be prepared to explain how the single-active-session invariant is enforced in Core Data and why `NSMergeByPropertyObjectTrumpMergePolicy` was chosen].
> - **Peer / User Feedback Notes**: [Add notes from a classmate testing the app in the simulator].
