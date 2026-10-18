# Anchor — 2–3 Minute Viva Live Demonstration Script

**Audience**: Viva Examiner / Marker  
**Objective**: Demonstrate core workflows, architectural robustness, design system consistency, and accessibility features within 2 to 3 minutes.

---

## Preparation (Pre-Demo Setup)

1. Launch Xcode and open `Anchor.xcodeproj`.
2. Start the **iPhone 17** simulator (iOS 26.1).
3. In Simulator menu, set **Features > Location > Apple** (or **Custom Location**: `37.7749, -122.4194`).
4. Launch the **Anchor** app.

---

## Step-by-Step Demonstration Flow

| Time | Step | Action | Speaking Points / Rationale |
|:---:|:---|:---|:---|
| **0:00 – 0:25** | **1. Empty State** | Launch into Parking tab. | *"Welcome to Anchor. Notice the clean, uncluttered empty state. There are no distracting statistics or decorative clutter. The single primary action is 'Save parking'."* |
| **0:25 – 0:50** | **2. Saving Spot & GPS** | Tap **Save parking**. Tap **Use current location** (or tap map). | *"Anchor uses a battery-efficient one-shot Core Location request. Notice the button shows a loading spinner and then updates the map pin. If GPS is weak or permission is denied, the driver can tap anywhere on the map to manually set the spot."* |
| **0:50 – 1:15** | **3. Adding Garage Metadata** | Enter title: *"City Center Garage"*, Floor: *"P3"*, Bay: *"42B"*, Note: *"Near north elevators"*. Tap **Save**. | *"Here is our core value proposition: GPS only marks the building entrance. For multi-level garages, Anchor allows drivers to easily record their floor, bay, and landmark notes with dedicated, accessible fields."* |
| **1:15 – 1:40** | **4. Active Parking State** | Observe active card below map. | *"The active screen pairs an interactive MapKit view with our custom reusable `ParkingInfoCard`. Notice the live minute-level elapsed timer (`ElapsedTimerView`) and prominent floor/bay badges. Empty fields are omitted cleanly."* |
| **1:40 – 2:00** | **5. Edit & Directions** | Tap **Edit parking**. Update note to *"Near Door 4"*, tap **Save**. Tap **Walk to car**. | *"Editing preserves the original UUID and parking timestamp. When ready to return, the driver taps 'Walk to car', which cleanly hands off coordinates directly to Apple Maps walking directions."* |
| **2:00 – 2:30** | **6. Collecting the Car** | Tap **Collected car**. Confirm dialog. | *"To prevent accidental completion, 'Collected car' is separated from navigation and protected by a confirmation dialog. Marking it collected computes total parked duration, resets the active state, and archives the session."* |
| **2:30 – 2:50** | **7. Parking History** | Switch to **History** tab. Tap entry to view details. | *"Switching to History reveals our completed session sorted newest-first. Tapping opens `HistoricalDetailsView`, which reuses `ParkingInfoCard` to present date, time, and duration metrics. Swipe-to-delete allows record removal."* |

---

## Key Talking Points for Technical Questions

- **Why no indoor routing?**  
  *"Standard smartphone GPS and consumer satellite signals cannot reliably penetrate reinforced concrete multi-level parking garages. Rather than providing false floor positioning, Anchor explicitly captures floor and bay metadata and pairs it with building-entrance GPS."*
- **Why Apple Maps handoff instead of in-app turn-by-turn?**  
  *"Apple Maps provides best-in-class walking directions, pedestrian crossings, and voice guidance. Re-implementing a turn-by-turn routing engine would introduce fragile third-party dependencies and battery drain without adding user value."*
- **How is data integrity guaranteed?**  
  *"Core Data enforces our single-active-session invariant. If a session is active, another cannot be created without completing the current one. UUIDs and parked timestamps are preserved during edits."*
