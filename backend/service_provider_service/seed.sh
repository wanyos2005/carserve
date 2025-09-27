#!/bin/bash

BASE_URL="http://localhost:8000/service-providers"

# --- Provider categories ---
echo "---- Seeding Provider Categories ----"
PROVIDER_CATEGORIES=("Garage" "Insurance" "Car Wash" "Towing" "Tyres" "Spare Parts" "Painting" "Detailing" "Battery Shop" "Roadside Assistance")
for CAT in "${PROVIDER_CATEGORIES[@]}"; do
  curl -s -X POST $BASE_URL/categories/provider-categories \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$CAT\"}" | jq
done

# --- Service categories ---
echo "---- Seeding Service Categories ----"
SERVICE_CATEGORIES=("Car Wash" "Towing" "Repair" "Tyres" "Painting" "Detailing" "Insurance Claim" "Diagnostics" "Battery Replacement" "Inspection")
for CAT in "${SERVICE_CATEGORIES[@]}"; do
  curl -s -X POST $BASE_URL/categories/service-categories \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$CAT\"}" | jq
done

# --- Providers ---
echo "---- Seeding Providers ----"

NAMES=("Mombasa Road Garage" "Westlands AutoCare" "Kilimani Car Wash" "Karen Tyre Centre" "Thika Road Towing" "Ngong Spare Parts" "Industrial Area Auto Paint" "Lavington Car Detailing" "CBD Battery Hub" "Eastleigh Roadside Assist")
ADDRESSES=("Mombasa Road, Nairobi" "Westlands, Nairobi" "Kilimani, Nairobi" "Karen, Nairobi" "Thika Road, Nairobi" "Ngong, Kajiado" "Industrial Area, Nairobi" "Lavington, Nairobi" "Nairobi CBD" "Eastleigh, Nairobi")
LATS=(-1.322 -1.266 -1.300 -1.328 -1.220 -1.375 -1.295 -1.290 -1.283 -1.280)
LNGS=(36.821 36.812 36.799 36.720 37.020 36.650 36.860 36.770 36.820 36.850)

for i in {0..9}; do
  CATEGORY_ID=$(( (i % 10) + 15 ))   # now generates 15–24

  PROVIDER=$(curl -s -X POST $BASE_URL/ \
    -H "Content-Type: application/json" \
    -d "{
          \"category_id\": $CATEGORY_ID,
          \"name\": \"${NAMES[$i]}\",
          \"description\": \"${NAMES[$i]} provides reliable automotive services in Nairobi.\",
          \"location\": {
            \"address\": \"${ADDRESSES[$i]}\",
            \"lat\": ${LATS[$i]},
            \"lng\": ${LNGS[$i]}
          },
          \"contact_info\": {
            \"phone\": \"+25470000$((100+i))\",
            \"email\": \"provider$((i+1))@example.com\",
            \"website\": \"https://www.${NAMES[$i]// /}.co.ke\"
          },
          \"is_registered\": true
        }")

  echo $PROVIDER | jq
  PROVIDER_ID=$(echo $PROVIDER | jq -r '.id // empty')

  if [ -n "$PROVIDER_ID" ]; then
    echo "---- Creating Service for ${NAMES[$i]} ----"
    SERVICE_CATEGORY_ID=$(( (i % 10) + 18 ))  # service categories are 18–27
    curl -s -X POST $BASE_URL/$PROVIDER_ID/services \
      -H "Content-Type: application/json" \
      -d "{
            \"category_id\": $SERVICE_CATEGORY_ID,
            \"name\": \"Standard Service Package\",
            \"description\": \"Comprehensive service offered by ${NAMES[$i]}\",
            \"price_range\": \"KES $((i+1))000 - KES $((i+2))500\",
            \"requirements\": {\"booking\": true, \"duration\": \"${i}0min\"}
          }" | jq
  else
    echo "❌ Failed to create provider $i"
  fi
done
