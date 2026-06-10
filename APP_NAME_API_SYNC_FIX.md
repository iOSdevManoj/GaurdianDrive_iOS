# App Name API Sync Fix - Root Cause and Solution

## Problem Description
When the parent adds apps using the system picker, the app names show correctly in the UI (YouTube, Spido, Onegolf, Music, FaceTime, Skype), but when the data is synced to the API, the server receives "Unknown App" instead of the real names.

## Root Cause Analysis

### The Flow (Before Fix)

#### When Picker Closes:
1. `onChange(of: isPickerPresented)` fires
2. Calls `viewModel.refreshAndSave()`
   - This calls `syncAppStatuses()`
   - Which adds new tokens to `appStatuses` with `appName: nil`
   - Then calls `writeToSwiftData()` → **Saved with nil names** ❌
3. Calls `resolveNamesAndSort()` to start async name resolution
4. Returns immediately (doesn't wait for resolution)
5. 0.5 seconds later: `isSaving = false` → **Save button becomes enabled**

#### When UI Renders:
6. `LabelWithNameCapture` component renders for each app
7. Waits 0.5 seconds, then extracts name from `Label(token)`
8. Calls `viewModel.updateAppName()` → Updates SwiftData ✅
9. **But this takes 0.5-6 seconds per app**

#### When User Taps Save (Too Early):
10. If user taps Save before step 8 completes, `appStatuses` still has `nil` names
11. `syncAppsWithServer()` sends payload with `appName: nil`
12. Server stores "Unknown App" ❌

### Why UI Shows Real Names
The UI shows real names because `Label(token)` is rendered directly in the SwiftUI view, and FamilyControls framework populates it. But this happens **asynchronously** and the names are not immediately available in `appStatuses`.

### The Timing Problem
```
Time 0s:   Picker closes → Save with nil names to SwiftData
Time 0.5s: isSaving = false → Save button enabled
Time 1-6s: LabelWithNameCapture resolves names → Updates SwiftData
Time ???:  User taps Save → If before step 3, sends nil names to API ❌
```

## Solution Implemented

### Key Changes

#### 1. **Resolve Names BEFORE Saving to SwiftData** (Picker onChange)
**Before:**
```swift
.onChange(of: isPickerPresented) { _, presented in
    viewModel.refreshAndSave()  // ← Saves with nil names immediately
    resolveNamesAndSort()        // ← Starts async resolution (doesn't wait)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        isSaving = false  // ← Save button enabled too early
    }
}
```

**After:**
```swift
.onChange(of: isPickerPresented) { _, presented in
    // 1. Identify new tokens
    let newTokens = viewModel.selection.applicationTokens.filter { token in
        !viewModel.appStatuses.contains(where: { $0.token == token })
    }
    
    // 2. Resolve names for all new tokens
    var pending = newTokens.count
    var resolvedNamesMap: [ApplicationToken: String] = [:]
    
    for token in newTokens {
        renderLabelName(for: token) { name in
            if let name = name { resolvedNamesMap[token] = name }
            pending -= 1
            if pending == 0 {
                // 3. All names resolved - NOW save with real names
                viewModel.syncAppStatuses(updatedNames: resolvedNamesMap)
                isSaving = false  // ← Save button enabled AFTER resolution
            }
        }
    }
}
```

#### 2. **Resolve Names BEFORE Syncing to API** (Save Button)
**Before:**
```swift
Button(action: {
    viewModel.refreshAndSave()  // ← Saves with nil names
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        resolveNamesAndSync(childId: childId)  // ← Too late
    }
})
```

**After:**
```swift
Button(action: {
    // 1. Check if any names need resolution
    let statusesNeedingResolution = viewModel.appStatuses.filter { /* has nil/Unknown name */ }
    
    if statusesNeedingResolution.isEmpty {
        // All names known - save and sync immediately
        viewModel.refreshAndSave()
        viewModel.syncAppsWithServer(childId: childId)
    } else {
        // 2. Resolve names first
        var pending = statusesNeedingResolution.count
        for status in statusesNeedingResolution {
            renderLabelName(for: status.token) { name in
                if let name = name { viewModel.updateAppName(name, for: status.token) }
                pending -= 1
                if pending == 0 {
                    // 3. All resolved - NOW save and sync with real names
                    viewModel.refreshAndSave()
                    viewModel.syncAppsWithServer(childId: childId)
                }
            }
        }
    }
})
```

#### 3. **Made syncAppStatuses Public**
Changed `private func syncAppStatuses` to `func syncAppStatuses` so the view can call it with resolved names.

### Files Modified

1. ✅ `/GaurdianDrive/ParentControl/ParentControlView.swift`
   - Updated `onChange(of: isPickerPresented)` to resolve names before saving
   - Updated Save button action to resolve names before syncing to API

2. ✅ `/GaurdianDrive/ParentControl/ParentControlViewModel.swift`
   - Changed `syncAppStatuses` from `private` to `public`

## How It Works Now

### When Picker Closes:
```
1. Picker closes
2. Identify new tokens (e.g., YouTube, Spido, Music)
3. For each token:
   - Create off-screen Label(token) view
   - Wait 0.5s initial delay
   - Poll every 0.5s up to 6s for name resolution
4. When ALL names resolved:
   - Call syncAppStatuses(updatedNames: ["YouTube", "Spido", ...])
   - Save to SwiftData with real names ✅
   - Set isSaving = false (enable Save button)
```

### When User Taps Save:
```
1. Check if any apps have nil/Unknown names
2. If all names known:
   - Save to SwiftData
   - Sync to API immediately ✅
3. If some names unknown:
   - Resolve those names first (0.5-6s per app)
   - When all resolved:
     - Save to SwiftData with real names
     - Sync to API with real names ✅
```

## Expected Behavior

### ✅ Success Criteria

1. **Picker closes**: Save button stays disabled until all names are resolved
2. **UI shows real names**: YouTube, Spido, Onegolf, Music, FaceTime, Skype
3. **SwiftData has real names**: `appStatuses[i].appName` is "YouTube", not nil
4. **API receives real names**: Server stores "YouTube", not "Unknown App"
5. **Child sees real names**: Blocked app dropdown shows "YouTube", not "Unknown App"

### Console Logs (Success Pattern)

```
🔍 [Picker] Resolving 6 new app names before saving...
🔍 [renderLabelName] Added view to window, waiting for FamilyControlsAgent...
✅ [renderLabelName] Resolved name: YouTube after 3 attempts
✅ [renderLabelName] Resolved name: Spido after 4 attempts
✅ [renderLabelName] Resolved name: Onegolf after 2 attempts
✅ [renderLabelName] Resolved name: Music after 3 attempts
✅ [renderLabelName] Resolved name: FaceTime after 2 attempts
✅ [renderLabelName] Resolved name: Skype after 5 attempts
✅ [Picker] All names resolved, saving to SwiftData
```

### API Payload (Success)

**Before Fix:**
```json
{
  "apps": [
    {"name": "Unknown App", "token": "...", "a": "1"},
    {"name": "Unknown App", "token": "...", "a": "1"}
  ]
}
```

**After Fix:**
```json
{
  "apps": [
    {"name": "YouTube", "token": "...", "a": "1"},
    {"name": "Spido", "token": "...", "a": "1"},
    {"name": "Onegolf", "token": "...", "a": "1"},
    {"name": "Music", "token": "...", "a": "1"},
    {"name": "FaceTime", "token": "...", "a": "1"},
    {"name": "Skype", "token": "...", "a": "1"}
  ]
}
```

## Testing Instructions

### Test 1: Add Apps from Picker
1. Log in as parent
2. Go to Parental Control screen
3. Tap "+" to open system picker
4. Select 5-10 apps (YouTube, Instagram, TikTok, etc.)
5. Close picker
6. **Expected**: 
   - Save button stays disabled for 1-6 seconds
   - Console shows "🔍 [Picker] Resolving X new app names..."
   - Console shows "✅ [renderLabelName] Resolved name: YouTube after X attempts"
   - Console shows "✅ [Picker] All names resolved, saving to SwiftData"
   - Save button becomes enabled
   - UI shows real app names

### Test 2: Tap Save Immediately
1. After picker closes and Save button is enabled
2. Tap "Save" immediately
3. **Expected**:
   - Console shows "✅ [Save] All names resolved, saving to SwiftData and syncing to server"
   - API receives real app names (check server logs/database)
   - Child device shows real app names in blocked app dropdown

### Test 3: Check Database
1. After saving, check the database/API response
2. Query: `GET /child/{childId}/apps`
3. **Expected**: Response contains real app names, not "Unknown App"

### Test 4: Child Side
1. Log in as child
2. View blocked apps dropdown
3. **Expected**: Shows real app names (YouTube, Spido, etc.), not "Unknown App"

## Known Limitations

### 1. Timing Variability
- Name resolution takes 0.5-6 seconds per app
- Adding 10 apps may take 5-60 seconds before Save button is enabled
- This is expected behavior (FamilyControlsAgent is async)

### 2. Removed Apps
- Apps that have been uninstalled will timeout after 6 seconds
- They will be saved with `nil` name → API stores "Unknown App"
- This is expected behavior

### 3. Must Test on Real Device
- Simulator cannot resolve FamilyControls names
- All testing must be done on physical iOS device

## Rollback Plan

If this fix causes issues:

1. Revert `ParentControlView.swift` onChange handler to:
```swift
.onChange(of: isPickerPresented) { _, presented in
    guard !presented else { return }
    guard !isSaving else { return }
    isSaving = true
    viewModel.removeOwnAppFromSelection()
    viewModel.refreshAndSave()
    resolveNamesAndSort()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        isSaving = false
    }
}
```

2. Revert Save button action to:
```swift
Button(action: {
    isSaving = true
    viewModel.refreshAndSave()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        resolveNamesAndSync(childId: childId)
        if !UserDefaults.Main.bool(forKey: .isParent) {
            viewModel.updateMonitoring()
        }
    }
})
```

3. Change `syncAppStatuses` back to `private`

## Additional Notes

### Why This Fix Works

1. **Synchronous Resolution**: Names are resolved BEFORE saving to SwiftData, not after
2. **Blocking UI**: Save button stays disabled until names are resolved
3. **Guaranteed Order**: SwiftData always has real names before API sync
4. **No Race Conditions**: No timing issues between UI rendering and data persistence

### Performance Impact

- **Before**: Save button enabled after 0.5s, but API gets wrong data
- **After**: Save button enabled after 1-60s (depending on number of apps), but API gets correct data
- **Trade-off**: Slightly longer wait time, but guaranteed correct data

### Why LabelWithNameCapture Still Exists

The `LabelWithNameCapture` component is still used for:
1. Displaying names in the UI (real-time rendering)
2. Updating names for apps that were added in previous sessions
3. Fallback for any apps that weren't resolved during picker close

It's now a **secondary** mechanism, not the primary one.

---

**Last Updated**: May 20, 2026
**Status**: Ready for device testing
**Priority**: HIGH - Fixes critical data integrity issue
