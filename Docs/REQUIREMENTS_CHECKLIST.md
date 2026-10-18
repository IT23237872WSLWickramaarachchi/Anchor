# Anchor — Assignment Requirements Compliance Matrix

**Course**: Mobile Application Development  
**Part A**: Individual iOS Application (Anchor)  
**Part B**: visionOS / tvOS Exploration (*Out of Scope — Managed as separate assignment submission*)  
**Status**: Ready for Viva Examination & Grading  

---

## Part A Requirements Mapping

| # | Assignment Requirement | Implementation Location | Evidence & Verification | Status |
|:---:|:---|:---|:---|:---:|
| **1** | **Meaningful Framework Integration** | `Services/LocationService.swift`<br>`Services/DirectionsService.swift` | Integrated **MapKit** (interactive maps, custom annotations, walking directions handoff) and **Core Location** (one-shot GPS positioning). | **COMPLETE** |
| **2** | **At Least Three Navigable Screens** | `Views/CurrentParkingView.swift`<br>`Views/SaveParkingView.swift`<br>`Views/HistoryView.swift`<br>`Views/HistoricalDetailsView.swift` | 4 distinct screens: (1) Empty / Active Parking, (2) Save & Edit Form Sheet, (3) Parking History List, (4) Historical Session Details. | **COMPLETE** |
| **3** | **Persistent Storage (Core Data)** | `Persistence/PersistenceController.swift`<br>`Models/ParkingSession.swift`<br>`Services/ParkingService.swift` | Full Core Data stack with `ParkingSession` entity, SQLite persistence, and in-memory test configuration. Single-active-session invariant enforced. | **COMPLETE** |
| **4** | **Custom SwiftUI UI Components** | `Components/ParkingInfoCard.swift`<br>`Components/PrimaryActionButtonStyle.swift`<br>`Components/DetailBadge.swift` | Custom `ParkingInfoCard` genuinely reused across active & history screens; `PrimaryActionButtonStyle` provides >= 48pt touch targets and animation. | **COMPLETE** |
| **5** | **Accessibility & Dynamic Type** | `Components/ParkingInfoCard.swift`<br>`Views/HistoryView.swift`<br>`Assets.xcassets/AccentColor.colorset` | Full Dynamic Type scaling (adaptive vertical stacking for accessibility sizes); VoiceOver descriptions; Reduce Motion respect; Light/Dark teal contrast. | **COMPLETE** |
| **6** | **Automated Unit & Integration Tests** | `AnchorTests/AnchorTests.swift` | 13 automated tests covering session creation, invariant enforcement, editing persistence, collection, sorting, duration calculation, and disk SQLite survival. | **COMPLETE** |
| **7** | **Documentation** | `README.md`<br>`Docs/*.md` | Complete documentation suite: User Guide, Technical Report, Test Results, Demo Script, AI Disclosure, and Requirements Matrix. | **COMPLETE** |
| **8** | **Live Demonstration Preparedness** | `Docs/DEMO_SCRIPT.md` | Structured 2–3 minute demonstration script with simulator location setup, screen transitions, and technical defense prompts. | **COMPLETE** |
| **9** | **User Acceptance Testing (Real Persons)** | `Docs/TECHNICAL_REPORT.md` | Testing checklist prepared; real-world user feedback section flagged for personal student completion before final grading. | **PENDING STUDENT EVALUATION** |
| **10**| **Part B (visionOS / tvOS)** | External to this repository | Explicitly separated per assignment instructions; Part B is an independent project. | **OUT OF SCOPE (PART B)** |

---

## Component Reuse Verification

To ensure requirements are genuinely fulfilled rather than nominally present:
- **`ParkingInfoCard`**:
  - Reused in [CurrentParkingView.swift](file:///Users/imstudent/Documents/IT23237872/Anchor/Anchor/Anchor/Views/CurrentParkingView.swift#L170) with a live `ElapsedTimerView` in the trailing slot.
  - Reused in [HistoricalDetailsView.swift](file:///Users/imstudent/Documents/IT23237872/Anchor/Anchor/Anchor/Views/HistoricalDetailsView.swift#L45) with total duration formatting in the trailing slot.
- **`PrimaryActionButtonStyle`**:
  - Reused for the empty-state CTA in [CurrentParkingView.swift](file:///Users/imstudent/Documents/IT23237872/Anchor/Anchor/Anchor/Views/CurrentParkingView.swift#L130).
  - Reused for the primary "Walk to car" navigation action in [CurrentParkingView.swift](file:///Users/imstudent/Documents/IT23237872/Anchor/Anchor/Anchor/Views/CurrentParkingView.swift#L187).
