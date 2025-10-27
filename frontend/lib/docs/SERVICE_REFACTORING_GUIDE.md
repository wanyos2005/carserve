# Service Refactoring Guide - DRY Compliance

## 🎯 **Objective**
Eliminate DRY violations by centralizing permission handling while maintaining service separation.

## 📊 **Current Architecture Analysis**

### ✅ **GOOD: Following DRY Principles**
- **Single Responsibility**: Each service has a clear, focused purpose
- **No Code Duplication**: Services handle their own domains without repeating logic
- **Proper Separation**: Services are well-separated by functionality

### ⚠️ **DRY VIOLATION IDENTIFIED**
**Duplicate Permission Handling** between:
- `permission_service.dart` - Generic permission handling
- `location_service.dart` - Location-specific permission handling

## 🛠️ **Refactoring Solution**

### **New Architecture: Unified Permission Service**

```
┌─────────────────────────────────────┐
│        UnifiedPermissionService     │
│  - Centralized permission logic     │
│  - Geolocator integration           │
│  - Consistent dialog handling       │
└─────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
┌───────▼───┐ ┌─────▼─────┐ ┌──▼────────┐
│LocationSvc│ │PermissionSvc│ │OtherSvc   │
│- Location │ │- Generic   │ │- Uses     │
│- Geolocator│ │- All types │ │- Delegates│
└───────────┘ └───────────┘ └───────────┘
```

## 📋 **Migration Steps**

### **Step 1: Update LocationService**
```dart
// BEFORE (DRY violation)
static Future<LocationPermission> requestLocationPermission() async {
  return await Geolocator.requestPermission();
}

// AFTER (DRY compliant)
static Future<bool> requestLocationPermission({BuildContext? context}) async {
  return await UnifiedPermissionService.requestLocationPermission(context: context);
}
```

### **Step 2: Update PermissionService**
```dart
// BEFORE (duplicate logic)
static Future<bool> requestLocationPermission() async {
  var status = await Permission.location.status;
  // ... duplicate logic
}

// AFTER (delegates to unified service)
static Future<bool> requestLocationPermission({BuildContext? context}) async {
  return await UnifiedPermissionService.requestLocationPermission(context: context);
}
```

### **Step 3: Update Other Services**
```dart
// In any service that needs permissions
import 'unified_permission_service.dart';

// Use unified service
bool hasCamera = await UnifiedPermissionService.requestCameraPermission(context: context);
bool hasLocation = await UnifiedPermissionService.requestLocationPermission(context: context);
```

## 🔄 **Backward Compatibility**

### **Maintain Existing APIs**
```dart
// Old API still works
bool hasPermission = await PermissionService.requestLocationPermission();

// New API with context
bool hasPermission = await PermissionService.requestLocationPermission(context: context);
```

### **Gradual Migration**
1. **Phase 1**: Create `UnifiedPermissionService`
2. **Phase 2**: Update `LocationService` to delegate
3. **Phase 3**: Update `PermissionService` to delegate
4. **Phase 4**: Update all other services
5. **Phase 5**: Remove old duplicate methods

## 📁 **File Structure After Refactoring**

```
frontend/lib/services/
├── unified_permission_service.dart    # NEW: Centralized permission handling
├── permission_service.dart            # UPDATED: Delegates to unified service
├── location_service.dart              # UPDATED: Delegates to unified service
├── fcm_service.dart                   # UNCHANGED: No permission duplication
├── coordinate_research.dart           # UNCHANGED: Data only, no permissions
├── coordinate_collector.dart          # UPDATED: Uses unified service
└── ...other services                  # UPDATED: Use unified service
```

## 🎯 **Benefits of Refactoring**

### **DRY Compliance**
- ✅ Single source of truth for permission logic
- ✅ No duplicate permission handling code
- ✅ Consistent permission dialogs across app

### **Maintainability**
- ✅ Easier to update permission logic
- ✅ Centralized permission explanations
- ✅ Consistent user experience

### **Testability**
- ✅ Single service to test permission logic
- ✅ Mockable permission service
- ✅ Isolated permission testing

## 🚀 **Implementation Priority**

### **High Priority**
1. **Create `UnifiedPermissionService`** ✅ DONE
2. **Update `LocationService`** ✅ DONE
3. **Update `PermissionService`** (Next)

### **Medium Priority**
4. **Update `CoordinateCollector`**
5. **Update other services**

### **Low Priority**
6. **Remove old duplicate methods**
7. **Add comprehensive tests**

## 📝 **Code Examples**

### **Using Unified Service**
```dart
// Request multiple permissions
Map<String, bool> permissions = await UnifiedPermissionService.getAllPermissionStatus();

// Request specific permission with context
bool hasLocation = await UnifiedPermissionService.requestLocationPermission(
  context: context,
  showDialog: true,
);

// Check permission status
bool hasCamera = await UnifiedPermissionService.isPermissionGranted(Permission.camera);
```

### **Service Integration**
```dart
class MyService {
  static Future<void> doSomething(BuildContext context) async {
    // Use unified service
    bool hasPermission = await UnifiedPermissionService.requestLocationPermission(
      context: context,
    );
    
    if (hasPermission) {
      // Proceed with location-based functionality
    }
  }
}
```

## ✅ **Verification Checklist**

- [ ] `UnifiedPermissionService` created
- [ ] `LocationService` updated to delegate
- [ ] `PermissionService` updated to delegate
- [ ] All services use unified permission handling
- [ ] No duplicate permission logic remains
- [ ] All permission dialogs are consistent
- [ ] Backward compatibility maintained
- [ ] Tests updated for new architecture

---

**Result**: DRY-compliant architecture with centralized permission handling while maintaining service separation and single responsibility principles.
