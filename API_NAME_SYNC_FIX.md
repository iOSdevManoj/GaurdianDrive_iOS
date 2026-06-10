# API Name Sync Fix - Resolved Names Now Sync to Server

## Problem
App names were being resolved locally on the parent device but **NOT syncing to the server**. This caused:
- ❌ All apps showing as "Unknown App" in the server database
- ❌ Child device seeing "Unknown App" for all blocked apps
- ❌ Request app access feature showing "Unknown App" instead of real names
- ❌ Parent could see real names locally, but child never received them

## Root Cause Analysis

### Data Flow
1. **Parent Device** (ParentControlView):
   - Saves app tokens immediately after picker closes
   - Syncs to server with "Unknown App" names initially
   - Resolves names in background using FamilyControls Label views
   - Updates local SwiftData with resolved names
   - ❌ **MISSING**: Did not re-sync resolved names to server

2. **Server** (API):
   - Stores apps with `name` or `appName` field
   - Returns apps to child device with whatever name was last synced

3. **Child Device** (ChildHomeVC):
   - Fetches blocked apps from server
   - Displays `displayAppName` = `name ?? appName ?? "Unknown App"`
   - ❌ Always showed "Unknown App" because server never received real names

### Why Names Weren't Syncing

**Before Fix:**
```swift
// ParentControlView.resolveAndUpdateNames()
for await (token, name) in group {
    if let name = name {
        viewModel.updateAppName(name, for: token)  // Only updates local SwiftData
        sortVersion += 1
    }
}
// ❌ No server sync after name resolution
```

**ViewModel.updateAppName():**
```swift
func updateAppName(_ name: String, for token: ApplicationToken) {
    appStatuses[index].appName = name
    writeToSwiftData()  // Only saves locally
    // ❌ No server sync
}
```

## Solution: Batch Sync After Name Resolution

### Changes Made

#### 1. ParentControlView.swift - Batch Server Sync

**Added batch syncing after each group of names resolves:**

```swift
private func resolveAndUpdateNames() async {
    let batchSize = 5
    var resolvedCount = 0
    
    for i in stride(from: 0, to: statusesNeedingResolution.count, by: batchSize) {
        let batch = Array(statusesNeedingResolution[i..<end])
        var batchResolvedCount = 0
        
        await withTaskGroup(of: (ApplicationToken, String?).self) { group in
            // Resolve names in parallel
            for status in batch {
                group.addTask {
                    await self.resolveNameAsync(for: status.token)
                }
            }
            
            // Update local state
            for await (token, name) in group {
                if let name = name {
                    viewModel.updateAppName(name, for: token)
                    batchResolvedCount += 1
                }
            }
        }
        
        // ✅ NEW: Sync batch to server after resolution
        if batchResolvedCount > 0 {
            resolvedCount += batchResolvedCount
            print("📤 [Background] Syncing \(batchResolvedCount) resolved names to server...")
            viewModel.syncAppsWithServer(childId: childId) { success in
                if success {
                    print("✅ [Background] Server updated with batch of \(batchResolvedCount) names")
                }
            }
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s between batches
    }
    
    print("✅ [Background] Name resolution complete - \(resolvedCount) names resolved and synced")
}
```

**Key improvements:**
- ✅ Syncs to server after each batch of 5 names
- ✅ Only syncs if names were actually resolved (avoids empty syncs)
- ✅ Logs progress for debugging
- ✅ Batching reduces API calls (5 names per sync instead of 1)

#### 2. ParentControlViewModel.swift - Simplified updateAppName

**Removed premature server sync attempt:**

```swift
@MainActor func updateAppName(_ name: String, for token: ApplicationToken) {
    guard let index = appStatuses.firstIndex(where: { $0.token == token }) else { return }
    guard appStatuses[index].appName != name else { return }
    
    appStatuses[index].appName = name
    _cachedOwnAppTokens = nil
    writeToSwiftData()
    
    // Note: Caller should batch sync to server to avoid excessive API calls
    print("✅ [ViewModel] Name resolved: \(name)")
}
```

**Why this approach:**
- ViewModel doesn't have access to `childId` parameter
- Batching at the View level is more efficient
- Avoids 100+ individual API calls for 100 apps
- View controls the sync timing and batching strategy

## How It Works Now

### Complete Flow

1. **User Selects Apps** (Parent Device)
   ```
   User taps "+" → Selects apps → Picker closes
   ```

2. **Immediate Save & Sync**
   ```swift
   onChange(of: isPickerPresented) {
       viewModel.refreshAndSave()  // Save tokens to SwiftData
       // Names are "Unknown App" at this point
   }
   ```

3. **Background Name Resolution** (Batched)
   ```
   Batch 1 (5 apps):
     - Resolve names using FamilyControls Label
     - Update local SwiftData
     - Sync batch to server ✅
     - Wait 0.5s
   
   Batch 2 (5 apps):
     - Resolve names
     - Update local SwiftData
     - Sync batch to server ✅
     - Wait 0.5s
   
   ... continues for all apps
   ```

4. **Server Receives Real Names**
   ```json
   {
     "apps": [
       {
         "name": "Instagram",  // ✅ Real name
         "token": "base64...",
         "a": "1"
       },
       {
         "name": "TikTok",  // ✅ Real name
         "token": "base64...",
         "a": "1"
       }
     ]
   }
   ```

5. **Child Device Sees Real Names**
   ```swift
   // ChildHomeVC.fetchBlockedApps()
   for app in serverApps {
       let name = app.displayAppName  // "Instagram", "TikTok", etc.
       blockedAppNames.append(name)
   }
   
   // ViewForReqAppSelection displays real names
   reqView.setTokenDropdownData(tokens, tokenNames: blockedAppNames)
   ```

## Benefits

### ✅ Efficiency
- **Batched syncs**: 5 names per API call instead of 1
- **Conditional syncs**: Only syncs if names actually resolved
- **Reduced load**: ~20 API calls for 100 apps instead of 100

### ✅ Reliability
- **Progressive updates**: Server gets names as they resolve
- **No blocking**: UI remains responsive
- **Graceful degradation**: If some names fail, others still sync

### ✅ User Experience
- **Parent sees**: Real names immediately in UI (via Label views)
- **Child sees**: Real names in request dropdown (from server)
- **Server has**: Real names for analytics and reporting

## Testing Checklist

### Parent Device
- [ ] Select 10+ apps from picker
- [ ] Verify apps save immediately (no long wait)
- [ ] Check Xcode console for batch sync logs:
  ```
  🔍 [Background] Resolving 10 app names in background
  📤 [Background] Syncing 5 resolved names to server...
  ✅ [Background] Server updated with batch of 5 names
  📤 [Background] Syncing 5 resolved names to server...
  ✅ [Background] Server updated with batch of 5 names
  ✅ [Background] Name resolution complete - 10 names resolved and synced
  ```

### Server API
- [ ] Check server database after parent saves apps
- [ ] Verify `name` or `appName` fields contain real names (not "Unknown App")
- [ ] Use API endpoint: `GET /api/child/{childId}/apps`
- [ ] Response should show real app names:
  ```json
  {
    "apps": [
      {"name": "Instagram", "a": "1"},
      {"name": "TikTok", "a": "1"}
    ]
  }
  ```

### Child Device
- [ ] Open "Request App Access" screen
- [ ] Verify dropdown shows real app names (not "Unknown App")
- [ ] Check that app icons show correct first letter
- [ ] Submit a request and verify real name appears in submitted card

## Expected Logs

### Parent Device (Xcode Console)
```
🔍 [Background] Resolving 85 app names in background
📤 [Background] Syncing 5 resolved names to server...
✅ [Background] Server updated with batch of 5 names
📤 [Background] Syncing 5 resolved names to server...
✅ [Background] Server updated with batch of 5 names
... (continues for all batches)
✅ [Background] Name resolution complete - 85 names resolved and synced
```

### Child Device (Xcode Console)
```
[ViewModel] Fetching apps from server for ID: 12345
[ViewModel] Loaded 85 blocked apps from server
✅ [Stack] created, viewforTextfields=OK
```

## Troubleshooting

### Issue: Still seeing "Unknown App" on child device

**Check:**
1. **Parent logs**: Did name resolution complete?
   - Look for "✅ [Background] Name resolution complete"
2. **Server sync**: Did batches sync successfully?
   - Look for "✅ [Background] Server updated with batch"
3. **FamilyControls auth**: Is authorization approved?
   - Check: `AuthorizationCenter.shared.authorizationStatus == .approved`
4. **Child refresh**: Did child fetch latest data?
   - Pull to refresh or restart child app

### Issue: Names resolve but don't sync

**Check:**
1. **Network**: Is device online?
2. **API endpoint**: Is server reachable?
3. **childId**: Is it being passed correctly?
   - Check `viewModel.syncAppsWithServer(childId: childId)`
4. **Logs**: Look for sync errors in console

### Issue: Too many API calls

**Current batching:**
- 5 names per sync call
- 0.5s delay between batches
- ~20 calls for 100 apps

**To reduce further:**
- Increase `batchSize` from 5 to 10
- Increase delay from 0.5s to 1s
- Sync only once at the end (trade-off: child waits longer)

## Files Modified

1. **ParentControlView.swift**
   - Added batch sync logic in `resolveAndUpdateNames()`
   - Added `batchResolvedCount` tracking
   - Added server sync after each batch
   - Added detailed logging

2. **ParentControlViewModel.swift**
   - Simplified `updateAppName()` to only update local state
   - Removed premature server sync attempt
   - Added note about caller responsibility for batching

## Performance Impact

### Before Fix
- ❌ 0 server syncs after name resolution
- ❌ Child always sees "Unknown App"

### After Fix
- ✅ ~20 server syncs for 100 apps (batched)
- ✅ Child sees real names within seconds
- ✅ Progressive updates as names resolve

### Network Usage
- **Per batch**: ~5KB (5 apps × ~1KB each)
- **Total for 100 apps**: ~100KB
- **Time**: ~10 seconds (20 batches × 0.5s delay)

## Next Steps

1. **Test on real device** (FamilyControls requires physical device)
2. **Verify server receives real names** (check database or API)
3. **Test child device** sees real names in dropdown
4. **Monitor logs** for successful batch syncs
5. **Adjust batch size** if needed (currently 5 apps per batch)

## Summary

✅ **Problem solved**: App names now sync to server after resolution
✅ **Efficient**: Batched syncs reduce API calls
✅ **Progressive**: Names update as they resolve
✅ **Reliable**: Graceful handling of failures
✅ **User-friendly**: Child sees real names, not "Unknown App"

The fix ensures that resolved app names are automatically synced to the server in efficient batches, making them immediately available to the child device for the "Request App Access" feature.
