# Lazy Name Resolution Fix

## Problem
The app was trying to resolve all app names upfront before saving, which caused:
- Long delays (5+ seconds) when selecting apps
- Timeouts when FamilyControlsAgent wasn't ready
- All apps syncing to server as "Unknown App"
- Poor user experience with blocking UI

## Root Cause
FamilyControls' `Label(token)` view requires:
1. Authorization to be approved
2. FamilyControlsAgent to be running and responsive
3. The Label view to be in the view hierarchy (not hidden)
4. Time for the agent to populate the name asynchronously

The old approach tried to resolve all names immediately after picker closed, but FamilyControlsAgent often wasn't ready yet, causing timeouts.

## Solution: Lazy Name Resolution

### Key Changes

1. **Save Immediately**
   - When picker closes or Save is tapped, save tokens immediately to SwiftData
   - Sync to server right away (even with "Unknown" names initially)
   - Don't block the UI waiting for name resolution

2. **Resolve Names in Background**
   - Start background task to resolve names after saving
   - Process in small batches (5 at a time) to avoid overwhelming FamilyControlsAgent
   - Use shorter timeout (3 seconds instead of 5)
   - Update server incrementally as names resolve

3. **UI Updates Progressively**
   - `LabelWithNameCapture` wrapper captures names as Label views render
   - Names update in the UI as they become available
   - List re-sorts automatically when names change
   - User sees immediate feedback, names improve over time

### Benefits

✅ **Fast Response**: UI responds immediately, no blocking waits
✅ **Better Reliability**: Names resolve when FamilyControlsAgent is ready
✅ **Progressive Enhancement**: Apps show immediately, names improve over time
✅ **Server Sync**: Server gets updated with real names as they resolve
✅ **Graceful Degradation**: If name resolution fails, app still works with "Unknown"

### Implementation Details

#### ParentControlView.swift

**onChange(of: isPickerPresented)**
```swift
// OLD: Blocked UI for 5+ seconds trying to resolve all names
// NEW: Save immediately, resolve in background
viewModel.removeOwnAppFromSelection()
viewModel.refreshAndSave()  // Save tokens immediately

Task { @MainActor in
    await resolveNewAppNamesLazily()  // Background resolution
}
```

**Save Button**
```swift
// OLD: Blocked until all names resolved before syncing
// NEW: Save and sync immediately, resolve in background
viewModel.refreshAndSave()
viewModel.syncAppsWithServer(childId: childId) { success in
    isSaving = false
    if success { onBack?() }
}

Task { @MainActor in
    await resolveAndUpdateNames()  // Background resolution
}
```

**Background Resolution**
```swift
private func resolveAndUpdateNames() async {
    // Process in batches of 5
    let batchSize = 5
    for batch in statusesNeedingResolution.chunked(into: batchSize) {
        await withTaskGroup { group in
            for status in batch {
                group.addTask {
                    await self.resolveNameAsync(for: status.token)
                }
            }
            // Update as names resolve
            for await (token, name) in group {
                if let name = name {
                    viewModel.updateAppName(name, for: token)
                    viewModel.syncAppsWithServer(childId: childId)
                }
            }
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s between batches
    }
}
```

**UI Capture**
```swift
// LabelWithNameCapture wraps each Label in the list
LabelWithNameCapture(token: status.token) { capturedName in
    let key = tokenKey(status.token)
    if resolvedNames[key] == nil || resolvedNames[key] == "Unknown" {
        resolvedNames[key] = capturedName
        viewModel.updateAppName(capturedName, for: status.token)
        sortVersion += 1  // Trigger re-sort
    }
}
```

### Testing Checklist

- [ ] Select apps from picker - should save immediately without long wait
- [ ] Check server API - apps should sync (even if names are "Unknown" initially)
- [ ] Watch UI - names should update progressively as they resolve
- [ ] Check logs - should see "Background resolution" messages
- [ ] Tap Save - should return to previous screen immediately
- [ ] Check server again - names should update as they resolve
- [ ] Test with many apps (100+) - should still be responsive

### Expected Behavior

1. **User selects apps in picker**
   - Picker closes immediately
   - Apps appear in list (may show "Unknown" initially)
   - Names resolve in background over next few seconds
   - List re-sorts as names become available

2. **User taps Save**
   - Returns to previous screen immediately
   - Apps sync to server right away
   - Names continue resolving in background
   - Server gets updated with real names as they resolve

3. **Server receives updates**
   - Initial sync: tokens with "Unknown" names
   - Progressive updates: real names as they resolve
   - Final state: all apps with correct names

### Fallback Behavior

If name resolution fails:
- App still works with "Unknown" names
- User can still block/unblock apps
- Names may resolve on next app launch
- ViewModel's `resolveAppNamesIfNeeded()` will retry on next load

## Files Modified

- `GaurdianDrive/ParentControl/ParentControlView.swift`
  - Removed blocking name resolution from picker onChange
  - Removed blocking name resolution from Save button
  - Added lazy background resolution functions
  - Reduced timeout for background resolution (3s instead of 5s)
  - Added progressive server sync as names resolve

## Next Steps

1. Test with real device (FamilyControls only works on device, not simulator)
2. Monitor logs for "Background resolution" messages
3. Verify server receives progressive name updates
4. Check that UI remains responsive with many apps
5. Confirm names resolve correctly over time

## Notes

- FamilyControlsAgent behavior is unpredictable and varies by device/iOS version
- Some names may never resolve (removed apps, system apps, etc.)
- This is expected and handled gracefully
- The lazy approach is more resilient to FamilyControlsAgent quirks
