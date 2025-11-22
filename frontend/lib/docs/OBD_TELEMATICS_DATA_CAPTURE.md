# OBD Telematics: Location & Mileage Data Capture

## Direct Answer

**Yes, telematics OBD devices capture both location and mileage data, but with important technical distinctions:**

### ✅ Location (GPS)
- **Source**: Built-in GPS module in the OBD device (NOT from OBD-II port)
- **OBD-II standard does NOT include GPS** - it's a separate component
- **Accuracy**: 5-10 meters typically
- **Continuous tracking**: Yes, when vehicle is on

### ✅ Mileage
- **Primary source**: Vehicle ECU odometer via OBD-II (if supported)
- **Fallback**: GPS distance calculation
- **Alternative**: Speed × time from OBD-II speed data
- **Accuracy**: Varies by vehicle make/model and device capability

---

## Technical Explanation

### What OBD-II Port Provides (Vehicle ECU Data)
```
✅ Vehicle speed (from ECU)
✅ Engine RPM
✅ Fuel level
✅ Engine temperature
✅ Diagnostic trouble codes (DTCs)
✅ Odometer reading (if vehicle supports it)
❌ NO GPS/location data
```

### What Telematics OBD Devices Add
Telematics OBD devices are **hybrid devices** that combine multiple components:

1. **OBD-II Connector** → Reads vehicle ECU
2. **GPS Module** → Provides location (separate hardware)
3. **Cellular Modem** → Transmits data
4. **Accelerometer** → Detects driving behavior

---

## Data Capture Comparison

| Data | Smartphone Only | OBD Telematics Device |
|------|----------------|----------------------|
| **Location (GPS)** | ✅ Yes | ✅ Yes (built-in GPS) |
| **Mileage (GPS calc)** | ✅ Yes | ✅ Yes |
| **Mileage (ECU odometer)** | ❌ No | ✅ Yes (if supported) |
| **Vehicle Speed** | ⚠️ Estimated | ✅ Accurate (from ECU) |
| **Engine RPM** | ❌ No | ✅ Yes |
| **Fuel Level** | ❌ No | ✅ Yes (if supported) |
| **Hard Braking** | ✅ Yes (accelerometer) | ✅ Yes (accelerometer) |
| **Works when phone off** | ❌ No | ✅ Yes |
| **Battery drain** | ⚠️ High | ✅ None (phone) |

---

## Key Advantage of OBD for Insurance

### **Odometer Verification & Fraud Detection**

OBD devices can read the **actual vehicle odometer** from the ECU, which provides:

1. **Fraud Prevention**
   - Detect odometer tampering
   - Verify user-reported mileage
   - Compare OBD odometer vs GPS distance

2. **More Reliable Mileage**
   - GPS can have signal gaps (tunnels, parking garages)
   - OBD odometer is continuous and accurate
   - Direct from vehicle's own system

3. **Insurance Use Cases**
   - Verify low-mileage discounts
   - Detect mileage fraud in claims
   - Accurate usage-based insurance pricing

---

## Implementation Notes for DriveOn

### Smartphone-Only Approach (Phase 1)
- ✅ Location: GPS from phone
- ✅ Mileage: Calculated from GPS waypoints
- ⚠️ Limitations: Requires phone to be present, battery drain, GPS gaps

### OBD Device Approach (Phase 2)
- ✅ Location: GPS from device
- ✅ Mileage: ECU odometer (preferred) OR GPS fallback
- ✅ Advantages: Works without phone, no battery drain, odometer verification
- ⚠️ Cost: KSh 8,000-20,000 per device

### Hybrid Approach (Recommended)
- Use smartphone for basic telematics (low barrier)
- Offer OBD upgrade for users wanting:
  - Higher premium discounts
  - Odometer verification
  - Continuous tracking
  - More accurate data

---

## Database Schema Consideration

When implementing, track the **data source** for mileage:

```sql
distance_km DECIMAL(10,2),
distance_source VARCHAR,  -- 'gps', 'obd_odometer', 'obd_speed_calc'
odometer_reading INTEGER,  -- actual odometer from OBD (if available)
```

This allows you to:
- Prefer OBD odometer when available (most accurate)
- Fall back to GPS calculation
- Detect discrepancies (potential fraud)
- Provide data quality metrics to insurance partners

---

## Bottom Line

**Yes, OBD telematics devices capture both location and mileage**, but:
- **Location comes from GPS module** (not OBD-II)
- **Mileage can come from ECU odometer** (best) or GPS calculation
- **OBD provides additional value**: odometer verification, fraud detection, continuous tracking
- **For Kenya market**: Start with smartphone, offer OBD as premium upgrade
