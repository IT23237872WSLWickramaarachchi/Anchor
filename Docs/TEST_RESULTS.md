# Anchor — Test Results & Verification Log

**Date of Execution**: October 17, 2026  
**Environment**: macOS 26.1, Xcode 26.1 (Build 17B100), iOS 26.1 Simulator (`iPhone 17`)  
**Test Suite Destination**: `platform=iOS Simulator,name=iPhone 17`  

---

## 1. Automated Test Suite Execution

### Exact Command:
```bash
cd /Users/imstudent/Documents/IT23237872/Anchor/Anchor
xcodebuild test -project Anchor.xcodeproj -scheme Anchor -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:AnchorTests
```

### Result: **PASSED (13 of 13 tests passed, 0 failures)**

| # | Test Name | Target | Result | Runtime | Verified Behavior |
|:---:|:---|:---:|:---:|:---:|:---|
| 1 | `testCreateActiveSessionSuccess` | AnchorTests | Passed | 0.002s | Creates session with valid coordinate, title, floor, bay, note, and timestamps. |
| 2 | `testAtMostOneActiveSessionEnforced` | AnchorTests | Passed | 0.002s | Rejects second active session creation with `activeSessionAlreadyExists`. |
| 3 | `testUpdateActiveSessionPreservesIDAndParkedAt` | AnchorTests | Passed | 0.001s | Editing existing spot preserves original UUID and `parkedAt` timestamp. |
| 4 | `testMarkCollectedCompletesSession` | AnchorTests | Passed | 0.052s | Sets `collectedAt`, clears active session query, and adds record to history. |
| 5 | `testCannotCollectAlreadyCompletedSessionAndPreservesTimestamp` | AnchorTests | Passed | 0.002s | Rejects re-collection and preserves original `collectedAt` timestamp. |
| 6 | `testCompletedHistoryOrderedNewestFirst` | AnchorTests | Passed | 0.001s | Ensures completed history is returned in descending order of collection time. |
| 7 | `testDeleteCompletedSessionSucceedsAndPreservesActiveSession` | AnchorTests | Passed | 0.002s | Deleting historical item removes it and leaves active parking intact. |
| 8 | `testCannotDeleteActiveSessionFromHistory` | AnchorTests | Passed | 0.024s | Throws `cannotDeleteActiveSession` if active session is passed to delete method. |
| 9 | `testBlankTitleDefaultsToParkedCar` | AnchorTests | Passed | 0.004s | Empty or whitespace-only titles normalize to "Parked car". |
| 10| `testRejectInvalidCoordinatesAndAcceptsZeroZero` | AnchorTests | Passed | 0.006s | Rejects out-of-bounds latitudes/longitudes and NaN; explicitly accepts (0.0, 0.0). |
| 11| `testActiveAndCompletedDurationsUseCorrectTimestamps` | AnchorTests | Passed | 0.006s | Verifies active elapsed duration and completed duration formatting with controlled clock. |
| 12| `testFloorAndBaySummaryFormatting` | AnchorTests | Passed | 0.001s | Formats "Floor 2 • Bay 10", "Floor 3", "Bay B4", or nil. |
| 13| `testPersistenceDiskIntegration` | AnchorTests | Passed | 0.012s | Saves session to temporary SQLite disk file, tears down stack, reopens file, and confirms data survival. |

---

## 2. Automated UI Test Runs

### Exact Command:
```bash
xcodebuild test -project Anchor.xcodeproj -scheme Anchor -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:AnchorUITests/AnchorUITests/testAppLaunchAndEmptyStateNavigation
```
- **Result**: **PASSED (16.7s)**
- **Verified**:
  1. Clean launch into Empty State with primary "Save parking" CTA.
  2. Save Parking sheet opens with interactive map and spot detail inputs.
  3. Save button is disabled when no coordinate is selected.
  4. Cancel button dismisses sheet cleanly.
  5. Tab bar switches between "Parking" and "History".
  6. Empty history message displayed when no sessions exist.

---

## 3. Manual Inspection & Acceptance Checklist

The following items were inspected directly during development:

| Check | Status | Verification Detail |
|:---|:---:|:---|
| **App Launch & Empty State** | **PASSED** | Verified in simulator; parking symbol, text, and primary button render cleanly. |
| **Manual Map Pin Selection** | **PASSED** | Tapping on the map immediately drops and repositions pin with coordinate conversion. |
| **Floor & Bay Badges** | **PASSED** | Emphasized in `DetailBadge` components; omitted cleanly when fields are left blank. |
| **Walk to car Handoff** | **PASSED** | `MKMapItem` walking launch options invoked without crashing or errors. |
| **Collected Car Confirmation** | **PASSED** | Confirmation dialog appears with explicit prompt before completing session. |
| **Disk Persistence Survival** | **PASSED** | Verified via `testPersistenceDiskIntegration` using an isolated SQLite database file. |
| **Dark Mode Adaptation** | **PASSED** | Dual-appearance `#008080` (Light) and `#2DD4BF` (Dark) verified in asset catalog. |
| **Dynamic Type Text Wrapping** | **PASSED** | `ParkingInfoCard` and `HistoryRowView` adapt to vertical layout without clipping. |
| **VoiceOver Accessibility** | **PASSED** | Synthesized labels provide full session metadata without requiring visual map view. |

### Pending Manual Checks (To Be Completed in Viva / Physical Device):
- [ ] Physical device GPS lock in an outdoor lot.
- [ ] Real-world multi-floor garage walk-back test with user.
- [ ] End-user feedback review session.
