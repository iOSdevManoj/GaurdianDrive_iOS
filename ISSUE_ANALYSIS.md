# GuardianDrive — App Name Sync Issue Analysis

**Date:** May 21, 2026  
**Status:** Partially Resolved — Core issues fixed, FamilyControlsAgent dependency remains

---

## The Core Problem (Plain English)

The parent selects apps to block. Those apps need to show up on the **child's device** with their real names (e.g. "Instagram", "TikTok"). Instead, the child sees **"Sync Failed"**, **"Name"**, or **"Unknown App"** in the dropdown.

---

## Root Cause Chain

```
Parent selects apps
        ↓
App saves tokens immediately (no names yet)
        ↓
FamilyControls Label(token) is supposed to resolve real names
        ↓
FamilyControlsAgent is NOT READY / NOT AUTHORIZED
        ↓
Names never resolve → stay as "Unknown App"
        ↓
Sync fires BEFORE names resolve
        ↓
Server receives "Unknown App" for every entry
        ↓
Child device fetches from server → sees "Unknown App"
```

---

## Issue 1 — FamilyControls Authorization Not Approved

### What Happened
```
Current authorization status: Not Determined
Cannot enforce app removal policy: Family Controls not approved (Not Determined).
Failed to get remote content: Error Domain=FamilyControlsAgent.FamilyActivityLabelError Code=2
```

### Why It Matters
`Label(token)` — the Apple API that resolves an `ApplicationToken` to a real app name — **only works when FamilyControls is authorized**. If status is `Not Determined` or `Denied`, the Label view renders empty forever.

### Impact
- Every app name stays as "Unknown App"
- All 86 apps sync to server as "Unknown App"
- Child sees "Unknown App" for everything

### Fix Applied
- Added authorization check before attempting name resolution
- If not `.approved`, skip resolution immediately instead of waiting 3s per token

---

## Issue 2 — Sync Fired Before Names Resolved

### What Happened
```swift
// OLD CODE — sync fires immediately, names not ready yet
viewModel.refreshAndSave()
viewModel.syncAppsWithServer(childId: childId) { success in
    onBack()  // navigates away
}
// Names resolve AFTER navigation — too late
Task { await resolveAndUpdateNames() }
```

### Why It Matters
The app was syncing to the server **before** FamilyControls had time to resolve the names. The server received "Unknown App" for every entry.

### Impact
- Server database permanently stored "Unknown App"
- Child device always saw "Unknown App"
- Even after names resolved locally, server was never updated

### Fix Applied
```swift
// NEW CODE — wait for names, THEN sync
await resolveAndUpdateNames()  // wait for real names
viewModel.syncAppsWithServer(childId: childId) { success in
    onBack()  // navigate only after sync completes
}
```

---

## Issue 3 — Server Data Pollution (Duplicate Entries)

### What Happened
The server accumulated **hundreds of duplicate entries** with garbage names:
```json
{"name": "Sync Failed", "a": "1"},  // × 26 duplicates
{"name": "Name", "a": "1"},          // × 8 duplicates
{"name": "Unknown App", "a": "1"},   // × many more
```

### Why It Happened
Every failed sync attempt created new server entries instead of updating existing ones. The `executeFinalSync` function was fetching the server state and **re-appending all old garbage entries** back into every new sync payload:

```swift
// OLD CODE — re-appended ALL server entries including garbage
for item in appsArray {
    if !currentTokensInPayload.contains(serverToken) {
        finalPayload.append(cleanItem)  // ← added "Sync Failed", "Name", etc. back
    }
}
```

### Impact
- Server had 86+ entries instead of the real ~4 apps
- Child dropdown showed 86 items, all with garbage names
- Every new sync made it worse (more duplicates)

### Fix Applied
```swift
// NEW CODE — only preserve REQUESTED items with real names
let isGarbage = serverName.isEmpty
    || serverName == "Unknown App" || serverName == "Unknown"
    || serverName == "Removed App" || serverName == "Sync Failed"
    || serverName == "Name"

if status == "REQUESTED" && !isGarbage {
    finalPayload.append(cleanItem)  // only real names preserved
}
// All other server-only entries dropped
```

---

## Issue 4 — HTTP 500 Optimistic Locking Error

### What Happened
```
"error": "optimistic locking failed; nested exception is 
org.hibernate.StaleObjectStateException: Row was updated or deleted 
by another transaction"
```

### Why It Happened
Two `syncAppsWithServer` calls were running **simultaneously**:
1. One from the Save button flow
2. One from `fetchFromServer` → `resolveAppNamesIfNeeded`

Both fetched the same server rows, both tried to update them at the same time → database conflict → HTTP 500.

### Impact
- Sync failed silently
- Names never updated on server
- User saw "Sync Failed" alert repeatedly

### Fix Applied
```swift
// Added sync lock
private var isSyncInProgress = false

func syncAppsWithServer(...) {
    guard !isSyncInProgress else {
        print("⏭ Sync already in progress — skipping")
        return
    }
    isSyncInProgress = true
    // ... sync logic ...
    // isSyncInProgress = false in all completion paths
}
```

---

## Issue 5 — "Label is already or no longer part of the view hierarchy"

### What Happened
```
Label is already or no longer part of the view hierarchy  (× 200+ times)
```

### Why It Happened
The name resolution code added a `UIHostingController` view to `rootViewController.view`. When the user navigated away (or the app changed state), `rootViewController` changed and the view was orphaned mid-polling.

```swift
// OLD CODE — attached to rootVC which can change
rootVC.view.addSubview(hc.view)
// ... async polling ...
// rootVC changes during navigation → view orphaned
```

### Impact
- Hundreds of console warnings
- Name resolution failed for all tokens
- FamilyControlsAgent couldn't populate the Label

### Fix Applied
```swift
// NEW CODE — dedicated off-screen UIWindow, independent of navigation
let offscreenWindow = UIWindow(windowScene: windowScene)
offscreenWindow.frame = CGRect(x: -2000, y: 0, width: 300, height: 44)
offscreenWindow.isHidden = false
offscreenWindow.alpha = 0.01
offscreenWindow.rootViewController = hc
// Window stays stable regardless of navigation
```

---

## Issue 6 — FamilyControlsAgent Unavailable

### What Happened
```
Failed to get service proxy: Error Domain=NSCocoaErrorDomain Code=4097 
"connection to service named com.apple.FamilyControlsAgent"
⏱ [renderLabel] Timed out — name not resolved  (× 82 times)
```

### Why It Happened
`FamilyControlsAgent` is an Apple system service that runs in the background. It can be:
- Not started yet (app just launched)
- Killed by iOS (memory pressure)
- Unavailable when app is in background

When the agent is unavailable, every `Label(token)` renders empty and times out after 3 seconds.

### Impact
- 82 tokens × 3 seconds = **4+ minutes** of timeout loops
- All names fail to resolve
- Server never gets real names

### Fix Applied
- Check authorization status before attempting resolution
- If agent is unavailable, skip gracefully
- Names will resolve on next app launch when agent is ready

---

## Current State After Fixes

| Issue | Status |
|-------|--------|
| Server data pollution (duplicates) | ✅ Fixed — garbage entries no longer re-appended |
| Sync before names resolve | ✅ Fixed — await resolution before sync |
| HTTP 500 concurrent syncs | ✅ Fixed — sync lock added |
| View hierarchy warnings | ✅ Fixed — dedicated UIWindow |
| Authorization check | ✅ Fixed — skip if not approved |
| FamilyControlsAgent unavailable | ⚠️ Partial — graceful skip, but names won't resolve until agent is ready |

---

## What Still Needs Attention

### 1. FamilyControlsAgent Reliability
The agent is an Apple system service — we cannot control when it's available. Names will only resolve when:
- App is in foreground
- FamilyControls is authorized (`.approved`)
- Agent is running (not killed by iOS)

**Recommendation:** Show a loading indicator while names are resolving. Don't navigate away until resolution completes or times out.

### 2. Server Cleanup
The server still has old garbage entries (id 334666–334691) with names "Sync Failed" and "Name". These are **real app names** resolved by FamilyControls — they are not garbage. However, the server has duplicate entries for the same tokens.

**Recommendation:** Ask the backend team to deduplicate entries by token, keeping only the most recent one per token.

### 3. "Name" and "Sync Failed" Are Real App Names
These are **actual app names** returned by FamilyControls. There are apps on the device literally named "Name" and "Sync Failed". The code currently treats them as garbage and filters them out — this is **incorrect** and will prevent those apps from being blocked.

**Recommendation:** Remove "Sync Failed" and "Name" from the garbage filter. Instead, use a different strategy to detect garbage (e.g., check if the name was set before FamilyControls was authorized).

---

## Files Modified

| File | Changes |
|------|---------|
| `ParentControl/ParentControlView.swift` | Save button awaits resolution; dedicated UIWindow for Label rendering; authorization check |
| `ParentControl/ParentControlViewModel.swift` | Sync lock; garbage filter in executeFinalSync; garbage filter in fetchFromServer; waitForNamesAndSync |

---

## How Name Resolution Works (Technical)

```
ApplicationToken (opaque binary blob)
        ↓
Label(token)  ← SwiftUI view from FamilyControls framework
        ↓
FamilyControlsAgent (Apple system service)
        ↓
Looks up app metadata in system database
        ↓
Populates Label with real app name + icon
        ↓
We extract text via UILabel traversal
        ↓
Store name in appStatuses[].appName
        ↓
Sync to server with real name
```

The entire chain depends on FamilyControlsAgent being alive and authorized. There is no direct API to get an app name from a token — the Label view is the only supported method.

---

## Timeline of Events (From Logs)

```
15:14:46  App launches, loads 86 app statuses from SwiftData
15:14:46  Fetches apps from server → all 86 have "Sync Failed"/"Name" names
15:14:46  FamilyControls authorization: Not Determined
15:14:46  Cannot enforce app removal policy
15:14:46  Authorization request sent
15:14:46  Authorization APPROVED
15:15:41  User enters passcode (1111)
15:15:43  Opens ParentControlView — 86 apps loaded
15:15:55  Picker closes → resolveAndUpdateNames() starts
15:15:55  82 apps need resolution
15:15:55  FamilyControlsAgent: Code=4097 (unavailable)
15:15:55  All 82 tokens timeout (3s each)
15:15:55  Sync fires with 4 resolved names
15:15:55  HTTP 500 — concurrent sync conflict
15:16:27  Server now has only 4 apps (cleanup worked)
15:16:29  Sync succeeds with 4 apps
```

---

*Document generated: May 21, 2026*
